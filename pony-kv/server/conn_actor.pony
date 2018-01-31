use "debug"

use "server/engine"
use "optional"


actor ConnActor

  let _engine: StorageEngine tag
  var _state: Optional[SEState] = None
  var _op_queue: Array[{()} iso] = Array[{()} iso](0)

  new create(engine: StorageEngine tag) =>
    _engine = engine
    refresh()

  be receive_state(state: SEState) =>
    _state = state
    Debug("ConnActor: received state")

    // executing ops that were registered for
    // the next state change
    while _op_queue.size() > 0 do
      try
        let op = _op_queue.pop()?
        op.apply()
      end
    end

  be refresh() =>
    _engine.request_state(this)

  be _register(op: {()} iso, state: Optional[SEState]) =>
    """
    register operation to occur after the next state update

    or execute immediately if state already changed
    """
    if _state isnt state then
      // immediately execute operation if state has already changed
      op.apply()
    else
      // register for next state change
      _op_queue.push(consume op)
    end

  be get(k: Array[U8] val, cb: {(Optional[Array[U8] val])} iso) =>
    """
    get the value for k

    It is possible that this function is returning `None` to the callback `cb`
    if the initial state has not yet been sent to this actor.
    In this case retry.
    """
    let value_opt = Opt.flat_map[SEState, Array[U8] val](_state, {(s) => s.get(k)})
    cb(value_opt)

  be set(k: Array[U8] val, v: Array[U8] val) =>
    """
    asynchronously setting k to v
    using optimistic concurrency control.

    If the state is not the latest one, from the
    storage engines point of view,
    we request a state update and then try again (also asynchronously).

    There is currently no way to get to know when exactly the operation
    succeeded.
    """
    match _state
    | let n: None =>
      _register(recover this~set(k, v) end, _state)
    | let current_state: SEState =>
      let new_state = current_state.set(k, v)
      let that = recover tag this end
      _engine.send_state(
        current_state,
        new_state,
        that,  // StateRequestor for receiving state update on success
        {() => // retry callback
          that.refresh()
          that._register(recover that~set(k, v) end, _state)
        })
    end

  be delete(k: Array[U8] val) =>
    match _state
    | let n: None =>
      _register(recover this~delete(k) end, _state)
    | let current_state: SEState =>
      let new_state = current_state.delete(k)
      let that = recover tag this end
      _engine.send_state(
        current_state,
        new_state,
        that,  // StateRequestor for receiving state update on success
        {() => // retry callback
          that.refresh()
          that._register(recover that~delete(k) end, _state)
        })
    end

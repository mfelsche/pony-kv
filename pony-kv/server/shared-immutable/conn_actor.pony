use "debug"
use "maybe"

use "server/shared-immutable/engine"


actor ConnActor is StateRequestor

  let _engine: StorageEngine tag
  var _state: Maybe[SEState] = None

  new create(engine: StorageEngine tag) =>
    _engine = engine
    _engine.request_state(this) // request initial state
    _engine.register(this)

  be receive_state(state: SEState) =>
    _state = state
    Debug("ConnActor: received state")

  be get(k: Array[U8] val, cb: {(Maybe[Array[U8] val])} iso) =>
    let value_opt = Opt.flat_map[SEState, Array[U8] val](_state, {(s) => s.get(k)})
    cb(value_opt)

  be set(k: Array[U8] val, v: Array[U8] val) =>
    _engine.send_mutation(
      {(state: SEState): SEState => state.set(k, v) })

  be delete(k: Array[U8] val) =>
    _engine.send_mutation(
      {(state: SEState): SEState => state.delete(k) })

  be dispose() =>
    _engine.unregister(this)

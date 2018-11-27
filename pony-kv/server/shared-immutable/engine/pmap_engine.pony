use "debug"
use "time"
use "collections/persistent"
use "maybe"
use collections = "collections"

actor PersistentMapStorageEngine is StorageEngine
  var _state: SEState
  var _mutations: USize = 0
  let _update_after_mutations: USize
  let _registered_receivers: collections.SetIs[StateRequestor tag] = collections.SetIs[StateRequestor tag]

  new create(update_after_mutations: USize) =>
    _update_after_mutations = update_after_mutations
    _state = PersistentMapSEState
    // TODO add timer

  be register(requestor: StateRequestor tag) =>
    _registered_receivers.set(requestor)

  be unregister(requestor: StateRequestor tag) =>
    _registered_receivers.unset(requestor)

  be request_state(requestor: StateRequestor tag) =>
    """
    one shot requesting of the current state
    """
    requestor.receive_state(_state)

  be send_mutation(mutation: {(SEState): SEState} val) =>
    let new_state = mutation.apply(_state)
    if new_state isnt _state then
      // we have an actual mutation
      _state = new_state
      _mutations = _mutations + 1
      if _mutations >= _update_after_mutations then
        _send_state()
      end
    end

  fun ref _send_state() =>
    for requestor in _registered_receivers.values() do
      requestor.receive_state(_state)
    end
    _mutations = 0 // reset


primitive ByteArrayHashFunction is collections.HashFunction[Array[U8] val]

  fun hash(x: box->Array[U8] val!): USize =>
    @ponyint_hash_block[USize](x.cpointer(), x.size())

  fun eq(x: box->Array[U8] val!, y: box->Array[U8] val!): Bool =>
    if x.size() != y.size() then
      return false
    end

    let xi = x.values()
    let yi = y.values()

    try
      while xi.has_next() and yi.has_next() do
        if xi.next()? != yi.next()? then
          return false
        end
      end
    else
      false
    end
    true

type ByteMap is HashMap[Array[U8] val, Array[U8] val, ByteArrayHashFunction]

class val PersistentMapSEState is SEState
  let _map: ByteMap

  new val create() =>
    _map = _map.create()

  new val _copy(map: ByteMap) =>
    _map = map

  fun val get(k: Array[U8] val): Maybe[Array[U8] val] =>
    try
      _map(k)?
    else
      None
    end

  fun val set(k: Array[U8] val, v: Array[U8] val): SEState =>
    PersistentMapSEState._copy(_map.update(k, v))

  fun val delete(k: Array[U8] val): SEState =>
    try
      PersistentMapSEState._copy(_map.remove(k)?)
    else
      this
    end


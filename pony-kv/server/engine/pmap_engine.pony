use "debug"
use "collections/persistent"
use "optional"
use collections = "collections"

actor PersistentMapStorageEngine is StorageEngine
  var _state: SEState

  new create() =>
    _state = PersistentMapSEState

  be request_state(requestor: StateRequestor tag) =>
    requestor.receive_state(_state)

  be send_state(
    old_state: SEState,
    state: SEState,
    requestor: StateRequestor tag,
    retry_cb: {()} iso
  ) =>
    if old_state isnt _state then
      Debug("state sent comes from stale old state, retrying")
      retry_cb.apply()
      return
    else
      // new state comes from current state, accept new state
      // and send to requestor
      _state = state
      requestor.receive_state(_state)
    end

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

  fun val get(k: Array[U8] val): Optional[Array[U8] val] =>
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


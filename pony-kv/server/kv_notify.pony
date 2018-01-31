use "net"
use "engine"

class iso KVConnectionNotify is TCPConnectionNotify

  let _env: Env
  let _conn_actor: ConnActor

  new iso create(env: Env, storage_engine: StorageEngine tag) =>
    _env = env
    _conn_actor = ConnActor(storage_engine)

  fun ref received(
    conn: TCPConnection ref,
    data: Array[U8] iso,
    times: USize)
    : Bool
  =>
    // TODO: parse and send commands to _conn_actor
    true

  fun ref connect_failed(conn: TCPConnection ref) =>
    _env.err.print("connect failed")


class iso KVListenNotify is TCPListenNotify
  let _env: Env
  let _storage_engine: StorageEngine tag

  new iso create(env: Env) =>
    _env = env
    _storage_engine = PersistentMapStorageEngine

  fun ref connected(listen: TCPListener ref): TCPConnectionNotify iso^ =>
    KVConnectionNotify(_env, _storage_engine)

  fun ref not_listening(listen: TCPListener ref) =>
    None

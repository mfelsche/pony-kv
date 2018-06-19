use "net"
use "engine"
use "buffered"
use "debug"
use "resp"

class iso KVConnectionNotify is TCPConnectionNotify

  let _env: Env
  let _conn_actor: ConnActor
  let _cmd_parser: CommandParser

  new iso create(env: Env, storage_engine: StorageEngine tag) =>
    _env = env
    _conn_actor = ConnActor(storage_engine)
    _cmd_parser = CommandParser({(_) => None })

  fun _get(cmd: Array[String] val, respond: Respond) ? =>
    let key = cmd(1)?
    _conn_actor.get(
      key.array(),
      {(o) =>
        let r =
          match o
          | None => None
          | let value: Array[U8] val => String.from_array(value)
          end
        respond(r)
      })

  fun _set(cmd: Array[String] val, respond: Respond) ? =>
    let key = cmd(1)?
    let value = cmd(2)?
    _conn_actor.set(
      key.array(),
      value.array())
    respond.ok()

  fun _delete(cmd: Array[String] val, respond: Respond) =>
    for key in cmd.trim(1, cmd.size()).values() do
      _conn_actor.delete(key.array())
    end
    respond.ok()

  fun _ping(respond: Respond) =>
    respond.simple("PONG")

  fun ref received(
    conn: TCPConnection ref,
    data: Array[U8] iso,
    times: USize)
    : Bool
  =>
    _cmd_parser.append(consume data)
    let respond = Respond(recover tag conn end)
    for cmd in _cmd_parser do
      try
        match cmd(0)?
        | "ping" => _ping(respond)
        | "PING" => _ping(respond)
        | "get"  => _get(cmd, respond)?
        | "GET"  => _get(cmd, respond)?
        | "set"  => _set(cmd, respond)?
        | "SET"  => _set(cmd, respond)?
        | "del"  => _delete(cmd, respond)
        | "DEL"  => _delete(cmd, respond)
        | let s: String val => respond.err("Unknown Command " + s)
        end
      else
        respond.err("Invalid Request.")
      end
    end
    true

  fun ref connect_failed(conn: TCPConnection ref) =>
    _env.err.print("connect failed")


class iso KVListenNotify is TCPListenNotify
  let _env: Env
  let _storage_engine: StorageEngine tag

  new iso create(env: Env) =>
    _env = env
    // TODO: make storage engine configurable
    _storage_engine = PersistentMapStorageEngine

  fun ref connected(listen: TCPListener ref): TCPConnectionNotify iso^ =>
    KVConnectionNotify(_env, _storage_engine)


  fun ref listening(listen: TCPListener ref) =>
    ifdef debug then
      let addr = listen.local_address()
      let port: U16 = addr.port()
      let ip: U32 = addr.ipv4_addr()
      _env.out.print("listening on " +
          (ip >> 24).u8().string() + "." +
          (ip >> 16).u8().string() + "." +
          (ip >> 8).u8().string() + "." +
          ip.u8().string() + ":" + port.string())
    else
      None
    end

  fun ref not_listening(listen: TCPListener ref) =>
    None

use "net"
use "engine"
use "buffered"
use "debug"

class iso KVConnectionNotify is TCPConnectionNotify

  let _env: Env
  let _conn_actor: ConnActor
  let _reader: Reader

  new iso create(env: Env, storage_engine: StorageEngine tag) =>
    _env = env
    _conn_actor = ConnActor(storage_engine)
    _reader = Reader

  fun _get(cmd: RESPArray, conn: TCPConnection) ? =>
    let key = cmd.data(1)? as RESPBulkString
    _conn_actor.get(
      key.data.array(),
      {(o) =>
        let r =
          match o
          | None => None
          | let value: Array[U8] val =>
            RESPBulkString(value)
          end
        conn.writev(RESPCodec.serialize(r))
      })

  fun _set(cmd: RESPArray, conn: TCPConnection) ? =>
    let key = cmd.data(1)? as RESPBulkString
    let value = cmd.data(2)? as RESPBulkString
    _conn_actor.set(
      key.data.array(),
      value.data.array())
    conn.writev(RESPCodec.serialize("OK"))

  fun _delete(cmd: RESPArray, conn: TCPConnection) ? =>
    for key in cmd.data.values() do
      _conn_actor.delete((key as RESPBulkString).data.array())
    end
    conn.writev(RESPCodec.serialize("OK"))

  fun _ping(conn: TCPConnection) =>
    conn.writev(RESPCodec.serialize("PONG"))

  fun ref received(
    conn: TCPConnection ref,
    data: Array[U8] iso,
    times: USize)
    : Bool
  =>
    let ds = data.size()
    Debug("received " + ds.string() + " bytes")
    let tconn = recover tag conn end
    _reader.append(consume data)
      try
        let resp = RESPCodec.deserialize(_reader)?
        match resp
        | let array: RESPArray if array.data.size() > 0 =>
          try
            // extract command
            let cmd = array.data(0)? as RESPBulkString
            match cmd.data
            | "ping" => _ping(tconn)
            | "PING" => _ping(tconn)
            | "get"  => _get(array, tconn)?
            | "GET"  => _get(array, tconn)?
            | "set"  => _set(array, tconn)?
            | "SET"  => _set(array, tconn)?
            | "del"  => _delete(array, tconn)?
            | "DEL"  => _delete(array, tconn)?
            | let s: String val =>
              conn.writev(
                RESPCodec.serialize(
                  RESPError("Unknown Command " + s)))
            end
          else
            conn.writev(
              RESPCodec.serialize(
                RESPError("Invalid Request.")))
          end
        else
          conn.writev(
            RESPCodec.serialize(
              RESPError("Invalid Request.")))
        end
      else
        conn.writev(
          RESPCodec.serialize(
            RESPError("Error Deserializing Request.")))
      end
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


  fun ref listening(listen: TCPListener ref) =>
    ifdef debug then
      let addr = listen.local_address()
      let port: U16 = @ntohs[U16](addr.port)
      let ip: U32 = @ntohl[U32](addr.addr)
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

use "net"
use "debug"

use "resp"
use "maybe"

class iso SingleKVConnectionNotify is TCPConnectionNotify
  let _env: Env
  let _single_kv_actor: SingleKVActor
  let _cmd_parser: CommandParser

  new iso create(env: Env, single_kv_actor: SingleKVActor) =>
    _env = env
    _single_kv_actor = single_kv_actor
    _cmd_parser = CommandParser({(_) => None })

  fun ref _ping(respond: Respond) =>
    respond.simple("PONG")

  fun ref _get(cmd: Array[String] val, respond: Respond) ? =>
    let key = cmd(1)?
    _single_kv_actor.get(
      key,
      {(value: Maybe[String]) => respond(value)})

  fun ref _set(cmd: Array[String] val, respond: Respond) ? =>
    let key = cmd(1)?
    let value = cmd(2)?
    _single_kv_actor.set(key, value)
    respond.ok()

  fun ref _delete(cmd: Array[String] val, respond: Respond) =>
    _single_kv_actor.delete(cmd)
    respond.ok()

  fun ref received(conn: TCPConnection ref, data: Array[U8] iso, times: USize): Bool =>
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


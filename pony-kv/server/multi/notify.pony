use "net"
use "debug"

use "resp"
use "maybe"

class iso MultiKVConnectionNotify is TCPConnectionNotify
  let _env: Env
  let _cmd_parser: CommandParser

  new iso create(env: Env) =>
    _env = env
    _cmd_parser = CommandParser({(_) => None })

  fun ref _ping(respond: Respond) =>
    respond.simple("PONG")

  fun ref _get(cmd: Array[String] val, respond: Respond) ? =>
    let key = cmd(1)?

  fun ref _set(cmd: Array[String] val, respond: Respond) ? =>
    let key = cmd(1)?
    let value = cmd(2)?
    respond.ok()

  fun ref _delete(cmd: Array[String] val, respond: Respond) =>
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


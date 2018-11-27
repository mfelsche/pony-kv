
"""

## Simple Key Value Store - Server

This Key Value Store is reachable via TCP talking a line based protocol.

Every new connection is handled by a single actor.

The actual store is implemented using a kv_engine which is responsible to hold
the data and provides an interface for adding, deleting, and getting it.

Each connections actor has a reference to the kv_engine, which is updated on every

"""

use "cli"
use "net"
use single = "server/single"
use shared_immutable = "server/shared-immutable"
use multi = "server/multi"


actor Main
  new create(env: Env) =>
    let cmd_spec =
      try
        CommandSpec.parent(
          "pony-kv",
          "A simple Key Value Store - Server",
          [
            OptionSpec.i64("port", "TCP port" where short' = 'p', default' = I64(65535))
            OptionSpec.string("host", "hostname or IP address" where short' = 'h', default' = "127.0.0.1")
          ],
          [
            single.SingleCLI.command_spec()?
            shared_immutable.SharedImmutableCLI.command_spec()?
            multi.MultiCLI.command_spec()?
          ])? .> add_help()?
      else
        env.exitcode(1)
        return
      end

    let cmd =
      match CommandParser(cmd_spec).parse(env.args, env.vars)
      | let c: Command => c
      | let ch: CommandHelp =>
        ch.print_help(env.out)
        env.exitcode(0)
        return
      | let se: SyntaxError =>
        env.err.print(se.string())
        env.exitcode(1)
        return
      end
    let host = recover val cmd.option("host").string() end
    let port = recover val cmd.option("port").i64().string() end

    try
      let listener =
        match cmd.spec().name()
        | single.SingleCLI.name() =>
          env.out.print("starting single KV store")
          single.SingleKVListener(env)
        | shared_immutable.SharedImmutableCLI.name() =>
          env.out.print("starting shared-immtable KV store")
          shared_immutable.KVListenNotify(env)
        | multi.MultiCLI.name() =>
          env.out.print("starting multi KV store")
          multi.MultiKVListener(env)
        else
          env.err.print("unknown kv store engine")
          env.exitcode(1)
          return
        end
      TCPListener(
        env.root as AmbientAuth,
        consume listener,
        host,
        port
      )
    else
      env.err.print("Unable to start listening on " + host + ":" + port)
      env.exitcode(1)
      return
    end


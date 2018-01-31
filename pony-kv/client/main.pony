use "cli"
use "net"

actor Main
  new create(env: Env) =>

    let cmd_spec =
      try
        CommandSpec.leaf(
          "pony-kv",
          "A simple Key Value Store - Server",
          [
            OptionSpec.i64("port", "TCP port" where short' = 'p', default' = I64(65535))
            OptionSpec.string("host", "hostname or IP address" where short' = 'h', default' = "127.0.0.1")
          ],
          [
            ArgSpec.string("" where default' = "") // dummy
          ])? .> add_help()?
      else
        env.exitcode(1)
        return
      end

    let cmd =
      match CommandParser(cmd_spec).parse(env.args, env.vars())
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

    env.out.print("connecting to " + host + ":" + port)

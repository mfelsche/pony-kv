use "net"

class iso MultiKVListener is TCPListenNotify
  let _env: Env

  new iso create(env: Env) =>
    _env = env

  fun ref connected(listen: TCPListener ref): TCPConnectionNotify iso^ =>
    MultiKVConnectionNotify(_env)

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
    end

  fun ref not_listening(listen: TCPListener ref) =>
    _env.err.print("not listening")

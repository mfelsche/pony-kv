use "net"

class iso SingleKVListener is TCPListenNotify
  let _env: Env
  let _single_kv_actor: SingleKVActor

  new iso create(env: Env) =>
    _env = env
    _single_kv_actor = SingleKVActor

  fun ref connected(listen: TCPListener ref): TCPConnectionNotify iso^ =>
    SingleKVConnectionNotify(_env, _single_kv_actor)

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

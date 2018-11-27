use "collections"
use "maybe"

actor SingleKVActor
  let _state: Map[String, String] = Map[String, String](4096)

  be get(key: String val, cb: {(Maybe[String])} val) =>
    let res: Maybe[String] = try _state(key)? end
    cb.apply(res)

  be set(key: String val, value: String val) =>
    _state(key) = value

  be delete(keys: Array[String] val) =>
    for key in keys.values() do
      try _state.remove(key)? end
    end


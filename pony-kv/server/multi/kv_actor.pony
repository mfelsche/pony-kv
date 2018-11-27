
actor KVActor
  let _value: String

  new create(value: String) =>
    _value = value

  be apply(cb: {(String)} val) => cb(_value)


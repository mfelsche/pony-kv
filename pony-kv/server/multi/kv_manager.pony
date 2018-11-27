use "collections/persistent"

actor KVManager
  var _state: Map[String, KVActor] = Map[String, KVActor]

  be add(key: String, kv_actor: KVActor) =>
    let old_state = _state = _state.update(key, kv_actor)
    if old_state isnt _state then
      // TODO
      None
    end

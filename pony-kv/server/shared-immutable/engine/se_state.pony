use "maybe"

trait val SEState
  fun val get(k: Array[U8] val): Maybe[Array[U8] val]

  fun val set(k: Array[U8] val, v: Array[U8] val): SEState

  fun val delete(k: Array[U8] val): SEState


type Optional[T] is (T | None)

primitive Opt

  fun get[T](opt: Optional[T], other: T): T =>
    match consume opt
    | let n: None => consume other
    | let o: T => consume o
    end

  fun map[T, R](opt: Optional[T], operation: {(T): R}): Optional[R] =>
    match consume opt
    | let n: None => None
    | let o: T => operation.apply(consume o)
    end

  fun flat_map[T, R](opt: Optional[T], operation: {(T): Optional[R]}): Optional[R] =>
    match consume opt
    | let n: None => None
    | let o: T => operation.apply(consume o)
    end

  fun filter[T](opt: Optional[T], predicate: {(T): (Bool, T^)}): Optional[T] =>
    match consume opt
    | let n: None => None
    | let o: T =>
      (let satisfied: Bool, let o2: T) = predicate.apply(consume o)
      if satisfied then
        consume o2
      else
        None
      end
    end

  fun apply[T](opt: Optional[T], operation: {(T): None}): None =>
    match consume opt
    | let o: T => operation.apply(consume o)
    end

  fun force[T](opt: Optional[T]): T ? =>
    (consume opt) as T

  fun iter[T](opt: Optional[T]): Iterator[T]^ =>
    // TODO: use iftype
    match consume opt
    | let n: None =>
      object ref is Iterator[T]
        fun ref has_next(): Bool => false
        fun ref next(): T ? => error
      end
    | let o: T =>
      object is Iterator[T]
        var _has_next: Bool = true
        var _o: Optional[T] = consume o
        fun ref has_next(): Bool => _has_next

        fun ref next(): T ? =>
          _has_next = false
          Opt.force[T](_o = None)?
      end
    end

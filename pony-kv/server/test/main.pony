use ".."
use "../engine"
use "ponytest"

class iso DummyTest is UnitTest
  fun name(): String => "dummy"

  fun apply(h: TestHelper) =>
    let se = PersistentMapStorageEngine
    let conn_actor = ConnActor(se)
    h.assert_true(true)

actor Main is TestList
  new create(env: Env) => PonyTest(env, this)

  new make() => None

  fun tag tests(test: PonyTest) =>
    test(DummyTest)


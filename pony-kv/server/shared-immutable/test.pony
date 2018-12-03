use ".."
use "engine"
use "ponytest"

class iso DummyTest is UnitTest
  fun name(): String => "dummy"

  fun apply(h: TestHelper) =>
    let se = PersistentMapStorageEngine(1000)
    let conn_actor = ConnActor(se)
    h.assert_true(true)

actor SharedImmutableTestList is TestList
  new make() => None

  fun tag tests(test: PonyTest) =>
    test(DummyTest)


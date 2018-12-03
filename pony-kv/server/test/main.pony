use "ponytest"
use "../shared-immutable"

actor Main is TestList
  new create(env: Env) => PonyTest(env, this)

  new make() => None

  fun tag tests(test: PonyTest) =>
    SharedImmutableTestList.make().tests(test)


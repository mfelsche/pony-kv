use "cli"

primitive SharedImmutableCLI
  fun name(): String => "shared-immutable"
  fun command_spec(): CommandSpec ? =>
    CommandSpec.leaf(
      name(),
      "Key-Value Store sharing immutable copies of the current state with the connection actors")?

use "cli"

primitive MultiCLI
  fun name(): String => "multi"
  fun command_spec(): CommandSpec ? =>
    CommandSpec.leaf(
      name(),
      "Key-Value Store modeling each key-value pair as a separate actor")?

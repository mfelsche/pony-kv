use "cli"

primitive SingleCLI
  fun name(): String => "single"
  fun command_spec(): CommandSpec ? =>
    CommandSpec.leaf(
      name(),
      "Key-Value Store with a single actor maintaining the whole state in a single map")?

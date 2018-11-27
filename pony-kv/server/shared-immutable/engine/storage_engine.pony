interface StateRequestor
  be receive_state(state: SEState)

trait StorageEngine
  be send_mutation(mutation: {(SEState): SEState} val)
  be request_state(requestor: StateRequestor tag)
  be register(requestor: StateRequestor tag)
  be unregister(requestpr: StateRequestor tag)


interface StateRequestor
  be receive_state(state: SEState)

trait StorageEngine

  be request_state(requestor: StateRequestor tag)

  be send_state(
    old_state: SEState,
    state: SEState,
    requestor: StateRequestor tag,
    retry_cb: {()} iso
  )


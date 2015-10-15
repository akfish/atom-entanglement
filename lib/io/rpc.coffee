class RPC
  constructor: (@io) ->

  invoke: (args..., cb) ->
    if not @io.connected
      throw new Error("Not connected")

    payload =
      args: args
    @io.emit rpc, payload, cb

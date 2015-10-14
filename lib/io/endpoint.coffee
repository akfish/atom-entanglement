IO = require('socket.io-client')
module.exports =
class Endpoint
  constructor: (@url, @type) ->
    @io = IO(@url)

    @io.on "connect", @onConnect.bind(@)
    @io.on "error", @onError.bind(@)
    @io.on "disconnect", @onDisconnect.bind(@)

  onConnect: ->
    console.log "Endpoint connected #{@type}:#{@io.id}"
    @register()

  onError: (err) ->
    console.log "Endpoint error: "
    console.log err

  onDisconnect: ->

  register: ->
    console.log "Registering as #{@type}"
    @io.emit "register", type: @type, (err, ac) =>
      if err?
        console.log "Endpoint refused by server: "
        console.log err
        return
      console.log "Endpoint accepted by server"
      console.log ac

      console.log "Try connect to /atom"
      atom_io = IO "#{@url}atom", {forceNew: true, query: "access_token=#{ac.token}"}

      atom_io.on "connect", => console.log "Connected to /atom as #{@type}"
      atom_io.on "error", (err) ->
        # TODO: re-register is token is not valid
        console.log err

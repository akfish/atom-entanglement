IO = require('socket.io-client')
module.exports =
class Endpoint
  constructor: (@url, @type) ->
    @io = IO(@url, {forceNew: true})

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
    id = @io.id
    @io.emit "register", type: @type, (err, ac) =>
      # TODO: ac should contain an unique ID
      #       such ID will be sent if available
      #       in case of losing connection
      if err?
        console.log "Endpoint refused by server: #{id}"
        console.log err
        return
      console.log "Endpoint accepted by server #{id}"
      console.log ac

      @atom_io?.disconnect()

      console.log "Try connect to /atom #{id}"
      @atom_io = atom_io = IO "#{@url}atom", {forceNew: true, query: "access_token=#{ac.token}&parent=#{id}"}

      atom_io.on "connect", => console.log "Connected to /atom as #{@type}:#{id}"
      atom_io.on "error", (err) =>
        # TODO: re-register is token is not valid
        console.log "#{err} #{id}"
        atom_io.disconnect()
        if /^Access token is not valid/.test err
          console.log "Re-register"
          # @register()

  of: (namespace) ->

if require.main == module
  console.log "Loaded"
  app = require('express')()
  server = require('http').Server(app)
  sio = require('socket.io')(server)

  atom_io =   sio.of '/atom'      # atom registery
  device_io = sio.of '/device'    # device registery
  log_io =    sio.of '/log'       # log channel
  rpc_io =    sio.of '/rpc'       # rpc channel

  # 0. Namespace / is for watch dogs
  # 1. Atoms/devices must first complete registery on /.
  #    Each ns should do auth as configured. Server will hold their socket.id
  #    as authentication token.
  # 2. Then they can connect to `/rpc` channel and request endpoint list.
  # 3. They can connect to `/log` channel to read and write logs
  # 4. Atoms can control server on `/atom` channel
  # 5. They can perform RPC over `/rpc` channel

  epAC =
    atom:
      primary: '/atom'
      allowed: ['/atom', '/rpc', '/log']
    device:
      primary: '/device'
      allowed: ['/device', '/rpc', '/log']

  epReg = {}

  accessControl = (ns) ->
    (socket, next) ->
      console.log "AC #{socket.id}"
      access_token = socket.handshake.query.access_token
      if not access_token?
        console.log "No access_token"
        return next(new Error("Access token is not provided"))
      if not epReg[access_token]?
        console.log "Invalid access_token"
        return next(new Error("Access token is not valid"))

      # TODO: validate token against socket.id
      type = epReg[access_token]
      ac = epAC[type]

      if ns not in ac.allowed
        console.log "Endpoint '#{type}' is not allowed to access #{ns}"
        return next(new Error("Endpoint '#{type}' is not allowed to access #{ns}"))

      next()

  atom_io.use accessControl('/atom')



  crypto = require 'crypto'
  genToken = (type, id) ->
    checksum = crypto.createHash('sha1')
    checksum.update("#{type}:#{id}@#{new Date().getTime()}")
    checksum.digest('hex')

  sio.on "connection", (socket) ->
    console.log "Socket #{socket.id} connected"
    socket.on "register", (ep, cb) ->
      # TODO: only allow localhost to register as atom
      console.log "Registering #{socket.id}"
      console.log ep
      ac = epAC[ep.type]
      if not ac?
        return cb(new Error("Unknown endpoint type: #{ep.type}"))

      # TODO: store token timestamp for validation
      token = genToken ep.type, socket.id
      epReg[token] = ep.type


      cb null, access: ac, token: token


    socket.on "disconnect", ->
      console.log "Socket #{socket.id} disconnected"

  sio.on "error", (err) ->
    console.log err

  start = (port) ->
    console.log "Server started: #{port}"
    server.listen parseInt(port)

  main = (opts) ->
    console.log "Process started: #{process.pid}"
    start opts.port

  console.log process.argv
  opts = require('minimist')(process.argv.slice(2))
  console.log opts
  main(opts)

prepareServerProcessArgv = (opts) ->
  path = require('path')
  coffee_executable = path.resolve __dirname, "../../node_modules/coffee-script/bin/coffee"
  console.log coffee_executable
  console.log opts
  argv = [coffee_executable, __filename]
  for key, value of opts
    argv.push "--#{key}"
    argv.push value
  console.log argv
  argv

module.exports =
  isRunning: (opts, cb) ->
    io = require('socket.io-client')("http://localhost:#{opts.port}/")
    notRunning = (reason) ->
      io.disconnect()
      cb new Error("Server is not running. Reason: #{reason}")
    io.on "connect", ->
      io.disconnect()
      cb null
    io.on "error", notRunning
    io.on "connect_error", notRunning

  watch: (opts) ->
    io = require('socket.io-client')("http://localhost:#{opts.port}/")

    child = null
    killer = -1

    tryRun = =>
      if child?
        if child.exitCode != null
          console.log "Child already existed with #{child.exitCode}"
          child = null
        else if not io.connected
          console.log "Still trying"
          if killer < 0
            console.log "Kill in 10s"
            killer = setTimeout (->
              console.log "Killing child"
              child.kill()
              killer = -1
              tryRun()
              ), 10000
        return

      console.log "Server is down, restarting"
      child ?= this.run opts

    io.on "connect", ->
      if killer > 0
        console.log "Kill the killer"
        clearTimeout killer
      console.log "Server is up"

    io.on "disconnect", ->
      console.log child
      console.log "Disconnected from server"
      tryRun()

    io.on "error", (err) ->
      console.log "Error: "
      console.log err
      tryRun()

    io.on "connect_error", (err) ->
      console.log "Connection error"
      console.log err
      tryRun()

  run: (opts) ->
    console.log "Run"
    {spawn} = require('child_process')
    fs = require('fs')
    log = fs.openSync('i:\\server.log', 'a')
    # log = fs.openSync('./server.log', 'a')

    argv = prepareServerProcessArgv(opts)
    child = spawn 'node', argv, {detached: true, stdio: ['ignore', log, log]}
    child.unref()

    child.on "error", (err) ->
      console.log "Server process error:"
      console.log err

    child.on "exit", (code, signal) ->
      console.log "Server process exited: #{code}, SGN = #{signal}"


    console.log "Server process: #{child.pid}, port: #{opts.port}"

    child

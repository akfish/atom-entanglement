class Logger
  constructor: (@lio, @opts = maxHistory: 1024) ->
    @history = []
    @lio.on 'connection', (socket) =>
      socket.emit 'history', @history
      socket.on 'log', @writeLog.bind(@, socket)

    ['debug', 'info', 'log', 'warn', 'error'].forEach (t) =>
      @[t] = @writeLog.bind(@, null, t)

  writeLog: (socket, type, args) ->
    payload =
      source: socket?.id ? "server"
      type: type
      args: args
      t: new Date().getTime()

    @history.push payload
    if @history.length > @opts.maxHistory
      @history.shift()

    if socket?
      socket.broadcast.emit 'log', payload
      payload.isSelf = true
      socket.emit 'log', payload
      payload.isSelf = false
    else
      @lio.emit 'log', payload

    console.log "[%s][%s][%s] %O", new Date(payload.t), payload.type, payload.source, payload.args

class RemoteLogger
  constructor: (@lio) ->
    Settings = require('../settings')
    ['debug', 'info', 'log', 'warn', 'error'].forEach (t) =>
      @[t] = @writeLog.bind(@, t)
    @lio.on "log", (payload) =>
      if @enbaled
        @formatLog payload
    @lio.on "history", (history) =>
      if @enabled
        history?.forEach (h) => @formatLog h
      @info "Done fetching log history"

    @enabled = Settings.showLog()
    Settings.observeShowLog (v) =>
      @enabled = v

  writeLog: (type, args...) ->
    @lio.emit "log", type, args

  formatLog: (p) ->
    t = new Date(p.t)
    pad = (n, p) ->
      s = "" + n
      p.substr(0, p.length - s.length) + s

    time = "#{pad(t.getHours(), "00")}:#{pad(t.getMinutes(), "00")}:#{pad(t.getMilliseconds(), "000")}"

    src = p.source.substr(0, 'server'.length)

    typeColor =
      debug: '#757575'
      info: '#2196F3'
      log: '#689F38'
      warn: '#EF6C00'
      error: '#E64A19'

    # srcColor =
    #   server: "#03A9F4"
    #   self: "#8BC34A"
    #   other: "#CDDC39"


    resetStyle = "font-weight: initial; color: initial; background: initial; text-decoration: none"
    timeStyle = "font-weight: bold; padding-left: 6px"
    typeStyle = "font-weight: bold; width: 64px; color: white; background: #{typeColor[p.type]}"
    srcStyle = resetStyle
    if p.isSelf
      srcStyle += ";text-decoration: underline"
    # srcType = 'other'
    # if p.src == 'server' then srcType = 'server'
    # if p.src == id then srcType = 'self'
    # srcStyle = "text-decoration: underline; color: srcColor[srcType]"

    console.log "Entangled%c%s%c[%s]%c[%s]", timeStyle, time, typeStyle, pad(p.type, "====="), srcStyle, src, p.args

module.exports = Logger
module.exports.Remote = RemoteLogger

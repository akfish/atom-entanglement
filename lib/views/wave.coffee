Color = require('../util/color')

class Wave
  constructor: (@el, @opts) ->
    @canvas = document.createElement('canvas')
    @el.appendChild(@canvas)
    @initCanvas()

  initCanvas: ->
    @width = @el.offsetWidth
    @height = @el.offsetHeight
    @canvas.width = @width
    @canvas.height = @height
    @ctx = @canvas.getContext('2d')
    @xSize = @opts.xRange[1] - @opts.xRange[0]
    @ySize = @opts.yRange[1] - @opts.yRange[0]
    @xCenter = Math.abs(@opts.xRange[0]/@xSize) * @width
    @yCenter = Math.abs(@opts.yRange[0]/@ySize) * @height
    @xScale = @width / @xSize
    @yScale = @height / @ySize
    @xRes = 1 / @xScale
    @yRes = 1 / @yScale

  _transformContext: ->
    @ctx.translate(@xCenter, @yCenter)
    @ctx.scale(@xScale, -@yScale)

  _interpolate: (fn, params) ->
    points = []
    x = min = @opts.xRange[0]
    max = @opts.xRange[1]
    step = @xRes

    while (x <= max)
      points.push [x, fn(x, params)]
      x += step

    points

  draw: (fn, params, style) ->
    if @width == 0 or @height == 0
      @initCanvas()
    if @width == 0 or @height == 0
      console.warn "Canvas not initialized"
      return
    points = @_interpolate(fn, params)
    @ctx.save()
    @ctx.save()
    @_transformContext()

    # TODO: draw path
    @ctx.beginPath()
    @ctx.moveTo points[0][0], points[0][1]

    for i in [1..points.length - 1]
      p = points[i]
      @ctx.lineTo p[0], p[1]

    @ctx.restore()
    # TODO: set style
    for key, value of style
      @ctx[key] = value

    @ctx.stroke()

    @ctx.restore()

  clear: ->
    @ctx.clearRect 0, 0, @width, @height

  animate: (opts) ->

module.exports = Wave

style =
  lineJoin: 'round'
  lineWidth: 1
  strokeStyle: 'white'
  globalAlpha: 0.3
  shadowBlur: 10
  shadowColor: '#E3F2FD'

historyStyle =
  lineJoin: 'round'
  lineWidth: 0.1
  strokeStyle: 'white'
  globalAlpha: 0.7
  shadowColor: 'blue'
  shadowBlur: 10

NK = 1 / Math.sqrt(2 * Math.PI)
DEFAULT_PARAMS =
  sigma: 0.8
  mu: 0
  P: 6
  k: 5

clone = (obj) ->
  o = {}
  for key, value of obj
    o[key] = value
  o

wavePacket = (f, x, p = DEFAULT_PARAMS) ->
  A = NK / p.sigma
  M = (x - p.mu) / p.sigma
  E = Math.exp(-0.5 * M * M)
  S = p.P * f(p.k * x)

  A * E * S

module.exports.wavePacket = wavePacket

module.exports.animate =
animate = (wave) ->
  period = 3000
  from = 0
  to = 20
  t0 = -1

  interpolate = (t0, t, period) ->
    elapse = t - t0
    f = elapse % period / period
    return f

  linear = (from, to, f) ->
    range = to - from
    return from + f * range

  pingPong = (from, to, f) ->
    range = to - from
    if f < 0.5
      return from + f * 2 * range
    else
      return to - (f - 0.5) * 2 * range

  frame = 0
  history = []
  historyTtl = 1000
  MAX_HISTORY = 22

  fromColor = "#f79459"
  toColor = "#5e4fa2"
  tick = (t) ->
    frame++
    if t0 == -1
      t0 = t
    p = clone(DEFAULT_PARAMS)
    f = interpolate(t0, t, period)
    p.mu = pingPong(from, to, f)
    history.push {p: p, t0: t}
    if history.length > MAX_HISTORY
      history.shift()
    if (t - history[0].t0) > historyTtl
      history.shift()
    wave.clear()
    history.forEach (h, i) ->
      _f = interpolate(h.t0, t, historyTtl)
      _p = clone h.p
      _s = clone historyStyle
      _p.P = pingPong(5, 0, _f) * (1 + Math.random())
      _p.sigma = pingPong(1, 10, _f)
      _p.mu = pingPong(h.p.mu, h.p.mu - 30, _f)

      _c = Color.interpolate(linear, fromColor, toColor, _f)
      _s.globalAlpha = linear(1, 0, _f)
      _s.shadowBlur = linear(1, 300, _f)
      _s.strokeStyle = _c
      _s.shadowColor = _c
      wave.draw wavePacket.bind(undefined, (x) -> -Math.cos(x)), _p, _s
    c = Color.interpolate(pingPong, fromColor, toColor, f)#
    s = clone style
    s.shadowColor = c
    # s.strokeStyle = c
    wave.draw wavePacket.bind(undefined, Math.cos), p, s
    requestAnimationFrame tick

  # animation =
  #   fn: wavePacket.bind(undefined, Math.log10)
  #   period: period
  #   params:
  #     mu: "linear -20 20"
  #   history:
  #     fn: wavePacket.bind(undefined, Math.log)
  #     max: 20
  #     ttl: 1000
  #     params:
  #       P: (p0, f) -> linear(5, 0, f) * (1 + Math.random())
  #       sigma: "linear 1 10"
  #       mu: (p0, f) -> linear(p0.mu, p0.mu - 30)
  #     styles:
  #       globalAlpha: "linear 0.9 0.5"
  #       shadowBlur: "linear 0 300"
  #       strokeStyle: (s0, f) -> linearHSL(fromColor, toColor)
  #       shadowColor: (s0, f) -> linearHSL(fromColor, toColor)

  requestAnimationFrame tick

Color =
  rHex: /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i

  isHex: (a) ->
    Color.rHex.test a

  hex2rgb: (hex) ->
    m = this.rHex.exec hex
    if m?
      return [m[1], m[2], m[3]].map (c) -> parseInt(c, 16)
    else
      return null

  rgb2hex: (c) ->
    "#" + ((1 << 24) + (c[0] << 16) + (c[1] << 8) + c[2]).toString(16).slice(1)

  formatRGBA: (c, alpha = 1) ->
    "rgba(#{c.join(',')},#{alpha})"

  formatHSL: (h) ->
    "hsl(#{h[0]}, #{h[1]}%, #{h[2]}%)"

  rgb2hsl: (c) ->
    [r, g, b] = c
    r /= 255
    g /= 255
    b /= 255
    max = Math.max(r, g, b)
    min = Math.min(r, g, b)
    l = (max + min) / 2
    if max == min
      h = s = 0
    else
      d = max - min
      s = if l > 0.5 then d / (2 - max - min) else d / (max + min)
      switch max
        when r then h = (g - b) / d + (if g < b then 6 else 0)
        when g then h = (b - r) / d + 2
        when b then h = (r - g) / d + 4
      h /= 6

    [h, s, l]

  hsl2rgb: (c) ->
    [h, s, l] = c
    if s == 0
      l = Math.round(l * 255)
      return [l, l, l]

    hue2rgb = (p, q, t) ->
      if t < 0 then t += 1
      if t > 1 then t -= 1
      if t < 1/6 then return p + (q - p) * 6 * t
      if t < 1/2 then return q
      if t < 2/3 then return p + (q - p) * (2/3 - t) * 6
      return p

    q = if l < 0.5 then l * (1 + s) else l + s - l * s
    p = 2 * l - q
    r = hue2rgb p, q, h + 1/3
    g = hue2rgb p, q, h
    b = hue2rgb p, q, h - 1/3
    [Math.round(r * 255), Math.round(g * 255), Math.round(b * 255)]

  interpolate: (fn, from, to, f) ->
    if Color.isHex(from) then from = Color.hex2rgb(from)
    if Color.isHex(to) then to = Color.hex2rgb(to)

    from = Color.rgb2hsl from
    to = Color.rgb2hsl to

    c = []
    for i in [0..2]
      c.push fn(from[i], to[i], f)

    return Color.rgb2hex Color.hsl2rgb c

module.exports = Color

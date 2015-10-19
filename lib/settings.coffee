settings =
  config:
    port:  # http://www.iana.org/assignments/service-names-port-numbers/service-names-port-numbers.xml
      type: 'integer'
      default: 2333
      min: 1024
      max: 49151
    auth:
      type: 'string'
      default: 'None'
      enum: ['None', 'One click']
      title: "Authorization method"
      description: "Method used for device authentication and authorization"
    showLog:
      type: 'boolean'
      default: true
      title: 'Show log messages'
      description: "Show all messages on `/log` channel in dev tools (for debugging)"

title = (s) ->
  s[0].toUpperCase() + s.substr(1)

Object.keys(settings.config).forEach (k) ->
  keyPath = 'atom-entanglement.' + k
  settings[k] = ->
    atom.config.get(keyPath)

  titled = title(k)

  settings["observe#{titled}"] = (cb) ->
    atom.config.observe keyPath, cb

module.exports = settings

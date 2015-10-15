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

Object.keys(settings.config).forEach (k) ->
  settings[k] = ->
    atom.config.get('atom-entanglement.'+k)

module.exports = settings

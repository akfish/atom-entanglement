{$, View} = require('atom-space-pen-views')
{wavePacket} = Wave = require('./wave')
DetailView = require('./detail')
Miao = require 'miao'

module.exports =
class StatusBarView extends View
  @content: ->
    @div {class: 'atom-entanglement-status', click: 'toggleDetailView'}, =>
      @div class: "atom icon entangled-icon-atom"
      @div {outlet: 'waveContainer', class: "wave"}
      @div class: "device icon entangled-icon-device-mobile"


  initialize: (serializedState) ->
    @detailView = new DetailView()
    @updateTooltip("Atom Entanglement")

    $(document).ready =>
      waveOpts =
        xRange: [0, 20]
        yRange: [-5, 5]
      @wave = new Wave(@waveContainer[0], waveOpts)
      Wave.animate @wave

  getStatus: ->
    status =
      discoveryUrl: Miao({proxy: 'http://catx.me/miao/', port: 4000})
      atomCount: 1
      deviceCount: 2
      pluginCount: 0

    status

  toggleDetailView: ->
    @detailView.toggle @getStatus()

  updateTooltip: (msg) ->
    if @tooltip?
      @tooltip.dispose()
    @tooltip = atom.tooltips.add(@element, {title: msg})

  drawWave: ->
    p =
      sigma: 0.8
      mu: 0
      P: 6
      k: 5
    s =
      lineJoin: 'round'
      lineWidth: 3
      strokeStyle: 'white'
      globalAlpha: 0.3
      shadowBlur: 10
      shadowColor: '#E3F2FD'

    @wave.draw wavePacket.bind(undefined, Math.cos), p, s


  # Returns an object that can be retrieved when package is activated
  serialize: ->

  # Tear down any state and detach
  destroy: ->
    @tooltip.dispose()
    @element.remove()

  getElement: ->
    @element

{CompositeDisposable} = require 'atom'
{$, View} = require('atom-space-pen-views')
QR = require('../qr')
module.exports =
class DetailView extends View
  @content: ->
    @div class: 'detail-view padded', =>
      @div class: "header", =>
        @h1 "Atom Entanglement"
        @tag "button", {click: 'hide', class: "btn icon icon-x inline-block-tight"}, ""
      @div class: "discovery", =>
        @div class: 'qr', outlet: 'qr'
        @div class: 'info block', =>
          @h2 "Service discovery URL"
          @tag "atom-text-editor", {outlet: 'urlEditor', mini: true}, ""
          @div class: "get-url", =>
            @span {outlet: 'message', class: "span-message inline-block highlight-success"}
            @tag "button", {class: "btn btn-copy icon icon-clippy inline-block-tight", click: "copyUrl"}, "Copy to clipboard"
            @span class: 'span-scan', "Scan the QR code or "
      @div class: "footer", =>
        @span {outlet: "state", class: "service-state text-info"}, "Connected"
        @span {outlet: 'pluginCount',class: "badge icon icon-tools"}, 'N/A'
        @span {outlet: 'deviceCount',class: "badge badge-info icon icon-device-mobile"}, 'N/A'
        @span {outlet: 'atomCount', class: "badge badge-success icon icon-device-desktop"}, 'N/A'

  initialize: ->
    @qrGen = new QR(@qr[0], {
      text: "",
      width: 128,
      height: 128
      })

  show: (@status) ->
    @panel ?= atom.workspace.addModalPanel(item: this, visible: false, className: "atom-entanglement-detail")
    @panel.show()
    @updateStatus()

  hide: ->
    @panel.hide()

  toggle: (status) ->
    if @panel?.isVisible()
      @hide()
    else
      @show(status)

  updateStatus: ->
    @qrGen.clear()
    @qrGen.makeCode(@status.discoveryUrl)
    @message.text("")
    @message.addClass('hidden')
    @urlEditor[0].component.setInputEnabled(false)
    @urlEditor[0].getModel().setText(@status.discoveryUrl)
    @deviceCount.text(@status.deviceCount)
    @atomCount.text(@status.atomCount)
    @pluginCount.text(@status.pluginCount)
    @updateTooltips()

  updateTooltips: ->
    if @tooltips?
      @tooltips.dispose()

    @tooltips = new CompositeDisposable()

    count = (thing, n) ->
      "#{n} #{thing}#{if n > 1 then "s" else ""}"

    @tooltips.add atom.tooltips.add(@atomCount, title: "#{count("Atom", @status.atomCount)} connected")
    @tooltips.add atom.tooltips.add(@deviceCount, title: "#{count("device", @status.deviceCount)} connected")
    @tooltips.add atom.tooltips.add(@pluginCount, title: "#{count("plugin", @status.pluginCount)} loaded")

  copyUrl: ->
    atom.clipboard.write(@status.discoveryUrl)
    @message.text("Copied")
    @message.removeClass('hidden')

  destroy: ->
    @tooltips.dispose()

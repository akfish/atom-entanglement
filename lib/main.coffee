StatusBarView = require './views/status-bar'
{CompositeDisposable} = require 'atom'
Settings = require './settings'
Server = require './io/server'
Endpoint = require './io/endpoint'

module.exports = AtomEntanglement =
  config: Settings.config
  statusBarView: null
  subscriptions: null

  activate: (state) ->
    @statusBarView = new StatusBarView(state.statusBarViewState)
    # @modalPanel = atom.workspace.addModalPanel(item: @statusBarView.getElement(), visible: false)
    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace', 'atom-entanglement:toggle status': => @statusBarView.toggleDetailView()

    serverOpts =
      port: Settings.port()
    Server.watch serverOpts
    url = "http://localhost:#{serverOpts.port}/"
    atomEp = new Endpoint(url, 'atom')
    deviceEp = new Endpoint(url, 'device')
    # unknownEp = new Endpoint(url, 'miao')

  deactivate: ->
    @subscriptions.dispose()
    @statusBarView.destroy()

  consumeStatusBar: (statusBar) ->
    @statusBarTile = statusBar.addRightTile(item: @statusBarView.element, priority: 100)

  serialize: ->
    statusBarViewState: @statusBarView.serialize()

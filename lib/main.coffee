StatusBarView = require './views/status-bar'
{CompositeDisposable} = require 'atom'
Settings = require './settings'

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

  deactivate: ->
    @subscriptions.dispose()
    @statusBarView.destroy()

  consumeStatusBar: (statusBar) ->
    @statusBarTile = statusBar.addRightTile(item: @statusBarView.element, priority: 100)

  serialize: ->
    statusBarViewState: @statusBarView.serialize()

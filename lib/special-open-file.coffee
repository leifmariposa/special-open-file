module.exports =
  activate: (state) ->
    atom.commands.add 'atom-workspace',
      'special-open-file:toggle': =>
        @createSpecialOpenFileView().toggle()

    # process.nextTick => @startLoadPathsTask()

  deactivate: ->
    if @SpecialOpenFileView?
      @SpecialOpenFileView.destroy()
      @SpecialOpenFileView = null
    @projectPaths = null
    @fileIconsDisposable?.dispose()

  createSpecialOpenFileView: ->
    unless @SpecialOpenFileView?
      SpecialOpenFileView = require './special-open-file-view'
      @SpecialOpenFileView = new SpecialOpenFileView()
    @SpecialOpenFileView

  # startLoadPathsTask: ->
  #   @stopLoadPathsTask()
  #
  #   return unless @active
  #   return if atom.project.getPaths().length is 0
  #
  #   PathLoader = require './path-loader'
  #   @loadPathsTask = PathLoader.startTask (@projectPaths) =>
  #   @projectPathsSubscription = atom.project.onDidChangePaths =>
  #     @projectPaths = null
  #     @stopLoadPathsTask()
  #
  # stopLoadPathsTask: ->
  #   @projectPathsSubscription?.dispose()
  #   @projectPathsSubscription = null
  #   @loadPathsTask?.terminate()
  #   @loadPathsTask = null

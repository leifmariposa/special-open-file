fs = require 'fs-plus'
{Task} = require 'atom'

module.exports =
  startTask: (callback) ->
    results = []
    taskPath = require.resolve('./load-paths-handler')
    followSymlinks = atom.config.get 'core.followSymlinks'
    includeNames = atom.config.get('special-open-file.fileTypes') ? []
    projectPaths = atom.config.get('special-open-file.searchPaths') ? []
    #projectPaths = atom.project.getPaths().map((path) => fs.realpathSync(path))
    #projectPaths = ["c:\\dropbox\\info\\"]

    task = Task.once(
      taskPath,
      projectPaths,
      followSymlinks,
      includeNames, ->
        callback(results)
    )

    task.on 'load-paths:paths-found', (paths) ->
      results.push(paths...)

    task

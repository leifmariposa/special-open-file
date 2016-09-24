async = require 'async'
fs = require 'fs'
path = require 'path'
_ = require 'underscore-plus'
{GitRepository} = require 'atom'
{Minimatch} = require 'minimatch'

PathsChunkSize = 100

emittedPaths = new Set

class PathLoader
  constructor: (@rootPath, @traverseSymlinkDirectories, @includeNames) ->
    @paths = []
    @realPathCache = {}
    @repo = null

  load: (done) ->
    @loadPath @rootPath, true, =>
      @flushPaths()
      @repo?.destroy()
      done()

  isIncluded: (loadedPath) ->
    for includeName in @includeNames
      return true if includeName.match(loadedPath)

  pathLoaded: (loadedPath, done) ->
    #if @isIncluded(loadedPath) and not emittedPaths.has(loadedPath)
    if @isIncluded(loadedPath)
      #console.log "loadedPath: #{loadedPath}"
      @paths.push(loadedPath)
      emittedPaths.add(loadedPath)

    if @paths.length is PathsChunkSize
      @flushPaths()
    done()

  flushPaths: ->
    emit('load-paths:paths-found', @paths)
    @paths = []

  loadPath: (pathToLoad, root, done) ->
    fs.lstat pathToLoad, (error, stats) =>
      return done() if error?
      if stats.isSymbolicLink()
        @isInternalSymlink pathToLoad, (isInternal) =>
          return done() if isInternal
          fs.stat pathToLoad, (error, stats) =>
            return done() if error?
            if stats.isFile()
              @pathLoaded(pathToLoad, done)
            else if stats.isDirectory()
              if @traverseSymlinkDirectories
                @loadFolder(pathToLoad, done)
              else
                done()
            else
              done()
      else if stats.isDirectory()
        @loadFolder(pathToLoad, done)
      else if stats.isFile()
        @pathLoaded(pathToLoad, done)
      else
        done()

  loadFolder: (folderPath, done) ->
    fs.readdir folderPath, (error, children=[]) =>
      async.each(
        children,
        (childName, next) =>
          @loadPath(path.join(folderPath, childName), false, next)
        done
      )

  isInternalSymlink: (pathToLoad, done) ->
    fs.realpath pathToLoad, @realPathCache, (err, realPath) =>
      if err
        done(false)
      else
        done(realPath.search(@rootPath) is 0)

module.exports = (rootPaths, followSymlinks, includes=[]) ->
  includeNames = []
  for include in includes when include
    try
      includeNames.push(new Minimatch(include, matchBase: true, dot: true))
    catch error
      console.warn "Error parsing include pattern (#{include}): #{error.message}"

  async.each(
    rootPaths,
    (rootPath, next) ->
      new PathLoader(
        rootPath,
        followSymlinks,
        includeNames
      ).load(next)
    @async()
  )

module.exports = new class AutoreloadPackageService
  config:
    debug:
      type: "integer"
      default: 0
      minimum: 0
  disposables: null
  debug: ->
  activate: ->
    {CompositeDisposable} = require 'atom'
    @disposables = new CompositeDisposable
    @disposables.add @provideAutoreload()(pkg:"autoreload-package-service")
  consumeDebug: (debugSetup) =>
    @debug = debugSetup(pkg: "autoreload-package-service", nsp: "")
    @debug("got debug service",2)
  recursiveDelete: (children) =>
    return unless children? and children.length?
    for child in children
      if child?.id? and require.cache[child.id]?
        childs = require.cache[child.id].children
        @recursiveDelete childs if childs?
        delete require.cache[child.id]
    null
  provideAutoreload: =>
    return ({pkg,folders,files}) =>
      throw new Error "no pkg provided" unless pkg?
      return {dispose: ->} unless atom.inDevMode()
      folders ?= ["lib"]
      files ?= ["package.json"]
      watchers = []
      dispose = =>
        @debug("disposing watchers for #{pkg}",2)
        watcher.dispose() for watcher in watchers
        watchers = []
        dispose = ->
      pkgPath = atom.packages.resolvePackagePath(pkg)
      @debug("watching #{pkg}",2)
      {Directory} = require 'atom'
      rootDir = new Directory(pkgPath)
      reloading = false
      reload = =>
        return null if reloading
        @debug("reloading #{pkg}",2)
        reloading = true
        dispose()
        pkgModel = atom.packages.getLoadedPackage(pkg)
        mainPath = pkgModel.mainModulePath
        @debug("deactivating #{pkg}",2)
        pkgModel.deactivate()
        pkgModel.mainModule = null
        pkgModel.mainModuleRequired = false
        @debug("resetting #{pkg}",2)
        pkgModel.reset()
        if require.cache[mainPath]?
          @recursiveDelete require.cache[mainPath].children
          delete require.cache[mainPath]
        deps = []
        for id, module of require.cache
          if id.indexOf(pkgPath) > -1
            deps.push id
        for id in deps
          @recursiveDelete require.cache[id]?.children
          delete require.cache[id]
        @debug("loading #{pkg}",2)
        pkgModel.load()
        @debug("activating #{pkg}",2)
        pkgModel.activate()
      for folder in folders
        disposable = rootDir.getSubdirectory(folder).onDidChange ->
          setTimeout reload,10
        watchers.push disposable
        @disposables.add disposable
      for file in files
        disposable = rootDir.getFile(file).onDidChange -> setTimeout reload,10
        watchers.push disposable
        @disposables.add disposable
      #dispose on package deactivate
      disposable = atom.packages.onDidDeactivatePackage -> setTimeout ((p) ->
        if p.name == pkg
          dispose()
        ),10
      watchers.push disposable
      @disposables.add disposable
      return {reload:reload,dispose:dispose}
  deactivate: ->
    @disposables.dispose()

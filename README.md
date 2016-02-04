# autoreload-package-service

provides a service which other packages can use to reload on file change

![autoreload-package-service](https://cloud.githubusercontent.com/assets/1881921/8182233/b969fc1c-142d-11e5-9845-91a13374ba0c.png)

#### Only works in dev mode!

## Usage

package.json
```json
{
  ...
  "consumedServices": {
    "autoreload": {
      "versions": {
        "^0.0.1": "consumeAutoreload"
      }
    }
  }
  ...
}
```

your package:
```coffee
  #in main module
  consumeAutoreload: (reloader) ->
    reloader(pkg:"nameOfYourPackage",files:["package.json"],folders:["lib/"])
    # pkg has to be the name of your package and is required
    # files are watched and your package reloaded on changes, defaults to ["package.json"]
    # folders are watched and your package reloaded on changes, defaults to ["lib/"]
```

Keep in mind, the service wont be loaded if your `activate` function throws an error.
This is recommended:
```coffee
  #in main module
  activate: ->
    realActivate = ->
      #do your stuff
    if atom.inDevMode()
      try
        realActivate()
      catch e
        console.log e
    else
      realActivate()
  #make sure your deactivate wont throw, even when realActivate wasn't successful
  deactivate: ->
    somestuff?.dispose()
```

## License
Copyright (c) 2015 Paul Pflugradt
Licensed under the MIT license.

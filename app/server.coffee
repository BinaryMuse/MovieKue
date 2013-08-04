http = require 'http'
path = require 'path'
url = require 'url'
express = require 'express'
extend = require 'extend'
request = require 'request'
assets = require './middleware/assets'
configuration = require './configuration'

app = express()
server = http.createServer(app)

rootPath = path.resolve(".")
assetPath = path.join rootPath, "assets"
publicPath = path.join rootPath, "public"

app.set "config", configuration("../config/config.json", "default", app.get("env"))
app.set "port", process.env.PORT || 3000

app.use express.favicon()
app.use express.logger("dev")
app.use express.bodyParser()
app.use express.methodOverride()

if app.get("env") == "development"
  app.use assets.sass(assetPath, publicPath)
  app.use assets.coffee(assetPath, publicPath, false)
  app.use assets.sourcemap(assetPath)

if app.get("env") == "production"
  console.log "Skipping SASS middleware in production (precompilation required)..."
  app.use assets.coffee(assetPath, publicPath, true)

app.use express.static(publicPath)
app.use app.router
app.use express.errorHandler() if app.get("env") == "development"

# Forward all GET requests on the path /moviedb
# to the the themoviedb.org JSON API with our key.
app.get "/moviedb/*", (req, res) ->
  uri = url.parse(req.originalUrl, true)
  uri.protocol = 'https:'
  uri.hostname = 'api.themoviedb.org'
  uri.pathname = uri.pathname.replace(/^\/moviedb/, "/3")
  uri.search = null # override since we want `query` to supercede
  uri.query ?= {}
  uri.query.api_key = app.get('config').moviedb.api_key
  headers =
    "Accept": "application/json"
  request(url: uri.format(), headers: headers).pipe(res)

app.get "*", (req, res) ->
  res.sendfile path.join publicPath, "index.htm"

server.listen app.get("port"), ->
  console.log "App is listening on port #{app.get("port")}"

es = require("event-stream")
util = require("gulp-util")
http = require("http")
connect = require("connect")
liveReload = require("connect-livereload")
tiny_lr = require("tiny-lr")
opt = {}
lr = null

class Connect
  constructor: (options) ->
    opt = options
    opt.port = opt.port || "1337"
    opt.root = opt.root || ["app"]
    opt.host = opt.host || "localhost"
    opt.livereload = if typeof opt.livereload is "boolean" then opt.livereload else (opt.livereload or true)
    @oldMethod("open") if opt.open
    @server()

  server: () ->
    self = @
    middleware = @middleware()
    app = connect.apply(null, middleware)
    server = http.createServer(app)
    app.use connect.directory(opt.root[0]) if opt.root.length
    server.listen(opt.port).on "listening", ->
      self.log "Server started http://#{opt.host}:#{opt.port}"
      if opt.livereload
        lr = tiny_lr()
        lr.listen opt.livereload.port

  middleware: () ->
    middleware = if opt.middleware then opt.middleware.call(this, connect, opt) else []
    if opt.livereload
      opt.livereload = {}  if typeof opt.livereload is "boolean"
      opt.livereload.port = 35729  unless opt.livereload.port
      middleware.push liveReload(port: opt.livereload.port)
      @log "LiveReload started on port #{opt.livereload.port}"
    opt.root.forEach (path) ->
      middleware.push connect.static(path)
    return middleware

  log: (@text) ->
    util.log util.colors.green(@text)

  logWarning: (@text) ->
    util.log util.colors.yellow(@text)

  reload: () ->
    es.map (file, callback) ->
      if opt.livereload and typeof lr == "object"
        lr.changed body:
          files: file.path
      callback null, file

  oldMethod: (type) ->
    text = 'does not work in gulp-connect v 2.*. Please read "readme" https://github.com/AveVlad/gulp-connect'
    switch type
      when "open" then @logWarning("Option open #{text}")
module.exports = module = (options = {}) ->
  connect = new Connect(options)
  module.reload = connect.reload

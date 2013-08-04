fs = require 'fs'
path = require 'path'
sass = require 'node-sass'
coffee = require 'coffee-middleware'

module.exports.sass = (src, dest) ->
  sass.middleware
    src: src
    dest: dest
    debug: true
    outputStyle: "compressed"

module.exports.coffee = (src, dest, once) ->
  coffee
    src: src
    once: once

module.exports.sourcemap = (src) ->
  (req, res, next) ->
    return next() unless req.path.match(/^\/js\//)
    fs.exists path.join(src, req.path), (exists) ->
      if exists
        res.sendfile path.join(src, req.path)
      else
        next()

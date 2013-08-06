fs = require 'fs'
path = require 'path'
extend = require 'extend'

module.exports = (file, envs...) ->
  path = path.resolve(process.cwd(), file)
  if fs.existsSync(path)
    config = require path
    configs = ((config[env] || {}) for env in envs)
    extend(true, {}, configs...)
  else
    {}

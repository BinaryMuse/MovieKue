fs = require 'fs'
extend = require 'extend'

module.exports = (file, envs...) ->
  if fs.existsSync(file)
    config = require file
    configs = ((config[env] || {}) for env in envs)
    extend(true, {}, configs...)
  else
    {}

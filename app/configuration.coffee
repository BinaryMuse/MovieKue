extend = require 'extend'

module.exports = (file, envs...) ->
  config = require file
  configs = ((config[env] || {}) for env in envs)
  extend(true, {}, configs...)

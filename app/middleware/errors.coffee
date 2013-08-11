module.exports = ->
  (req, res, next) ->
    unless res.socket._errorHandlersSet
      res.socket.on 'timeout', ->
        console.error "Timeout: #{req.url}"

      res.socket.on 'error', (err) ->
        console.error "Response socket error: #{req.url}"
        console.error err.stack
        res.sock?.destroy()

      res.socket._errorHandlersSet = true

    unless req.socket._errorHandlersSet
      req.socket.on 'error', (err) ->
        console.error "Request socket error: #{req.url}"
        console.error err.stack
        req.sock?.destroy()

      req.socket._errorHandlersSet = true

    next()

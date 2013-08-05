module.exports = ->
  (req, res, next) ->
    return next() if res.socket._errorHandlersSet
    res.socket._errorHandlersSet = true

    res.socket.on 'timeout', ->
      console.error "Timeout: #{req.url}"

    req.socket.on 'error', (err) ->
      console.error "Request socket error: #{req.url}"
      console.error err.stack
      req.sock.destroy()

    res.socket.on 'error', (err) ->
      console.error "Response socket error: #{req.url}"
      console.error err.stack
      res.sock.destroy()

    next()

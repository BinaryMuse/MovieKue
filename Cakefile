{spawn} = require "child_process"

task "server", "run the development server", ->
  spawn "./node_modules/.bin/coffee", ["./app/server.coffee"], stdio: "inherit"

task "assets:compile", "compile the JS and CSS assets into public", ->
  throw new Error("This task totally needs to be written")

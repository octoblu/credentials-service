_             = require 'lodash'
Server        = require './src/server'
redis         = require 'redis'
RedisNS       = require 'redis-ns'
publicKey     = require './public-key.json'

class Command
  constructor: ->
    @serverOptions =
      port          : process.env.PORT || 80
      disableLogging: process.env.DISABLE_LOGGING == "true"
      publicKey     : publicKey

    @redisUri = process.env.REDIS_URI

  panic: (error) =>
    console.error error.stack
    process.exit 1

  run: =>
    # Use this to require env
    @panic new Error('Missing required environment variable: REDIS_URI') if _.isEmpty @redisUri

    redisClient = redis.createClient process.env.REDIS_URI
    client = new RedisNS 'credentials-service', redisClient

    server = new Server @serverOptions, {client}
    server.run (error) =>
      return @panic error if error?
      {address,port} = server.address()
      console.log "Server listening on #{address}:#{port}"

command = new Command()
command.run()

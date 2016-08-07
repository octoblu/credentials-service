_              = require 'lodash'
Server         = require './src/server'
redis          = require 'redis'
JobManager     = require 'meshblu-core-job-manager'
OctobluRaven   = require 'octoblu-raven'
RedisNS        = require '@octoblu/redis-ns'
FetchPublicKey = require 'fetch-meshblu-public-key'

class Command
  constructor: ->
    @octobluRaven = new OctobluRaven
    @serverOptions =
      port          : process.env.PORT || 80
      disableLogging: process.env.DISABLE_LOGGING == "true"
      octobluRaven  : @octobluRaven

    @publicKeyUri = process.env.MESHBLU_PUBLIC_KEY_URI
    @redisUri = process.env.REDIS_URI
    @redisNamespace = process.env.REDIS_NAMESPACE ? 'credentials'
    @credentialsUuid = process.env.CREDENTIALS_UUID

  panic: (error) =>
    console.error error.stack
    process.exit 1

  catchErrors: =>
    @octobluRaven.patchGlobal()

  run: =>
    # Use this to require env
    @panic new Error('Missing required environment variable: MESHBLU_PUBLIC_KEY_URI') if _.isEmpty @publicKeyUri
    @panic new Error('Missing required environment variable: REDIS_URI') if _.isEmpty @redisUri
    @panic new Error('Missing required environment variable: CREDENTIALS_UUID') if _.isEmpty @credentialsUuid
    new FetchPublicKey().fetch @publicKeyUri, (error, publicKey) =>
      return @panic error if error?

      @serverOptions.publicKey = publicKey

      redisClient = redis.createClient process.env.REDIS_URI
      client = new RedisNS @redisNamespace, redisClient

      jobManager = new JobManager client: client, timeoutSeconds: 45

      @server = new Server @serverOptions, {jobManager,@credentialsUuid}
      @server.run (error) =>
        return @panic error if error?
        {address,port} = @server.address()
        console.log "Credentials Service listening on port:#{port}"

    process.on 'SIGTERM', =>
      console.log 'SIGTERM caught, exiting'
      if @server?.stop?
        console.log 'stopping server'
        @server.stop =>
          process.exit 0
        return
      process.exit 0

command = new Command()
command.catchErrors()
command.run()

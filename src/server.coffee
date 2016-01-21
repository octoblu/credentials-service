redis              = require 'redis'
morgan             = require 'morgan'
express            = require 'express'
RedisNS            = require '@octoblu/redis-ns'
bodyParser         = require 'body-parser'
errorHandler       = require 'errorhandler'
meshbluHealthcheck = require 'express-meshblu-healthcheck'
MeshbluConfig      = require 'meshblu-config'
debug              = require('debug')('credentials-service:server')
Router             = require './router'
CredentialService  = require './services/credential-service'
httpSignature      = require '@octoblu/connect-http-signature'

class Server
  constructor: ({@disableLogging, @port, @publicKey}, {@meshbluConfig, @client})->
    @meshbluConfig ?= new MeshbluConfig().toJSON()

  address: =>
    @server.address()

  run: (callback) =>
    app = express()
    app.use morgan 'dev', immediate: false unless @disableLogging
    app.use errorHandler()
    app.use meshbluHealthcheck()
    app.use httpSignature.verify pub: @publicKey.publicKey
    app.use httpSignature.gateway()
    app.use bodyParser.urlencoded limit: '5mb', extended : true
    app.use bodyParser.json limit : '5mb'

    credentialService = new CredentialService {@client}

    router = new Router {@meshbluConfig, credentialService}

    router.route app

    @server = app.listen @port, callback

  stop: (callback) =>
    @server.close callback

module.exports = Server

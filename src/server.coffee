redis              = require 'redis'
morgan             = require 'morgan'
express            = require 'express'
bodyParser         = require 'body-parser'
errorHandler       = require 'errorhandler'
meshbluHealthcheck = require 'express-meshblu-healthcheck'
debug              = require('debug')('credentials-service:server')
Router             = require './router'
CredentialService  = require './services/credential-service'
httpSignature      = require '@octoblu/connect-http-signature'

class Server
  constructor: ({@disableLogging, @port, @publicKey}, {@jobManager,@credentialsUuid})->

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

    credentialService = new CredentialService {@jobManager, @credentialsUuid}

    router = new Router {credentialService}

    router.route app

    @server = app.listen @port, callback

  stop: (callback) =>
    @server.close callback

module.exports = Server

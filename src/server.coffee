redis              = require 'redis'
morgan             = require 'morgan'
express            = require 'express'
bodyParser         = require 'body-parser'
compression        = require 'compression'
sendError          = require 'express-send-error'
OctobluRaven       = require 'octoblu-raven'
expressVersion     = require 'express-package-version'
meshbluHealthcheck = require 'express-meshblu-healthcheck'
Router             = require './router'
CredentialService  = require './services/credential-service'
httpSignature      = require '@octoblu/connect-http-signature'
debug              = require('debug')('credentials-service:server')

class Server
  constructor: ({@disableLogging, @port, @publicKey, @octobluRaven}, {@jobManager,@credentialsUuid})->
    @octobluRaven ?= new OctobluRaven()

  address: =>
    @server.address()

  run: (callback) =>
    app = express()
    app.use compression()
    app.use @octobluRaven.express().handleErrors()
    app.use meshbluHealthcheck()
    app.use expressVersion({format: '{"version": "%s"}'})
    skip = (request, response) =>
      return response.statusCode < 400

    app.use morgan 'dev', { immediate: false, skip } unless @disableLogging
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

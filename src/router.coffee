CredentialController = require './controllers/credential-controller'

class Router
  constructor: ({@credentialService}) ->
  route: (app) =>
    credentialController = new CredentialController {@credentialService}

    app.post '/flows/:flowId/instances/:instanceId', credentialController.create

module.exports = Router

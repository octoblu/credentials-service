class CredentialController
  constructor: ({@credentialService}) ->

  create: (request, response) =>
    {flowId, instanceId} = request.params

    unless request.header('X-MESHBLU-UUID') == flowId
      return response.status(403).end()

    message =
      metadata:
        flowId: flowId
        instanceId: instanceId
        toNodeId: 'engine-input'
      message: request.body

    @credentialService.create {message, flowId}, (error) =>
      return response.status(error.code || 500).send(error: error.message) if error?
      response.sendStatus(201)

module.exports = CredentialController

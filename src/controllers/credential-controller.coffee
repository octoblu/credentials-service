class CredentialController
  constructor: ({@credentialService}) ->

  create: (request, response) =>
    {flowId, nodeId} = request.body
    unless request.header('X-MESHBLU-UUID') == flowId
      return response.status(403).end()

    message =
      metadata:
        flowId: flowId
        nodeId: nodeId
        toNodeId: 'engine-input'
      message: {}

    @credentialService.create {message, flowId}, (error) =>
      return response.status(error.code || 500).send(error: error.message) if error?
      response.sendStatus(201)

module.exports = CredentialController

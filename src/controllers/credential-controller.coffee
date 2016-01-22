class CredentialController
  constructor: ({@credentialService}) ->

  create: (request, response) =>
    {nodeId} = request.body
    flowId = request.header('X-MESHBLU-UUID')
    return response.sendStatus(403) unless flowId?
    return response.sendStatus(422) unless nodeId?

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

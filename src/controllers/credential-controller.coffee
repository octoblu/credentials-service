_ = require 'lodash'
class CredentialController
  constructor: ({@credentialService}) ->

  create: (request, response) =>
    incomingMessage = request.body
    return response.sendStatus(422) unless incomingMessage?.payload?.nodeId?
    flowId = incomingMessage.fromUuid
    return response.sendStatus(403) unless flowId?

    {nodeId} = incomingMessage.payload
    
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

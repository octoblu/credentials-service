debug = require('debug')('credentials-service:service')

class CredentialService
  constructor: ({@client}) ->

  create: ({message, flowId}, callback) =>
    messageStr = JSON.stringify message
    requestQueueName = 'request:queue'

    debug '@client.lpush', requestQueueName, messageStr
    @client.lpush requestQueueName, messageStr, (error) =>
      return callback @_createError 500, error.message if error?
      callback()

  _createError: (code, message) =>
    error = new Error message
    error.code = code if code?
    return error

module.exports = CredentialService

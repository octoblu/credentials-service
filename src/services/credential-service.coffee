debug = require('debug')('credentials-service:service')

class CredentialService
  constructor: ({@jobManager}) ->

  create: ({message, flowId}, callback) =>
    debug 'pushing into request queue', message
    @jobManager.createRequest 'request', message, (error) =>
      return callback @_createError 500, error.message if error?
      callback()

  _createError: (code, message) =>
    error = new Error message
    error.code = code if code?
    return error

module.exports = CredentialService

http       = require 'http'
request    = require 'request'
shmock     = require '@octoblu/shmock'
Server     = require '../../src/server'
JobManager = require 'meshblu-core-job-manager'
redis      = require 'fakeredis'
RedisNS    = require '@octoblu/redis-ns'
uuid       = require 'uuid'
{publicKey, privateKey} = require '../keys.json'

describe 'Get Credentials', ->
  beforeEach (done) ->
    serverOptions =
      port: undefined,
      disableLogging: true
      publicKey:
        publicKey: publicKey

    @HTTP_SIGNATURE_OPTIONS =
      keyId: 'credentials-service-uuid'
      key: privateKey
      headers: [ 'date', 'X-MESHBLU-UUID' ]

    @redisKey = uuid.v1()

    client = new RedisNS 'credentials', redis.createClient @redisKey
    jobManager = new JobManager client: client, timeoutSeconds: 1

    testClient = new RedisNS 'credentials', redis.createClient @redisKey
    @testJobManager = new JobManager client: testClient, timeoutSeconds: 1

    @server = new Server serverOptions, {jobManager,credentialsUuid:'credentials-service-uuid'}

    @server.run =>
      @serverPort = @server.address().port
      done()

  afterEach (done) ->
    @server.stop done

  describe 'when a valid request is made', ->
    beforeEach (done) ->
      options =
        uri: '/request'
        baseUrl: "http://localhost:#{@serverPort}"
        httpSignature: @HTTP_SIGNATURE_OPTIONS
        headers:
          'X-MESHBLU-UUID': 'credentials-service-uuid'
        json:
          fromUuid: 'flow-uuid'
          payload:
            nodeId: 'node-uuid'
            messageId: 'message-uuid'

      request.post options, (error, @response, @body) =>
        done error

    it 'should return a 201', ->
      expect(@response.statusCode).to.equal 201

    describe 'it should store the request into a queue', ->
      beforeEach (done) ->
        @testJobManager.getRequest ['request'], (error, @result) => done error

      it 'should return the request', ->
        expect(@result.metadata).to.deep.equal
          flowId: 'flow-uuid'
          nodeId: 'node-uuid'
          toNodeId: 'engine-input'
          messageId: 'message-uuid'

  describe 'when an unauthorized request is made', ->
    beforeEach (done) ->
      options =
        uri: '/request'
        baseUrl: "http://localhost:#{@serverPort}"
        httpSignature: @HTTP_SIGNATURE_OPTIONS
        headers:
          'X-MESHBLU-UUID': 'some-other-uuid'
        json: true

      request.post options, (error, @response, @body) =>
        done error

    it 'should return a 422', ->
      expect(@response.statusCode).to.equal 422

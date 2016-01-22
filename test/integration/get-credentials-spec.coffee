http    = require 'http'
request = require 'request'
shmock  = require '@octoblu/shmock'
Server  = require '../../src/server'
redis   = require 'fakeredis'
RedisNS = require '@octoblu/redis-ns'
uuid    = require 'uuid'
{publicKey, privateKey} = require '../keys.json'

describe 'Get Credentials', ->
  beforeEach (done) ->
    serverOptions =
      port: undefined,
      disableLogging: true
      publicKey:
        publicKey: publicKey

    @HTTP_SIGNATURE_OPTIONS =
      keyId: 'credentials-service-key'
      key: privateKey
      headers: [ 'date', 'X-MESHBLU-UUID' ]

    @redisKey = uuid.v1()

    client = new RedisNS 'credentials', redis.createClient @redisKey

    @redisClient = new RedisNS 'credentials', redis.createClient @redisKey

    @server = new Server serverOptions, {client}

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
          'X-MESHBLU-UUID': 'flow-uuid'
        json:
          nodeId: 'node-uuid'

      request.post options, (error, @response, @body) =>
        done error

    it 'should return a 201', ->
      expect(@response.statusCode).to.equal 201

    describe 'it should store the request into a queue', ->
      beforeEach (done) ->
        @redisClient.brpop 'request:queue', 1, (error, @result) => done error

      it 'should return the request', ->
        [channel, requestData] = @result
        expect(channel).to.deep.equal 'credentials:request:queue'
        expect(JSON.parse requestData).to.deep.equal
          metadata:
            flowId: 'flow-uuid'
            nodeId: 'node-uuid'
            toNodeId: 'engine-input'
          message: {}

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

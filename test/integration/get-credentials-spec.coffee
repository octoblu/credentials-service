http    = require 'http'
request = require 'request'
shmock  = require '@octoblu/shmock'
Server  = require '../../src/server'
redis   = require 'fakeredis'
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

    client = redis.createClient @redisKey

    @redisClient = redis.createClient @redisKey

    @server = new Server serverOptions, {client}

    @server.run =>
      @serverPort = @server.address().port
      done()

  afterEach (done) ->
    @server.stop done

  describe 'when a valid request is made', ->
    beforeEach (done) ->
      options =
        uri: '/flows/flow-uuid/instances/instance-uuid'
        baseUrl: "http://localhost:#{@serverPort}"
        httpSignature: @HTTP_SIGNATURE_OPTIONS
        headers:
          'X-MESHBLU-UUID': 'flow-uuid'
        json:
          'something': 'is-awesome'
          'it-must-be': 'peter'

      request.post options, (error, @response, @body) =>
        done error

    it 'should return a 201', ->
      expect(@response.statusCode).to.equal 201

    describe 'it should store the request into a queue', ->
      beforeEach (done) ->
        @redisClient.brpop 'request:queue', 1, (error, @result) => done error

      it 'should return the request', ->
        [channel, requestData] = @result
        expect(channel).to.deep.equal 'request:queue'
        expect(JSON.parse requestData).to.deep.equal
          metadata:
            flowId: 'flow-uuid'
            instanceId: 'instance-uuid'
            toNodeId: 'engine-input'
          message:
            'something': 'is-awesome'
            'it-must-be': 'peter'

  describe 'when an unauthorized request is made', ->
    beforeEach (done) ->
      options =
        uri: '/flows/flow-uuid/instances/instance-uuid'
        baseUrl: "http://localhost:#{@serverPort}"
        httpSignature: @HTTP_SIGNATURE_OPTIONS
        headers:
          'X-MESHBLU-UUID': 'some-other-uuid'
        json: true

      request.post options, (error, @response, @body) =>
        done error

    it 'should return a 403', ->
      expect(@response.statusCode).to.equal 403

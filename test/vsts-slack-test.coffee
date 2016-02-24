Helper = require 'hubot-test-helper'
chai = require 'chai'
sinon = require 'sinon'
chai.use require 'sinon-chai'

expect = chai.expect

helper = new Helper('./../src/vsts-slack.coffee')
    
describe 'vsts-slack', ->
  room = null 
  
  beforeEach ->
    room = helper.createRoom()
    
  afterEach ->
    room.destroy()
    
  context 'user misspells project', ->
    beforeEach -> 
        room.user.say 'charlie', 'hubot vsts projec'

    it 'should reply with nothing', ->
      expect(room.messages).to.eql [
          ['charlie', 'hubot vsts projec']
      ]

  context 'user requests projects', ->
    beforeEach -> 
        room.user.say 'charlie', 'hubot vsts projects'

    it 'should reply with a list of projects', ->
      expect(room.messages).to.eql [
          ['charlie', 'hubot vsts projects'],
          ['hubot', 'Retrieving list of VSTS projects...'],
          ['hubot', '`projectx`, `projecty`']
      ]

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
    
    context 'negative tests:', ->
        context 'user misspells project', ->
            beforeEach -> 
                room.user.say 'charlie', 'hubot vsts projec'

            it 'should reply with nothing', ->
                expect(room.messages).to.eql [
                    ['charlie', 'hubot vsts projec']
                ]

        context 'user requests projects but env vars not present', ->
            beforeEach -> 
                room.user.say 'charlie', 'hubot vsts projects'

            it 'should return an error', ->
                expect(room.messages).to.eql [
                    ['charlie', 'hubot vsts projects']
                    ['hubot', 'VSTS API Token is missing: Make sure the HUBOT_VSTS_API_TOKEN is set']
                    ['hubot', 'VSTS DefaultCollection URL is missing: Make sure the HUBOT_VSTS_DEFAULTCOLLECTION_URL is set']
                ]

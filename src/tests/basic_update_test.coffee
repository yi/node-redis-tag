###
# test for taggabler_via_redis
###

## Module dependencies
should = require "should"
taggable = require "../taggabler_via_redis"

REDIS_CLIENT = null

MODULE_NAME = "people"

## Test cases
describe "basic update tests", ->

  before (done) ->
    redis = require("redis")
    REDIS_CLIENT = redis.createClient()
    REDIS_CLIENT.flushall()
    taggable.init(REDIS_CLIENT)
    setTimeout done, 1800 # wait to prevent flushall() happens during test execusion
    #done()

  describe "taggabler_via_redis", ->

    it "should set tags on person", (done) ->
      taggable.set MODULE_NAME, 21, [
        "hockey"
        "basketball"
        "rugby"
      ], (err) ->
        should.not.exist(err)
        done()
        return

      return

    it "should set tags on second person", (done) ->
      taggable.set MODULE_NAME, 22, ["hockey"], (err) ->
        should.not.exist(err)
        done()
        return
      return

    it "should change tags first person", (done) ->
      taggable.set MODULE_NAME, 21, [
        "cricket"
        "hockey"
        "football"
        "baseball"
      ], (err) ->
        should.not.exist(err)
        done()
        return
      return

    it "should get tags for person", (done) ->
      taggable.get MODULE_NAME, 21, (err, tags) ->
        should.not.exist(err)
        tags.sort().should.containDeep([
          "cricket"
          "hockey"
          "football"
          "baseball"
        ].sort())
        done()
        return
      return

    it "should get hockey as most popular tag", (done) ->
      taggable.popular MODULE_NAME, 5, (err, tags) ->
        should.not.exist(err)
        tags.length.should.be.below(6)
        tags[0].should.containDeep([
          "hockey"
          2
        ])
        done()
        return
      return




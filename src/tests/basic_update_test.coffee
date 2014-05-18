###
# test for taggabler_via_redis
###

## Module dependencies
should = require "should"
Taggable = require "../taggabler_via_redis"
personTagger = new Taggable("person")

## Test cases
describe "basic update tests", ->

  before (done) ->
    redis = require("redis")
    client = redis.createClient()
    client.flushall()
    client.quit()
    setTimeout done, 1800 # wait to prevent flushall() happens during test execusion
    #done()

  describe "taggabler_via_redis", ->

    it "should set tags on person", (done) ->
      personTagger.set 21, [
        "hockey"
        "basketball"
        "rugby"
      ], (err) ->
        should.not.exist(err)
        done()
        return

      return

    it "should set tags on second person", (done) ->
      personTagger.set 22, ["hockey"], (err) ->
        should.not.exist(err)
        done()
        return
      return

    it "should change tags first person", (done) ->
      personTagger.set 21, [
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
      personTagger.get 21, (err, tags) ->
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
      personTagger.popular 5, (err, tags) ->
        should.not.exist(err)
        tags.length.should.be.below(6)
        tags[0].should.containDeep([
          "hockey"
          2
        ])
        done()
        return
      return




###
# test for taggabler_via_redis
###

## Module dependencies
should = require "should"
Taggable = require "../taggabler_via_redis"

REDIS_CLIENT = null
thingTagger  = null

## Test cases
describe "basic find tests", ->

  before (done) ->
    redis = require("redis")
    REDIS_CLIENT = redis.createClient()
    REDIS_CLIENT.flushall()
    thingTagger = new Taggable
      taggable : "thing"
      redisClient : REDIS_CLIENT
    setTimeout done, 1800 # wait to prevent flushall() happens during test execusion

  describe "taggabler_via_redis", ->

    it "set things up", (done) ->
      thingTagger.set "thing1", ["foo","bar","baz"], (err) ->
        should.not.exist(err)
        thingTagger.set "thing2", ["foo"], (err) ->
          should.not.exist(err)
          thingTagger.set "thing3", ["foo","bar"], (err) ->
            should.not.exist(err)
            done()
            return
          return
        return
      return

    it "should find 3 books from tag foo", (done) ->
      thingTagger.find "foo", (err, rsp) ->
        should.not.exist(err)
        rsp.sort().should.containDeep([
          "thing1"
          "thing2"
          "thing3"
        ])
        done()
        return
      return

    it "should find 2 books from tag foo and bar", (done) ->
      thingTagger.find [ "foo", "bar" ], (err, rsp) ->
        should.not.exist(err)
        rsp.sort().should.containDeep([
          "thing1"
          "thing3"
        ])
        done()
        return

      return

    it "should find 1 books from tag baz", (done) ->
      thingTagger.find "baz", (err, rsp) ->
        should.not.exist(err)
        rsp.sort().should.containDeep(["thing1"])
        done()
        return
      return



###
# test for taggabler_via_redis
###

## Module dependencies
should = require "should"
taggable = require "../taggabler_via_redis"

REDIS_CLIENT = null

MODULE_NAME = "book"

## Test cases
describe "basic find tests", ->

  before (done) ->
    redis = require("redis")
    REDIS_CLIENT = redis.createClient()
    REDIS_CLIENT.flushall()
    taggable.init(REDIS_CLIENT)
    setTimeout done, 1800 # wait to prevent flushall() happens during test execusion

  describe "taggabler_via_redis", ->

    it "set things up", (done) ->
      taggable.set MODULE_NAME, "thing1", ["foo","bar","baz"], (err) ->
        should.not.exist(err)
        taggable.set MODULE_NAME, "thing2", ["foo"], (err) ->
          should.not.exist(err)
          taggable.set MODULE_NAME, "thing3", ["foo","bar"], (err) ->
            should.not.exist(err)
            done()
            return
          return
        return
      return

    it "should find 3 books from tag foo", (done) ->
      taggable.find  MODULE_NAME, "foo", (err, rsp) ->
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
      taggable.find  MODULE_NAME, [ "foo", "bar" ], (err, rsp) ->
        should.not.exist(err)
        rsp.sort().should.containDeep([
          "thing1"
          "thing3"
        ])
        done()
        return

      return

    it "should find 1 books from tag baz", (done) ->
      taggable.find MODULE_NAME, "baz", (err, rsp) ->
        should.not.exist(err)
        rsp.sort().should.containDeep(["thing1"])
        done()
        return
      return



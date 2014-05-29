###
# test for taggabler_via_redis
###

## Module dependencies
should = require "should"
taggable = require "../taggabler_via_redis"

REDIS_CLIENT = null
USER_27 = "user/27"
USER_42 = "user/42"

TAGS_NODE = "javascript,server,programming".split(",").sort()
TAGS_JQUERY = "javascript,client,programming".split(",").sort()
TAGS_RAILS = "ruby,programming".split(",").sort()
TAGS_COFFEESCRIPT = "javascript,client,server,programming".split(",").sort()
TAGS_NODE2 = "javascript,server,programming,async,joyent".split(",").sort()

MODULE_NAME = "book"

## Test cases
describe "scope add tests", ->

  before (done) ->
    redis = require("redis")
    REDIS_CLIENT = redis.createClient()
    REDIS_CLIENT.flushall()
    taggable.init(REDIS_CLIENT)
    setTimeout done, 1800 # wait to prevent flushall() happens during test execusion

  describe "taggabler_via_redis", ->

    it "should set tags on book 1", (done) ->
      taggable.set MODULE_NAME,  1, TAGS_NODE,USER_27,  (err) ->
        should.not.exist(err)
        done()
        return
      return

    it "should get tags for book 1", (done) ->
      taggable.get MODULE_NAME,  1,USER_27,  (err, rsp) ->
        should.not.exist(err)
        rsp.sort().should.containDeep TAGS_NODE
        done()
        return
      return

    it "should set tags on book 2", (done) ->
      taggable.set MODULE_NAME,  2, TAGS_JQUERY,USER_27,  (err) ->
        should.not.exist(err)
        done()
        return

      return

    it "should get tags for book 2", (done) ->
      taggable.get MODULE_NAME,  2,USER_27,  (err, rsp) ->
        should.not.exist(err)
        rsp.sort().should.containDeep TAGS_JQUERY
        done()
        return
      return

    it "should set tags on book 3", (done) ->
      taggable.set  MODULE_NAME, 3, TAGS_RAILS,USER_42,  (err) ->
        should.not.exist(err)
        done()
        return
      return

    it "should get tags for book 3", (done) ->
      taggable.get  MODULE_NAME, 3,USER_42,  (err, rsp) ->
        should.not.exist(err)
        rsp.sort().should.containDeep TAGS_RAILS
        done()
        return
      return

    it "should set tags on book 4", (done) ->
      taggable.set MODULE_NAME,  4, TAGS_COFFEESCRIPT,USER_42,  (err) ->
        should.not.exist(err)
        done()
        return
      return

    it "should get tags for book 4", (done) ->
      taggable.get MODULE_NAME,  4,USER_42,  (err, rsp) ->
        should.not.exist(err)
        rsp.sort().should.containDeep TAGS_COFFEESCRIPT
        done()
        return
      return

    it "should get empty array if book has not been tagged", (done) ->
      taggable.get  MODULE_NAME, 99,USER_42,  (err, rsp) ->
        should.not.exist(err)
        rsp.should.be.empty
        done()
        return
      return

    it "should find books from tag", (done) ->
      taggable.find MODULE_NAME,  "client",USER_42,  (err, rsp) ->
        should.not.exist(err)
        rsp.should.containDeep(["4"])
        done()
        return
      return

    it "should get empty array for non existing tag", (done) ->
      taggable.find MODULE_NAME,  "maytag",USER_42,  (err, rsp) ->
        should.not.exist(err)
        rsp.should.be.empty
        done()
        return
      return

    it "should get all items if no tags specified", (done) ->
      taggable.find MODULE_NAME,  [], USER_42, (err, rsp) ->
        should.not.exist(err)
        rsp.should.be.empty
        done()
        return
      return

    it "should get most popular tags from user 42", (done) ->
      taggable.popular MODULE_NAME,  10, USER_42, (err, rsp) ->
        should.not.exist(err)
        rsp[0].should.containDeep([
          "programming"
          2
        ])
        done()
        return
      return

    it "should get most popular tags globally", (done) ->
      taggable.popular  MODULE_NAME, 10, (err, rsp) ->
        should.not.exist(err)
        rsp[0].should.containDeep([
          "programming"
          4
        ])
        done()
        return
      return




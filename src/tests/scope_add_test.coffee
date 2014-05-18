###
# test for taggabler_via_redis
###

## Module dependencies
should = require "should"
Taggable = require "../taggabler_via_redis"
bookTagger = new Taggable("person")

USER_27 = "user:27"
USER_42 = "user:42"

TAGS_NODE = "javascript,server,programming".split(",").sort()
TAGS_JQUERY = "javascript,client,programming".split(",").sort()
TAGS_RAILS = "ruby,programming".split(",").sort()
TAGS_COFFEESCRIPT = "javascript,client,server,programming".split(",").sort()
TAGS_NODE2 = "javascript,server,programming,async,joyent".split(",").sort()


## Test cases
describe "scope add tests", ->

  before (done) ->
    redis = require("redis")
    client = redis.createClient()
    client.flushall()
    client.quit()
    setTimeout done, 1800 # wait to prevent flushall() happens during test execusion
    #done()

  describe "taggabler_via_redis", ->

    it "should set tags on book 1", (done) ->
      bookTagger.set USER_27, 1, TAGS_NODE, (err) ->
        should.not.exist(err)
        done()
        return
      return

    it "should get tags for book 1", (done) ->
      bookTagger.get USER_27, 1, (err, rsp) ->
        should.not.exist(err)
        rsp.sort().should.containDeep TAGS_NODE
        done()
        return
      return

    it "should set tags on book 2", (done) ->
      bookTagger.set USER_27, 2, TAGS_JQUERY, (err) ->
        should.not.exist(err)
        done()
        return

      return

    it "should get tags for book 2", (done) ->
      bookTagger.get USER_27, 2, (err, rsp) ->
        should.not.exist(err)
        rsp.sort().should.containDeep TAGS_JQUERY
        done()
        return
      return

    it "should set tags on book 3", (done) ->
      bookTagger.set USER_42, 3, TAGS_RAILS, (err) ->
        should.not.exist(err)
        done()
        return
      return

    it "should get tags for book 3", (done) ->
      bookTagger.get USER_42, 3, (err, rsp) ->
        should.not.exist(err)
        rsp.sort().should.containDeep TAGS_RAILS
        done()
        return
      return

    it "should set tags on book 4", (done) ->
      bookTagger.set USER_42, 4, TAGS_COFFEESCRIPT, (err) ->
        should.not.exist(err)
        done()
        return
      return

    it "should get tags for book 4", (done) ->
      bookTagger.get USER_42, 4, (err, rsp) ->
        should.not.exist(err)
        rsp.sort().should.containDeep TAGS_COFFEESCRIPT
        done()
        return
      return

    it "should get empty array if book has not been tagged", (done) ->
      bookTagger.get USER_42, 99, (err, rsp) ->
        should.not.exist(err)
        rsp.should.be.empty
        done()
        return
      return

    it "should find books from tag", (done) ->
      bookTagger.find USER_42, "client", (err, rsp) ->
        should.not.exist(err)
        rsp.should.containDeep(["4"])
        done()
        return
      return

    it "should get empty array for non existing tag", (done) ->
      bookTagger.find USER_42, "maytag", (err, rsp) ->
        should.not.exist(err)
        rsp.should.be.empty
        done()
        return
      return

    it "should get all items if no tags specified", (done) ->
      bookTagger.find USER_42, [], (err, rsp) ->
        should.not.exist(err)
        rsp.should.be.empty
        done()
        return
      return

    it "should get most popular tags from user 42", (done) ->
      bookTagger.popular USER_42, 10, (err, rsp) ->
        should.not.exist(err)
        rsp[0].should.containDeep([
          "programming"
          2
        ])
        done()
        return
      return

    it "should get most popular tags globally", (done) ->
      bookTagger.popular 10, (err, rsp) ->
        should.not.exist(err)
        rsp[0].should.containDeep([
          "programming"
          4
        ])
        done()
        return
      return




###
# test for taggabler_via_redis
###

## Module dependencies
should = require "should"
Taggable = require "../taggabler_via_redis"
bookTagger = new Taggable("book")

# book                 tags
# 1 - node             [javascript, server, programming]
# 2 - jquery           [javascript, client, programming]
# 3 - rails            [ruby, server, programming]
# 4 - coffeescript     [javascript, client, server, programming]

TAGS_NODE = "javascript,server,programming".split(",").sort()
TAGS_JQUERY = "javascript,client,programming".split(",").sort()
TAGS_RAILS = "ruby,server,programming".split(",").sort()
TAGS_COFFEESCRIPT = "javascript,client,server,programming".split(",").sort()


## Test cases
describe "basic add tests", ->

  before (done) ->
    redis = require("redis")
    client = redis.createClient()
    client.flushall()
    client.quit()
    setTimeout done, 1800 # wait to prevent flushall() happens during test execusion
    #done()

  describe "taggabler_via_redis", ->

    it "should set tags on book 1", (done) ->
      bookTagger.set 1, TAGS_NODE, (err) ->
        should.not.exist(err)
        done()
        return
      return

    it "should get tags for book 1", (done) ->
      bookTagger.get 1, (err, tags) ->
        console.log "[taggabler_via_redis_test] tags:#{tags}"

        should.not.exist(err)
        tags.sort().should.containDeep(TAGS_NODE)
        done()
        return
      return

    it "should set tags on book 2", (done) ->
      bookTagger.set 2, TAGS_JQUERY, (err) ->
        should.not.exist(err)
        done()
        return
      return

    it "should get tags for book 2", (done) ->
      bookTagger.get 2, (err, tags) ->
        console.log "[taggabler_via_redis_test] tags:#{tags}"
        should.not.exist(err)
        tags.sort().should.containDeep(TAGS_JQUERY)
        done()
        return
      return

    it "should set tags on book 3", (done) ->
      bookTagger.set 3, TAGS_RAILS, (err) ->
        should.not.exist(err)
        done()
        return
      return

    it "should get tags for book 3", (done) ->
      bookTagger.get 3, (err, tags) ->
        console.log "[taggabler_via_redis_test] tags:#{tags}"
        should.not.exist(err)
        tags.sort().should.containDeep(TAGS_RAILS)
        done()
        return
      return

    it "should set tags on book 4", (done) ->
      bookTagger.set 4, TAGS_COFFEESCRIPT, (err)->
        should.not.exist(err)
        done()
        return
      return

    it "should get tags for book 4", (done) ->
      bookTagger.get 4, (err, tags) ->
        console.log "[taggabler_via_redis_test] tags:#{tags}"
        should.not.exist(err)
        tags.sort().should.containDeep(TAGS_COFFEESCRIPT)
        done()
        return
      return

    it "should get empty array if book has not been tagged", (done) ->
      bookTagger.get 99, (err, tags) ->
        should.not.exist(err)
        Array.isArray(tags).should.be.ok
        tags.should.be.empty
        done()
        return
      return

    it "should find books from tag", (done) ->
      bookTagger.find "client", (err, rsp) ->
        should.not.exist(err)
        rsp.sort().should.containDeep(["2","4"])
        done()
        return
      return

    it "should get empty array for non existing tag", (done) ->
      bookTagger.find "maytag", (err, rsp) ->
        should.not.exist(err)
        Array.isArray(rsp).should.be.ok
        rsp.should.be.empty
        done()
        return
      return

    it "should get all items if no tags specified", (done) ->
      bookTagger.find [], (err, rsp) ->
        console.log "[taggabler_via_redis_test] rsp:#{rsp}"
        should.not.exist(err)
        Array.isArray(rsp).should.be.ok
        rsp.should.be.empty
        done()
        return
      return

    it "should get most popular tags", (done) ->
      bookTagger.popular 10, (err, rsp) ->
        console.log "[taggabler_via_redis_test] rsp:"
        console.dir rsp
        should.not.exist(err)
        #console.log "[taggabler_via_redis_test] rsp[0]:#{rsp[0]}"
        rsp[0].should.containDeep(["programming", 4])
        done()
        return
      return



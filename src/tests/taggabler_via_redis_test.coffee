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
TAGS_COFFEESCRIPT = "javascript,client,server,programmin".split(",").sort()


## Test cases
describe "test taggabler_via_redis", ->

  before () ->
    # before test happen

  describe "taggabler_via_redis", ->

    it "should set tags on book 1", (done) ->
      bookTagger.set 1, TAGS_NODE, (err) ->
        should.not.exist(err)
        done()
        return
      return

    it "should get tags for book 1", (done) ->
      bookTagger.get 1, (err, tags) ->
        console.log "[taggabler_via_redis_test::method] tags:#{tags}"

        should.not.exist(err)
        tags.sort().should.containDeep(TAGS_NODE)
        done()
        return

      #return

    #"should set tags on book 2": (test) ->
      #bookTagger.set 2, [
        #"javascript"
        #"client"
        #"programming"
      #], (rsp) ->
        #test.ok rsp
        #test.done()
        #return

      #return

    #"should get tags for book 2": (test) ->
      #bookTagger.get 2, (rsp) ->
        #test.deepEqual rsp.sort(), [
          #"javascript"
          #"client"
          #"programming"
        #].sort()
        #test.done()
        #return

      #return

    #"should set tags on book 3": (test) ->
      #bookTagger.set 3, [
        #"ruby"
        #"server"
        #"programming"
      #], (rsp) ->
        #test.ok rsp
        #test.done()
        #return

      #return

    #"should get tags for book 3": (test) ->
      #bookTagger.get 3, (rsp) ->
        #test.deepEqual rsp.sort(), [
          #"ruby"
          #"server"
          #"programming"
        #].sort()
        #test.done()
        #return

      #return

    #"should set tags on book 4": (test) ->
      #bookTagger.set 4, [
        #"javascript"
        #"client"
        #"server"
        #"programming"
      #], (rsp) ->
        #test.ok rsp
        #test.done()
        #return

      #return

    #"should get tags for book 4": (test) ->
      #bookTagger.get 4, (rsp) ->
        #test.deepEqual rsp.sort(), [
          #"javascript"
          #"client"
          #"server"
          #"programming"
        #].sort()
        #test.done()
        #return

      #return

    #"should get empty array if book has not been tagged": (test) ->
      #bookTagger.get 99, (rsp) ->
        #test.deepEqual rsp, []
        #test.done()
        #return

      #return

    #"should find books from tag": (test) ->
      #bookTagger.find ["client"], (rsp) ->
        #test.deepEqual rsp.sort(), [
          #"2"
          #"4"
        #].sort()
        #test.done()
        #return

      #return

    #"should get empty array for non existing tag": (test) ->
      #bookTagger.find ["maytag"], (rsp) ->
        #test.deepEqual rsp, []
        #test.done()
        #return

      #return

    #"should get all items if no tags specified": (test) ->
      #bookTagger.find [], (rsp) ->
        #test.equal rsp, `undefined`
        #test.done()
        #return

      #return

    #"should get most popular tags": (test) ->
      #bookTagger.popular 10, (rsp) ->
        #test.deepEqual rsp[0], [
          #"programming"
          #4
        #]
        #test.done()
        #return

      #return

    #cleanup: (test) ->
      #redis = require("redis")
      #client = redis.createClient()
      #client.flushall()
      #client.quit()
      #bookTagger.quit()
      #test.done()
      #return
  #)


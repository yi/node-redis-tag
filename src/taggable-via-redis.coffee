##
# taggable-via-redis
# https://github.com/yi/node-taggable-via-redis
#
# Copyright (c) 2014 Yi
# Licensed under the MIT license.
##

redis = require "redis"


class Taggable


  ###
  constructor
  @param {String} taggable
  @param {uint}  [redisPort] specify custom redis port
  @param {String} [redisHost] specify custom redis host
  ###
  constructor : (taggable, redisPort, redisHost) ->
    @redisClient = redis.createClient(redisPort, redisHost)
    @taggable = taggable
    return

  scopedSet : (scope, id, tags, cb) ->
    that = this
    newList = tags

    # get current tags
    that.redisClient.smembers scope + ":" + that.taggable + ":" + id + ":tags", (err, reply) ->

      # keep record of old list
      oldList = (if reply then reply else [])

      # make array of tags that need to be removed
      added = newList.filter((i) ->
        oldList.indexOf(i) is -1
      )

      # make array of tags that need to be added
      removed = oldList.filter((i) ->
        newList.indexOf(i) is -1
      )

      # set counters
      toAddCount = added.length
      toRemoveCount = removed.length

      # nothing has been changed
      if toAddCount is 0 and toRemoveCount is 0
        cb()
        return

      # add new tags
      added.forEach (tag) ->
        that.redisClient.multi().sadd(scope + ":" + that.taggable + ":" + id + ":tags", tag).sadd(scope + ":" + that.taggable + ":tags:" + tag, id).zincrby(scope + ":" + that.taggable + ":tags", 1, tag).sadd(that.taggable + ":" + id + ":tags", tag).sadd(that.taggable + ":tags:" + tag, id).zincrby(that.taggable + ":tags", 1, tag).exec (err, replies) ->
          toAddCount--
          cb true  if toAddCount is 0 and toRemoveCount is 0
          return

        return


      # remove the rest
      removed.forEach (tag) ->
        that.redisClient.multi().srem(scope + ":" + that.taggable + ":" + id + ":tags", tag).srem(scope + ":" + that.taggable + ":tags:" + tag, id).zincrby(scope + ":" + that.taggable + ":tags", -1, tag).srem(that.taggable + ":" + id + ":tags", tag).srem(that.taggable + ":tags:" + tag, id).zincrby(that.taggable + ":tags", -1, tag).exec (err, replies) ->
          that.redisClient.zrem scope + ":" + that.taggable + ":tags", tag  if replies[2] is "0"

          # remove tag from system if count is zero
          that.redisClient.zrem that.taggable + ":tags", tag  if replies[5] is "0"
          toRemoveCount--
          cb true  if toAddCount is 0 and toRemoveCount is 0
          return

        return

      return

    return

  unscopedSet : (id, tags, cb) ->
    that = this
    newList = tags

    # get current tags
    that.redisClient.smembers that.taggable + ":" + id + ":tags", (err, reply) ->

      # keep record of old list
      oldList = (if reply then reply else [])

      # make array of tags that need to be added
      removed = oldList.filter((i) ->
        newList.indexOf(i) is -1
      )

      # make array of tags that need to be removed
      added = newList.filter((i) ->
        oldList.indexOf(i) is -1
      )

      # set counters
      toAddCount = added.length
      toRemoveCount = removed.length

      # nothing has been changed
      if toAddCount is 0 and toRemoveCount is 0
        cb()
        return

      # add new tags
      added.forEach (tag) ->
        that.redisClient.multi().sadd(that.taggable + ":" + id + ":tags", tag).sadd(that.taggable + ":tags:" + tag, id).zincrby(that.taggable + ":tags", 1, tag).exec (err, replies) ->
          toAddCount--
          cb true  if toAddCount is 0 and toRemoveCount is 0
          return

        return


      # remove the rest
      removed.forEach (tag) ->
        that.redisClient.multi().srem(that.taggable + ":" + id + ":tags", tag).srem(that.taggable + ":tags:" + tag, id).zincrby(that.taggable + ":tags", -1, tag).exec (err, replies) ->

          # remove tag from system if count is zero
          that.redisClient.zrem that.taggable + ":tags", tag  if replies[2] is "0"
          toRemoveCount--
          cb true  if toAddCount is 0 and toRemoveCount is 0
          return

        return

      return

    return

  set : (scope, id, tags, cb) ->
    if cb
      @scopedSet scope, id, tags, cb
    else

      # cb = tags
      # tags = id
      # id = scope
      @unscopedSet scope, id, tags
    return

  get : (scope, id, cb) ->

    # scope
    if cb
      @redisClient.smembers scope + ":" + @taggable + ":" + id + ":tags", (err, reply) ->
        cb reply
        return

    else

      # cb = id
      # id = scope
      @redisClient.smembers @taggable + ":" + scope + ":tags", (err, reply) ->
        id reply
        return

    return

  find : (scope, tags, cb) ->
    sets = []
    that = this

    # set list of arguments

    # scope
    if cb
      tags.forEach (tag) ->
        sets.push scope + ":" + that.taggable + ":tags:" + tag
        return

    else

      # cb = tags
      # tags = scope
      scope.forEach (tag) ->
        sets.push that.taggable + ":tags:" + tag
        return

      cb = tags
    @redisClient.sinter sets, (err, reply) ->
      cb reply
      return

    return

  popular : (scope, count, cb) ->

    # scoped
    if cb
      key = scope + ":" + @taggable + ":tags"

    # unscoped
    else
      cb = count
      count = scope
      key = @taggable + ":tags"
    @redisClient.zrevrange key, 0, count - 1, "WITHSCORES", (err, reply) ->
      list = []
      type = "key"
      tag = []
      counter = reply.length / 2
      reply.forEach (item) ->
        if type is "key"
          type = "value"
          tag[0] = item
        else
          type = "key"
          tag[1] = parseInt(item)
          list.push tag
          tag = []
          counter--
          cb list  if counter is 0
        return

      return

    return

  @quit = ->
    @redisClient.quit()
    return

module.exports = Taggable




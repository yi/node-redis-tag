##
# taggable-via-redis
# https://github.com/yi/node-taggable-via-redis
#
# Copyright (c) 2014 Yi
# Licensed under the MIT license.
##

redis = require "redis"
debuglog = require("debug")("Taggable")
assert = require "assert"

EMPTY_STRING = ''

DEFAULT =
  prefix : "_T" # redis key prefix

class Taggable


  ###
  constructor
  @param {String} taggable
  @param {uint}  [redisPort] specify custom redis port
  @param {String} [redisHost] specify custom redis host
  ###
  constructor : (options) ->
    assert options, "missing options"
    assert options.taggable, "missing taggable in options"
    if options.redisClient
      @redisClient = options.redisClient
    else
      @redisClient = redis.createClient(redisPort, redisHost)
    @taggable = options.taggable
    @prefix = options.prefix || DEFAULT.prefix
    return

  # @param {String} scope
  # @param {String} id
  # @param {String[]} tags
  # @param {Function} callback
  scopedSet : (scope, id, tags, callback) ->
    debuglog "[scopedSet] scope:#{scope}, id:#{id}, tags:#{tags}"

    newList = tags

    # get current tags
    @redisClient.smembers "#{@prefix}:#{scope}:#{@taggable}:#{id}:tags", (err, oldList) =>
      return callback?(err) if err?

      # keep record of old list
      oldList = oldList || []

      # make array of tags that need to be removed
      added = newList.filter((i) -> oldList.indexOf(i) is -1)

      # make array of tags that need to be added
      removed = oldList.filter((i) -> newList.indexOf(i) is -1)

      # set counters
      toAddCount = added.length
      toRemoveCount = removed.length

      # nothing has been changed
      return callback?() if toAddCount is 0 and toRemoveCount is 0

      # add new tags
      added.forEach (tag) =>
        @redisClient.multi()
        .sadd("#{@prefix}:#{scope}:#{@taggable}:#{id}:tags", tag)
        .sadd("#{@prefix}:#{scope}:#{@taggable}:tags:#{tag}", id)
        .zincrby("#{@prefix}:#{scope}:#{@taggable}:tags", 1, tag)
        .sadd("#{@prefix}:#{@taggable}:#{id}:tags", tag)
        .sadd("#{@prefix}:#{@taggable}:tags:#{tag}", id)
        .zincrby("#{@prefix}:#{@taggable}:tags", 1, tag)
        .exec (err, replies) ->
          return callback?(err) if err?
          toAddCount--
          return callback?() if toAddCount <= 0 and toRemoveCount <= 0
        return


      # remove the rest
      removed.forEach (tag) =>
        @redisClient.multi()
        .srem("#{@prefix}:#{scope}:#{@taggable}:#{id}:tags", tag)
        .srem("#{@prefix}:#{scope}:#{@taggable}:tags:#{tag}", id)
        .zincrby("#{@prefix}:#{scope}:#{@taggable}:tags", -1, tag)
        .srem("#{@prefix}:#{@taggable}:#{id}:tags", tag)
        .srem("#{@prefix}:#{@taggable}:tags:#{tag}", id)
        .zincrby("#{@prefix}:#{@taggable}:tags", -1, tag)
        .exec (err, replies) =>
          return callback?(err) if err?

          @redisClient.zrem("#{@prefix}:#{scope}:#{@taggable}:tags", tag) if replies[2] is "0"

          # remove tag from system if count is zero
          @redisClient.zrem("#{@prefix}:#{@taggable}:tags", tag) if replies[5] is "0"

          toRemoveCount--

          callback?() if toAddCount <= 0 and toRemoveCount <= 0
          return

        return

      return

    return

  unscopedSet : (id, tags, callback) ->
    debuglog "[unscopedSet] id:#{id}, tags:#{tags}"

    newList = tags

    # get current tags
    @redisClient.smembers "#{@prefix}:#{@taggable}:#{id}:tags", (err, oldList) =>

      # keep record of old list
      oldList = oldList || []

      # make array of tags that need to be added
      removed = oldList.filter((i) -> newList.indexOf(i) is -1)

      # make array of tags that need to be removed
      added = newList.filter((i) -> oldList.indexOf(i) is -1)

      # set counters
      toAddCount = added.length
      toRemoveCount = removed.length

      # nothing has been changed
      return callback?() if toAddCount is 0 and toRemoveCount is 0

      # add new tags
      added.forEach (tag) =>
        @redisClient.multi()
        .sadd("#{@prefix}:#{@taggable}:#{id}:tags", tag)
        .sadd("#{@prefix}:#{@taggable}:tags:#{tag}", id)
        .zincrby("#{@prefix}:#{@taggable}:tags", 1, tag)
        .exec (err, replies) =>
          return callback?(err) if err?

          toAddCount--
          callback?() if toAddCount is 0 and toRemoveCount is 0
          return
        return

      # remove the rest
      removed.forEach (tag) =>
        @redisClient.multi()
        .srem("#{@prefix}:#{@taggable}:#{id}:tags", tag)
        .srem("#{@prefix}:#{@taggable}:tags:#{tag}", id)
        .zincrby("#{@prefix}:#{@taggable}:tags", -1, tag)
        .exec (err, replies) =>
          # remove tag from system if count is zero
          @redisClient.zrem("#{@prefix}:#{@taggable}:tags", tag) if replies[2] is "0"
          toRemoveCount--
          callback?() if toAddCount is 0 and toRemoveCount is 0
          return
        return
      return
    return

  set : (scope, id, tags, callback) ->
    debuglog "[set] scope:#{scope}, id:#{id}"

    if callback
      @scopedSet scope, id, tags, callback
    else

      # callback = tags
      # tags = id
      # id = scope
      @unscopedSet scope, id, tags
    return

  get : (scope, id, callback) ->
    # scope
    if callback
      @redisClient.smembers "#{@prefix}:#{scope}:#{@taggable}:#{id}:tags", callback
    else
      # callback = id
      # id = scope
      @redisClient.smembers "#{@prefix}:#{@taggable}:#{scope}:tags", id

    return

  find : (scope, tags, callback) ->

    unless callback?
      callback = tags
      tags = scope
      scope = ""
    else
      scope = "#{scope}:"

    debuglog "[find] scope:#{scope}, tags:#{tags}"

    return callback(null, []) unless (tags || EMPTY_STRING).toString()

    sets = []  # leave tags untouched

    if Array.isArray(tags)
      for tag, i in tags
        sets.push "#{@prefix}:#{scope}#{@taggable}:tags:#{tag}"
    else
      sets.push "#{@prefix}:#{scope}#{@taggable}:tags:#{tags}"

    @redisClient.sinter sets, callback
    return

  popular : (scope, count, callback) ->

    # scoped
    if callback
      key = "#{@prefix}:#{scope}:#{@taggable}:tags"

    # unscoped
    else
      callback = count
      count = scope
      key = "#{@prefix}:#{@taggable}:tags"

    @redisClient.zrevrange key, 0, count - 1, "WITHSCORES", (err, reply) ->
      return callback?(err) if err?
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
        callback?(null, list) if counter <= 0
        return

      return

    return

  @quit = -> @redisClient.quit()

module.exports = Taggable




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
EMPTY_ARRAY = []

PREFIX = "_T" # redis key prefix

REDIS_CLIENT = null

# @param {String} scope
# @param {String} id
# @param {String[]} tags
# @param {Function} callback
scopedSet = (type, scope, id, tags, callback) ->
  debuglog "[scopedSet] type:#{type}, scope:#{scope}, id:#{id}, tags:#{tags}"

  newList = tags

  # get current tags
  REDIS_CLIENT.smembers "#{PREFIX}:#{scope}:#{type}:#{id}:tags", (err, oldList) =>
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
      REDIS_CLIENT.multi()
      .sadd("#{PREFIX}:#{scope}:#{type}:#{id}:tags", tag)
      .sadd("#{PREFIX}:#{scope}:#{type}:tags:#{tag}", id)
      .zincrby("#{PREFIX}:#{scope}:#{type}:tags", 1, tag)
      .sadd("#{PREFIX}:#{type}:#{id}:tags", tag)
      .sadd("#{PREFIX}:#{type}:tags:#{tag}", id)
      .zincrby("#{PREFIX}:#{type}:tags", 1, tag)
      .exec (err, replies) ->
        return callback?(err) if err?
        toAddCount--
        return callback?() if toAddCount <= 0 and toRemoveCount <= 0
      return


    # remove the rest
    removed.forEach (tag) =>
      REDIS_CLIENT.multi()
      .srem("#{PREFIX}:#{scope}:#{type}:#{id}:tags", tag)
      .srem("#{PREFIX}:#{scope}:#{type}:tags:#{tag}", id)
      .zincrby("#{PREFIX}:#{scope}:#{type}:tags", -1, tag)
      .srem("#{PREFIX}:#{type}:#{id}:tags", tag)
      .srem("#{PREFIX}:#{type}:tags:#{tag}", id)
      .zincrby("#{PREFIX}:#{type}:tags", -1, tag)
      .exec (err, replies) =>
        return callback?(err) if err?

        REDIS_CLIENT.zrem("#{PREFIX}:#{scope}:#{type}:tags", tag) if replies[2] is "0"

        # remove tag from system if count is zero
        REDIS_CLIENT.zrem("#{PREFIX}:#{type}:tags", tag) if replies[5] is "0"

        toRemoveCount--

        callback?() if toAddCount <= 0 and toRemoveCount <= 0
        return

      return

    return

  return

unscopedSet = (type, id, tags, callback) ->
  debuglog "[unscopedSet] type:#{type}, id:#{id}, tags:#{tags}"

  newList = tags

  # get current tags
  REDIS_CLIENT.smembers "#{PREFIX}:#{type}:#{id}:tags", (err, oldList) =>

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
      REDIS_CLIENT.multi()
      .sadd("#{PREFIX}:#{type}:#{id}:tags", tag)
      .sadd("#{PREFIX}:#{type}:tags:#{tag}", id)
      .zincrby("#{PREFIX}:#{type}:tags", 1, tag)
      .exec (err, replies) =>
        return callback?(err) if err?

        toAddCount--
        callback?() if toAddCount is 0 and toRemoveCount is 0
        return
      return

    # remove the rest
    removed.forEach (tag) =>
      REDIS_CLIENT.multi()
      .srem("#{PREFIX}:#{type}:#{id}:tags", tag)
      .srem("#{PREFIX}:#{type}:tags:#{tag}", id)
      .zincrby("#{PREFIX}:#{type}:tags", -1, tag)
      .exec (err, replies) =>
        # remove tag from system if count is zero
        REDIS_CLIENT.zrem("#{PREFIX}:#{type}:tags", tag) if replies[2] is "0"
        toRemoveCount--
        callback?() if toAddCount is 0 and toRemoveCount is 0
        return
      return
    return
  return


exports.init = (redisClient, prefix)->
  REDIS_CLIENT = redisClient || REDIS_CLIENT
  PREFIX = prefix || PREFIX
  return

exports.set = (type, id, tags, scope, callback) ->

  assert REDIS_CLIENT, "redis client not init"

  type = String(type || EMPTY_STRING)
  assert type, "bad argument type:#{type})"

  id = String(id || EMPTY_STRING)
  assert id, "bad argument id:#{id})"

  if 'function' is typeof scope
    callback = scope
    scope = null

  tags = tags || EMPTY_ARRAY

  debuglog "[set] type:#{type}, id:#{id}, tags:#{tags}, scope:#{scope},"

  if scope
    scopedSet type, scope, id, tags, callback
  else
    unscopedSet type, id, tags, callback
  return


exports.get = (type, ids, scope, callback) ->

  if 'function' is typeof scope
    callback = scope
    scope = ""
  else
    scope = if scope? then "#{scope}:" else EMPTY_STRING

  debuglog "[get] type:#{type}, ids:#{ids}, scope:#{scope}"

  unless ids
    return callback?(null, [])

  unless Array.isArray(ids) and ids.length > 0
    # single id
    REDIS_CLIENT.smembers "#{PREFIX}:#{scope}#{type}:#{ids}:tags", callback
  else
    proc = REDIS_CLIENT.multi()
    for id in ids
      proc = proc.smembers "#{PREFIX}:#{scope}#{type}:#{id}:tags"
    proc.exec callback
  return

exports.find = (type, tags, scope, callback) ->

  assert REDIS_CLIENT, "redis client not init"

  if 'function' is typeof scope
    callback = scope
    scope = EMPTY_STRING
  else
    scope = if scope? then  "#{scope}:" else EMPTY_STRING

  debuglog "[find] type:#{type}, tags:#{tags}, scope:#{scope}"

  return callback(null, []) unless (tags || EMPTY_STRING).toString()

  sets = []  # leave tags untouched

  if Array.isArray(tags)
    for tag, i in tags
      sets.push "#{PREFIX}:#{scope}#{type}:tags:#{tag}"
  else
    sets.push "#{PREFIX}:#{scope}#{type}:tags:#{tags}"

  REDIS_CLIENT.sinter sets, callback
  return

exports.popular = (type, count, scope, callback) ->

  assert REDIS_CLIENT, "redis client not init"

  count = parseInt count, 10
  assert count > 0, "bad argument count:#{count}"

  if 'function' is typeof scope
    callback = scope
    scope = EMPTY_STRING
  else
    scope = if scope? then  "#{scope}:" else EMPTY_STRING

  debuglog "[popular] type:#{type}, count:#{count}, scope:#{scope}"

  key = "#{PREFIX}:#{scope}#{type}:tags"

  REDIS_CLIENT.zrevrange key, 0, count - 1, "WITHSCORES", (err, reply) ->
    return callback?(err) if err?

    results = []
    for item, i in reply by 2
      results.push([reply[i], parseInt(reply[i+1], 10)])

    callback?(null, results)
    return

  return





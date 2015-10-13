'use strict'

OptimistHelpers = (options = {}) ->
  timestamp = ->
    now = new Date()
    now.toISOString()

  isObject = (item) ->
    item != null && typeof item == 'object' && Array.isArray(item) == false

  mask = (source, maskObj) ->
    masked = {}

    for own name, value of source
      if maskObj.hasOwnProperty name
        if isObject value
          masked[name] = mask value, maskObj[name]
        else
          masked[name] = value

    masked

  filter = (source, filterObj) ->
    filtered = {}

    for own name, value of source
      if filterObj.hasOwnProperty name
        if isObject(value) && isObject(filterObj[name])
          filtered[name] = filter value, filterObj[name]
      else
        filtered[name] = angular.copy value

    filtered

  walk = (collection, action) ->
    for own name, value of collection
      if isObject(value)
        walk value, action
      else
        action value, name, collection

  timestamp: timestamp
  isObject: isObject
  mask: mask
  filter: filter
  walk: walk

OptimistHelpers.$inject = ['$rootScope']

angular.module('appirio-tech-ng-optimist').factory 'OptimistHelpers', OptimistHelpers
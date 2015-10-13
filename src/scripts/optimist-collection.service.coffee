'use strict'

OptimistCollection = (OptimistHelpers, OptimistModel) ->
  Collection = (options = {}) ->
    @configure options

    @

  Collection.prototype.configure = (options) ->
    @_collection = []
    @_defaults =
      updateCallback: options.updateCallback || angular.noop
      matchByProp: options.matchByProp || 'id'
      propsToIgnore: options.propsToIgnore || []

  Collection.prototype.get = ->
    @_collection

  Collection.prototype.clearError = ->
    if @_collection._error
      delete @_collection._error

  Collection.prototype.fetch = (options = {}) ->
    apiCall              = options.apiCall
    updateCallback       = options.updateCallback || @_defaults.updateCallback
    clearErrorsOnSuccess = options.clearErrorsOnSuccess != false
    propsToIgnore        = options.propsToIgnore || @_defaults.propsToIgnore

    @_collection._pending = true

    updateCallback(@_collection)

    request = apiCall()

    request.then (response) =>
      @_collection._lastUpdated = OptimistHelpers.timestamp()

      if clearErrorsOnSuccess
        @clearError()

      @_collection = response.map (item) =>
        new OptimistModel
          data: item
          updateCallback: updateCallback
          propsToIgnore: propsToIgnore

      response

    request.catch (err) =>
      @_collection._error = err

    request.finally () =>
      @_collection.pending = false
      updateCallback(@_collection)

  Collection.prototype.findWhere = (filters) ->
    @_collection.filter (ref) ->
      item = ref.get()

      for name, value of filters
        unless item[name] == value
          return false

      true

  Collection

OptimistCollection.$inject = ['OptimistHelpers', 'OptimistModel']

angular.module('appirio-tech-ng-optimist').factory 'OptimistCollection', OptimistCollection
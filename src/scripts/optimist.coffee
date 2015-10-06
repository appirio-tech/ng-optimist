'use strict'

Optimist = () ->

  ###########
  # Helpers #
  ###########

  metaTemplate =
    pending: false
    error: null
    propsUpdated: {}
    propsPending: {}
    propsErrored: {}

  Model = (options = {}) ->
    data = options.data || {}
    data = angular.copy data
    meta = angular.copy metaTemplate
    defaults =
      updateCallback: options.updateCallback || angular.noop
      propsToIgnore: options.propsToIgnore || []

    clearErrors = ->
      meta.error        = null
      meta.propsErrored = {}

    applyProps = (options = {}) ->
      source  = options.source || []
      include = options.include || []
      ignore =  options.ignore || []

      if include.length == 0
        includeAll = true

      for name, prop of source
        enumerable = source.propertyIsEnumerable(name)
        included = include.indexOf(name) >= 0
        ignored = ignore.indexOf(name) >= 0

        if (includeAll || included) && enumerable && !ignored
          data[name] = angular.copy(prop)

    timestamp = ->
      now              = new Date()
      meta.lastUpdated = now.toISOString()

    @hasPending = ->
      meta.pending || meta.propsPending.keys

    @get = ->
      snapshot = angular.copy data
      snapshot.o = angular.copy meta

      snapshot

    @fetch = (options = {}) ->
      apiCall              = options.apiCall || angular.noop
      updateCallback       = options.updateCallback || defaults.updateCallback
      handleResponse       = options.handleResponse != false
      clearErrorsOnSuccess = options.clearErrorsOnSuccess != false
      propsToIgnore        = options.propsToIgnore || defaults.propsToIgnore

      meta.pending = true

      # This callback should be non-blocking and update your app state
      updateCallback(data)

      # Should return a promise for a server update
      request = apiCall()

      request.then (response) ->
        timestamp()

        if clearErrorsOnSuccess
          clearErrors()

        if handleResponse
          applyProps
            source: response
            ignore: propsToIgnore

        response

      request.catch (err) ->
        meta.error = err

      request.finally () ->
        meta.pending = false
        updateCallback(data)

    @updateLocal = (options = {}) ->
      updates        = options.updates || []
      updateCallback = options.updateCallback || defaults.updateCallback

      applyProps
        source: updates

      updateCallback(data)

    @restore = ->
      # TODO: Fill out this function

    @update = (options = {}) ->
      @updateLocal(options)
      @save(options)

    @save = (options = {}) ->
      updates              = options.updates
      apiCall              = options.apiCall || angular.noop
      updateCallback       = options.updateCallback || defaults.updateCallback
      handleResponse       = options.handleResponse != false
      clearErrorsOnSuccess = options.clearErrorsOnSuccess != false
      rollbackOnFailure    = options.rollbackOnFailure || false

      request = apiCall data

      for name, prop of updates
        meta.propsPending[name] = true

      # This callback should be non-blocking and update your app state
      updateCallback(data)

      request.then (response) ->
        timestamp()

        if clearErrorsOnSuccess
          clearErrors()

        if handleResponse
          applyProps
            source: response
            include: Object.keys updates

      request.catch (err) ->
        if rollbackOnFailure
          @restore(options)

        for name, prop of updates
          meta.propsErrored[name] = err

      request.finally () ->
        for name, prop of updates
          delete meta.propsPending[name]

        updateCallback(data)

    @

  Collection = (options = {}) ->
    collection = []
    meta = angular.copy metaTemplate

    defaults =
      updateCallback: options.updateCallback || angular.noop
      matchByProp: options.matchByProp || 'id'

    timestamp = ->
      now              = new Date()
      meta.lastUpdated = now.toISOString()

    clearErrors = ->
      meta.error        = null
      meta.propsErrored = {}

    @get = ->
      collection.map (item) ->
        item.get()

    @fetch = (options = {}) ->
      apiCall              = options.apiCall || angular.noop
      updateCallback       = options.updateCallback || defaults.updateCallback
      clearErrorsOnSuccess = options.clearErrorsOnSuccess != false

      meta.pending = true

      # This callback should be non-blocking and update your app state
      updateCallback(collection)

      # Should return a promise for a server update
      request = apiCall()

      request.then (response) ->
        timestamp()

        if clearErrorsOnSuccess
          clearErrors()

        collection = response.map (item) ->
          new Model
            data: item

        response

      request.catch (err) ->
        meta.error = err

      request.finally () ->
        meta.pending = false
        updateCallback(collection)

    @findWhere = (filters) ->
      collection.filter (ref) ->
        item = ref.get()

        for name, value of filters
          unless item[name] == value
            return false

        true

    @

  Model      : Model
  Collection : Collection

Optimist.$inject = ['$rootScope']

angular.module('appirio-tech-ng-optimist').factory 'Optimist', Optimist
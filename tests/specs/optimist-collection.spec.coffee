'use strict'

describe 'Optimist', ->
  collection = null
  rootScope = null
  updateCallbackSpy = null
  apiSpy = null
  rejectApiSpy = null

  sample = [
    { a: 1 }
    { b: 2 }
    { c: 3 }
  ]

  beforeEach inject (OptimistCollection, $rootScope, $q) ->
    rootScope = $rootScope
    collection = new OptimistCollection

    updateCallbackSpy = sinon.spy ->

    apiSpy = sinon.spy (data) ->
      deferred = $q.defer()
      deferred.resolve sample
      deferred.promise

    rejectApiSpy = sinon.spy (data) ->
      deferred = $q.defer()
      deferred.reject 'error'
      deferred.promise

  describe 'instantiation', ->
    it 'should initialize an empty collection', ->
      expect(collection).to.exist

  describe 'fetch', ->
    it 'should invoke apiCall', ->
      collection.fetch
        apiCall: apiSpy

      expect(apiSpy.called).to.be.true

    it 'should update the collection data', ->
      collection.fetch
        apiCall: apiSpy

      rootScope.$apply()

      data = collection.get().map (item) ->
        item.get()

      expect(data[0].a).to.equal 1
      expect(data[1].b).to.equal 2
      expect(data[2].c).to.equal 3

    it 'should invoke updateCallback before promise resolves', ->
      collection.fetch
        apiCall: apiSpy
        updateCallback: updateCallbackSpy

      expect(updateCallbackSpy.callCount).to.equal 1

    it 'should invoke updateCallback after promise resolves', ->
      collection.fetch
        apiCall: apiSpy
        updateCallback: updateCallbackSpy

      rootScope.$apply()
      expect(updateCallbackSpy.callCount).to.equal 2

    it 'should set a pending flag on dispatch', ->
      collection.fetch
        apiCall: apiSpy
        updateCallback: updateCallbackSpy

      data = collection.get()

      expect(data._pending).to.be.true

    it 'should remove the pending flag on resolution', ->
      collection.fetch
        apiCall: apiSpy
        updateCallback: updateCallbackSpy

      rootScope.$apply()
      data = collection.get()

      expect(data._pending).to.be.undefined

    it 'should append an error message on api error', (done) ->
      collection.fetch
        apiCall: rejectApiSpy
        updateCallback: updateCallbackSpy

      rootScope.$apply()
      data = collection.get()

      expect(data._error).to.equal 'error'
      done()


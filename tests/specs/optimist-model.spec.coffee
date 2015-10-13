'use strict'

describe 'Optimist', ->
  Model = null
  model = null
  rootScope = null
  updateCallbackSpy = null
  apiSpy = null
  rejectApiSpy = null

  nested =
    a: 1
    sub:
      b: 2
      sub:
        c: 3

  withMeta =
    a: 1
    a_backup: 0
    a_pending: true
    a_error: 'error'
    sub:
      b: 2
      b_backup: 1
      b_pending: true
      b_error: 'error'

  beforeEach inject (OptimistModel, $rootScope, $q) ->
    rootScope = $rootScope
    Model = OptimistModel
    model = new Model

    updateCallbackSpy = sinon.spy ->

    apiSpy = sinon.spy (data) ->
      deferred = $q.defer()
      deferred.resolve nested
      deferred.promise

    rejectApiSpy = sinon.spy (data) ->
      deferred = $q.defer()
      deferred.reject 'error'
      deferred.promise

  describe 'instantiation', ->
    it 'should initialize a blank model', ->
      expect(model).to.exist

    it 'should accept initial data', ->
      model = new Model
        data: nested

      expect(model._data.sub.sub.c).to.equal 3

  describe 'configuration', ->
    it 'should accept data after instantiation', ->
      model.configure
        data: nested

      expect(model._data.sub.sub.c).to.equal 3

  describe 'get', ->
    it 'should return the current data', ->
      model = new Model
        data: nested

      expect(model.get().sub.sub.c).to.equal 3

  describe 'getClean', ->
    it 'should return the current data without any metadata', ->
      model = new Model
        data: withMeta

      data = model.getClean()

      expect(data.a).to.equal 1
      expect(data.a_pending).to.be.undefined
      expect(data.a_error).to.be.undefined
      expect(data.a_backup).to.be.undefined
      expect(data.sub.b).to.equal 2
      expect(data.sub.b_pending).to.be.undefined
      expect(data.sub.b_error).to.be.undefined
      expect(data.sub.b_backup).to.be.undefined

  describe 'fetch', ->
    it 'should invoke apiCall', ->
      model.fetch
        apiCall: apiSpy

      expect(apiSpy.called).to.be.true

    it 'should update the model data', ->
      model.fetch
        apiCall: apiSpy

      rootScope.$apply()
      data = model.get()
      expect(data.a).to.equal 1
      expect(data.sub.b).to.equal 2
      expect(data.sub.sub.c).to.equal 3

    it 'should invoke updateCallback before promise resolves', ->
      model.fetch
        apiCall: apiSpy
        updateCallback: updateCallbackSpy

      expect(updateCallbackSpy.callCount).to.equal 1

    it 'should invoke updateCallback after promise resolves', ->
      model.fetch
        apiCall: apiSpy
        updateCallback: updateCallbackSpy

      rootScope.$apply()
      expect(updateCallbackSpy.callCount).to.equal 2

    it 'should set a pending flag on dispatch', ->
      model.fetch
        apiCall: apiSpy
        updateCallback: updateCallbackSpy

      data = model.get()

      expect(data._pending).to.be.true

    it 'should remove the pending flag on resolution', ->
      model.fetch
        apiCall: apiSpy
        updateCallback: updateCallbackSpy

      rootScope.$apply()
      data = model.get()

      expect(data._pending).to.be.undefined

    it 'should append an error message on api error', (done) ->
      model.fetch
        apiCall: rejectApiSpy
        updateCallback: updateCallbackSpy

      rootScope.$apply()
      data = model.get()

      expect(data._error).to.equal 'error'
      done()

  describe 'set', ->
    it 'should merge updates onto model', ->
      model.set
        updates: nested
        updateValues: true

      expect(model.get().sub.sub.c).to.equal 3

    it 'should walk the whole model if updates are not passed', ->
      model = new Model
        data: nested

      model.set
        setPending: true

      data = model.get()

      expect(data.a).to.equal 1
      expect(data.a_pending).to.be.true

    it 'should invoke updateCallback after updating', ->
      model.set
        updates: nested
        updateCallback: updateCallbackSpy

      expect(updateCallbackSpy.callCount).to.equal 1

    it 'should add a pending flag for each property when setPending is true', ->
      model.set
        updates: nested
        updateValues: true
        setPending: true

      data = model.get()

      expect(data.a).to.equal 1
      expect(data.a_pending).to.equal true
      expect(data.sub.b).to.equal 2
      expect(data.sub.b_pending).to.equal true
      expect(data.sub.sub.c).to.equal 3
      expect(data.sub.sub.c_pending).to.equal true

  describe 'save', ->
    it 'should invoke apiCall with clean (no meta) model data', ->
      model.set
        updates: nested
        updateValues: true
        setPending: true
        setBackup: true
        setError: true
        error: 'wrong'

      model.save
        apiCall: apiSpy

      expect(apiSpy.calledWithMatch(nested)).to.be.true

    it 'should flag updating properties as pending on dispatch', ->
      model = new Model
        data: nested

      model.save
        apiCall: apiSpy

      data = model.get()

      expect(data.a_pending).to.be.true

    it 'should remove pending flag from updating properties on resolution', ->
      model = new Model
        data: nested

      model.save
        apiCall: apiSpy

      rootScope.$apply()

      data = model.get()

      expect(data.a_pending).to.be.false

    it 'should invoke updateCallback before promise resolves', ->
      model.save
        apiCall: apiSpy
        updateCallback: updateCallbackSpy

      expect(updateCallbackSpy.callCount).to.equal 1

    it 'should invoke updateCallback after promise resolves', ->
      model.save
        apiCall: apiSpy
        updateCallback: updateCallbackSpy

      rootScope.$apply()
      expect(updateCallbackSpy.callCount).to.equal 2

    it 'should set updated properties from response', ->
      model = new Model
        data:
          a: 0
          sub:
            b: 0
            sub:
              c: 0

      model.save
        apiCall: apiSpy

      rootScope.$apply()
      data = model.get()

      expect(data.a).to.equal 1
      expect(data.sub.b).to.equal 2
      expect(data.sub.sub.c).to.equal 3

    it 'should set error flag on updated properties on failure', (done) ->
      model = new Model
        data: nested

      model.save
        apiCall: rejectApiSpy

      rootScope.$apply()
      data = model.get()

      expect(data.a_error).to.equal 'error'
      expect(data.sub.b_error).to.equal 'error'
      expect(data.sub.sub.c_error).to.equal 'error'
      done()

    it 'should roll back updated properties on failure (if rollbackOnFailure is set)', ->
      model = new Model
        data:
          a: 0
          sub:
            b: 0
            sub:
              c: 0

      model.set
        updates: nested
        updateValues: true
        setBackup: true

      data = model.get()
      expect(data.a).to.equal 1
      expect(data.a_backup).to.equal 0

      model.save
        update: nested
        apiCall: rejectApiSpy
        rollbackOnFailure: true

      data = model.get()
      expect(data.a).to.equal 1
      expect(data.a_backup).to.equal 0

      rootScope.$apply()

      data = model.get()
      expect(data.a).to.equal 0
      expect(data.a_backup).to.equal 0

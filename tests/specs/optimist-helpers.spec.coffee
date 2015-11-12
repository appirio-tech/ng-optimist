'use strict'

describe 'Optimist', ->
  helpers = null

  beforeEach inject (OptimistHelpers) ->
    helpers = OptimistHelpers
    count = 0

  describe 'isObject', ->
    it 'should return true for objects', ->
      expect(helpers.isObject({})).to.be.true
      expect(helpers.isObject({ a: 1 })).to.be.true

    it 'should return false for non-objects', ->
      expect(helpers.isObject('string')).to.be.false
      expect(helpers.isObject(123)).to.be.false
      expect(helpers.isObject(null)).to.be.false
      expect(helpers.isObject([])).to.be.false

  describe 'mask', ->
    source =
      a: 1
      sub:
        b: 2
        sub:
          c: 3
          d: 4

    mask =
      sub:
        b: true
        sub:
          d: true

    it 'should return only values from the source object where values exist in the mask object', ->
      result = helpers.mask source, mask

      expect(result.a).to.be.undefined
      expect(result.sub.b).to.equal 2
      expect(result.sub.sub.c).to.be.undefined
      expect(result.sub.sub.d).to.equal 4

  describe 'filter', ->
    source =
      a: 1
      sub:
        b: 2
        sub:
          c: 3
          d: 4

    filter =
      a: true
      sub:
        sub:
          c: true

    it 'should return only values from the source element where values do not exist in the filter', ->
      result = helpers.filter source, filter

      expect(result.a).to.be.undefined
      expect(result.sub.b).to.equal 2
      expect(result.sub.sub.c).to.be.undefined
      expect(result.sub.sub.d).to.equal 4

  describe 'walk', ->
    count = 0

    flat =
      a: 1
      b: 2
      c: 3

    nested =
      a: 1
      sub:
        b: 2
        sub:
          c: 3

    countAction = (value) ->
      count = count + value

    beforeEach ->
      count = 0

    it 'should apply the action to each element', ->
      helpers.walk flat, countAction

      expect(count).to.equal 6

    it 'should work recursively on nested objects', ->
      helpers.walk nested, countAction

      expect(count).to.equal 6

  describe 'flatWalkTandem', ->
    count = 0

    flatA =
      a: 1
      b: 1

    flatB =
      b: 1
      c: 1

    countAction = (targetValue, sourceValue, name, target, source) ->
      count = count + 1

    beforeEach ->
      count = 0

    it 'should call action once for each unique key', ->
      helpers.flatWalkTandem flatA, flatB, countAction

      expect(count).to.equal 3

  describe 'extend', ->
    result = null

    flatA =
      a: 1
      b: 1

    flatB =
      b: 2
      c: 2

    nestedA =
      a: 1
      b: 1
      subA:
        a: 1
      subB:
        a: 1

    nestedB =
      b: 2
      c: 2
      subB:
        a: 2
      subC:
        a: 2

    beforeEach ->
      result = {}

    it 'should merge objects together', ->
      result = helpers.merge flatA, flatB

      expect(result.a).to.equal 1
      expect(result.b).to.equal 2
      expect(result.c).to.equal 2

    it 'should recursively merge object properties', ->
      result = helpers.merge nestedA, nestedB

      console.log result

      expect(result.a).to.equal 1
      expect(result.b).to.equal 2
      expect(result.c).to.equal 2
      expect(result.subA.a).to.equal 1
      expect(result.subB.a).to.equal 2
      expect(result.subC.a).to.equal 2

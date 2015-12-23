require 'angular'
require './scripts/optimist.module'
require './scripts/optimist-collection.service'
require './scripts/optimist-helpers.service'
require './scripts/optimist-model.service'

templateCache = ($templateCache) ->

templateCache.$nject = ['$templateCache']

angular.module('appirio-tech-ng-optimist').run templateCache
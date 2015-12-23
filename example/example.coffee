require 'appirio-tech-api-schemas'

templateCache = ($templateCache) ->

templateCache.$nject = ['$templateCache']

angular.module('example').run templateCache
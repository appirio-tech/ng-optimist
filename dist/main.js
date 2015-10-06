(function() {
  'use strict';
  var dependencies;

  dependencies = [];

  angular.module('appirio-tech-ng-optimist', dependencies);

}).call(this);

(function() {
  'use strict';
  var Optimist;

  Optimist = function() {
    var Model, metaTemplate;
    metaTemplate = {
      pending: false,
      error: null,
      propsUpdated: {},
      propsPending: {},
      propsErrored: {}
    };
    Model = function(options) {
      var applyProps, clearErrors, data, defaults, meta, timestamp;
      if (options == null) {
        options = {};
      }
      data = options.data || {};
      data = angular.copy(data);
      meta = angular.copy(metaTemplate);
      defaults = {
        updateCallback: options.updateCallback || angular.noop,
        propsToIgnore: options.propsToIgnore || []
      };
      clearErrors = function() {
        meta.error = null;
        return meta.propsErrored = {};
      };
      applyProps = function(options) {
        var enumerable, ignore, ignored, include, includeAll, included, name, prop, results, source;
        if (options == null) {
          options = {};
        }
        source = options.source || [];
        include = options.include || [];
        ignore = options.ignore || [];
        if (include.length === 0) {
          includeAll = true;
        }
        results = [];
        for (name in source) {
          prop = source[name];
          enumerable = source.propertyIsEnumerable(name);
          included = include.indexOf(name) >= 0;
          ignored = ignore.indexOf(name) >= 0;
          if ((includeAll || included) && enumerable && !ignored) {
            results.push(data[name] = prop);
          } else {
            results.push(void 0);
          }
        }
        return results;
      };
      timestamp = function() {
        var now;
        now = new Date();
        return meta.lastUpdated = now.toISOString();
      };
      this.hasPending = function() {
        return meta.pending || meta.propsPending.keys;
      };
      this.get = function() {
        var snapshot;
        snapshot = angular.copy(data);
        snapshot.o = angular.copy(meta);
        return snapshot;
      };
      this.fetch = function(options) {
        var apiCall, clearErrorsOnSuccess, handleResponse, propsToIgnore, request, updateCallback;
        if (options == null) {
          options = {};
        }
        apiCall = options.apiCall || angular.noop;
        updateCallback = options.updateCallback || defaults.updateCallback;
        handleResponse = options.handleResponse !== false;
        clearErrorsOnSuccess = options.clearErrorsOnSuccess !== false;
        propsToIgnore = options.propsToIgnore || defaults.propsToIgnore;
        meta.pending = true;
        updateCallback(data);
        request = apiCall();
        request.then(function(response) {
          timestamp();
          if (clearErrorsOnSuccess) {
            clearErrors();
          }
          if (handleResponse) {
            applyProps({
              source: response,
              ignore: propsToIgnore
            });
          }
          return response;
        });
        request["catch"](function(err) {
          return meta.error = err;
        });
        return request["finally"](function() {
          meta.pending = false;
          return updateCallback(data);
        });
      };
      this.updateLocal = function(options) {
        var updateCallback, updates;
        if (options == null) {
          options = {};
        }
        updates = options.updates || [];
        updateCallback = options.updateCallback || defaults.updateCallback;
        applyProps({
          source: updates
        });
        return updateCallback(data);
      };
      this.restore = function() {};
      this.update = function(options) {
        if (options == null) {
          options = {};
        }
        this.updateLocal(options);
        return this.save(options);
      };
      this.save = function(options) {
        var apiCall, clearErrorsOnSuccess, handleResponse, name, prop, request, rollbackOnFailure, updateCallback, updates;
        if (options == null) {
          options = {};
        }
        updates = options.updates;
        apiCall = options.apiCall || angular.noop;
        updateCallback = options.updateCallback || defaults.updateCallback;
        handleResponse = options.handleResponse !== false;
        clearErrorsOnSuccess = options.clearErrorsOnSuccess !== false;
        rollbackOnFailure = options.rollbackOnFailure || false;
        request = apiCall(data);
        for (name in updates) {
          prop = updates[name];
          meta.propsPending[name] = true;
        }
        updateCallback(data);
        request.then(function(response) {
          timestamp();
          if (clearErrorsOnSuccess) {
            clearErrors();
          }
          if (handleResponse) {
            return applyProps({
              source: response,
              include: Object.keys(updates)
            });
          }
        });
        request["catch"](function(err) {
          var results;
          if (rollbackOnFailure) {
            this.restore(options);
          }
          results = [];
          for (name in updates) {
            prop = updates[name];
            results.push(meta.propsErrored[name] = err);
          }
          return results;
        });
        return request["finally"](function() {
          for (name in updates) {
            prop = updates[name];
            delete meta.propsPending[name];
          }
          return updateCallback(data);
        });
      };
      return this;
    };
    return {
      Model: Model
    };
  };

  Optimist.$inject = ['$rootScope'];

  angular.module('appirio-tech-ng-optimist').factory('Optimist', Optimist);

}).call(this);

(function() {
  'use strict';
  var Optimist;

  Optimist = function() {
    var fetchOne, noop, restore, save, stripMeta, update, updateLocal, wrapWithMeta;
    noop = function() {};
    wrapWithMeta = function(model, meta) {
      var metaTemplate, metaToApply;
      metaTemplate = {
        pending: false,
        error: null,
        propsUpdated: {},
        propsPending: {},
        propsErrored: {}
      };
      metaToApply = meta || metaTemplate;
      if (!model.o) {
        return model.o = metaToApply;
      }
    };
    stripMeta = function(model) {
      var meta;
      meta = model.o;
      if (model.o) {
        delete model.o;
      }
      return meta;
    };
    fetchOne = function(options) {
      var apiCall, clearErrorsOnSuccess, handleResponse, model, request, updateCallback, updates;
      model = options.model || {};
      updates = options.updates || [];
      apiCall = options.apiCall || noop;
      updateCallback = options.updateCallback || noop;
      handleResponse = options.handleResponse !== false;
      clearErrorsOnSuccess = options.clearErrorsOnSuccess !== false;
      wrapWithMeta(model);
      model.o.pending = true;
      updateCallback(model);
      request = apiCall();
      request.then(function(response) {
        var name, now, prop;
        now = new Date();
        model.o.lastUpdated = now.toISOString();
        if (clearErrorsOnSuccess) {
          model.o.error = null;
        }
        for (name in response) {
          prop = response[name];
          if (response.propertyIsEnumerable(name)) {
            model[name] = prop;
          }
        }
        if (model.$promise) {
          delete model.$promise;
        }
        if (model.$resolved) {
          delete model.$resolved;
        }
        return response;
      });
      request["catch"](function(err) {
        return model.o.error = err;
      });
      return request["finally"](function() {
        model.o.pending = false;
        return updateCallback(model);
      });
    };
    updateLocal = function(options) {
      var model, name, prop, updateCallback, updates;
      model = options.model || {};
      updates = options.updates || [];
      updateCallback = options.updateCallback || noop;
      wrapWithMeta(model);
      for (name in updates) {
        prop = updates[name];
        model[name] = prop;
      }
      return updateCallback(model);
    };
    restore = function(options) {};
    update = function(options) {
      updateLocal(options);
      return save(options);
    };
    save = function(options) {
      var apiCall, clearErrorsOnSuccess, handleResponse, meta, model, name, prop, request, rollbackOnFailure, updateCallback, updates;
      model = options.model || {};
      updates = options.updates;
      apiCall = options.apiCall || noop;
      updateCallback = options.updateCallback || noop;
      handleResponse = options.handleResponse !== false;
      clearErrorsOnSuccess = options.clearErrorsOnSuccess !== false;
      rollbackOnFailure = options.rollbackOnFailure || false;
      meta = stripMeta(model);
      request = apiCall(angular.copy(model));
      wrapWithMeta(model, meta);
      for (name in updates) {
        prop = updates[name];
        model.o.propsPending[name] = true;
      }
      updateCallback(model);
      request.then(function(response) {
        var now, results;
        now = new Date();
        model.o.lastUpdated = now.toISOString();
        if (clearErrorsOnSuccess) {
          model.o.propsErrored = {};
        }
        if (handleResponse) {
          results = [];
          for (name in updates) {
            prop = updates[name];
            results.push(model[name] = response[name]);
          }
          return results;
        }
      });
      request["catch"](function(err) {
        var results;
        if (rollbackOnFailure) {
          restore(options);
        }
        results = [];
        for (name in updates) {
          prop = updates[name];
          model[name] = prop;
          results.push(model.o.errors[name] = err);
        }
        return results;
      });
      return request["finally"](function() {
        for (name in updates) {
          prop = updates[name];
          delete model.o.pending[name];
        }
        return updateCallback(model);
      });
    };
    return {
      wrapWithMeta: wrapWithMeta,
      stripMeta: stripMeta,
      fetchOne: fetchOne,
      updateLocal: updateLocal,
      restore: restore,
      update: update,
      save: save
    };
  };

  Optimist.$inject = ['$rootScope'];

  angular.module('appirio-tech-ng-submit-work').factory('Optimist', Optimist);

}).call(this);

(function() {
  'use strict';
  var dependencies;

  dependencies = [];

  angular.module('appirio-tech-ng-optimist', dependencies);

}).call(this);

(function() {
  'use strict';
  var dependencies;

  dependencies = [];

  angular.module('appirio-tech-ng-optimist', dependencies);

}).call(this);

(function() {
  'use strict';
  var OptimistHelpers,
    hasProp = {}.hasOwnProperty;

  OptimistHelpers = function(options) {
    var filter, isObject, mask, timestamp, walk;
    if (options == null) {
      options = {};
    }
    timestamp = function() {
      var now;
      now = new Date();
      return now.toISOString();
    };
    isObject = function(item) {
      return item !== null && typeof item === 'object' && Array.isArray(item) === false;
    };
    mask = function(source, maskObj) {
      var masked, name, value;
      masked = {};
      for (name in source) {
        if (!hasProp.call(source, name)) continue;
        value = source[name];
        if (maskObj.hasOwnProperty(name)) {
          if (isObject(value)) {
            masked[name] = mask(value, maskObj[name]);
          } else {
            masked[name] = value;
          }
        }
      }
      return masked;
    };
    filter = function(source, filterObj) {
      var filtered, name, value;
      filtered = {};
      for (name in source) {
        if (!hasProp.call(source, name)) continue;
        value = source[name];
        if (filterObj.hasOwnProperty(name)) {
          if (isObject(value) && isObject(filterObj[name])) {
            filtered[name] = filter(value, filterObj[name]);
          }
        } else {
          filtered[name] = angular.copy(value);
        }
      }
      return filtered;
    };
    walk = function(collection, action) {
      var name, results, value;
      results = [];
      for (name in collection) {
        if (!hasProp.call(collection, name)) continue;
        value = collection[name];
        if (isObject(value)) {
          results.push(walk(value, action));
        } else {
          results.push(action(value, name, collection));
        }
      }
      return results;
    };
    return {
      timestamp: timestamp,
      isObject: isObject,
      mask: mask,
      filter: filter,
      walk: walk
    };
  };

  OptimistHelpers.$inject = ['$rootScope'];

  angular.module('appirio-tech-ng-optimist').factory('OptimistHelpers', OptimistHelpers);

}).call(this);

(function() {
  'use strict';
  var OptimistCollection;

  OptimistCollection = function(OptimistHelpers, OptimistModel) {
    var Collection;
    Collection = function(options) {
      if (options == null) {
        options = {};
      }
      this.configure(options);
      return this;
    };
    Collection.prototype.configure = function(options) {
      this._collection = [];
      this._meta = {};
      return this._defaults = {
        updateCallback: options.updateCallback || angular.noop,
        matchByProp: options.matchByProp || 'id',
        propsToIgnore: options.propsToIgnore || []
      };
    };
    Collection.prototype.get = function() {
      var collection;
      collection = this._collection.map(function(item) {
        return item.get();
      });
      return angular.merge(collection, this._meta);
    };
    Collection.prototype.getShallow = function() {
      var collection;
      collection = angular.copy(this._collection);
      return angular.merge(collection, this._meta);
    };
    Collection.prototype.clearError = function() {
      if (this._meta._error) {
        return delete this._meta._error;
      }
    };
    Collection.prototype.fetch = function(options) {
      var apiCall, clearErrorsOnSuccess, propsToIgnore, request, updateCallback;
      if (options == null) {
        options = {};
      }
      apiCall = options.apiCall;
      updateCallback = options.updateCallback || this._defaults.updateCallback;
      clearErrorsOnSuccess = options.clearErrorsOnSuccess !== false;
      propsToIgnore = options.propsToIgnore || this._defaults.propsToIgnore;
      this._meta._pending = true;
      updateCallback(this._collection);
      request = apiCall();
      request.then((function(_this) {
        return function(response) {
          _this._meta._lastUpdated = OptimistHelpers.timestamp();
          if (clearErrorsOnSuccess) {
            _this.clearError();
          }
          _this._collection = response.map(function(item) {
            return new OptimistModel({
              data: item,
              updateCallback: updateCallback,
              propsToIgnore: propsToIgnore
            });
          });
          return response;
        };
      })(this));
      request["catch"]((function(_this) {
        return function(err) {
          return _this._meta._error = err;
        };
      })(this));
      return request["finally"]((function(_this) {
        return function() {
          _this._meta._pending = false;
          return updateCallback(_this._collection);
        };
      })(this));
    };
    Collection.prototype.findWhere = function(filters) {
      return this._collection.filter(function(ref) {
        var item, name, value;
        item = ref.get();
        for (name in filters) {
          value = filters[name];
          if (item[name] !== value) {
            return false;
          }
        }
        return true;
      });
    };
    Collection.prototype.findOneWhere = function(filters) {
      return this.findWhere(filters)[0];
    };
    return Collection;
  };

  OptimistCollection.$inject = ['OptimistHelpers', 'OptimistModel'];

  angular.module('appirio-tech-ng-optimist').factory('OptimistCollection', OptimistCollection);

}).call(this);

(function() {
  'use strict';
  var OptimistModel;

  OptimistModel = function(OptimistHelpers) {
    var Model, isMeta;
    Model = function(options) {
      if (options == null) {
        options = {};
      }
      this.configure(options);
      return this;
    };
    Model.prototype.configure = function(options) {
      this._data = angular.copy(options.data || {});
      return this._defaults = {
        updateCallback: options.updateCallback || angular.noop,
        propsToIgnore: options.propsToIgnore || []
      };
    };
    Model.prototype.get = function() {
      return angular.copy(this._data);
    };
    isMeta = function(name) {
      var backup, error, lastUpdated, pending;
      pending = name.indexOf('_pending') >= 0;
      error = name.indexOf('_error') >= 0;
      backup = name.indexOf('_backup') >= 0;
      lastUpdated = name.indexOf('_lastUpdated') >= 0;
      return pending || error || backup || lastUpdated;
    };
    Model.prototype.getClean = function() {
      var data;
      data = angular.copy(this._data);
      OptimistHelpers.walk(data, function(value, name, collection) {
        if (isMeta(name)) {
          return delete collection[name];
        }
      });
      return data;
    };
    Model.prototype.set = function(options) {
      var clearError, clearPending, error, propsToIgnore, restoreBackup, setBackup, setError, setPending, updateCallback, updateValues, updates;
      if (options == null) {
        options = {};
      }
      updates = angular.copy(options.updates || this._data);
      updateCallback = options.updateCallback || this._defaults.updateCallback;
      updateValues = options.updateValues || false;
      setPending = options.setPending || false;
      clearPending = options.clearPending || false;
      setBackup = options.setBackup || false;
      restoreBackup = options.restoreBackup || false;
      setError = options.setError || false;
      error = options.error || '';
      clearError = options.clearError || false;
      propsToIgnore = options.propsToIgnore || this._defaults.propsToIgnore;
      if (propsToIgnore) {
        updates = OptimistHelpers.filter(updates, propsToIgnore);
      }
      if (setBackup) {
        OptimistHelpers.walk(this._data, function(value, name, collection) {
          if (!isMeta(name)) {
            return collection[name + "_backup"] = collection[name];
          }
        });
      }
      OptimistHelpers.walk(updates, function(value, name, collection) {
        if (!isMeta(name)) {
          if (setPending) {
            collection[name + "_pending"] = true;
          }
          if (clearPending) {
            collection[name + "_pending"] = false;
          }
          if (restoreBackup) {
            collection[name] = collection[name + "_backup"];
          }
          if (setError) {
            collection[name + "_error"] = error;
          }
          if (clearError) {
            collection[name + "_error"] = false;
          }
          if (!(updateValues || restoreBackup)) {
            return delete collection[name];
          }
        }
      });
      angular.merge(this._data, updates);
      return updateCallback(this._data);
    };
    Model.prototype.fetch = function(options) {
      var apiCall, clearErrorsOnSuccess, handleResponse, propsToIgnore, request, updateCallback;
      if (options == null) {
        options = {};
      }
      apiCall = options.apiCall || angular.noop;
      updateCallback = options.updateCallback || this._defaults.updateCallback;
      handleResponse = options.handleResponse !== false;
      clearErrorsOnSuccess = options.clearErrorsOnSuccess !== false;
      propsToIgnore = options.propsToIgnore || this._defaults.propsToIgnore;
      this._data._pending = true;
      updateCallback(this._data);
      request = apiCall();
      request.then((function(_this) {
        return function(response) {
          _this._data._lastUpdated = OptimistHelpers.timestamp();
          if (clearErrorsOnSuccess) {
            if (_this._data._error) {
              delete _this._data._error;
            }
          }
          if (handleResponse) {
            _this.set({
              updates: response,
              updateValues: true,
              propsToIgnore: propsToIgnore
            });
          }
          return response;
        };
      })(this));
      request["catch"]((function(_this) {
        return function(err) {
          return _this._data._error = err;
        };
      })(this));
      return request["finally"]((function(_this) {
        return function() {
          delete _this._data._pending;
          return updateCallback(_this._data);
        };
      })(this));
    };
    Model.prototype.restore = function(updates) {
      var restoreBackup;
      return this.set({
        updates: updates
      }, restoreBackup = true);
    };
    Model.prototype.save = function(options) {
      var apiCall, clean, clearErrorsOnSuccess, handleResponse, propsToIgnore, request, rollbackOnFailure, updateCallback, updates;
      if (options == null) {
        options = {};
      }
      updates = options.updates;
      apiCall = options.apiCall || angular.noop;
      updateCallback = options.updateCallback || this._defaults.updateCallback;
      handleResponse = options.handleResponse !== false;
      clearErrorsOnSuccess = options.clearErrorsOnSuccess !== false;
      rollbackOnFailure = options.rollbackOnFailure || false;
      propsToIgnore = options.propsToIgnore || this._defaults.propsToIgnore;
      this.set({
        updates: updates,
        setPending: true,
        updateCallback: updateCallback
      });
      clean = this.getClean();
      request = apiCall(clean);
      request.then((function(_this) {
        return function(response) {
          _this._data._lastUpdated = OptimistHelpers.timestamp();
          if (handleResponse) {
            if (updates) {
              response = OptimistHelpers.mask(response, updates);
            }
            _this.set({
              updates: response,
              updateValues: true,
              clearPending: true,
              clearError: clearErrorsOnSuccess,
              updateCallback: updateCallback,
              propsToIgnore: propsToIgnore
            });
          }
          return response;
        };
      })(this));
      return request["catch"]((function(_this) {
        return function(err) {
          return _this.set({
            updates: updates,
            setError: true,
            error: err,
            restoreBackup: rollbackOnFailure
          });
        };
      })(this));
    };
    Model.prototype.update = function(options) {
      if (options == null) {
        options = {};
      }
      this.set({
        updates: options.updates || [],
        updateCallback: options.updateCallback || this._defaults.updateCallback,
        updateValues: true,
        setPending: true
      });
      return this.save(options);
    };
    return Model;
  };

  OptimistModel.$inject = ['OptimistHelpers'];

  angular.module('appirio-tech-ng-optimist').factory('OptimistModel', OptimistModel);

}).call(this);

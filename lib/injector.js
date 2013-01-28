var Module = require('./module');
var autoAnnotate = require('./annotation').parse;

var Injector = function(modules) {
  var currentlyResolving = [];
  var providers = {};
  var instances = {
    injector: this
  };

  var error = function(msg) {
    var stack = currentlyResolving.join(' -> ');
    currentlyResolving.length = 0;
    return new Error(stack ? msg + ' (Resolving: ' + stack + ')' : msg);
  };

  var get = function(name) {
    if (name.indexOf('.') !== -1) {
      var parts = name.split('.');
      var pivot = get(parts.shift());

      while(parts.length) {
        pivot = pivot[parts.shift()];
      }

      return pivot;
    }

    if (!instances.hasOwnProperty(name)) {
      if (currentlyResolving.indexOf(name) !== -1) {
        currentlyResolving.push(name);
        throw error('Can not resolve circular dependency!');
      }

      currentlyResolving.push(name);

      if (!providers.hasOwnProperty(name)) {
        throw error('No provider for "' + name + '"!');
      }

      instances[name] = providers[name][0](providers[name][1]);
      currentlyResolving.pop();
    }

    return instances[name];
  };

  var instantiate = function(Type) {
    var instance = Object.create(Type.prototype);
    var returned = invoke(Type, instance);

    return typeof returned === 'object' ? returned : instance;
  };

  var invoke = function(fn, context) {
    if (typeof fn !== 'function') {
      throw error('Can not invoke "' + fn + '". Expected a function!');
    }

    var inject = fn.$inject && fn.$inject || autoAnnotate(fn);
    var dependencies = inject.map(function(dep) {
      return get(dep);
    });

    // TODO(vojta): optimize without apply
    return fn.apply(context, dependencies);
  };

  var factoryMap = {
    factory: invoke,
    type: instantiate,
    value: function(value) {
      return value;
    },
    // TODO(vojta): figure out context of require (main module ? configurable ?)
    require: require
  };

  modules.forEach(function(module) {
    // TODO(vojta): handle wrong inputs (modules)
    if (module instanceof Module) {
      module.forEach(function(provider) {
        var name = provider[0];
        var type = provider[1];
        var value = provider[2];

        providers[name] = [factoryMap[type], value];
      });
    } else if (typeof module === 'object') {
      Object.keys(module).forEach(function(name) {
        var type = module[name][0];
        var value = module[name][1];

        providers[name] = [factoryMap[type], value];
      });
    }
  });

  // public API
  this.get = get;
  this.invoke = invoke;
  this.instantiate = instantiate;
};

module.exports = Injector;

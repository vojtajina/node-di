var Injector = function(module) {
  var providers = {};
  var instances = {
    $injector: this
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
      instances[name] = providers[name][0](providers[name][1]);
    }

    return instances[name];
  };

  var instantiate = function(Type) {
    var instance = Object.create(Type.prototype);
    var returned = invoke(Type, instance);

    return typeof returned === 'object' ? returned : instance;
  };

  var invoke = function(fn, context) {
    var dependencies = fn.$inject && fn.$inject.map(function(dep) {
      return get(dep);
    }) || [];

    // TODO(vojta): optimize without apply
    return fn.apply(context, dependencies);
  };

  var factoryMap = {
    factory: invoke,
    type: instantiate,
    value: function(value) {
      return value;
    },
    require: require
  };

  module.forEach(function(provider) {
    var name = provider[0];
    var type = provider[1];
    var value = provider[2];

    providers[name] = [factoryMap[type], value];
  });

  // public API
  this.get = get;
  this.invoke = invoke;
  this.instantiate = instantiate;
};

module.exports = Injector;

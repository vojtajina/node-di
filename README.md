## Dependency Injection framework for Node.js

### Example

```js
var Car = function(engine) {
  this.start = function() {
    engine.start();
  };
};

var createPetrolEngine = function(power) {
  return {
    start: function() {
      console.log('Starting engine with ' + power + 'hp');
    }
  };
};


// a module is just a plain JavaScript object
// it is a recipe for the injector, how to instantiate stuff
var module = {
  // if an object asks for 'car', the injector will call new Car(...) to produce it
  'car': ['type', Car],
  // if an object asks for 'engine', the injector will call createPetrolEngine(...) to produce it
  'engine': ['factory', createPetrolEngine],
  // if an object asks for 'power', the injector will give it number 1184
  'power': ['value', 1184] // probably Bugatti Veyron
};


var di = require('di');
var injector = new di.Injector([module]);

injector.invoke(function(car) {
  car.start();
});
```
For more examples, check out [the tests](/vojtajina/node-di/blob/master/test/injector.spec.coffee). You can also check out [Karma](https://github.com/karma-runner/karma) and its plugins for more complex examples.


### Registering stuff

#### type(token, Constructor)
To produce the instance, `Constructor` will be called with `new` operator.
```js
var module = {
  'engine': ['type', DieselEngine]
};
```

#### factory(token, factoryFn)
To produce the instance, `factoryFn` will be called (without any context) and its result will be used.
```js
var module = {
  'engine': ['factory', createDieselEngine]
};
```

#### value(token, value)
Register the final value.
```js
var module = {
  'power': ['value', 1184]
};
```


### Annotation
The injector looks up tokens based on argument names:
```js
var Car = function(engine, license) {
  // will inject objects bound to 'engine' and 'license' tokens
};
```

You can also use comments:
```js
var Car = function(/* engine */ e, /* x._weird */ x) {
  // will inject objects bound to 'engine' and 'x._weird' tokens
};
```

Sometimes it is helpful to inject only a specific property of some object:
```js
var Engine = function(/* config.engine.power */ power) {
  // will inject 1184 (config.engine.power),
  // assuming there is no direct binding for 'config.engine.power' token
};

var module = {
  'config': ['value', {engine: {power: 1184}, other : {}}]
};
```

### Differences to Angular's DI

- no config/runtime phases (configuration happens by injecting a config object)
- no global module register
- no array annotations (comments annotations instead)
- comment annotation
- no decorators (maybe not yet?)
- service -> type
- child injectors


---------
Made for [Karma]. Heavily influenced by [AngularJS]. Also inspired by [Guice] and [Pico Container].

[AngularJS]: http://angularjs.org/
[Pico Container]: http://picocontainer.codehaus.org/
[Guice]: http://code.google.com/p/google-guice/
[Karma]: http://karma-runner.github.io/


<!--
Object - a member of object graph in an application that can have dependencies on instances of other types (i.e. other Objects).
Token - each Object dependency (not an Object itself) is identified via a Token. Token is typically an annotation, string constant or a class/type
Injector - a container or context, capable of resolving Object dependencies and caching references to Objects constructed during the dependency resolution process.
Provider - a recipe for constructing Objects, typically a constructor or factory function
Binding - a mapping between a Token and a Provider
Module - a set of bindings. A Module is used to configure an Injector and defines which Objects can be resolved via an Injector. Module can also be used to override Object definitions (for reconfiguration or mocking purposes). 
-->

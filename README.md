## Dependency Injection framework for Node.js

### Why Dependency Injection ?
There are two things - **Dependency Injection pattern** (aka Inversion of Control) and **Dependency Injection framework**.

The Dependency Injection pattern is about separating the instantiation of objects from the actual logic and behavior that they encapsulate. This pattern has many benefits such as:

- **explicit dependencies** - all dependencies are passed in as constructor arguments, which makes it easy to understand how particular object depends on the rest of the environment,
- **code reuse** - such an object is much easier to reuse in other environments, because it is not coupled to a specific implementation of its dependencies,
- and **much easier to test**, because testing is essentially about instantiating a single object without the rest of the environment.

Following this pattern is, of course, possible without any framework.

However, if you do follow the Dependency Injection pattern, you typically end up with some kind of nasty `main()` method, where you instantiate all the objects and wire them together. The Dependency Injection framework saves you from this boilerplate. **It makes wiring the application declarative rather than imperative.** Each component declares its dependencies and the framework does transitively resolve these dependencies...


### Example

```js
var Car = function(engine) {
  this.engine = engine;
};
Car.prototype.start = function() {
  this.engine.start();
};
Car.prototype.info = function() {
  console.log('Car ' + (this.engine.running ? 'running' : 'stopped') + ' with ' + this.engine.power + 'hp');
};

var createPetrolEngine = function(power) {
  return {
    power : power,
    nitro : function () {
      this.power *= 1.5;
    },
    start: function() {
      this.running = true;
      console.log('Starting engine with ' + this.power + 'hp');
    }
  };
};


var di = require('di');

// a module is just a plain JavaScript object
// it is a recipe for the injector, how to instantiate stuff
var module = {
  // if an object asks for 'car', the injector will call new Car(...) to produce it
  car: di.type(Car),
  // if an object asks for 'engine', the injector will call createPetrolEngine(...) to produce it
  engine: di.factory(createPetrolEngine),
  // if an object asks for 'power', the injector will give it number 1184
  power: 1184 // probably Bugatti Veyron
};


var injector = new di.Injector([module]);

injector.invoke(function(car) {
  car.info();
  car.start();
  car.info();
  // power boost
  car.engine.nitro();
  // engine with moar power
  car.info();
});

injector.invoke(function(car) {
  // same car
  car.info();
});
```
For more examples, check out [the tests](/vojtajina/node-di/blob/master/test/injector.spec.coffee). You can also check out [Karma](https://github.com/karma-runner/karma) and its plugins for more complex examples.


### Registering stuff

#### type(token, Constructor)
To produce the instance, `Constructor` will be called with `new` operator.
```js
var module = {
  engine: di.type(DieselEngine)
};
```

#### factory(token, factoryFn)
To produce the instance, `factoryFn` will be called (without any context) and its result will be used.
```js
var module = {
  engine: di.factory(createDieselEngine)
};
```

#### value(token, value)
Register the final value.
```js
var module = {
  power: 1184
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
  config: {engine: {power: 1184}, other : {}}
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
- private modules


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

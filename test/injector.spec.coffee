expect = require('chai').expect


describe 'injector', ->

  Module = require '../lib/module'
  Injector = require '../lib/injector'

  it 'should consume an object as a module', ->
    class BazType
      constructor: -> @name = 'baz'

    module =
      foo: ['factory', -> 'foo-value']
      bar: ['value', 'bar-value']
      baz: ['type', BazType]

    injector = new Injector [module]
    expect(injector.get 'foo').to.equal 'foo-value'
    expect(injector.get 'bar').to.equal 'bar-value'
    expect(injector.get 'baz').to.be.an.instanceof BazType


  describe 'get', ->

    it 'should return an instance', ->
      class BazType
        constructor: -> @name = 'baz'

      module = new Module
      module.factory 'foo', -> {name: 'foo'}
      module.value 'bar', 'bar value'
      module.type 'baz', BazType

      injector = new Injector [module]

      expect(injector.get 'foo').to.deep.equal {name: 'foo'}
      expect(injector.get 'bar').to.equal 'bar value'
      expect(injector.get 'baz').to.deep.equal {name: 'baz'}
      expect(injector.get 'baz').to.be.an.instanceof BazType


    it 'should always return the same instance', ->
      class BazType
        constructor: -> @name = 'baz'

      module = new Module
      module.factory 'foo', -> {name: 'foo'}
      module.value 'bar', 'bar value'
      module.type 'baz', BazType

      injector = new Injector [module]

      expect(injector.get 'foo').to.equal(injector.get 'foo')
      expect(injector.get 'bar').to.equal(injector.get 'bar')
      expect(injector.get 'baz').to.equal(injector.get 'baz')


    it 'should resolve dependencies', ->
      class Foo
        constructor: (@bar, @baz) ->
      Foo.$inject = ['bar', 'baz']

      bar = (baz, abc) ->
        baz: baz
        abc: abc
      bar.$inject = ['baz', 'abc']

      module = new Module
      module.type 'foo', Foo
      module.factory 'bar', bar
      module.value 'baz', 'baz-value'
      module.value 'abc', 'abc-value'

      injector = new Injector [module]
      fooInstance = injector.get 'foo'
      expect(fooInstance.bar).to.deep.equal {baz: 'baz-value', abc: 'abc-value'}
      expect(fooInstance.baz).to.equal 'baz-value'


    it 'should inject properties', ->
      module = new Module
      module.value 'config', {a: 1, b: {c: 2}}

      injector = new Injector [module]
      expect(injector.get 'config.a').to.equal 1
      expect(injector.get 'config.b.c').to.equal 2


    it 'should inject dotted service if present', ->
      module = new Module
      module.value 'a.b', 'a.b value'

      injector = new Injector [module]
      expect(injector.get 'a.b').to.equal 'a.b value'


    it 'should provide "injector"', ->
      module = new Module
      injector = new Injector [module]

      expect(injector.get 'injector').to.equal injector


    it 'should throw error with full path if no provider', ->
      # a requires b requires c (not provided)
      aFn = (b) -> 'a-value'
      aFn.$inject = ['b']
      bFn = (c) -> 'b-value'
      bFn.$inject = ['c']

      module = new Module
      module.factory 'a', aFn
      module.factory 'b', bFn

      injector = new Injector [module]
      expect(-> injector.get 'a').to.throw 'No provider for "c"! (Resolving: a -> b -> c)'


    it 'should throw error if circular dependency', ->
      module = new Module
      aFn = (b) -> 'a-value'
      aFn.$inject = ['b']
      bFn = (a) -> 'b-value'
      bFn.$inject = ['a']

      module = new Module
      module.factory 'a', aFn
      module.factory 'b', bFn

      injector = new Injector [module]
      expect(-> injector.get 'a').to.throw 'Can not resolve circular dependency! ' +
                                           '(Resolving: a -> b -> a)'


  describe 'invoke', ->

    it 'should resolve dependencies', ->
      bar = (baz, abc) ->
        baz: baz
        abc: abc
      bar.$inject = ['baz', 'abc']

      module = new Module
      module.value 'baz', 'baz-value'
      module.value 'abc', 'abc-value'

      injector = new Injector [module]

      expect(injector.invoke bar).to.deep.equal {baz: 'baz-value', abc: 'abc-value'}


    it 'should invoke function on given context', ->
      context = {}
      module = new Module
      injector = new Injector [module]

      injector.invoke (-> expect(@).to.equal context), context


    it 'should throw error if a non function given', ->
      injector = new Injector []

      expect(-> injector.invoke 123).to.throw 'Can not invoke "123". Expected a function!'
      expect(-> injector.invoke 'abc').to.throw 'Can not invoke "abc". Expected a function!'
      expect(-> injector.invoke null).to.throw 'Can not invoke "null". Expected a function!'
      expect(-> injector.invoke undefined).to.throw 'Can not invoke "undefined". ' +
                                                    'Expected a function!'
      expect(-> injector.invoke {}).to.throw 'Can not invoke "[object Object]". ' +
                                             'Expected a function!'


    it 'should auto parse arguments/comments if no $inject defined', ->
      bar = `function(/* baz */ a, abc) {
        return {baz: a, abc: abc};
      }`

      module = new Module
      module.value 'baz', 'baz-value'
      module.value 'abc', 'abc-value'

      injector = new Injector [module]
      expect(injector.invoke bar).to.deep.equal {baz: 'baz-value', abc: 'abc-value'}


    it 'should support invokation of asynchronous modules', (finished) ->
      @timeout 500

      bar = `function(baz, abc) {
        var done = this.async();
        done({baz: baz, abc: abc});
      }`

      module = new Module
      module.value 'baz', 'baz-value'
      module.value 'abc', 'abc-value'

      injector = new Injector [module]

      done = (result) ->
        expect(result).to.deep.equal {baz: 'baz-value', abc: 'abc-value'}
        do finished

      injector.invoke bar, null, done

  describe 'instantiate', ->

    it 'should resolve dependencies', ->
      class Foo
        constructor: (@abc, @baz) ->
      Foo.$inject = ['abc', 'baz']

      module = new Module
      module.value 'baz', 'baz-value'
      module.value 'abc', 'abc-value'

      injector = new Injector [module]
      expect(injector.instantiate Foo).to.deep.equal {abc: 'abc-value', baz: 'baz-value'}


    it 'should return returned value from constructor if an object returned', ->
      module = new Module
      injector = new Injector [module]
      returnedObj = {}

      ObjCls = -> returnedObj
      StringCls = -> 'some string'
      NumberCls = -> 123

      expect(injector.instantiate ObjCls).to.equal returnedObj
      expect(injector.instantiate StringCls).to.be.an.instanceof StringCls
      expect(injector.instantiate NumberCls).to.be.an.instanceof NumberCls


  describe 'child', ->

    it 'should inject from child', ->
      moduleParent = new Module
      moduleParent.value 'a', 'a-parent'

      moduleChild = new Module
      moduleChild.value 'a', 'a-child'
      moduleChild.value 'd', 'd-child'

      injector = new Injector [moduleParent]
      child = injector.createChild [moduleChild]

      expect(child.get 'd').to.equal 'd-child'
      expect(child.get 'a').to.equal 'a-child'


    it 'should provide the child injector as "injector"', ->
      injector = new Injector []
      childInjector = injector.createChild []

      expect(childInjector.get 'injector').to.equal childInjector


    it 'should inject from parent if not provided in child', ->
      moduleParent = new Module
      moduleParent.value 'a', 'a-parent'

      moduleChild = new Module
      moduleChild.factory 'b', (a) -> {a: a}

      injector = new Injector [moduleParent]
      child = injector.createChild [moduleChild]

      expect(child.get 'b').to.deep.equal {a: 'a-parent'}


    it 'should inject from parent but never use dependency from child', ->
      moduleParent = new Module
      moduleParent.factory 'b', (c) -> 'b-parent'

      moduleChild = new Module
      moduleChild.value 'c', 'c-child'

      injector = new Injector [moduleParent]
      child = injector.createChild [moduleChild]

      expect(-> child.get 'b').to.throw 'No provider for "c"! (Resolving: b -> c)'


    it 'should force new instance in child', ->
      moduleParent = new Module
      moduleParent.factory 'b', (c) -> {c: c}
      moduleParent.value 'c', 'c-parent'
      injector = new Injector [moduleParent]

      expect(injector.get 'b').to.deep.equal {c: 'c-parent'}

      moduleChild = new Module
      moduleChild.value 'c', 'c-child'

      child = injector.createChild [moduleChild], ['b']

      expect(child.get 'b').to.deep.equal {c: 'c-child'}


    it 'should force new instance using provider from grand parent', ->
      # regression
      moduleGrandParent = new Module
      moduleGrandParent.value 'x', 'x-grand-parent'

      injector = new Injector [moduleGrandParent]
      grandChildInjector = injector.createChild([]).createChild([], ['x'])


    it 'should throw error if forced provider does not exist', ->
      moduleParent = new Module
      injector = new Injector [moduleParent]
      moduleChild = new Module

      expect(-> injector.createChild [], ['b']).to.throw 'No provider for "b". Can not use ' +
                                                         'provider from the parent!'


  describe 'private modules', ->

    it 'should only expose public bindings', ->
      mA =
        __exports__: ['publicFoo'],
        'publicFoo': ['factory', (privateBar) -> {dependency: privateBar}]
        'privateBar': ['value', 'private-value']

      mB =
        'bar': ['factory', (privateBar) -> null]
        'baz': ['factory', (publicFoo) -> {dependency: publicFoo}]

      injector = new Injector [mA, mB]
      publicFoo = injector.get 'publicFoo'
      expect(publicFoo).to.be.defined
      expect(publicFoo.dependency).to.equal 'private-value'
      expect(-> injector.get 'privateBar').to.throw 'No provider for "privateBar"! (Resolving: privateBar)'
      expect(-> injector.get 'bar').to.throw 'No provider for "privateBar"! (Resolving: bar -> privateBar)'
      expect(injector.get('baz').dependency).to.equal publicFoo


    it 'should allow name collisions in private bindings', ->
      mA =
        __exports__: ['foo']
        'foo': ['factory', (conflict) -> conflict]
        'conflict': ['value', 'private-from-a']

      mB =
        __exports__: ['bar']
        'bar': ['factory', (conflict) -> conflict]
        'conflict': ['value', 'private-from-b']

      injector = new Injector [mA, mB]
      expect(injector.get 'foo').to.equal 'private-from-a'
      expect(injector.get 'bar').to.equal 'private-from-b'


    it 'should allow forcing new instance', ->
      module =
        __exports__: ['foo']
        'foo': ['factory', (bar) -> {bar: bar}]
        'bar': ['value', 'private-bar']

      injector = new Injector [module]
      firstChild = injector.createChild [], ['foo']
      secondChild = injector.createChild [], ['foo']
      fooFromFirstChild = firstChild.get 'foo'
      fooFromSecondChild = secondChild.get 'foo'

      expect(fooFromFirstChild).not.to.equal fooFromSecondChild
      expect(fooFromFirstChild.bar).to.equal fooFromSecondChild.bar


    it 'should load additional __modules__', ->
      mB =
        'bar': ['value', 'bar-from-other-module']

      mA =
        __exports__: ['foo']
        __modules__: [mB]
        'foo': ['factory', (bar) -> {bar: bar}]

      injector = new Injector [mA]
      foo = injector.get 'foo'

      expect(foo).to.be.defined
      expect(foo.bar).to.equal 'bar-from-other-module'


    it 'should only create one private child injector', ->
      m =
        __exports__: ['foo', 'bar']
        'foo': ['factory', (bar) -> {bar: bar}]
        'bar': ['factory', (internal) -> {internal: internal}]
        'internal': ['factory', -> {}]

      injector = new Injector [m]
      foo = injector.get 'foo'
      bar = injector.get 'bar'

      childInjector = injector.createChild [], ['foo', 'bar']
      fooFromChild = childInjector.get 'foo'
      barFromChild = childInjector.get 'bar'

      expect(fooFromChild).to.not.equal foo
      expect(barFromChild).to.not.equal bar
      expect(fooFromChild.bar).to.equal barFromChild


  describe 'scopes', ->
    it 'should force new instances per scope', ->
      Foo = ->
      Foo.$scope = ['request']

      createBar = -> {}
      createBar.$scope = ['session']

      m =
        'foo': ['type', Foo]
        'bar': ['factory', createBar]

      injector = new Injector [m]
      foo = injector.get 'foo'
      bar = injector.get 'bar'

      sessionInjector = injector.createChild [], ['session']
      expect(sessionInjector.get 'foo').to.equal foo
      expect(sessionInjector.get 'bar').to.not.equal bar

      requestInjector = injector.createChild [], ['request']
      expect(requestInjector.get 'foo').to.not.equal foo
      expect(requestInjector.get 'bar').to.equal bar

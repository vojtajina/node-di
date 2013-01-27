expect = require('chai').expect

a = require '../lib/annotation'


describe 'annotation', ->

  describe 'annotate', ->
    annotate = a.annotate

    it 'should set $inject property on the last argument', ->
      fn = (a, b) -> null
      annotate 'aa', 'bb', fn
      expect(fn.$inject).to.deep.equal ['aa', 'bb']


    it 'should return the function', ->
      fn = (a, b) -> null
      expect(annotate 'aa', 'bb', fn).to.equal fn


  describe 'parse', ->
    parse = a.parse

    it 'should parse argument names without comments', ->
      fn = `function(one, two) {}`
      expect(parse fn).to.deep.equal ['one', 'two']


    it 'should parse comment annotation', ->
      fn = `function(/* one */ a, /*two*/ b,/*   three*/c) {}`
      expect(parse fn).to.deep.equal ['one', 'two', 'three']


    it 'should parse mixed comments with argument names', ->
      fn = `function(/* one */ a, b,/*   three*/c) {}`
      expect(parse fn).to.deep.equal ['one', 'b', 'three']

    it 'should parse empty arguments', ->
      fn = `function(){}`
      expect(parse fn).to.deep.equal []


    it 'should throw error if a non function given', ->
      expect(-> parse 123).to.throw 'Can not annotate "123". Expected a function!'
      expect(-> parse 'abc').to.throw 'Can not annotate "abc". Expected a function!'
      expect(-> parse null).to.throw 'Can not annotate "null". Expected a function!'
      expect(-> parse undefined).to.throw 'Can not annotate "undefined". Expected a function!'
      expect(-> parse {}).to.throw 'Can not annotate "[object Object]". Expected a function!'

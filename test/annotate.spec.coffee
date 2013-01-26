expect = require('chai').expect

annotate = require '../lib/annotate'


describe 'annotate', ->

  it 'should set $inject property on the last argument', ->
    fn = (a, b) -> null
    annotate 'aa', 'bb', fn
    expect(fn.$inject).to.deep.equal ['aa', 'bb']


  it 'should return the function', ->
    fn = (a, b) -> null
    expect(annotate 'aa', 'bb', fn).to.equal fn

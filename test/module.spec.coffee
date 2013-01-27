expect = require('chai').expect


describe 'module', ->

  Module = require '../lib/module'

  it 'should return self to enable chaining', ->
    module = new Module

    module.value('a', 'a-value')
          .factory('b', -> 'b-value')
          .type('c', ->)
          .require('d', 'fs')
          .value('e', 'e-value')


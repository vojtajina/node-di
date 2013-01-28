module.exports = (grunt) ->

  grunt.initConfig
    pkgFile: 'package.json'

    files:
      source: ['lib/*.js']

    test:
      unit: 'simplemocha:unit'

    simplemocha:
      options:
        ui: 'bdd'
        reporter: 'dot'
      unit:
        src: [
          'test/*.coffee'
        ]

    # JSHint options
    # http://www.jshint.com/options/
    jshint:
      source:
        files:
          src: '<%= files.source %>'
        options:
          strict: false

      options:
        quotmark: 'single'
        camelcase: true
        strict: true
        trailing: true
        curly: true
        eqeqeq: true
        immed: true
        latedef: true
        newcap: true
        noarg: true
        sub: true
        undef: true
        boss: true
        node: true
        es5: true
        globals: {}

  # grunt.loadTasks 'tasks'
  grunt.loadNpmTasks 'grunt-simple-mocha'
  grunt.loadNpmTasks 'grunt-contrib-jshint'

  grunt.registerTask 'default', ['jshint', 'test']
  grunt.registerTask 'test', ['simplemocha']

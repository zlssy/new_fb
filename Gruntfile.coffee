ALL_TASKS = ['jst:all', 'coffee:all', 'concat:all', 'stylus:all', 'copy', 'clean:compiled']

# formbuilder.js must be compiled in this order:
# 1. rivets-config
# 2. main
# 3. fields js
# 4. fields templates

module.exports = (grunt) ->

  path = require('path')
  exec = require('child_process').exec

  grunt.loadNpmTasks('grunt-contrib-coffee')
  grunt.loadNpmTasks('grunt-contrib-concat')
  grunt.loadNpmTasks('grunt-contrib-cssmin')
  grunt.loadNpmTasks('grunt-contrib-jst')
  grunt.loadNpmTasks('grunt-contrib-stylus')
  grunt.loadNpmTasks('grunt-contrib-uglify')
  grunt.loadNpmTasks('grunt-contrib-watch')
  grunt.loadNpmTasks('grunt-contrib-clean')
  grunt.loadNpmTasks('grunt-release')
  grunt.loadNpmTasks('grunt-karma')

  grunt.initConfig

    pkg: '<json:package.json>'
    srcFolder: 'src'
    compiledFolder: 'compiled'  # Temporary holding area.
    distFolder: 'dist'
    vendorFolder: 'vendor'
    testFolder: 'test'
    outerSite: '../ce_center/static/js/questionnaire'
    outerSiteCss: '../ce_center/static/css/default'

    jst:
      all:
        options:
          namespace: 'Formbuilder.templates'
          processName: (filename) ->
            signalStr = "templates/" #strip extra filepath and extensions
            filename.slice(filename.indexOf(signalStr)+signalStr.length, filename.indexOf(".html"))

        files:
          '<%= compiledFolder %>/templates.js': '<%= srcFolder %>/templates/**/*.html'

    coffee:
      all:
        files:
          '<%= compiledFolder %>/scripts.js': [
            '<%= srcFolder %>/scripts/underscore_mixins.coffee'
            '<%= srcFolder %>/scripts/rivets-config.coffee'
            '<%= srcFolder %>/scripts/main.coffee'
            '<%= srcFolder %>/scripts/fields/*.coffee'
          ]

    concat:
      all:
        files:
          '<%= distFolder %>/formbuilder.js': '<%= compiledFolder %>/*.js'
          '<%= outerSite %>/index.js': '<%= compiledFolder %>/*.js'
          '<%= vendorFolder %>/js/vendor.js': [
            'bower_components/ie8-node-enum/index.js'
            'bower_components/jquery/dist/jquery.js'
            'bower_components/jquery-ui/ui/jquery.ui.core.js'
            'bower_components/jquery-ui/ui/jquery.ui.widget.js'
            'bower_components/jquery-ui/ui/jquery.ui.mouse.js'
            'bower_components/jquery-ui/ui/jquery.ui.draggable.js'
            'bower_components/jquery-ui/ui/jquery.ui.droppable.js'
            'bower_components/jquery-ui/ui/jquery.ui.sortable.js'
            'bower_components/jquery-ui/ui/jquery.ui.datepicker.js'
            'bower_components/jquery-ui/ui/i18n/jquery.ui.datepicker-zh-CN.js'
            'bower_components/jquery.scrollWindowTo/index.js'
            'bower_components/underscore/underscore-min.js'
            'bower_components/underscore.mixin.deepExtend/index.js'
            'bower_components/rivets/dist/rivets.js'
            'bower_components/backbone/backbone.js'
            'bower_components/backbone-deep-model/src/deep-model.js'
          ]
          '<%= outerSite %>/lib.js': [
            'bower_components/ie8-node-enum/index.js'
            'bower_components/jquery-ui/ui/jquery.ui.core.js'
            'bower_components/jquery-ui/ui/jquery.ui.widget.js'
            'bower_components/jquery-ui/ui/jquery.ui.mouse.js'
            'bower_components/jquery-ui/ui/jquery.ui.draggable.js'
            'bower_components/jquery-ui/ui/jquery.ui.droppable.js'
            'bower_components/jquery-ui/ui/jquery.ui.sortable.js'
            'bower_components/jquery-ui/ui/jquery.ui.datepicker.js'
            'bower_components/jquery-ui/ui/i18n/jquery.ui.datepicker-zh-CN.js'
            'bower_components/jquery.scrollWindowTo/index.js'
            'bower_components/underscore/underscore-min.js'
            'bower_components/underscore.mixin.deepExtend/index.js'
            'bower_components/rivets/dist/rivets.js'
            'bower_components/backbone/backbone.js'
            'bower_components/backbone-deep-model/src/deep-model.js'
          ]
      mobile_friendly:
        files:
          '<%= distFolder %>/formbuilder.js': '<%= compiledFolder %>/*.js'
          '<%= vendorFolder %>/js/vendor_mobile_friendly.js': [
            'bower_components/ie8-node-enum/index.js'
            'bower_components/jquery.scrollWindowTo/index.js'
            'bower_components/underscore.mixin.deepExtend/index.js'
            'bower_components/rivets/dist/rivets.js'
            'bower_components/backbone-deep-model/src/deep-model.js'
          ]

    cssmin:
      dist:
        files:
          '<%= distFolder %>/formbuilder-min.css': '<%= distFolder %>/formbuilder.css'
          '<%= vendorFolder %>/css/vendor.css': 'bower_components/font-awesome/css/font-awesome.css'

    stylus:
      all:
        files:
          '<%= compiledFolder %>/formbuilder.css': '<%= srcFolder %>/styles/**.styl'
          '<%= distFolder %>/formbuilder.css': '<%= compiledFolder %>/**/*.css'
          '<%= outerSiteCss %>/questionnaire.css': '<%= compiledFolder %>/**/*.css'

    clean:
      compiled:
        ['<%= compiledFolder %>1']

    uglify:
      dist:
        files:
          '<%= distFolder %>/formbuilder-min.js': '<%= distFolder %>/formbuilder.js'

    watch:
      all:
        files: ['<%= srcFolder %>/**/*.{coffee,styl,html}']
        tasks: ALL_TASKS

    # To test, run `grunt --no-write -v release`
    release:
      npm: false

    karma:
      unit:
        configFile: '<%= testFolder %>/karma.conf.coffee'

  grunt.registerTask 'copy', ->
    content = grunt.file.read 'bower_components/font-awesome/css/font-awesome.css', {'encoding' : 'utf-8'}    
    content = content.replace(/(..\/fonts\/)/g, '../$1')
    content = require('clean-css').process(content, {})
    grunt.file.write grunt.config('outerSiteCss') + '/vendor.css',  content, {'encoding' : 'utf-8'}

  grunt.registerTask 'default', ALL_TASKS
  grunt.registerTask 'mobile_friendly', ['jst:all', 'coffee:all', 'concat:mobile_friendly', 'stylus:all', 'clean:compiled']
  grunt.registerTask 'dist', ['cssmin:dist', 'uglify:dist']
  grunt.registerTask 'test', ['dist', 'karma']

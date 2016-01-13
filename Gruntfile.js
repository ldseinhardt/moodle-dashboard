module.exports = function(grunt) {
  grunt.initConfig({
    pkg: grunt.file.readJSON('package.json'),
    copy: {
      license: {
        src: 'LICENSE',
        dest: 'dist/'
      },
      i18n: {
        expand: true,
        cwd: 'src/json/',
        src: [
          'en.json',
          'pt-br.json'
        ],
        dest: 'dist/_locales'
      },
      jquery: {
        expand: true,
        cwd: 'bower_components/jquery/dist/',
        src: 'jquery.min.js',
        dest: 'dist/js/'
      },
      d3: {
        expand: true,
        cwd: 'bower_components/d3/',
        src: 'd3.min.js',
        dest: 'dist/js/'
      },
      bootstrap_material_design: {
        files: [
          {
            expand: true,
            cwd: 'bower_components/bootstrap/dist/',
            src: [
              'css/bootstrap.min.css',
              'fonts/*.woff2',
              'js/bootstrap.min.js'
            ],
            dest: 'dist/'
          },
          {
            expand: true,
            cwd: 'bower_components/bootstrap-material-design/dist/',
            src: [
              'css/bootstrap-material-design.min.css',
              'css/ripples.min.css',
              'js/material.min.js',
              'js/ripples.min.js'
            ],
            dest: 'dist/'
          }
        ]
      },
      material_design_icons: {
        files: [
          {
            expand: true,
            cwd: 'bower_components/material-design-icons/iconfont/',
            src: [
              'MaterialIcons-Regular.woff2'
            ],
            dest: 'dist/fonts/'
          }
        ]

      },
      bootstrap_datetimepicker: {
        files: [
          {
            expand: true,
            cwd: 'bower_components/moment/min/',
            src: 'moment-with-locales.min.js',
            dest: 'dist/js'
          },
          {
            expand: true,
            cwd: 'bower_components/eonasdan-bootstrap-datetimepicker/build/',
            src: [
              'css/bootstrap-datetimepicker.min.css',
              'js/bootstrap-datetimepicker.min.js'
            ],
            dest: 'dist/'
          }
        ]
      }
    },
    coffee: {
      compile: {
        files: {
          'build/js/main.js': [
            'src/coffee/graph.coffee',
            'src/coffee/client.coffee',
            'src/coffee/i18n.coffee'
          ],
          'build/js/inject.js': [
            'src/coffee/inject.coffee',
            'src/coffee/i18n.coffee'
          ],
          'build/js/background.js': [
            'src/coffee/moodle.coffee',
            'src/coffee/dashboard.coffee'
          ]
        }
      }
    },
    less: {
      compile: {
        files: {
          "build/css/main.css": [
            "src/less/material-icons.less",
            "src/less/client.less",
            "src/less/graph.less"
          ],
          "build/css/inject.css": [
            "src/less/inject.less"
          ]
        }
      }
    },
    concat: {
      main: {
        src: [
          'src/html/header.html',
          'src/html/moodle-select.html',
          'src/html/moodle-dashboard.html',
          'src/html/moodle-error.html',
          'src/html/moodle-sync.html',
          'src/html/moodle-message.html',
          'src/html/footer.html',
        ],
        dest: 'build/main.html',
      }
    },
    uglify: {
      options: {
        banner: '/*!\n * Moodle dashboard v<%= pkg.version %> (<%= pkg.homepage %>)\n * Copyright 2015-2016 <%= pkg.author %>.\n * Licensed under the <%= pkg.license %> license\n */\n'
      },
      target: {
        files: [{
          expand: true,
          cwd: 'build/js',
          src: ['*.js', '!*.min.js'],
          dest: 'dist/js',
          ext: '.min.js'
        }]
      }
    },
    cssmin: {
      target: {
        files: [{
          expand: true,
          cwd: 'build/css',
          src: ['*.css', '!*.min.css'],
          dest: 'dist/css',
          ext: '.min.css'
        }]
      }
    },
    htmlmin: {
      dist: {
        options: {
          removeComments: true,
          collapseWhitespace: true
        },
        files: {
          'dist/main.html': 'build/main.html'
        }
      }
    },
    compress: {
      main: {
        options: {
          archive: '<%= pkg.name %>_<%= pkg.version %>_<%= grunt.template.today("yyyy-mm-dd") %>.tar.gz',
          mode: 'tar'
        },
        expand: true,
        cwd: 'dist/',
        src: ['**/*'],
        dest: './'
      }
    }
  });

  grunt.loadNpmTasks('grunt-contrib-copy');
  grunt.loadNpmTasks('grunt-contrib-coffee');
  grunt.loadNpmTasks('grunt-contrib-less');
  grunt.loadNpmTasks('grunt-contrib-concat');
  grunt.loadNpmTasks('grunt-contrib-uglify');
  grunt.loadNpmTasks('grunt-contrib-cssmin');
  grunt.loadNpmTasks('grunt-contrib-htmlmin');
  grunt.loadNpmTasks('grunt-contrib-compress');

  grunt.registerTask('default', [
    'copy',
    'coffee',
    'less',
    'concat',
    'uglify',
    'cssmin',
    'htmlmin'
  ]);

  grunt.registerTask('dist', [
    'default',
    'compress'
  ]);
};

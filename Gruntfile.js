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
        dest: 'dist/_locales/'
      },
      jquery: {
        expand: true,
        cwd: 'bower_components/jquery/dist/',
        src: 'jquery.min.js',
        dest: 'dist/js/'
      },
      d3: {
        expand: true,
        cwd: 'vendor/d3/',
        src: 'd3-tsv-parse.min.js',
        dest: 'build/js/min/'
      },
      google: {
        files: [
          {
            expand: true,
            cwd: 'vendor/google/',
            src: 'google-visualization.min.css',
            dest: 'build/css/min/'
          },
          {
            expand: true,
            cwd: 'vendor/google/js/',
            src: 'google-visualization.min.js',
            dest: 'build/js/min/'
          }
        ]
      },
      bootstrap_material_design: {
        files: [
          {
            expand: true,
            cwd: 'bower_components/bootstrap/dist/',
            src: 'fonts/*.woff2',
            dest: 'dist/'
          },
          {
            expand: true,
            cwd: 'bower_components/bootstrap/dist/css/',
            src: 'bootstrap.min.css',
            dest: 'build/css/min/'
          },
          {
            expand: true,
            cwd: 'bower_components/bootstrap/dist/js/',
            src: 'bootstrap.min.js',
            dest: 'build/js/min/'
          },
          {
            expand: true,
            cwd: 'bower_components/bootstrap-material-design/dist/css/',
            src: [
              'bootstrap-material-design.min.css',
              'ripples.min.css'
            ],
            dest: 'build/css/min/'
          },
          {
            expand: true,
            cwd: 'bower_components/bootstrap-material-design/dist/js/',
            src: [
              'material.min.js',
              'ripples.min.js'
            ],
            dest: 'build/js/min/'
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
            src: 'moment.min.js',
            dest: 'build/js/min/'
          },
          {
            expand: true,
            cwd: 'bower_components/moment/locale/',
            src: 'pt-br.js',
            dest: 'build/js/'
          },
          {
            expand: true,
            cwd: 'bower_components/eonasdan-bootstrap-datetimepicker/build/css/',
            src: 'bootstrap-datetimepicker.min.css',
            dest: 'build/css/min/'
          },
          {
            expand: true,
            cwd: 'bower_components/eonasdan-bootstrap-datetimepicker/build/js/',
            src: 'bootstrap-datetimepicker.min.js',
            dest: 'build/js/min/'
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
          'build/css/main.css': [
            'src/less/material-icons.less',
            'src/less/client.less',
            'src/less/graph.less'
          ],
          'build/css/inject.css': [
            'src/less/inject.less'
          ]
        }
      }
    },
    uglify: {
      target: {
        files: [{
          expand: true,
          cwd: 'build/js/',
          src: ['*.js', '!*.min.js'],
          dest: 'build/js/min/',
          ext: '.min.js'
        }]
      }
    },
    cssmin: {
      target: {
        files: [{
          expand: true,
          cwd: 'build/css/',
          src: ['*.css', '!*.min.css'],
          dest: 'build/css/min/',
          ext: '.min.css'
        }]
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
        dest: 'build/main.html'
      },
      css_main: {
        src: [
          'build/css/min/bootstrap.min.css',
          'build/css/min/bootstrap-material-design.min.css',
          'build/css/min/ripples.min.css',
          'build/css/min/bootstrap-datetimepicker.min.css',
          'build/css/min/google-visualization.min.css',
          'build/css/min/main.min.css'
        ],
        dest: 'dist/css/main.min.css',
      },
      css_inject: {
        src: [
          'build/css/min/inject.min.css'
        ],
        dest: 'dist/css/inject.min.css',
      },
      js_main: {
        src: [
          'build/js/min/bootstrap.min.js',
          'build/js/min/material.min.js',
          'build/js/min/ripples.min.js',
          'build/js/min/moment.min.js',
          'build/js/min/pt-br.min.js',
          'build/js/min/bootstrap-datetimepicker.min.js',
          'build/js/min/google-visualization.min.js',
          'build/js/min/main.min.js'
        ],
        dest: 'dist/js/main.min.js',
      },
      js_background: {
        src: [
          'build/js/min/d3-tsv-parse.min.js',
          'build/js/min/background.min.js'
        ],
        dest: 'dist/js/background.min.js',
      },
      js_inject: {
        src: [
          'build/js/min/inject.min.js'
        ],
        dest: 'dist/js/inject.min.js',
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
    'uglify',
    'cssmin',
    'concat',
    'htmlmin'
  ]);

  grunt.registerTask('dist', [
    'default',
    'compress'
  ]);
};

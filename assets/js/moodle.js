(function(global, d3) {
  'use strict';

  /**
   * =========================================================================
   * Public functions
   * =========================================================================
   */

  /**
   * Moodle constructor
   */

  var Moodle = function(options) {
    if (!options) {
      return this; 
    }
    return this.setProperty(
      (typeof options === 'string')
        ? this.parse(options)
        : options
    );
  };

  /**
   * Sync Moodle Courses
   */

  Moodle.prototype.syncCourses = function(url, callback) {
    var moodle = this;
    var location = document.createElement('a');
    location.href = url;
    var paths = location.pathname
      .replace(/\/$/, '').split('/').filter(function(path) {
        return !/\./.test(path);
      });
    var sync = {
      success: false,
      count: paths.length
    };
    var response = this.response;
    while (paths.length) {
      (function(url) {
        ajax({
          url: url + '/my',
          success: function(xhr) {
            sync.success = true;
            var parser = new DOMParser();
            var doc = parser.parseFromString(xhr.responseText, 'text/html');
            var lang = $('html', doc).lang.replace('-', '_');
            var link = $('.course_list a[href*="course/view.php"]', doc);
            if (!link) {
              return callback(response.ERROR_MOODLE_PERMISSION);
            } else if (!(link instanceof Array)) {
              link = [link];
            }
            var courses = [];
            for (var i = 0; i < link.length; i++) {
              courses.push({
                id: /[\\?&]id=([^&#]*)/.exec(link[i].search)[1],
                name: link[i].html(),
                selected: (i === 0)
              });
            }
            var data = {
              url: url,
              lang: lang,
              courses: courses
            };
            if (moodle.hasCourses()) {
              if (moodle.url === url && moodle.lang === lang) {
                if (moodle.courses.length === courses.length) {
                  for (var i = 0; i < moodle.courses.length; i++) {
                    if (moodle.courses[i].name != courses[i].name) {
                      moodle.setProperty(data);
                      break;
                    }
                  }
                } else {
                  moodle.setProperty(data);
                }
              } else {
                moodle.setProperty(data);
              }
            } else {
              moodle.setProperty(data);
            }
            return callback(response.SUCCESS);
          },
          error: function() {
            if (!sync.success) {
              if (!(--sync.count)) {
                return callback(response.ERROR_MOODLE_ACCESS); 
              }
            }
          }
        });
      })(location.protocol + '//' + location.host + paths.join('/'));      
      paths.pop();
    }
    return this;
  };

  /**
   * Sync Course data
   */

  Moodle.prototype.sync = function(callback, course) {
    return this
      .setCourse(course ? course : 0)
      .syncUsers(function(response) {
        if (response === this.response.SUCCESS) {
          this.syncLogs(function(response) {
            return callback(response);
          });
        } else {
          return callback(response);
        }
      }.bind(this));
  };

  /**
   * Sync Users
   */

  Moodle.prototype.syncUsers = function(callback) {
    var response = this.response;
    if (!this.hasCourses()) {
      return callback(response.ERROR_NOT_SYNC_COURSES);
    }
    var url = this.url;
    var course = this.getCourse();
    ajax({
      url: url + '/enrol/users.php',
      data: {
        id: course.id,
        role: 5
      },
      success: function(xhr) {
        var parser = new DOMParser();
        var doc = parser.parseFromString(xhr.responseText, 'text/html');
        var user = doc.querySelectorAll(
          'div[class*="picture"] a, div[class*="name"]',
          'table'
        );
        if (!user.length) {
          return callback(response.ERROR_MOODLE_PERMISSION);
        }
        course.users = [];
        for (var i = 0; i < user.length; i++) {
          course.users.push({
            id: /[\\?&]id=([^&#]*)/.exec(user[i].search)[1],
            name: user[++i].html(),
            selected: true
          });
        }
        course.users.sort(function(a, b){
          var x = a.name.toLowerCase()
            , y = b.name.toLowerCase()
            ;
          if (x < y)
            return -1;
          if (x > y)
            return 1;
          return 0;
        });
        callback(response.SUCCESS);
      },
      error: function() {
        callback(response.ERROR_MOODLE_ACCESS);
      }
    });
    return this;
  };

  /**
   * Sync Logs
   */

  Moodle.prototype.syncLogs = function(callback) {
    var response = this.response;
    if (!this.hasCourses()) {
      return callback(response.ERROR_NOT_SYNC_COURSES);
    }
    var course = this.getCourse();
    if (!course.hasOwnProperty('users')) {
      return callback(response.ERROR_NOT_SYNC_USERS);
    }
    var url = this.url;
    var lang = this.lang;
    ajax({
      url: url + '/report/log',
      data: {
        id: course.id,
        chooselog: 1,
        logformat: 'downloadascsv',
        download: 'tsv',
        lang: 'en'
      },
      success: function(xhr) {
        var type = xhr.getResponseHeader('content-type') || '';
        if (/application\/download|text\/tab-separated-values/.test(type)) {
          processRaw(xhr.responseText, course);
          return callback(response.SUCCESS);
        } else {
          return callback(response.ERROR_MOODLE_PERMISSION);
        }
      },
      error: function() {
        setDefaultLang();
        return callback(response.ERROR_MOODLE_ACCESS);
      },
      received: setDefaultLang
    });
    return this;

    /**
     * Set Moodle language
     */

    function setDefaultLang() {
      ajax({
        url: url,
        data: {
          lang: lang
        },
        type: 'HEAD'
      });
    }

    /**
     * Process Raw Moodle data
     * logs:
     *  - Action / Event name
     *  - Information / Description
     *  - Time
     */

    function processRaw(logs, course) {
      logs = logs.replace(/\"Saved\sat\:(.+)\s/, '');
      d3.tsv.parse(logs).forEach(function(row) {
        var user = row['User full name'].replace(/\s/g, '').toLowerCase();
        for (var i = 0; i < course.users.length; i++) {
          if (course.users[i].name.replace(/\s/g, '').toLowerCase() == user) {
            if (!course.users[i].hasOwnProperty('components')) {
              course.users[i].components = [];
            }
            var options = {
              information: row[row.hasOwnProperty('Information')
                ? 'Information'
                : 'Description'
              ].trim(),
              time: Date.parse(row['Time'])
            };
            if (row.hasOwnProperty('Action')) {
              options.action = row['Action'].split(' (').first().trim();
            } else {
              options.action = row['Event name'].trim();
            }
            options.component = options.action.split(' ').first();
            processRow(
              course.users[i].components,
              options,
              ['component', 'action', 'information', 'time']
            );
            break;
          }
        }
      });
      processDates(course);

      /**
       * Process line logs and insert in data object
       */

      function processRow(data, row, nodes) {
        var item = nodes.shift();
        if (nodes.length) {
          var children = nodes.first() + 's';
          var obj = {};
          obj[item] = row[item];
          obj[children] = [];
          var i = addInArray(data, item, row[item], obj);
          return processRow(data[i][children], row, nodes);
        } else {
          addInArray(data, item, row[item], row[item]);
        }
      }

      /**
       * Process dates (min, max)
       */

      function processDates(course) {
        var dates = [];
        course.users.forEach(function(user) {
          if (user.hasOwnProperty('components')) {
            user.components.forEach(function(component) {
              component.actions.forEach(function(action) {
                action.informations.forEach(function(information) {
                  information.times.forEach(function(time) {
                    addInArray(dates, null, time, time);
                  });
                });
              });
            });
          }
        });
        if (dates.length) {
           // Sort by date asc
          dates.sort(function(a, b){
            return new Date(a) - new Date(b);
          });
          var min = new Date(dates.first()).toISOString().slice(0, 10);
          var max = new Date(dates.last()).toISOString().slice(0, 10);
          course.date = {
            min: min,
            max: max,
            selected: {
              min: min,
              max: max
            }
          };     
        }
      }
    }
  };

  /**
   * Get Summary of data
   */

  Moodle.prototype.getSummary = function() {
    if (!this.hasCourses()) {
      return this.response.ERROR_NOT_SYNC_COURSES;
    }
    var course = this.getCourse();
    if (!course.hasOwnProperty('users')) {
      return this.response.ERROR_NOT_SYNC_USERS;
    }
    var recorded_view = 0
      , selected_view = 0
      , recorded_actn = []
      , selected_actn = []
      , recorded_page = []
      , selected_page = [];
    course.users.forEach(function(user) {
      if (user.hasOwnProperty('components')) {
        user.components.forEach(function(component) {
          component.actions.forEach(function(action) {
            action.informations.forEach(function(information) {
              var unique = action['action'] + information['information'];
              var rapu = checkTime(information.times, course.date);
              if (rapu) {
                addInArray(recorded_actn, null, unique, unique);
                if (/view/.test(action['action'])) {
                  recorded_view += rapu;
                  addInArray(recorded_page, null, unique, unique);
                }
              }
              if (user.selected) {
                var sapu = checkTime(information.times, course.date.selected);
                if (sapu) {
                  addInArray(selected_actn, null, unique, unique);
                  if (/view/.test(action['action'])) {
                    selected_view += sapu;
                    addInArray(selected_page, null, unique, unique);
                  }
                }
              }
            });
          });
        });
      }
    });
    return {
      recorded: {
        views: recorded_view,
        users: course.users.length,
        actions: recorded_actn.length,
        pages: recorded_page.length,
        date: {
          min: course.date.min,
          max: course.date.max
        }
      },
      selected: {
        views: selected_view,
        users: course.users.filter(function(user) {
          return user.selected;
        }).length,
        actions: selected_actn.length,
        pages: selected_page.length,
        date: course.date.selected
      }
    };
  };

  /**
   * Get list of users x interactions
   */

  Moodle.prototype.getInteractionsSize = function() {
    var response = this.response;
    if (!this.hasCourses()) {
      return response.ERROR_NOT_SYNC_COURSES;
    }
    var course = this.getCourse();
    if (!course.hasOwnProperty('users')) {
      return response.ERROR_NOT_SYNC_USERS;
    }
    var date = course.date.selected;
    var data = {
      'name': 'Interactions',
      'children': []
    };
    course.users.forEach(function(user) {
      if (user.selected && user.hasOwnProperty('components')) {
        user.components.forEach(function(component) {
          var i = addInArray(
            data.children, 'name', component['component'], {
              'name': component['component'],
              'children': []
            }
          );
          component.actions.forEach(function(action) {
            var j = addInArray(
              data.children[i].children,'name', action['action'], {
                'name': action['action'],
                'size': 0
              }
            );
            action.informations.forEach(function(information) {
              data.children[i].children[j].size +=
                checkTime(information.times, date);
            });
          });
        });
      }
    });
    data = classes(data);
    if (!data.children.length) {
      return response.ERROR_NO_DATA;
    }
    return data;
  };

  /**
   * Get list of interactions size
   */

  Moodle.prototype.getUsersInteraction = function() {
    var response = this.response;
    if (!this.hasCourses()) {
      return response.ERROR_NOT_SYNC_COURSES;
    }
    var course = this.getCourse();
    if (!course.hasOwnProperty('users')) {
      return response.ERROR_NOT_SYNC_USERS;
    }
    var date = course.date.selected;
    var data = [];
    course.users.forEach(function(user) {
      if (user.selected && user.hasOwnProperty('components')) {
        var i = addInArray(data, 'name', user.name, {
          'name': user.name,
          'size': 0
        });
        user.components.forEach(function(component) {
          component.actions.forEach(function(action) {
            action.informations.forEach(function(information) {
              data[i].size += checkTime(information.times, date);
            });
          });
        });
      }
    });
    // Filter users with zero interactions
    data = data.filter(function(d) {
      return (d.size > 0);
    });
    if (!data.length) {
      return response.ERROR_NO_DATA;
    }
    // Order by user interactions size desc
    data.sort(function(a, b) {
      if (a.size > b.size)
        return -1;
      if (a.size < b.size)
        return 1;
      return 0;
    });
    return data;
  };

  /**
   * Set course id
   */

  Moodle.prototype.setCourse = function(id) {
    for (var i = 0; i < this.courses.length; i++) {
      this.courses[i].selected = (i == id);
    }
    return this;
  };

  /**
   * Set selected users
   */

  Moodle.prototype.setUsers = function(users) {
    var us = this.getCourse().users;
    for (var i = 0; i < us.length; i++) {
      us[i].selected = (users.indexOf(i) >= 0);
    }
    return this;
  };

  /**
   * Set date range
   */

  Moodle.prototype.setDate = function(date) {
    var course = this.getCourse();
    if (date.hasOwnProperty('min')) {
      course.date.selected.min = date.min;
    }
    if (date.hasOwnProperty('max')) {
      course.date.selected.max = date.max;
    }
    return this;
  };

  /**
   * Get Course selected
   */

  Moodle.prototype.getCourse = function() {
    return this.courses.filter(function(e) {
      return e.selected;
    }).first();
  };

  /**
   * Get Courses
   */

  Moodle.prototype.getCourses = function() {
    var courses = [];
    this.courses.forEach(function(course) {
      courses.push({
        name: course.name,
        selected: course.selected
      });
    });
    return courses;
  };

  /**
   * Get Users
   */

  Moodle.prototype.getUsers = function() {
    var users = [];
    this.getCourse().users.forEach(function(user, i) {
      users.push({
        id: i,
        name: user.name,
        selected: user.selected
      });
    });
    return users;
  };

  /**
   * Get Date
   */

  Moodle.prototype.getDate = function() {
    return this.getCourse().date;
  };

  /**
   * Check if has sync courses
   */

  Moodle.prototype.hasCourses = function() {
    if (!this.hasOwnProperty('courses')) {
      return false;
    }
    return true;
  };

  /**
   * Check if has sync users
   */

  Moodle.prototype.hasUsers = function() {
    if (!this.hasCourses()) {
      return false;
    }
    if (!this.getCourse().hasOwnProperty('users')) {
      return false;
    }
    return true;
  };

  /**
   * Check if has sync logs
   */

  Moodle.prototype.hasLogs = function() {
    if (!this.hasCourses()) {
      return false;
    }
    return this.getCourse().hasOwnProperty('date');
  };

  /**
   * Set all properties of options in Moodle
   */

  Moodle.prototype.setProperty = function(options) {
    Object.keys(options).forEach(function(key) {
      this[key] = options[key];
    }, this);
    return this;
  };

  /**
   * Serialize Moodle object
   */

  Moodle.prototype.toString = function() {
    return JSON.stringify(this);
  };

  /**
   * Parse Moodle serialized to Moodle object
   */

  Moodle.prototype.parse = function(str) {
    return JSON.parse(str);
  };

  /**
   * Moodle response codes
   */

  Moodle.prototype.response = Enum([
    'SUCCESS',
    'ERROR_MOODLE_ACCESS',
    'ERROR_MOODLE_PERMISSION',
    'ERROR_NOT_SYNC_COURSES',
    'ERROR_NOT_SYNC_USERS',
    'ERROR_NO_DATA'
  ]);

  /**
   * =========================================================================
   * Private functions
   * =========================================================================
   */

  /**
   * Short tree data structure
   */

  function classes(root) {
    var classes = [];
    function recurse(name, node) {
      if (node.children) {
        node.children.forEach(function(child) {
          recurse(node.name, child);
        });
      } else {
        classes.push({
          packageName: name,
          className: node.name,
          value: node.size
        });
      }
    }
    recurse(null, root);
    classes = classes.filter(function(d) {
      return (d.value > 0);
    });
    return {
      children: classes
    };
  }

  /**
   * Check if data is in range
   */

  function checkTime(dates, date) {
    var count = 0;
    for (var i = 0; i < dates.length; i++) {
      var s = new Date(dates[i]).toISOString().slice(0, 10);
      var v = new Date(Date.parse(s));
        if ((new Date(Date.parse(date.min)) - v <= 0) && 
            (v - new Date(Date.parse(date.max)) <= 0)) {
          count++;
        }
    }
    return count;
  }

  /**
   * Add in array if not exists value and return index
   */

  function addInArray(array, key, value, obj) {
    for (var i = 0; i < array.length; i++) {
      if ((key ? array[i][key] : array[i]) === value) {
        return i;
      }
    }
    return array.push(obj) - 1;
  }

  /**
   * Ajax for requests
   */

  function ajax(options) {
    var data = '';
    if (options.data instanceof Object) {
      data = '?' + Object.keys(options.data).map(function(key) {
        return key + '=' + options.data[key];
      }).join('&');
    }
    var xhr = new XMLHttpRequest();
    xhr.onprogress = function(event) {
      if (options.progress instanceof Function) {
        options.progress(event);
      }
    };
    xhr.open(options.type || 'GET', options.url + data, true);
    xhr.onreadystatechange = function() {
      switch (xhr.readyState) {
        case 2:
          if (options.received instanceof Function) {
            options.received(xhr);
          }
          break;
        case 4:
          var f = (xhr.status === 200)
            ? options.success
            : options.error;
          if (f instanceof Function) {
            f(xhr);
          }
          if (options.complete instanceof Function) {
            options.complete(xhr);
          }
      }
    };
    xhr.send();
  }

  /**
   * =========================================================================
   * Exports
   * =========================================================================
   */

  if (global) {
    global.Moodle = Moodle;
  }

})(this, this.d3);
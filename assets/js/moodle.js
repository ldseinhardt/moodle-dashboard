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
        return !/\.|\0/.test(path);
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
    var course = this.courses.filter(function(e) {
      return e.selected;
    })[0];
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
    var course = this.courses.filter(function(e) {
      return e.selected;
    })[0];
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
        download: 'csv',
        lang: 'en'
      },
      success: function(xhr) {
        var type = xhr.getResponseHeader('content-type') || '';
        if (/application\/download/.test(type)) {
          processRaw(xhr.responseText, 'tsv', course.users);
          processDates(course);
          return callback(response.SUCCESS);
        } else if (/text\/csv/.test(type)) {
          processRaw(xhr.responseText, 'csv', course.users);
          processDates(course);
          return callback(response.SUCCESS);
        } else {
          return callback(response.ERROR_MOODLE_PERMISSION);
        }
      },
      error: function(xhr) {
        ajax({
          url: url + '/?lang=' + lang,
          type: 'HEAD'
        });
        return callback(response.ERROR_MOODLE_ACCESS);
      },
      received: function(xhr) {
        ajax({
          url: url + '/?lang=' + lang,
          type: 'HEAD'
        });
      }
    });
    return this;
  };

  /**
   * Get Summary of data
   */

  Moodle.prototype.getSummary = function() {
    var response = this.response;
    if (!this.hasCourses()) {
      return response.ERROR_NOT_SYNC_COURSES;
    }
    var course = this.courses.filter(function(e) {
      return e.selected;
    })[0];
    if (!course.hasOwnProperty('users')) {
      return response.ERROR_NOT_SYNC_USERS;
    }
    return {
      recorded: {
        users: course.users.length,
        actions: actions(true),
        date: {
          min: course.date.min,
          max: course.date.max
        }
      },
      selected: {
        users: course.users.filter(function(user) {
          return user.selected;
        }).length,
        actions: actions(),
        date: course.date.selected
      }
    };
    function actions(recorded) {
      var actions = [];
      course.users.forEach(function(user) {
        if (user.selected || recorded) {
          user.components.forEach(function(component) {
            component.actions.forEach(function(action) {
              action.informations.forEach(function(information) {
                if (checkTime(information.times, recorded ? course.date : course.date.selected) > 0) {
                  addInArray(actions, 'name', action['action'] + information['information'], {
                    'name': action['action'] + information['information']
                  });
                }
              });
            });
          });
        }
      });
      return actions.length;
    }
  };

  /**
   * Get list of users x interactions
   */

  Moodle.prototype.getInteractionsSize = function() {
    var response = this.response;
    if (!this.hasCourses()) {
      return response.ERROR_NOT_SYNC_COURSES;
    }
    var course = this.courses.filter(function(e) {
      return e.selected;
    })[0];
    if (!course.hasOwnProperty('users')) {
      return response.ERROR_NOT_SYNC_USERS;
    }
    var date = course.date.selected;
    var data = {
      'name': 'Interactions',
      'children': []
    };
    course.users.forEach(function(user) {
      if (user.selected) {
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
    var course = this.courses.filter(function(e) {
      return e.selected;
    })[0];
    if (!course.hasOwnProperty('users')) {
      return response.ERROR_NOT_SYNC_USERS;
    }
    var date = course.date.selected;
    var data = [];
    course.users.forEach(function(user) {
      if (user.selected) {
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
    var us = this.courses.filter(function(e) {
      return e.selected;
    })[0].users;
    for (var i = 0; i < us.length; i++) {
      us[i].selected = (users.indexOf(i) >= 0);
    }
    return this;
  };

  /**
   * Set date range
   */

  Moodle.prototype.setDate = function(date) {
    var course = this.courses.filter(function(e) {
      return e.selected;
    })[0];
    if (date.hasOwnProperty('min')) {
      course.date.selected.min = date.min;
    }
    if (date.hasOwnProperty('max')) {
      course.date.selected.max = date.max;
    }
    return this;
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
    this.courses.filter(function(e) {
      return e.selected;
    })[0].users.forEach(function(user, i) {
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
    return this.courses.filter(function(e) {
      return e.selected;
    })[0].date;
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
    var course = this.courses.filter(function(e) {
      return e.selected;
    })[0];
    if (!course.hasOwnProperty('users')) {
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
    var course = this.courses.filter(function(e) {
      return e.selected;
    })[0];
    return course.hasOwnProperty('date');
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
      var min = new Date(dates[0]).toISOString().slice(0, 10);
      var max = new Date(dates[dates.length-1]).toISOString().slice(0, 10);
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

  /**
   * Process Raw Moodle data
   */

  function processRaw(logs, type, users) {
    switch (type) {
      case 'csv':
        return processCSV(logs, users);
      case 'tsv':
        return processTSV(logs, users);
    }

    /**
     * Process CSV data:
     * Event name
     * Description
     * Time
     */

    function processCSV(csv, users) {
      d3.csv.parse(csv).forEach(function(row) {
        var user = row['User full name'].replace(/\s/g, '').toLowerCase();
        for (var i = 0; i < users.length; i++) {
          if (users[i].name.replace(/\s/g, '').toLowerCase() == user) {
            if (!users[i].hasOwnProperty('components')) {
              users[i].components = [];
            }
            processRow(users[i].components, {
              component: row['Event name'].trim().split(' ')[0],
              action: row['Event name'].trim(),
              information: row['Description'].trim(),
              time: Date.parse(row['Time'])
            }, ['component', 'action', 'information', 'time']);
            break;
          }
        }
      }, this);
    }

    /**
     * Process TSV data:
     * Action
     * Information
     * Time
     */

    function processTSV(tsv, users) {
      tsv = tsv.replace(/\"Saved\sat\:(.+)\s/, '');
      d3.tsv.parse(tsv).forEach(function(row) {
        var user = row['User full name'].replace(/\s/g, '').toLowerCase();
        for (var i = 0; i < users.length; i++) {
          if (users[i].name.replace(/\s/g, '').toLowerCase() == user) {
            if (!users[i].hasOwnProperty('components')) {
              users[i].components = [];
            }
            var action = row['Action'].split(' (')[0].trim();
            processRow(users[i].components, {
              component: action.trim().split(' ')[0],
              action: action,
              information: row['Information'].trim(),
              time: Date.parse(row['Time'])
            }, ['component', 'action', 'information', 'time']);
            break;
          }
        }
      }, this);
    }

    /**
     * Process line logs and insert in data object
     */

    function processRow(data, row, nodes) {
      var a, b, i, obj;
      a = nodes[0];
      b = nodes.length > 1 ? nodes[1] + 's' : null;
      if (b) {
        obj = {};
        obj[a] = row[a];
        obj[b] = [];
      } else {
        obj = row[a];
      }    
      i = addInArray(data, a, row[a], obj);
      return b ? processRow(data[i][b], row, nodes.slice(1)) : null;
    }
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
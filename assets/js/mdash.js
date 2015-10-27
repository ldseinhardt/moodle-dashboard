(function(global, d3) {
  'use strict';

  var mdash = {};

  // Realiza requisições para obter url, linguagem e cursos do moodle
  mdash.moodle = function(url, callback) {
    var location = document.createElement('a');
    location.href = url;
    var check = {
      success: false,
      count: 0
    };
    var nav = function(url) {
      ajax({
        url: url + '/my',
        success: function(xhr) {
          var parser = new window.DOMParser();
          var doc = parser.parseFromString(xhr.responseText, 'text/html');
          var lang = doc.querySelector('html').lang.replace('-', '_');
          var link = doc.querySelectorAll('.course_list a[href*="course/view.php"]');
          var courses = [];
          for (var i = 0; i < link.length; i++) {
            var regex = new RegExp('[\\?&]id=([^&#]*)');
            var regid = regex.exec(link[i].search);
            var couid = (regid === null) ? 0 : parseInt(regid[1]);
            if (couid > 0) {
              courses.push({
                name: link[i].innerHTML, 
                id: couid
              });
            }
          }
          if (courses.length) {
            callback({
              url: url,
              lang: lang,
              courses: courses
            });
          } else {
            callback({
              error: 2
            });
          }
          check.success = true;
        },
        error: function() {
          if (!check.success) {
            check.count--;
            if (!check.count) {
              callback({
                error: 1
              }); 
            }
          }
        }  
      });
    };
    if (location.pathname === '/') {
      check.count = 1;
      nav(location.protocol + '//' + location.host);
    } else {
      var paths = location.pathname.split('/').filter(function(path) {
        return path.indexOf('.') === -1;
      });
      check.count = paths.length;
      for (var i = paths.length; i > 0 ; i--) {
        nav(location.protocol + '//' + location.host + paths.join('/'));
        paths.pop();
      }
    }
  };

  // Realiza uma requisição para obter os logs do moodle
  mdash.sync = function(options) {
    if (options.init instanceof Function) {
      options.init();
    }
    ajax({
      url: options.url + '/report/log',
      data: {
        id: options.course,         // ID do curso
        chooselog: 1,               // Visualizar logs
        logformat: 'downloadascsv', // Formato para download (tsv) Moodle 2.6
        download: 'csv',            // Formato para download (csv) Moodle 2.7+
        lang: 'en'                  // Linguagem
      },
      success: function(xhr) {
        var type = xhr.getResponseHeader('content-type') || '';
        if (type.search('application/download') > -1) {
          if (options.done instanceof Function) {
            options.done(processTSV(xhr.responseText));
          }
        } else if (type.search('text/csv') > -1) {
          if (options.done instanceof Function) {
            options.done(processCSV(xhr.responseText));
          }
        } else {
          if (options.fail instanceof Function) {
            options.fail({
              error: 2
            });
          }
        }
      },
      error: function(xhr) {
        setDefaultLang(options.url, options.lang);
        if (options.fail instanceof Function) {
          options.fail({
            error: 1
          });
        }
      },
      received: function(xhr) {
        setDefaultLang(options.url, options.lang);
      }
    });
  };

  // Realiza uma requisição para obter usuários do moodle
  mdash.users = function(url, course, callback) {
    var STUDENT = 5;
    ajax({
      url: url + '/enrol/users.php',
      data: {
        id: course,
        role: STUDENT
      },
      success: function(xhr) {
        var parser = new window.DOMParser();
        var doc = parser.parseFromString(xhr.responseText, 'text/html');
        var user = doc.querySelectorAll('table > tbody > tr > td > div[class*="firstname"]');
        var users = [];
        for (var i = 0; i < user.length; i++) {
          users.push({
            name: user[i].innerHTML,
            selected: true            
          });
        }
        if (users.length) {
          users.sort(function(a, b){
            var a = a.name.toLowerCase()
              , b = b.name.toLowerCase()
              ;
            if (a < b)
              return -1;
            if (a > b)
              return 1;
            return 0;
          });
          callback(users);
        } else {
          callback({
            error: 2
          });
        }
      },
      error: function() {
        callback({
          error: 1
        });
      }
    });
  };

  // Retorna o primeiro e último dia dos dados
  mdash.time = function(data) {
    var listOfUniqueDays = [];
    data.forEach(function(context) {
      context.users.forEach(function(user) {
        user.components.forEach(function(component) {
          component.actions.forEach(function(action) {
            action.informations.forEach(function(information) {
              information.times.forEach(function(time) {
                var value = new Date(time).toDateString();
                addInArray(listOfUniqueDays, null, value, value);
              });
            });
          });
        });
      });
    });
    // Ordena de modo crescente pela data
    listOfUniqueDays.sort(function(a, b){
      return new Date(Date.parse(a)) - new Date(Date.parse(b));
    });
    var min = new Date(listOfUniqueDays[0]).toISOString().slice(0, 10);
    var max = new Date(listOfUniqueDays[listOfUniqueDays.length-1]).toISOString().slice(0, 10);
    return {
      min: {value: min, selected: min},
      max: {value: max, selected: max}
    };
  };

  // Retorna a lista de componentes e ações e suas quantidades
  mdash.listOfActions = function(data, users, time) {
    var listOfActions = {'name': 'Actions', 'children': []};
    data.forEach(function(context) {
      context.users.forEach(function(user) {
        if (checkUser(users, user['user'])) {
          user.components.forEach(function(component) {
            var i = addInArray(listOfActions.children, 'name', component['component'], {
              'name': component['component'],
              'children': []
            });
            component.actions.forEach(function(action) {
              var j = addInArray(listOfActions.children[i].children, 'name', action['action'], {
                'name': action['action'],
                'size': 0
              });
              action.informations.forEach(function(information) {
                listOfActions.children[i].children[j].size += checkTime(information.times, time);
              });
            });
          });
        }
      });
    });
    // Ordena de modo crescente as interações pelo nome do componente
    listOfActions.children.sort(function(a, b) {
      if (a.name < b.name)
        return -1;
      if (a.name > b.name)
        return 1;
      return 0;
    });
    return listOfActions;
  };

  // Retorna a lista de Usuários e o número de ações
  mdash.listOfUsers = function(data, users, time) {
    var listOfUsers = [];
    data.forEach(function(context) {
      context.users.forEach(function(user) {
        if (checkUser(users, user['user'])) {
          var i = addInArray(listOfUsers, 'name', user['user'], {
            'name': user['user'],
            'size': 0
          });
          user.components.forEach(function(component) {
            component.actions.forEach(function(action) {
              action.informations.forEach(function(information) {
                listOfUsers[i].size += checkTime(information.times, time);
              });
            });
          });
        }
      });
    });
    // Ordena de modo decrescente os usuários pelo número de interações
    listOfUsers.sort(function(a, b) {
      if (a.size > b.size)
        return -1;
      if (a.size < b.size)
        return 1;
      return 0;
    });
    return listOfUsers;
  };

  // Retorna a linguagem do moodle
  function setDefaultLang(url, lang) {
    ajax({
      url: url + '/?lang=' + lang,
      type: 'HEAD'
    });
  }

  // Processa o TSV (Moodle 2.6)
  function processTSV(tsv) {
    /*
      Dados:
      - Time: '19 September 2015, 3:22 PM'
      - User full name
      - IP address (x)
      - Course
      - Action
      - Information
    */
    return (function(tsv) {
      var data = [];
      // Remove a primeira linha com informação de hora de download
      if (tsv.search('Saved at:') > -1) {
        tsv = tsv.split('\n').slice(1).join('\n');  
      }
      d3.tsv.parse(tsv).forEach(function(row) {
        var action = row['Action'].split(' (')[0].trim();
        processRow(data, {
          context: 'Course: '+row['Course'].trim(),
          user: row['User full name'].trim(),
          component: action.split(' ')[0].trim(),
          action: action,
          information: row['Information'].trim(),
          time: Date.parse(row['Time'])
        }, ['context', 'user', 'component', 'action', 'information', 'time']);
      }, this);
      return data;
    })(tsv);
  }

  // Processa o CSV (Moodle 2.7+)
  function processCSV(csv) {
    /*
      Dados:
      - Time: '20 Sep, 02:10'
      - User full name: 'Terri Teacher'
      - IP address: '177.194.218.46' (x)
      - Event context: 'Course: My first course'
      - Component: 'Logs'
      - Event name: 'Log report viewed'
      - Description: 'The user with id '3' viewed the log report for the course with id '2'.'
      - Origin: 'web' (x)
      - Affected user: '-' (x)
    */
    return (function(csv) {
      var data = [];
      d3.csv.parse(csv).forEach(function(row) {
        processRow(data, {
          context: row['Event context'].trim(),
          user: row['User full name'].trim(),
          component: row['Component'].trim(),
          action: row['Event name'].trim(),
          information: row['Description'].trim(),
          time: Date.parse(row['Time'])
        }, ['context', 'user', 'component', 'action', 'information', 'time']);
      }, this);
      return data;
    })(csv);
  }

  // Processa uma linha do TSV/CSV e insere no objeto data
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

  // Verifica se um usuário esta selecionado
  function checkUser(users, name) {
    name = name.replace(new RegExp(' ', 'g'), '');
    for (var i = 0; i < users.length; i ++) {
      if (users[i].name.replace(new RegExp(' ', 'g'), '') === name) {
        return users[i].selected;
     }
    }
    return false;
  }

  // Verifica se a data está no intervalo selecionado
  function checkTime(times, time) {
    var min = time.min.selected;
    var max = time.max.selected;
    var count = 0;
    for (var i = 0; i < times.length; i++) {
      var value = new Date(times[i]).toISOString().slice(0, 10);
        if ((new Date(Date.parse(min)) - new Date(Date.parse(value)) <= 0) && 
            (new Date(Date.parse(value)) - new Date(Date.parse(max)) <= 0)) {
          count++;
        }
    }
    return count;
  }

  // Adiciona no array se não existir e retorna o indice sempre
  function addInArray(array, key, value, obj) {
    for (var i = 0; i < array.length; i++) {
      if ((key ? array[i][key] : array[i]) === value) {
        return i;
      }
    }
    return array.push(obj) - 1;
  }

  /**
   * Ajax para realização de requisições
   * @param options { url, [data, type, success, error, progress, received, complete] }
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

  if (global) {
    global.mdash = mdash;
  }

})(this, this.d3);
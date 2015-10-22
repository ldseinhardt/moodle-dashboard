(function(global, d3) {
  "use strict";
  
  var mdash = {};
  
  // Retorna a lista de usuários unicos contidos nos logs
  mdash.uniqueUsers = function(data) {
    var listOfUniqueUsers = [];
    
    data.forEach(function(context) {
      context.users.forEach(function(user) {
        addInArray(listOfUniqueUsers, "name", user["user"], {
            name: user["user"],
            selected: true
        });
      });
    });
    
    // Ordena de modo crescente pelo nome de usuário
    listOfUniqueUsers.sort(function(a, b) {
      if (a.name < b.name)
        return -1;
      if (a.name > b.name)
        return 1;
      return 0;
    });
    
    return listOfUniqueUsers;
  };
  
  // Retorna a lista de dias contidos nos logs, além do primeiro e último dia
  mdash.uniqueDays = function(data) {
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
      max: {value: max, selected: max},
      list: listOfUniqueDays
    };
  };
  
  // Retorna a lista de componentes e ações e suas quantidades
  mdash.listOfActions = function(data, users, time) {
    var listOfActions = {"name": "Actions", "children": []};
    
    data.forEach(function(context) {
      context.users.forEach(function(user) {
        if (checkUser(users, user["user"])) {
          user.components.forEach(function(component) {
            var i = addInArray(listOfActions.children, "name", component["component"], {
              "name": component["component"],
              "children": []
            });
            component.actions.forEach(function(action) {
              var j = addInArray(listOfActions.children[i].children, "name", action["action"], {
                "name": action["action"],
                "size": 0
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
  
  // Retorna a lista de Usuários e o numero de ações
  mdash.listOfUsers = function(data, users, time) {
    var listOfUsers = [];
    
    data.forEach(function(context) {
      context.users.forEach(function(user) {
        if (checkUser(users, user["user"])) {
          var i = addInArray(listOfUsers, "name", user["user"], {
            "name": user["user"],
            "size": 0
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
  
  // Realiza uma requisição para obter os logs do moodle
  mdash.sync = function(options) {
    if (options.init instanceof Function) {
      options.init();
    }
    ajax({
      url: options.url + "/report/log/index.php",
      data: {
            "id": options.course,         // ID do curso
            "chooselog": 1,               // Visualizar logs
            "logformat": "downloadascsv", // Formato para download (tsv) Moodle 2.6
            "download": "csv",            // Formato para download (csv) Moodle 2.7+
            "lang": "en"                  // Linguagem
          },
      done: function(xhr) {
        var type = xhr.getResponseHeader("content-type") || "";
        if (type.search("application/download") > -1) {
          if (options.done instanceof Function) {
            options.done(processTSV(xhr.responseText));
          }
        } else if (type.search("text/csv") > -1) {
          if (options.done instanceof Function) {
            options.done(processCSV(xhr.responseText));
          }
        } else {
          if (options.fail instanceof Function) {
            options.fail({
              type: 1,
              message: "Formato Inválido"
            });
          }
        }
      },
      fail: function(xhr) {
        setDefaultLang(options.url, options.lang);
        if (options.fail instanceof Function) {
          options.fail({
            type: 0,
            message: xhr.statusText
          });
        }
      },
      received: function(xhr) {
        setDefaultLang(options.url, options.lang);
      }
    });
    return this;
  };

  // Retorna a linguagem do moodle
  var setDefaultLang = function(url, lang) {
    ajax({
      type: "HEAD",
      url: url + "/?lang=" + lang
    });
  };
  
  // Processa o TSV (Moodle 2.6)
  var processTSV = function(tsv) {

    /*
      Dados:
      - Time: "19 September 2015, 3:22 PM"
      - User full name
      - IP address (x)
      - Course
      - Action
      - Information
    */

    return (function(tsv) {
      var data = [];

      // Remove a primeira linha com informação de hora de download
      if (tsv.search("Saved at:") > -1) {
        tsv = tsv.split("\n").slice(1).join("\n");  
      }

      d3.tsv.parse(tsv).forEach(function(row) {
        var action = row["Action"].split(" (")[0].trim();
        processRow(data, {
          context: "Course: "+row["Course"].trim(),
          user: row["User full name"].trim().replace(/(?:^|\s)\S/g, function(a) { return a.toUpperCase(); }),
          component: action.split(" ")[0].trim(),
          action: action,
          information: row["Information"].trim(),
          time: Date.parse(row["Time"])
        }, ["context", "user", "component", "action", "information", "time"]);
      }, this);

      return data;
    })(tsv);
  };

  // Processa o CSV (Moodle 2.7+)
  var processCSV = function(csv) {

    /*
      Dados:
      - Time: "20 Sep, 02:10"
      - User full name: "Terri Teacher"
      - IP address: "177.194.218.46" (x)
      - Event context: "Course: My first course"
      - Component: "Logs"
      - Event name: "Log report viewed"
      - Description: "The user with id '3' viewed the log report for the
          course with id '2'."
      - Origin: "web" (x)
      - Affected user: "-" (x)
    */

    return (function(csv) {
      var data = [];

      d3.csv.parse(csv).forEach(function(row) {
        processRow(data, {
          context: row["Event context"].trim(),
          user: row["User full name"].trim().replace(/(?:^|\s)\S/g, function(a) { return a.toUpperCase(); }),
          component: row["Component"].trim(),
          action: row["Event name"].trim(),
          information: row["Description"].trim(),
          time: Date.parse(row["Time"])
        }, ["context", "user", "component", "action", "information", "time"]);
      }, this);
      
      return data;
    })(csv);
  };
  
  // Processa uma linha do TSV/CSV e insere no objeto data
  var processRow = function(data, row, nodes) {
    var a, b, i, obj;
    a = nodes[0];
    b = nodes.length > 1 ? nodes[1] + "s" : null;
    if (b) {
      obj = {};
      obj[a] = row[a];
      obj[b] = [];
    } else {
      obj = row[a];
    }    
    i = addInArray(data, a, row[a], obj);
    return b ? processRow(data[i][b], row, nodes.slice(1)) : null;
  };
  
  // Verifica se um usuário esta selecionado
  var checkUser = function(users, name) {
    for (var i = 0; i < users.length; i ++) {
      if (users[i].name === name) {
        return users[i].selected;
     }
    }
    return false;
  }
  
  // Verifica se a data está no intervalo selecionado
  var checkTime = function(times, time) {
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
  var addInArray = function(array, key, value, obj) {
    for (var i = 0; i < array.length; i++) {
      if ((key ? array[i][key] : array[i]) === value) {
        return i;
      }
    }
    
    return array.push(obj) - 1;
  };
  
  // Ajax para realizar requisições
  var ajax = function(options) {
    var data = "";
    
    if (options.data instanceof Object) {
      data = "?" + Object.keys(options.data).map(function(key) {
        return key + '=' + options.data[key];
      }).join('&');
    }
    
    var xhr = new XMLHttpRequest();
    
    xhr.onprogress = function(event) {
      if (options.progress instanceof Function) {
        options.progress(event);
      }
    };
    
    xhr.open(options.type || "GET", options.url + data, true);
    
    xhr.onreadystatechange = function() {
      switch (xhr.readyState) {
        case 2:
          if (options.received instanceof Function) {
            options.received(xhr);
          }
          break;
        case 4:
          var f = (xhr.status === 200)
            ? options.done
            : options.fail;
          if (f instanceof Function) {
            f(xhr);
          }
          if (options.complete instanceof Function) {
            options.complete(xhr);
          }
      }
    };
    
    xhr.send();
  };  
  
  if (global) {
    global.mdash = mdash;
  }

})(this, this.d3);
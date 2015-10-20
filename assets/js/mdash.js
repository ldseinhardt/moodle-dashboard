(function(global, d3) {
  "use strict";
  
  var mdash = {};
  
  mdash.listOfActions = function(data) {
    var result = {"name": "Actions", "children": []};
    
    data.forEach(function(context) {
      context.users.forEach(function(user) {
        user.components.forEach(function(component) {
          var i = addInArray(result.children, "name", component["component"], {
            "name": component["component"],
            "children": []
          });
          component.actions.forEach(function(action) {
            var j = addInArray(result.children[i].children, "name", action["action"], {
              "name": action["action"],
              "size": 0
            });
            action.informations.forEach(function(information) {
              information.dates.forEach(function(date) {
                result.children[i].children[j].size += date.hours.length;
              });
            });
          });
        });
      });
    });
    
    // Ordena de modo crescente as interações pelo nome do componente
    result.children.sort(function(a, b) {
      if(a.name < b.name)
        return -1;
      if(a.name > b.name)
        return 1;
      return 0;
    });
    
    return result;
  };
  
  mdash.listOfUsers = function(data) {
    var result = [];
    
    data.forEach(function(context) {
      context.users.forEach(function(user) {
        var i = addInArray(result, "name", user["user"], {
          "name": user["user"],
          "size": 0
        });
        user.components.forEach(function(comp) {
          comp.actions.forEach(function(act) {
            act.informations.forEach(function(inf) {
              inf.dates.forEach(function(dat) {
                result[i].size += dat.hours.length;
              });
            });
          });
        });
      });
    });
    
    // Ordena de modo decrescente os usuários pelo número de interações
    result.sort(function(a, b) {
      if(a.size > b.size)
        return -1;
      if(a.size < b.size)
        return 1;
      return 0;
    });
    
    return result;
  };
  
  // Realiza uma requisição para obter os dados do moodle
  mdash.sync = function(options) {
    if (options.init instanceof Function) {
      options.init();
    }
    ajax({
      url: options.moodle.url,
      data: {
            "id": options.moodle.data.id,     // ID do curso
            "group": 0,                       // ID do grupo
            "user": 0,                        // ID do usuário
            "date": 0,                        // data para mostrar
            "modid": 0,                       // ID da ação
            "modaction": "",                  // Tipo de ação
            "page": 0,                        // Página para mostrar
            "perpage": 100,                   // Quantidade por página
            "showcourses": 0,                 // Whether to show courses if we're over our limit
            "showusers": 0,                   // Whether to show users if we're over our limit
            "chooselog": 1,                   // Visualizar logs
            "logformat": "downloadascsv",     // Formato para download (tsv) Moodle 2.6
            "download": "csv",                // Formato para download (csv) Moodle 2.7+
            "logreader": "logstore_standard", // Leitor utilizado para leitura de logs
            "edulevel": -1,                   // Tipo de usuário
            "lang": "en"                      // Linguagem
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
        setDefaultLang(options.moodle);
        if (options.fail instanceof Function) {
          options.fail({
            type: 0,
            message: xhr.statusText
          });
        }
      },
      received: function(xhr) {
        setDefaultLang(options.moodle);
      }
    });
    return this;
  };

  // Retorna a linguagem do moodle
  var setDefaultLang = function(options) {
    options.type = "HEAD";
    ajax(options);
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
        var time = row["Time"].split(", ");
        processRow(data, {
          context: "Course: "+row["Course"].trim(),
          user: row["User full name"].trim(),
          component: action.split(" ")[0].trim(),
          action: action,
          information: row["Information"].trim(),
          date: time[0].trim(),
          hour: time[1].trim()
        }, ["context", "user", "component", "action", "information", "date", "hour"]);
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
        var time = row["Time"].split(", ");
        processRow(data, {
          context: row["Event context"].trim(),
          user: row["User full name"].trim(),
          component: row["Component"].trim(),
          action: row["Event name"].trim(),
          information: row["Description"].trim(),
          date: time[0].trim(),
          hour: time[1].trim()
        }, ["context", "user", "component", "action", "information", "date", "hour"]);
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
  
  // Adiciona no array se não existir e retorna o indice sempre
  var addInArray = function(array, key, value, obj) {
    for (var i = 0; i < array.length; i++) {
      if (array[i][key] == value) {
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
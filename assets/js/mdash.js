(function(global, d3) {
  "use strict";
  
  var mdash = {};
  
  mdash.listOfActions = function(data) {
    var result = {"name": "Actions", "children": []};
    
    data.forEach(function(context) {
      context.users.forEach(function(us) {
        us.components.forEach(function(comp) {
          var i = result.children.findIndex(function(node) {
              return node.name === comp.component;
          });
          if(i === -1) {  
            i += result.children.push({
              "name": comp.component,
              "children": []
            }); 
          }
          comp.actions.forEach(function(act) {
            var j = result.children[i].children.findIndex(function(node) {
              return node.name === act.action;
            });
            if(j === -1) {
              j += result.children[i].children.push({
                "name": act.action,
                "size": 0
              });
            }
            act.informations.forEach(function(inf) {
              result.children[i].children[j].size += inf.interactions.length;
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
      context.users.forEach(function(us) {
        var i = result.findIndex(function(node) {
          return node.name === us.user;
        });
        if(i === -1) {
          i += result.push({
            "name": us.user,
            "size": 0
          }); 
        }
        us.components.forEach(function(comp) {
          comp.actions.forEach(function(act) {
            act.informations.forEach(function(inf) {
              result[i].size += inf.interactions.length;
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
      url: options.url,
      data: {
            "id": options.course,             // ID do curso
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
        setDefaultLang(options);
        if (options.fail instanceof Function) {
          options.fail({
            type: 0,
            message: xhr.statusText
          });
        }
      },
      received: function(xhr) {
        setDefaultLang(options);
      }
    });
    return this;
  };

  // Retorna a linguagem do moodle
  var setDefaultLang = function(options) {
    ajax({
      url: options.url,
      data: {
        "id": options.course,
        "lang": options.lang
      }
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
        data = processData({
          data: data,
          context: "Course: "+row["Course"].trim(),
          user: row["User full name"].trim(),
          component: action.split(" ")[0].trim(),
          action: action,
          information: row["Information"].trim(),
          time: row["Time"].trim()
        });
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
        data = processData({
          data: data,
          context: row["Event context"].trim(),
          user: row["User full name"].trim(),
          component: row["Component"].trim(),
          action: row["Event name"].trim(),
          information: row["Description"].trim(),
          time: row["Time"].trim(),
          affecteduser: row["Affected user"].trim()
        });
      }, this);

      return data;
    })(csv);
  };
  
  // Processa os dados do TSV/CSV
  var processData = function(options) {
    var i = options.data.findIndex(function(node) {
      return node.context === options.context;
    });

    if (i === -1) {
      i += options.data.push({
        "context": options.context, "users": []
      });
    }

    var j = options.data[i].users.findIndex(function(node) {
      return node.user === options.user;
    });

    if (j === -1) {
      j += options.data[i].users.push({
        "user": options.user, "components": []
      });
    }

    var k = options.data[i].users[j].components.findIndex(function(node) {
      return node.component === options.component;
    });

    if (k === -1) {
      k += options.data[i].users[j].components.push({
        "component": options.component, "actions": []
      });
    }

    var l = options.data[i].users[j].components[k].actions
    .findIndex(function(node) {
      return node.action === options.action;
    });

    if (l === -1) {
      l += options.data[i].users[j].components[k].actions.push({
        "action": options.action, "informations": []
      });
    }

    var m = options.data[i].users[j].components[k].actions[l].informations
    .findIndex(function(node) {
      return node.information === options.information;
    });

    if (m === -1) {
      m += options.data[i].users[j].components[k].actions[l].informations.push({
        "information": options.information, interactions: []
      });
    }

    options.data[i].users[j].components[k].actions[l].informations[m]
    .interactions.push({
      "time": options.time,
      "affecteduser": (options.affecteduser !== undefined &&
      options.affecteduser !== "-") ? options.affecteduser : ""
    });

    return options.data;
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
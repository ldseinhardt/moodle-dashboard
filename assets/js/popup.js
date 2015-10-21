(function(chrome, $, mdash, graph) {
  "use strict";

  /* Objetos do DOM */
  var
    DRAWER      = $(".mdl-layout__drawer")[0],
    SPINNER     = $("#spinner"),
    CARD_ALL    = $(".mdl-card"),
    CARD_SYNC   = $("#card-sync"),
    CARD_USER   = $("#card-user"),
    CARD_TIME   = $("#card-time"),
    CARD_GRAPH  = $("#card-graph"),
    BTN_SYNC    = $(".btn-sync"),
    BTN_USER    = $(".btn-user"),
    BTN_TIME    = $(".btn-time"),
    BTN_CONF    = $(".btn-conf"),
    BTN_GRAPH_1 = $(".btn-graph-1"),
    BTN_GRAPH_2 = $(".btn-graph-2");

  /**
   * Start: Verifica se há alguma sincronização,
   * se existir mostra o gráfico padrão
   */

  // Manipula dados sincronizados
  var getData = function(title, done) {
    chrome.storage.local.get({
      data: null,
      user: null,
      time: null,
      sync: false
    }, function(items) {
      if (items.sync && items.data && items.user && items.time) {
        if (done instanceof Function) {
          
          CARD_ALL.hide();
          $(".mdl-card__title-text", CARD_GRAPH).html(title);
          $(".mdl-card__supporting-text", CARD_GRAPH).html("");
          
          done(items.data, items.user, items.time, {
            context: "#card-graph > .mdl-card__supporting-text"
          });
          
          CARD_GRAPH.show(); 
          
        }
      } else {
        CARD_ALL.hide();
        CARD_SYNC.show();
      }
    });    
  };
  
  // Exibe o gráfico 1 (ações)
  var graph1 = function() {
    getData("Ações", function(data, user, time, options) {
      options.data = mdash.listOfActions(data, user, time);
      options.diameter = 390;
      graph.Bubble(options);
    });    
  };
  
  // Exibe o gráfico 2 (usuários)
  var graph2 = function() {
    getData("Usuários e interações", function(data, user, time, options) {
      options.data = mdash.listOfUsers(data, user, time);
      options.width = 390;
      graph.Bar(options);
    });
  };
  
  var goGraph = function() {
    switch (location.hash) {
      case "#2":
        graph2();
        break;
      default:
        graph1();
    }
  };
  
  goGraph();

  /**
   * Global: Em todas as páginas
   */
   
  // Botão de sincronização
  BTN_SYNC.click(function() {
    var sendMessage = function(message) {
      $(".error-message", CARD_SYNC).remove();
      $(".mdl-card__supporting-text", CARD_SYNC).append("<p class=\"error-message\" style=\"color: red\">" + message + "</p>");
      CARD_SYNC.show();
    };
    
    chrome.storage.local.get({
      url: "",
      course: 0,
      lang: "en"
    }, function(items) {
      if (items.url !== "" && items.course !== 0) {
        mdash.sync({
          url: items.url,
          course: items.course,
          lang: items.lang,
          init: function() {
            CARD_ALL.hide();
            SPINNER.show();
          },
          done: function(data) {
            chrome.storage.local.set({
              data: data,
              user: mdash.uniqueUsers(data),
              time: mdash.uniqueDays(data),
              sync: true
            });
            
            SPINNER.hide();
            
            goGraph();
          },
          fail: function(params) {
            
            SPINNER.hide();
            
            console.log("Error Type: %s", params.type);
            console.log("Error Message: %s", params.message);
            
            sendMessage("Erro ao sincronizar, verifique se você possui uma sessão de professor aberta.");
          }
        });
      } else {
        sendMessage("Erro ao sincronizar, acesse um curso no Moodle por favor.");
      }
    });
  });

  // Botão filtro de usuários
  BTN_USER.click(function() {
    CARD_TIME.hide();
    if (!CARD_USER.is(":visible")) {
      chrome.storage.local.get({
        user: null,
        sync: false
      }, function(items) {
        if (items.sync && items.user) {
          $(".items", CARD_USER).html("");
          items.user.forEach(function(user) {
            var html = "";
            html += "<label class=\"mdl-checkbox mdl-js-checkbox mdl-js-ripple-effect\">";
            html += "  <input type=\"checkbox\" class=\"mdl-checkbox__input\"" + (user.selected ? " checked" : "") + "/>";
            html += "  <span class=\"mdl-checkbox__label\">" + user.name + "</span>";
            html += "</label>";
            $(".items", CARD_USER).append(html);
            upgradeDom();
          });
        }
      });
    }
    CARD_USER.toggle();
  });
  
  $(".action-confirm", CARD_USER).click(function() {
    var listOfUniqueUsers = [];
    $(".mdl-checkbox", CARD_USER).each(function(index, element) {
      listOfUniqueUsers.push({
        name: $(".mdl-checkbox__label", element).html(),
        selected: $(".mdl-checkbox__input", element).prop("checked")
      });
    });
    
    chrome.storage.local.set({
      user: listOfUniqueUsers
    });
    
    CARD_USER.hide();
    
    goGraph();
  });
  
  $(".action-select-all", CARD_USER).click(function() {
      
  });
  
  $(".action-invert", CARD_USER).click(function() {
      
  });

  // Botão filtro de período
  BTN_TIME.click(function() {
    CARD_USER.hide();
    if (!CARD_TIME.is(":visible")) {
      chrome.storage.local.get({
        time: null,
        sync: false
      }, function(items) {
        if (items.sync && items.time) {
          
          $("input", CARD_TIME).first()
            .attr("min", items.time.min.value)
            .attr("max", items.time.max.value)
            .attr("value", items.time.min.selected)
            .change(function() {
              $(this).attr("value", this.value);
            });
            
          $("input", CARD_TIME).last()
            .attr("min", items.time.min.value)
            .attr("max", items.time.max.value)
            .attr("value", items.time.max.selected)
            .change(function() {
              $(this).attr("value", this.value);
            });
        }
      });
    }
    CARD_TIME.toggle();
  });
  
  $(".action-confirm", CARD_TIME).click(function() {
    chrome.storage.local.get({
      time: null,
      sync: false
    }, function(items) {
      if (items.sync && items.time) {
        
        var min = $("input", CARD_TIME).first().attr("value");
        var max = $("input", CARD_TIME).last().attr("value");
        
        if (new Date(Date.parse(min)) - new Date(Date.parse(max)) <= 0) {
          items.time.min.selected = min;
          items.time.max.selected = max;
          chrome.storage.local.set({
            time: items.time
          });
        }
            
        CARD_TIME.hide();
    
        goGraph();
      }
    });
  });
  
  $("a", DRAWER).click(function() {
    DRAWER.classList.toggle("is-visible");
  });
  
  BTN_GRAPH_1.click(graph1);
  
  BTN_GRAPH_2.click(graph2);
  
  var upgradeDom = function() {
    // Expand all new MDL elements
    componentHandler.upgradeDom(); 
  };
  
})(this.chrome, this.jQuery, this.mdash, this.graph);
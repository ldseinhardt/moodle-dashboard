(function(chrome, $, mdash, graph) {
  "use strict";

  /* Objetos do DOM */
  var
    DRAWER     = $(".mdl-layout__drawer")[0],
    SPINNER    = $("#spinner"),
    CARD_ALL   = $(".mdl-card"),
    CARD_SYNC  = $("#card-sync"),
    CARD_USER  = $("#card-user"),
    CARD_TIME  = $("#card-time"),
    CARD_GRAPH = $("#card-graph"),
    BTN_SYNC   = $(".btn-sync"),
    BTN_USER   = $(".btn-user"),
    BTN_TIME   = $(".btn-time"),
    BTN_CONF   = $(".btn-conf"),
    BTN_GRAPH  = $(".btn-graph");

  /**
   * Start: Verifica se há alguma sincronização,
   * se existir mostra o gráfico padrão
   */

  // Exibe o gráfico apropriado
  var showGraph = function(hash) {
    var title, callback;
    
    switch (hash || location.hash) {
      case "#2":
        title = "Usuários e interações";
        callback = function(data, user, time, options) {
          options.data = mdash.listOfUsers(data, user, time);
          options.width = 390;
          graph.Bar(options);
        };
        break;
      default:
        title = "Ações";
        callback = function(data, user, time, options) {
          options.data = mdash.listOfActions(data, user, time);
          options.diameter = 390;
          graph.Bubble(options);
        };
    }
    
    chrome.storage.local.get({
      data: null,
      user: null,
      time: null,
      sync: false
    }, function(items) {
      if (items.sync && items.data && items.user && items.time) {
          CARD_ALL.hide();
          $(".mdl-card__title-text", CARD_GRAPH).html(title);
          $(".mdl-card__supporting-text", CARD_GRAPH).html("");
          
          callback(items.data, items.user, items.time, {
            context: "#card-graph > .mdl-card__supporting-text"
          });
          
          CARD_GRAPH.show();
      } else {
        CARD_ALL.hide();
        CARD_SYNC.show();
      }
    }); 
  };
  
  showGraph();

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
            
            showGraph();
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
    
    showGraph();
  });
  
  $(".action-select-all", CARD_USER).click(function() {
     $(".mdl-checkbox", CARD_USER).each(function(index, element) {
      element.MaterialCheckbox.check();
     });
  });
  
  $(".action-invert", CARD_USER).click(function() {
     $(".mdl-checkbox", CARD_USER).each(function(index, element) {
       if ($(".mdl-checkbox__input", element).prop("checked")) {
        element.MaterialCheckbox.uncheck();
       } else {
        element.MaterialCheckbox.check();
       }
     });
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
            .prop("min", items.time.min.value)
            .prop("max", items.time.max.value)
            .prop("value", items.time.min.selected);
            
          $("input", CARD_TIME).last()
            .prop("min", items.time.min.value)
            .prop("max", items.time.max.value)
            .prop("value", items.time.max.selected);
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
        
        var min = $("input", CARD_TIME).first().prop("value");
        var max = $("input", CARD_TIME).last().prop("value");
        
        if (new Date(Date.parse(min)) - new Date(Date.parse(max)) <= 0) {
          items.time.min.selected = min;
          items.time.max.selected = max;
          chrome.storage.local.set({
            time: items.time
          });
        }
            
        CARD_TIME.hide();
    
        showGraph();
      }
    });
  });
  
  $("a", DRAWER).click(function() {
    DRAWER.classList.toggle("is-visible");
  });
  
  BTN_GRAPH.click(function() {
    showGraph($(this).attr("href"));
  });
  
  var upgradeDom = function() {
    // Expand all new MDL elements
    componentHandler.upgradeDom(); 
  };
  
})(this.chrome, this.jQuery, this.mdash, this.graph);
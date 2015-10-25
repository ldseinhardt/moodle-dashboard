(function(chrome, $, dash, graph, componentHandler) {
  "use strict";

  /* Objetos do DOM */
  var
    DRAWER          = $(".mdl-layout__drawer")[0],
    SPINNER         = $("#spinner"),
    CARD_ALL        = $(".mdl-card"),
    CARD_SYNC       = $("#card-sync"),
    CARD_SYNC_LIST  = $("#card-sync-list"),
    CARD_USER       = $("#card-user"),
    CARD_TIME       = $("#card-time"),
    CARD_CONF       = $("#card-conf"),
    CARD_GRAPH      = $("#card-graph"),
    BTN_SYNC        = $(".btn-sync"),
    BTN_SYNC_COURSE = $(".btn-sync-course"),
    BTN_USER        = $(".btn-user"),
    BTN_TIME        = $(".btn-time"),
    BTN_CONF        = $(".btn-conf"),
    BTN_PAGE        = $(".btn-page");
    
  // Exibe o gráfico apropriado
  var showPage = function(hash) {
    var showGraph = function(title, callback) {
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
              context: "#card-graph > .mdl-card__supporting-text",
              size: $("#card-graph").innerWidth() * 0.91
            });
            
            CARD_GRAPH.show();
        } else {
          CARD_ALL.hide();
          CARD_SYNC.show();
        }
      });
    };
    
    switch ((hash || location.hash).replace("#", "")) {
      case "config":
        CARD_ALL.hide();
        CARD_CONF.show();
        break;
      case "2":
        showGraph("Usuários e interações", function(data, user, time, options) {
          options.data = dash.listOfUsers(data, user, time);
          graph.Bar(options);
        });
        break;
      default:
        showGraph("Ações", function(data, user, time, options) {
          options.data = dash.listOfActions(data, user, time);
          options.size = 430;
          graph.Bubble(options);
        });
    }
  };
  
  showPage();

  var sendErrorMessage = function(message) {
    $(".error-message", CARD_SYNC).remove();
    $(".mdl-card__supporting-text", CARD_SYNC).append("<p class=\"error-message\" style=\"color: red\">" + message + "</p>");

    CARD_ALL.hide();
    CARD_SYNC.show();
  };

  // Botão de sincronização
  BTN_SYNC.click(function() {
    var listCourses = function(data) {
      $(".items", CARD_SYNC_LIST).html("");

      data.forEach(function(course) {
        var html = "";
        html += "<label class=\"mdl-radio mdl-js-radio mdl-js-ripple-effect\">";
        html += "  <input type=\"radio\" class=\"mdl-radio__button\" name=\"course\" value=\"" + course.id + "\"/>";
        html += "  <span class=\"mdl-radio__label\">" + course.name + "</span>";
        html += "</label><br/>";
        $(".items", CARD_SYNC_LIST).append(html);
        upgradeDom();
      });

      $(".mdl-radio", CARD_SYNC_LIST)[0].MaterialRadio.check();

      CARD_ALL.hide();
      CARD_SYNC_LIST.show();
    };

    chrome.tabs.getSelected(null, function(tab) {
      if (tab.url.indexOf("chrome://") === -1 && tab.url.indexOf("chrome-extension://") === -1) {
        SPINNER.show();

        dash.moodle(tab.url, function(response) {
          if (response.hasOwnProperty("error")) {
            switch (response.error) {
              case 1:
                SPINNER.hide();
                sendErrorMessage("Erro ao sincronizar, acesse o Moodle.");
                break;
              case 2:
                SPINNER.hide();
                sendErrorMessage("Erro ao sincronizar, verifique se você está logado ao Moodle.");
                break;
            }
          } else {
            SPINNER.hide();

            listCourses(response.courses);

            chrome.storage.local.set(response);
          }
        });
      } else {
        chrome.storage.local.get({
          courses: null
        }, function(items) {
          if (items.courses) {
            listCourses(items.courses);
          } else {
            sendErrorMessage("Erro ao sincronizar, acesse o Moodle.");
          }
        });
      }
    });
  });

  BTN_SYNC_COURSE.click(function() {
    chrome.storage.local.get({
      url: null,
      lang: "en"
    }, function(items) {
      if (items.url) {
        dash.sync({
          url: items.url,
          course: $(".mdl-radio__button:checked", CARD_SYNC_LIST).val(),
          lang: items.lang,
          init: function() {
            CARD_ALL.hide();
            SPINNER.show();
          },
          done: function(data) {
            chrome.storage.local.set({
              data: data,
              user: dash.uniqueUsers(data),
              time: dash.uniqueDays(data),
              sync: true
            });
            
            SPINNER.hide();
            
            showPage();
          },
          fail: function(params) {            
            SPINNER.hide();
            
            console.log("Error Type: %s", params.type);
            console.log("Error Message: %s", params.message);
            
            sendErrorMessage("Erro ao sincronizar, verifique se você esta logado ao Moodle como professor.");
          }
        });
      } else {
        sendErrorMessage("Erro ao sincronizar, acesse o Moodle.");
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
  
  // Ação confirmar alterações na lista de usuários
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
    
    showPage();
  });
  
  // Ação selecionar todos usuários
  $(".action-select-all", CARD_USER).click(function() {
     $(".mdl-checkbox", CARD_USER).each(function(index, element) {
      element.MaterialCheckbox.check();
     });
  });
  
  // Ação inverter usuários selecionados
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
  
  // Ação confirmar alteração no período
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
    
        showPage();
      }
    });
  });
  
  // Fecha o drawer quando houver o clique em uma opção
  $("a", DRAWER).click(function() {
    DRAWER.classList.toggle("is-visible");
  });
  
  // Botão para seleção de página
  BTN_PAGE.click(function() {
    showPage($(this).attr("href"));
  });
  
  // Expande os elementos do MDL
  var upgradeDom = function() {
    componentHandler.upgradeDom(); 
  };
  
  $(window).resize(function() {
    showPage();
  });
  
})(this.chrome, this.jQuery, this.dash, this.graph, this.componentHandler);
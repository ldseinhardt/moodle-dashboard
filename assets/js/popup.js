(function(chrome, $, mdash, graph) {
  "use strict";

  /**
   * Start: Verifica se há alguma sincronização,
   * se existir mostra o gráfico padrão
   */
   
  chrome.storage.local.get({
    sync: false,
  }, function(items) {
    if (items.sync) {
      graph1();
    } else {
      $(".mdl-card").hide();
      $("#card-message-sync").show();
    }
  });
  
  var graph1 = function() {
    chrome.storage.local.get({
      data: null,
      sync: false
    }, function(items) {
      if (items.sync && items.data) {
        //Chama a visualização da tela apropriada
        //console.log(items.data);
        //console.log("listOfActions");
        var listOfActions = mdash.listOfActions(items.data);
        //console.log(listOfActions);
        
        $(".mdl-card").hide();
        $(".mdl-card__title-text", "#card-graph").html("Ações");
        $("#card-graph > .mdl-card__supporting-text").html("");
  
        graph.Bubble({
          data: listOfActions,
          context: "#card-graph > .mdl-card__supporting-text",
          diameter: 400
        });
  
        $("#card-graph").show();
      }
    });    
  };
  
  var graph2 = function() {
    chrome.storage.local.get({
      data: null,
      sync: false
    }, function(items) {
      if (items.sync && items.data) {
        //Chama a visualização da tela apropriada
        //console.log("listOfUsers");
        var listOfUsers = mdash.listOfUsers(items.data);
        //console.log(listOfUsers);
        
        $(".mdl-card").hide();
        $(".mdl-card__title-text", "#card-graph").html("Usuários e interações");
        $("#card-graph > .mdl-card__supporting-text").html("");
  
        graph.Bar({
          data: listOfUsers,
          context: "#card-graph > .mdl-card__supporting-text",
          width: 400
        });
  
        $("#card-graph").show();
      }
    });    
  };

  /**
   * Global: Em todas as páginas
   */
   
  // Botão de sincronização
  $(".btn-sync").click(function() {
    var sendMessage = function(message) {
      var message = $("#card-message-sync");
      $(".error-message", message).remove();
      $(".mdl-card__supporting-text", message).append("<p class=\"error-message\" style=\"color: red\">" + message + "</p>");
      message.show();
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
            $(".mdl-card").hide();
            $("#spinner").show();
          },
          done: function(data) {
            chrome.storage.local.set({
              data: data,
              user: mdash.uniqueUsers(data),
              time: mdash.uniqueDays(data),
              sync: true
            });
            
            $("#spinner").hide();
            
            graph1();
          },
          fail: function(params) {
            
            $("#spinner").hide();
            
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
  $(".btn-users").click(function() {
    $("#card-filter-time").hide();
    
    var users = $("#card-filter-users");
    
    $(".items", users).html("");

    chrome.storage.local.get({
      user: null,
      sync: false
    }, function(items) {
      if (items.sync && items.user) {
        items.user.forEach(function(user) {
          var html = "";
          html += "<label class=\"mdl-checkbox mdl-js-checkbox mdl-js-ripple-effect\">";
          html += "  <input type=\"checkbox\" class=\"mdl-checkbox__input\"" + (user.selected ? " checked" : "") + "/>";
          html += "  <span class=\"mdl-checkbox__label\">" + user.name + "</span>";
          html += "</label>";
          $(".items", "#card-filter-users").append(html);
          upgradeDom();
        });
      }
    });     
    
    users.toggle();
  });
  
  $("#filter_users_save").click(function() {
    var listOfUniqueUsers = [];
    $("label.mdl-checkbox", "#card-filter-users").each(function(index, element) {
      listOfUniqueUsers.push({
        name: $("span.mdl-checkbox__label", element).html(),
        selected: $("input.mdl-checkbox__input", element).prop("checked")
      });
    });
    
    chrome.storage.local.set({
      user: listOfUniqueUsers
    });
    
    $("#card-filter-users").hide();
  });

  // Botão filtro de período
  $(".btn-time").click(function() {
    $("#card-filter-users").hide();
    $("#card-filter-time").toggle();
  });
  
  var drawer = $(".mdl-layout__drawer")[0];
  
  $("a", drawer).click(function() {
    drawer.classList.toggle("is-visible");
  });
  
  $(".btn-graph-1").click(function() {
    graph1();
  });
  
  $(".btn-graph-2").click(function() {
    graph2();
  });
  
  var upgradeDom = function() {
    // Expand all new MDL elements
    componentHandler.upgradeDom(); 
  };
  
})(this.chrome, this.jQuery, this.mdash, this.graph);
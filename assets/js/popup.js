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
      data: "",
      sync: false
    }, function(items) {
      if (items.sync && items.data !== "") {
        //Chama a visualização da tela apropriada
        console.log("listOfActions");
        var listOfActions = mdash.listOfActions(items.data);
        console.log(listOfActions);
        
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
      data: "",
      sync: false
    }, function(items) {
      if (items.sync && items.data !== "") {
        //Chama a visualização da tela apropriada
        console.log("listOfUsers");
        var listOfUsers = mdash.listOfUsers(items.data);
        console.log(listOfUsers);
        
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
    chrome.storage.local.get({
      url: "",
      course: 0,
      lang: "en"
    }, function(items) {
      if (items.url !== "" && items.course !== 0) {
        mdash.sync({
          moodle: {
            url: items.url + "/report/log/index.php",
            data: {
              id: items.course,
              lang: items.lang
            }
          },
          init: function() {
            $(".mdl-card").hide();
            $("#spinner").show();
          },
          done: function(data) {
            chrome.storage.local.set({
              data: data,
              sync: true
            });
            
            $("#spinner").hide();
            graph1();
          },
          fail: function(params) {
            $("#spinner").hide();
            console.log("Error Type: %s", params.type);
            console.log("Error Message: %s", params.message);
            $(".error-message", "#card-message-sync").remove();
            $("#card-message-sync").show();
            $(".mdl-card__supporting-text", "#card-message-sync").append("<p class=\"error-message\" style=\"color: red\">Erro ao sincronizar, verifique se você possui uma sessão de professor aberta.</p>");
          }
        });
      } else {
        $(".error-message", "#card-message-sync").remove();
        $(".mdl-card__supporting-text", "#card-message-sync").append("<p class=\"error-message\" style=\"color: red\">Erro ao sincronizar, acesse um curso no Moodle por favor.</p>");
      }
    });
  });

  // Botão filtro de usuários
  $(".btn-users").click(function() {
      if($("#card-filter-users").length) {
        $("#card-filter-time").hide();
        $("#card-filter-users").toggle();
      }
  });

  // Botão filtro de período
  $(".btn-time").click(function() {
      if($("#card-filter-time").length) {
        $("#card-filter-users").hide();
        $("#card-filter-time").toggle();
      }
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
  
})(this.chrome, this.jQuery, this.mdash, this.graph);
(function(chrome, $, mdash) {
  "use strict";

  /**
   * Start: Verifica se há alguma sincronização
   */
   
  chrome.storage.local.get({
    sync: false,
  }, function(items) {
    if (!items.sync) {
      if($("#card-message-sync").length) {
        $(".mdl-card").hide();
        $("#card-message-sync").show();
      }
    }
  });

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
            
            location.reload();
          },
          fail: function(params) {
            $("#spinner").hide();
            console.log("Error Type: %s", params.type);
            console.log("Error Message: %s", params.message);
          }
        });
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
  
})(this.chrome, this.jQuery, this.mdash);
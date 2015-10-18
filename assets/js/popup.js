(function(chrome, $, mdash) {
  "use strict";

  /**
   * Informações do Moodle (url, curso, linguagem)
   */
   
  chrome.tabs.getSelected(null, function(tab) {
    var a = document.createElement("a");
    a.href = tab.url;
    var regex = new RegExp("[\\?&]id=([^&#]*)");
    var regid = regex.exec(a.search);
    var course = (regid === null) ? 0 : parseInt(regid[1]);

    if (course > 0) {

      var paths = a.pathname.split("/").filter(function(path) {
        return path.indexOf(".") === -1;
      });
      
      for (var i = paths.length; i > 0; i--) {
        (function(url) {
          $.ajax({
            type: 'HEAD',
            url: url + "/report/log/index.php?id=" + course,
            success: function() {
              chrome.storage.local.set({
                url: url,
                course: course
              });

              chrome.tabs.sendMessage(tab.id, {type: "GET", command: "lang"}, function(response) {
                if (response && response.moodle) {
                  chrome.storage.local.set({
                    lang: response.moodle.lang
                  });
                }
              });              
            }   
          });
        })(a.protocol + "//" + a.host + paths.join("/"));
        paths.pop();
      }
    }
  });

  /**
   * Monitor de armazenamento
   */

  chrome.storage.onChanged.addListener(function(changes, namespace) {
    for (var key in changes) {
      console.log(key + " := " + changes[key].newValue);
    }
  });

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
      console.log(items);
      
      if (items.url !== "" && items.course !== 0) {
        console.log("sync true");
        mdash.sync({
          moodle: {
            url: items.url + "/report/log/index.php",
            data: {
              course: items.course,
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
            
            //$("#spinner").hide();
            
            location.reload();
          },
          fail: function(params) {
            $("#spinner").hide();
            console.log("Error Type: " + params.type);
            console.log("Error Message: " + params.message);
          }
        });
      }
      console.log("sync");
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
(function(chrome, $) {
  "use strict";

  // Verifica a url do moodle
  chrome.storage.local.get({
    url: "http://demo.moodle.net/"
  }, function(items) {
    $("#config_moodle_url").val(items.url);
  });
  
  // Salva a url do moodle
  $("#config_save").click(function() {
    chrome.storage.local.set({
      url: $("#config_moodle_url").val()
    }, function() {
      $("#config_status").html("Configurações salvas!");
    });
  });
})(this.chrome, this.jQuery);
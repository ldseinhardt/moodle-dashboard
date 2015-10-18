(function(chrome, $) {
  "use strict";

  // Verifica a url do moodle
  chrome.storage.sync.get({
    moodle_url: "http://demo.moodle.net/"
  }, function(items) {
    $("#config_moodle_url").val(items.moodle_url);
  });
  
  // Salva a url do moodle
  $("#config_save").click(function() {
    chrome.storage.sync.set({
      moodle_url: $("#config_moodle_url").val()
    }, function() {
      $("#config_status").html("Configurações salvas!");
    });
  });
})(this.chrome, this.jQuery);
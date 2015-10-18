(function(chrome, $, mdash) {
  "use strict";

  /**
   * Informações do Moodle
   */

  chrome.tabs.getSelected(null, function(tab) {
    var a = document.createElement("a");
    a.href = tab.url;
    var regex = new RegExp("[\\?&]id=([^&#]*)");
    var regid = regex.exec(a.search); 
    chrome.storage.sync.set({
      url: tab.url,
      moodle_course: (regid === null) ? 0 : parseInt(regid[1])
    });

    chrome.tabs.sendMessage(tab.id, {type: "GET", command: "lang"}, function(response) {
      if (response && response.moodle) {
        chrome.storage.sync.set({
          moodle_lang: response.moodle.lang
        });
      }
    });
  });

  /**
   * Monitor de armazenamento
   */

  chrome.storage.onChanged.addListener(function(changes, namespace) {
    for (var key in changes) {
      console.log("Novo valor: "+changes[key].newValue);
      switch (key) {
        //case "moodle_url":
          //console.log(changes[key].newValue);
        //  break;  
      }
    }
  });

  /**
   * Start
   */
  chrome.storage.local.get({
    moodle_sync: false,
  }, function(items) {
    if (!items.moodle_sync) {
      if($("#card-message-sync").length) {
        $(".mdl-card").hide();
        $("#card-message-sync").show();
      }
    }
  });

  /**
   * Global
   */

  $(".btn-sync").click(function() {
    chrome.storage.sync.get({
      url: "",
      moodle_url: "",
      moodle_course: 0,
      moodle_lang: "en"
    }, function(items) {
      console.log(items.url);
      console.log(items.moodle_url);
      console.log(items.moodle_course);
      console.log(items.moodle_lang);
      if (items.url !== "" && items.moodle_url !== "" && items.moodle_course !== 0 && items.url.indexOf(items.moodle_url) > -1) {
        console.log("sync true");
        mdash.sync({
          url: items.moodle_url+"/report/log/index.php",
          course: items.moodle_course,
          lang: items.moodle_lang,
          init: function() {
            $(".mdl-card").hide();
            $("#spinner").show();
          },
          done: function(data) {
            chrome.storage.local.set({
              moodle_data: data,
              moodle_sync: true
            });
            
            $("#spinner").hide();
            
            chrome.storage.local.get({
              moodle_data: "",
              moodle_sync: false
            }, function(items) {
              console.log(items.moodle_sync);
              console.log(items.moodle_data);
            });
            
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

  $(".btn-users").click(function() {
      if($("#card-filter-users").length) {
        $("#card-filter-time").hide();
        $("#card-filter-users").toggle();
      }
  });

  $(".btn-time").click(function() {
      if($("#card-filter-time").length) {
        $("#card-filter-users").hide();
        $("#card-filter-time").toggle();
      }
  });

})(this.chrome, this.jQuery, this.mdash);
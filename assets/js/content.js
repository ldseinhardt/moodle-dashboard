(function(chrome) {
  "use strict";
  
  chrome.extension.onMessage.addListener(
    function(request, sender, sendResponse) {
      if (request.type && request.command) {
        if (request.type === "GET") {
          if (request.command === "lang") {
            sendResponse({ 
              moodle: {
                lang: document.querySelector("html").lang.replace("-", "_")
              } 
            }); 
          }
        }
      }
    }
  ); 
})(this.chrome);
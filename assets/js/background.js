(function(chrome) {
  'use strict';

  chrome.runtime.onMessage.addListener(function (request) {
    if (request) {
      switch (request.cmd) {
        case 'GET':
          chrome.storage.local.get({
            moodle: null
          }, function(items) {
            chrome.runtime.sendMessage({
              moodle: items.moodle
            });
          });
          break;
        case 'SET':
          chrome.storage.local.set({
            moodle: request.moodle
          });
          break;
      }
    }
  });

})(this.chrome);
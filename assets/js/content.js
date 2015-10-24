(function(chrome, ajax) {
  "use strict";

  /**
   * Informações do Moodle (url, curso, linguagem)
   */
   
  var regex = new RegExp("[\\?&]id=([^&#]*)");
  var regid = regex.exec(location.search);
  var course = (regid === null) ? 0 : parseInt(regid[1]);

  if (course > 0) {

    var paths = location.pathname.split("/").filter(function(path) {
      return path.indexOf(".") === -1;
    });
    
    var lang = document.querySelector("html").lang.replace("-", "_");
    
    for (var i = paths.length; i > 0; i--) {
      (function(url) {
        ajax({
          url: url + "/report/log/index.php?id=" + course,
          type: 'HEAD',
          success: function() {
            chrome.storage.local.set({
              url: url,
              course: course,
              lang: lang
            });
          }   
        });
      })(location.protocol + "//" + location.host + paths.join("/"));
      paths.pop();
    }
  }
  
})(this.chrome, this.ajax);
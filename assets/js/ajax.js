(function(global) {
  "use strict";
  
  /**
   * Ajax para realização de requisições
   * @param options { url, [data, type, success, error, progress, received, complete] }
   */
  
  var ajax = function(options) {
    var data = "";
    
    if (options.data instanceof Object) {
      data = "?" + Object.keys(options.data).map(function(key) {
        return key + '=' + options.data[key];
      }).join('&');
    }
    
    var xhr = new XMLHttpRequest();
    
    xhr.onprogress = function(event) {
      if (options.progress instanceof Function) {
        options.progress(event);
      }
    };
    
    xhr.open(options.type || "GET", options.url + data, true);
    
    xhr.onreadystatechange = function() {
      switch (xhr.readyState) {
        case 2:
          if (options.received instanceof Function) {
            options.received(xhr);
          }
          break;
        case 4:
          var f = (xhr.status === 200)
            ? options.success
            : options.error;
          if (f instanceof Function) {
            f(xhr);
          }
          if (options.complete instanceof Function) {
            options.complete(xhr);
          }
      }
    };
    
    xhr.send();
  };  
  
  if (global) {
    global.ajax = ajax;
  }

})(this);
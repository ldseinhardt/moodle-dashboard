(function(global) {
  'use strict';

  /**
   * =========================================================================
   * Helper functions
   * =========================================================================
   */

  /**
   * Query selector
   */

  function $(selector, e) {
    if (!e) {
      e = document;
    }
    var n = e.querySelectorAll(selector);
    return (n.length > 1)
      ? Array.prototype.slice.call(n)
      : n[0];
  }

  /**
   * Enumerator
   */

  function Enum(keys) {
    var e = {};
    for (var i = 0; i < keys.length; i++) {
      e[keys[i]] = i;
    }
    return e;
  }

  /**
   * Show element
   */

  Element.prototype.show = function() {
    this.style.display = 'block';
  };

  /**
   * Hide element
   */

  Element.prototype.hide = function() {
    this.style.display = 'none';
  };

  /**
   * Set/Get html
   */

  Element.prototype.html = function(html) {
    if (html !== undefined) {
      this.innerHTML = html;
    }
    return this.innerHTML;
  };

  /**
   * Hide all elements of array
   */

  Array.prototype.hide = function() {
    if (this[0] instanceof Element) {
      this.forEach(function(e) {
        e.hide();
      }); 
    }
  };

  /**
   * Add Event Listener to all elements of array
   */

  Array.prototype.addEventListener = function(evt, callback) {
    if (this[0] instanceof Element) {
      this.forEach(function(e) {
        e.addEventListener(evt, callback);
      });
    }
  };

  /**
   * =========================================================================
   * Exports
   * =========================================================================
   */

  if (global) {
    global.$ = $;
    global.Enum= Enum;
  }

})(this);
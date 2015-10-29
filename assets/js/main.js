(function(chrome, mdash, graph) {
  'use strict';

  var init = (function() {
    /* Principais elementos de interface */
    var DRAWER                 = $('.mdl-layout__drawer')
      , DRAWER_LINKS           = $('a', DRAWER)
      , SPINNER                = $('#spinner')
      , CARDS                  = $('.mdl-card')
      , CARD_SYNC              = $('#card-synchronize')
      , CARD_SYNC_BODY         = $('.mdl-card__supporting-text', CARD_SYNC)
      , CARD_SYNC_ERROR        = $('.error-message', CARD_SYNC)
      , CARD_SYNC_COURSE       = $('#card-synchronize-course')
      , CARD_SYNC_COURSE_LIST  = $('.items', CARD_SYNC_COURSE)
      , CARD_SYNC_COURSE_ERROR = $('.error-message', CARD_SYNC_COURSE)
      , CARD_USERS             = $('#card-users')
      , CARD_USERS_LIST        = $('.items', CARD_USERS)
      , CARD_USERS_OK          = $('.action-ok', CARD_USERS)
      , CARD_USERS_SELECT      = $('.action-select-all', CARD_USERS)
      , CARD_USERS_INVERT      = $('.action-invert-selection', CARD_USERS)
      , CARD_DATES             = $('#card-dates')
      , CARD_DATES_FIELDS      = $('input', CARD_DATES)
      , CARD_DATES_OK          = $('.action-ok', CARD_DATES)
      , CARD_SETTINGS          = $('#card-settings')
      , CARD_GRAPHICS          = $('#card-graphics')
      , CARD_GRAPHICS_TITLE    = $('.mdl-card__title-text', CARD_GRAPHICS)
      , CARD_GRAPHICS_BODY     = $('.mdl-card__supporting-text', CARD_GRAPHICS)
      , BTN_SYNC               = $('.btn-synchronize')
      , BTN_SYNC_COURSE        = $('.btn-synchronize-course')
      , BTN_USERS              = $('.btn-users')
      , BTN_DATES              = $('.btn-dates')
      , BTN_SETTINGS           = $('.btn-settings')
      , BTN_PAGE               = $('.btn-page')
      ;

    // i18n
    function __(key, value) {
      return chrome.i18n.getMessage(key, value);
    }

    [
      'app_name',
      'welcome',
      'synchronize',
      'synchronize_message_1',
      'synchronize_message_2',
      'course',
      'course_message',
      'users',
      'users_message',
      'date_range',
      'date_range_message',
      'settings',
      'settings_message',
      'views',
      'actions',
      'users_interactions',
      'ok',
      'select_all',
      'invert_selection'
    ].forEach(function(key) {
      var e = $('.__MSG_' + key + '__');
      if (e) {
        if (e.length) {
          e.forEach(function(e) {
            e.html(__(key));
          });
        } else {
          e.html(__(key));
        }
      }
    });

    // Exibe a página
    function showPage(hash) {
      function showGraph(title, callback) {
        chrome.storage.local.get({
          data: null,
          users: null,
          dates: null
        }, function(items) {
          if (items.data && items.users && items.dates) {
            CARDS.hide();
            CARD_GRAPHICS_TITLE.html(title);
            CARD_GRAPHICS_BODY.html('');
            callback(items.data, items.users, items.dates.selected, {
              context: '#card-graphics > .mdl-card__supporting-text',
              size: window.innerWidth * 0.91
            });
            CARD_GRAPHICS.show();
          } else {
            CARDS.hide();
            CARD_SYNC.show();
          }
        });
      }
      switch ((hash || location.hash).replace('#', '')) {
        case 's':
          CARDS.hide();
          CARD_SETTINGS.show();
          break;
        case '2':
          showGraph(__('users_interactions'), function(data, users, date_range, options) {
            options.data = mdash.listOfUsers(data, users, date_range);
            graph.Bar(options);
          });
          break;
        default:
          showGraph(__('actions'), function(data, users, date_range, options) {
            options.data = mdash.listOfActions(data, users, date_range);
            options.size = 430;
            graph.Bubble(options);
          });
      }
    }

    // Sincroniza um curso do moodle
    function sync(url, course, lang) {
      mdash.sync({
        url: url,
        course: course,
        lang: lang,
        init: function() {
          CARDS.hide();
          SPINNER.show();
        },
        done: function(data) {
          mdash.users(url, course, function(response) {
            if (response.hasOwnProperty('error')) {
              SPINNER.hide();
              switch (response.error) {
                case 1:
                  CARD_SYNC_COURSE_ERROR.html(__('synchronize_error_access'));
                  break;
                case 2:
                  CARD_SYNC_COURSE_ERROR.html(__('synchronize_error_users'));
                  break;
              }
              CARDS.hide();
              CARD_SYNC_COURSE.show();
            } else {
              chrome.storage.local.set({
                data: data,
                users: response,
                dates: mdash.dates(data),
                course: course
              });
              SPINNER.hide();
              showPage();
            }
          });
        },
        fail: function() {
          SPINNER.hide();
          CARD_SYNC_COURSE_ERROR.html(__('synchronize_error_permission'));
          CARD_SYNC_COURSE.show();
        }
      });
    }

    // Botão de sincronização
    BTN_SYNC.addEventListener('click', function() {
      function listCourses(options) {
        var html = '';
        var checked = false;
        options.courses.forEach(function(course, i) {
          html += '<label class="mdl-radio mdl-js-radio mdl-js-ripple-effect">';
          html += '<input type="radio" class="mdl-radio__button" name="course" value="' + course.id + '"';
          if ((options.course + i == 0) || (options.course == course.id)) {
            html += ' checked';
            checked = true;
          }
          html += '/>';
          html += '<span class="mdl-radio__label">' + course.name + '</span>';
          html += '</label><br/>';
        });
        CARD_SYNC_COURSE_LIST.html(html);
        upgradeDom();
        if (!checked) {
          $('.mdl-radio:first-child', CARD_SYNC_COURSE).MaterialRadio.check();
        }
        if (options.courses.length === 1) {
          sync(options.url, options.courses[0].id, options.lang);
        } else {
          CARDS.hide();
          CARD_SYNC_COURSE.show();
        }
      }
      chrome.tabs.getSelected(null, function(tab) {
        if (tab.url.indexOf('chrome://') === -1 && tab.url.indexOf('chrome-extension://') === -1) {
          SPINNER.show();
          mdash.moodle(tab.url, function(response) {
            if (response.hasOwnProperty('error')) {
                SPINNER.hide();
              switch (response.error) {
                case 1:
                  CARD_SYNC_ERROR.html(__('synchronize_error_access'));
                  break;
                case 2:
                  CARD_SYNC_ERROR.html(__('synchronize_error_permission'));
                  break;
              }
              CARDS.hide();
              CARD_SYNC.show();
            } else {
              SPINNER.hide();
              chrome.storage.local.get({
                course: 0
              }, function(items) {
                response.course = items.course;
                listCourses(response);
                chrome.storage.local.set(response);
              });
            }
          });
        } else {
          chrome.storage.local.get({
            url: null,
            lang: null,
            courses: null,
            course: 0
          }, function(items) {
            if (items.url && items.lang && items.courses) {
              listCourses(items);
            } else {
              CARD_SYNC_ERROR.html(__('synchronize_error_access'));
              CARDS.hide();
              CARD_SYNC.show();
            }
          });
        }
      });
    });

    // Botão de sincronização para o curso selecionado
    BTN_SYNC_COURSE.addEventListener('click', function() {
      chrome.storage.local.get({
        url: null,
        lang: 'en'
      }, function(items) {
        if (items.url) {
          sync(items.url, $('.mdl-radio__button:checked', CARD_SYNC_COURSE).value, items.lang);
        } else {
          CARD_SYNC_COURSE_ERROR.html(__('synchronize_error_access'));
        }
      });
    });

    // Botão para seleção de usuários
    BTN_USERS.addEventListener('click', function() {
      CARDS.forEach(function(e) {
        if (e != CARD_USERS) {
          e.hide();
        }
      });
      if (CARD_USERS.style.display === 'none') {
        chrome.storage.local.get({
          users: null
        }, function(items) {
          if (items.users) {
            var html = '';
            items.users.forEach(function(user) {
              html += '<label class="mdl-checkbox mdl-js-checkbox mdl-js-ripple-effect">';
              html += '<input type="checkbox" class="mdl-checkbox__input"' + (user.selected ? ' checked' : '') + '/>';
              html += '<span class="mdl-checkbox__label">' + user.name + '</span>';
              html += '</label>';
            });
            CARD_USERS_LIST.html(html);
            upgradeDom();
            CARD_USERS.show();
          } else {
            CARD_SYNC.show();
          }
        });
      } else {
        CARD_USERS.hide();
        showPage();
      }
    });

    // Botão de confirmação para seleção de usuários
    CARD_USERS_OK.addEventListener('click', function() {
      var users = [];
      var e = $('.mdl-checkbox', CARD_USERS);
      if (!e.length) {
        e = e ? [e] : [];
      }
      e.forEach(function(e) {
        users.push({
          name: $('.mdl-checkbox__label', e).html(),
          selected: $('.mdl-checkbox__input', e).checked
        });
      });
      chrome.storage.local.set({
        users: users
      });
      CARD_USERS.hide();
      showPage();
    });

    // Botão para selecionar todos usuários
    CARD_USERS_SELECT.addEventListener('click', function() {
      var e = $('.mdl-checkbox', CARD_USERS);
      if (!e.length) {
        e = e ? [e] : [];
      }
      e.forEach(function(e) {
        e.MaterialCheckbox.check();
      });
    });

    // Botão para inverter seleção de usuários
    CARD_USERS_INVERT.addEventListener('click', function() {
      var e = $('.mdl-checkbox', CARD_USERS);
      if (!e.length) {
        e = e ? [e] : [];
      }
      e.forEach(function(e) {
        if ($('.mdl-checkbox__input', e).checked) {
          e.MaterialCheckbox.uncheck();
        } else {
          e.MaterialCheckbox.check();
        }
      });
    });

    // Botão para seleção de período
    BTN_DATES.addEventListener('click', function() {
      CARDS.forEach(function(e) {
        if (e != CARD_DATES) {
          e.hide();
        }
      });
      if (CARD_DATES.style.display === 'none') {
        chrome.storage.local.get({
          dates: null
        }, function(items) {
          if (items.dates) {
            CARD_DATES_FIELDS.forEach(function(e, i) {
              e.min = items.dates.min;
              e.max = items.dates.max;
              e.value = items.dates.selected[i === 0 ? 'min' : 'max'];
            });
            CARD_DATES.show();
          } else {
            CARD_SYNC.show();
          }
        });
      } else {
        CARD_DATES.hide();
        showPage();
      }
    });

    // Botão de confimação para seleção de período
    CARD_DATES_OK.addEventListener('click', function() {
      if (new Date(Date.parse(CARD_DATES_FIELDS[0].value)) - new Date(Date.parse(CARD_DATES_FIELDS[1].value)) <= 0) {
        chrome.storage.local.set({
          dates: {
            min: CARD_DATES_FIELDS[0].min,
            max: CARD_DATES_FIELDS[1].max,
            selected: {
              min: CARD_DATES_FIELDS[0].value,
              max: CARD_DATES_FIELDS[1].value
            }
          }
        });
      }
      CARD_DATES.hide();
      showPage();
    });

    // Fecha o drawer ao clicar em um link
    DRAWER_LINKS.addEventListener('click', function() {
      DRAWER.classList.toggle('is-visible');
    });

    // Botão para seleção de página
    BTN_PAGE.addEventListener('click', function() {
      showPage(this.hash);
    });

    // Atualiza o Material Design no DOM
    function upgradeDom() {
      window.componentHandler.upgradeDom();
    }

    // Redimensiona a página de acordo com o tamanho da mesma
    window.addEventListener('resize', function() {
      showPage();
    });

    // Exibe a página padrão
    showPage();
  });
  
  /* Funções auxiliares */

  // Seletor de elemento
  function $(selector, e) {
    if (!e) {
      e = document;
    }
    var n = e.querySelectorAll(selector);
    return (n.length > 1)
      ? Array.prototype.slice.call(n)
      : n[0];
  }

  // Exibe um elemento
  Element.prototype.show = function() {
    this.style.display = 'block';
  };

  // Esconde um elemento
  Element.prototype.hide = function() {
    this.style.display = 'none';
  };

  // Insere ou retorna um elemento html
  Element.prototype.html = function(html) {
    if (html !== undefined) {
      this.innerHTML = html;
    }
    return this.innerHTML;
  };

  // Esconde elementos de uma lista
  Array.prototype.hide = function() {
    if (this[0] instanceof Element) {
      this.forEach(function(e) {
        e.hide();
      }); 
    }
  };

  // Adiciona eventos a elementos de uma lista
  Array.prototype.addEventListener = function(evt, callback) {
    if (this[0] instanceof Element) {
      this.forEach(function(e) {
        e.addEventListener(evt, callback);
      });
    }
  };

  // Inicia a aplicação
  init();

})(this.chrome, this.mdash, this.graph);
(function(chrome, mdash, graph) {
  'use strict';

  var init = (function() {
    /* Principais elementos de interface */
    var DRAWER                 = $('.mdl-layout__drawer')
      , DRAWER_LINKS           = $('a', DRAWER)
      , SPINNER                = $('#spinner')
      , CARDS                  = $('.mdl-card')
      , CARD_SYNC              = $('#card-sync')
      , CARD_SYNC_BODY         = $('.mdl-card__supporting-text', CARD_SYNC)
      , CARD_SYNC_ERROR        = $('.error-message', CARD_SYNC)
      , CARD_SYNC_COURSE       = $('#card-sync-course')
      , CARD_SYNC_COURSE_LIST  = $('.items', CARD_SYNC_COURSE)
      , CARD_SYNC_COURSE_ERROR = $('.error-message', CARD_SYNC_COURSE)
      , CARD_USER              = $('#card-user')
      , CARD_USER_LIST         = $('.items', CARD_USER)
      , CARD_USER_OK           = $('.action-confirm', CARD_USER)
      , CARD_USER_SELECT       = $('.action-select-all', CARD_USER)
      , CARD_USER_INVERT       = $('.action-invert', CARD_USER)
      , CARD_TIME              = $('#card-time')
      , CARD_TIME_FIELDS       = $('input', CARD_TIME)
      , CARD_TIME_OK           = $('.action-confirm', CARD_TIME)
      , CARD_CONF              = $('#card-conf')
      , CARD_GRAPH             = $('#card-graph')
      , CARD_GRAPH_TITLE       = $('.mdl-card__title-text', CARD_GRAPH)
      , CARD_GRAPH_BODY        = $('.mdl-card__supporting-text', CARD_GRAPH)
      , BTNS_SYNC              = $('.btn-sync')
      , BTNS_SYNC_COURSE       = $('.btn-sync-course')
      , BTNS_USER              = $('.btn-user')
      , BTNS_TIME              = $('.btn-time')
      , BTNS_CONF              = $('.btn-conf')
      , BTNS_PAGE              = $('.btn-page')
      ;

    // Exibe a página
    function showPage(hash) {
      function showGraph(title, callback) {
        chrome.storage.local.get({
          data: null,
          user: null,
          time: null
        }, function(items) {
          if (items.data && items.user && items.time) {
            CARDS.hide();
            CARD_GRAPH_TITLE.html(title);
            CARD_GRAPH_BODY.html('');
            callback(items.data, items.user, items.time, {
              context: '#card-graph > .mdl-card__supporting-text',
              size: window.innerWidth * 0.91
            });
            CARD_GRAPH.show();
          } else {
            CARDS.hide();
            CARD_SYNC.show();
          }
        });
      }
      switch ((hash || location.hash).replace('#', '')) {
        case 'config':
          CARDS.hide();
          CARD_CONF.show();
          break;
        case '2':
          showGraph('Usuários e interações', function(data, user, time, options) {
            options.data = mdash.listOfUsers(data, user, time);
            graph.Bar(options);
          });
          break;
        default:
          showGraph('Ações', function(data, user, time, options) {
            options.data = mdash.listOfActions(data, user, time);
            options.size = 430;
            graph.Bubble(options);
          });
      }
    }

    // Botão de sincronização
    BTNS_SYNC.addEventListener('click', function() {
      function listCourses(data) {
        var html = '';
        data.forEach(function(course, i) {
          html += '<label class="mdl-radio mdl-js-radio mdl-js-ripple-effect">';
          html += '<input type="radio" class="mdl-radio__button" name="course" value="' + course.id + '"' + (i === 0 ? ' checked' : '') + '/>';
          html += '<span class="mdl-radio__label">' + course.name + '</span>';
          html += '</label><br/>';
        });
        CARD_SYNC_COURSE_LIST.html(html);
        upgradeDom();
        CARDS.hide();
        CARD_SYNC_COURSE.show();
      }      
      chrome.tabs.getSelected(null, function(tab) {
        if (tab.url.indexOf('chrome://') === -1 && tab.url.indexOf('chrome-extension://') === -1) {
          SPINNER.show();
          mdash.moodle(tab.url, function(response) {
            if (response.hasOwnProperty('error')) {
                SPINNER.hide();
              switch (response.error) {
                case 1:
                  CARD_SYNC_ERROR.html('Erro ao sincronizar, acesse o Moodle.');
                  break;
                case 2:
                  CARD_SYNC_ERROR.html('Erro ao sincronizar, verifique se você está logado ao Moodle.');
                  break;
              }
              CARDS.hide();
              CARD_SYNC.show();
            } else {
              SPINNER.hide();
              listCourses(response.courses);
              chrome.storage.local.set(response);
            }
          });
        } else {
          chrome.storage.local.get({
            courses: null
          }, function(items) {
            if (items.courses) {
              listCourses(items.courses);
            } else {
              CARD_SYNC_ERROR.html('Erro ao sincronizar, acesse o Moodle.');
              CARDS.hide();
              CARD_SYNC.show();
            }
          });
        }
      });
    });

    // Botão de sincronização para o curso selecionado
    BTNS_SYNC_COURSE.addEventListener('click', function() {
      chrome.storage.local.get({
        url: null,
        lang: 'en'
      }, function(items) {
        if (items.url) {
          var course = $('.mdl-radio__button:checked', CARD_SYNC_COURSE).value;
          mdash.sync({
            url: items.url,
            course: course,
            lang: items.lang,
            init: function() {
              CARDS.hide();
              SPINNER.show();
            },
            done: function(data) {
              mdash.users(items.url, course, function(response) {
                if (response.hasOwnProperty('error')) {
                  SPINNER.hide();
                  switch (response.error) {
                    case 1:
                      CARD_SYNC_COURSE_ERROR.html('Erro ao sincronizar, acesse o Moodle.');
                      break;
                    case 2:
                      CARD_SYNC_COURSE_ERROR.html('Erro ao sincronizar, não foi encontrado usuários.');
                      break;
                  }
                  CARDS.hide();
                  CARD_SYNC_COURSE.show();
                } else {
                  chrome.storage.local.set({
                    data: data,
                    user: response,
                    time: mdash.time(data)
                  });
                  SPINNER.hide();
                  showPage();
                }
              });
            },
            fail: function() {
              SPINNER.hide();
              CARD_SYNC_COURSE_ERROR.html('Erro ao sincronizar, verifique se você esta logado ao Moodle como professor.');
              CARD_SYNC_COURSE.show();
            }
          });
        } else {
          CARD_SYNC_COURSE_ERROR.html('Erro ao sincronizar, acesse o Moodle.');
        }
      });
    });

    // Botão para seleção de usuários
    BTNS_USER.addEventListener('click', function() {
      CARDS.hide();
      if (CARD_USER.style.display === 'none') {
        chrome.storage.local.get({
          user: null
        }, function(items) {
          if (items.user) {
            var html = '';
            items.user.forEach(function(user) {
              html += '<label class="mdl-checkbox mdl-js-checkbox mdl-js-ripple-effect">';
              html += '<input type="checkbox" class="mdl-checkbox__input"' + (user.selected ? ' checked' : '') + '/>';
              html += '<span class="mdl-checkbox__label">' + user.name + '</span>';
              html += '</label>';
            });
            CARD_USER_LIST.html(html);
            CARD_USER.show();
            upgradeDom();
          } else {
            CARD_SYNC.show();
          }
        });
      }
    });

    // Botão de confirmação para seleção de usuários
    CARD_USER_OK.addEventListener('click', function() {
      var listOfUniqueUsers = [];
      var e = $('.mdl-checkbox', CARD_USER);
      if (!e.length) {
        e = e ? [e] : [];
      }
      e.forEach(function(e) {
        listOfUniqueUsers.push({
          name: $('.mdl-checkbox__label', e).html(),
          selected: $('.mdl-checkbox__input', e).checked
        });
      });
      chrome.storage.local.set({
        user: listOfUniqueUsers
      });
      CARD_USER.hide();
      showPage();
    });

    // Botão para selecionar todos usuários
    CARD_USER_SELECT.addEventListener('click', function() {
      var e = $('.mdl-checkbox', CARD_USER);
      if (!e.length) {
        e = e ? [e] : [];
      }
      e.forEach(function(e) {
        e.MaterialCheckbox.check();
      });
    });

    // Botão para inverter seleção de usuários
    CARD_USER_INVERT.addEventListener('click', function() {
      var e = $('.mdl-checkbox', CARD_USER);
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
    BTNS_TIME.addEventListener('click', function() {
      CARDS.hide();
      if (CARD_TIME.style.display === 'none') {
        chrome.storage.local.get({
          time: null
        }, function(items) {
          if (items.time) {
            CARD_TIME_FIELDS.forEach(function(e, i) {
              e.min = items.time.min.value;
              e.max = items.time.max.value;
              e.value = items.time[i === 0 ? 'min' : 'max'].selected;
            });
            CARD_TIME.show();
          } else {
            CARD_SYNC.show();
          }
        });
      }
    });

    // Botão de confimação para seleção de período
    CARD_TIME_OK.addEventListener('click', function() {
      if (new Date(Date.parse(CARD_TIME_FIELDS[0].value)) - new Date(Date.parse(CARD_TIME_FIELDS[1].value)) <= 0) {
        chrome.storage.local.set({
          time: {
            min: {value: CARD_TIME_FIELDS[0].min, selected: CARD_TIME_FIELDS[0].value},
            max: {value: CARD_TIME_FIELDS[1].max, selected: CARD_TIME_FIELDS[1].value}
          }
        });
      }
      CARD_TIME.hide();
      showPage();
    });

    // Fecha o drawer ao clicar em um link
    DRAWER_LINKS.addEventListener('click', function() {
      DRAWER.classList.toggle('is-visible');
    });

    // Botão para seleção de página
    BTNS_PAGE.addEventListener('click', function() {
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
(function(chrome, Moodle, Graph) {
  'use strict';

  /**
   * =========================================================================
   * App init
   * =========================================================================
   */

  /**
   * Interface elements
   */

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

  /**
   * Translate page
   */

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
    'summary',
    'actions',
    'users_interaction',
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

  /**
   * Get Moodle data saved
   */

  chrome.runtime.sendMessage({
    cmd: 'GET'
  });

  SPINNER.show();

  chrome.runtime.onMessage.addListener(function (request) {
    if (request.hasOwnProperty('moodle')) {
     var moodle = new Moodle(request.moodle);

      /**
       * Sync button
       */

      BTN_SYNC.addEventListener('click', function() {
        chrome.tabs.getSelected(null, function(tab) {
          if (/chrome(\-extension)*\:\/\//.test(tab.url)) {
            if (moodle.hasCourses()) {
              listCourses();
            } else {
              CARD_SYNC_ERROR.html(__('synchronize_error_access'));
              CARDS.hide();
              CARD_SYNC.show();
            }
          } else {
            SPINNER.show();
            moodle.syncCourses(tab.url, function(response) {
              SPINNER.hide();
              switch (response) {
                case moodle.response.SUCCESS:
                  listCourses();
                  break;
                case moodle.response.ERROR_MOODLE_PERMISSION:
                  CARD_SYNC_ERROR.html(__('synchronize_error_permission'));
                  CARDS.hide();
                  CARD_SYNC.show();
                  break;
                default:
                  CARD_SYNC_ERROR.html(__('synchronize_error_access'));
                  CARDS.hide();
                  CARD_SYNC.show();
              }
            });
          }
        });
        function listCourses() {
          var courses = moodle.getCourses();
          if (courses.length > 1) {
            var html = '';
            courses.forEach(function(course, i) {
              html += '<label class="mdl-radio mdl-js-radio mdl-js-ripple-effect">';
              html += '<input type="radio" class="mdl-radio__button" name="course" value="' + i + (course.selected ? '" checked/>' : '"/>');
              html += '<span class="mdl-radio__label">' + course.name + '</span>';
              html += '</label><br/>';
            });
            CARD_SYNC_COURSE_LIST.html(html);
            upgradeDom();
            CARDS.hide();
            CARD_SYNC_COURSE.show();
          } else {
            sync(moodle);
          }
        }
      });

      /**
       * Sync Course button
       */

      BTN_SYNC_COURSE.addEventListener('click', function() {
        sync(moodle, $('input:checked', CARD_SYNC_COURSE).value);
      });

      /**
       * Users button
       */

      BTN_USERS.addEventListener('click', function() {
        CARDS.forEach(function(e) {
          if (e != CARD_USERS) {
            e.hide();
          }
        });
        if (CARD_USERS.style.display === 'none') {
          if (moodle.hasUsers()) {
            var html = '';
            moodle.getUsers().forEach(function(user) {
              html += '<label class="mdl-checkbox mdl-js-checkbox mdl-js-ripple-effect">';
              html += '<input type="checkbox" class="mdl-checkbox__input" value="' + user.id + '"' + (user.selected ? ' checked' : '') + '/>';
              html += '<span class="mdl-checkbox__label">' + user.name + '</span>';
              html += '</label>';
            });
            CARD_USERS_LIST.html(html);
            upgradeDom();
            CARD_USERS.show();
          } else {
            CARD_SYNC.show();
          }
        } else {
          CARD_USERS.hide();
          showPage(moodle);
        }
      });

      /**
       * Confirm users button
       */

       CARD_USERS_OK.addEventListener('click', function() {
         var users = [];
         var e = $('.mdl-checkbox input:checked', CARD_USERS);
         if (!e.length) {
           e = e ? [e] : [];
         }
         e.forEach(function(e) {
           users.push(parseInt(e.value));
         });
         moodle.setUsers(users);
         CARD_USERS.hide();
         showPage(moodle);
       });

      /**
       * Date range button
       */

      BTN_DATES.addEventListener('click', function() {
        CARDS.forEach(function(e) {
          if (e != CARD_DATES) {
            e.hide();
          }
        });
        if (CARD_DATES.style.display === 'none') {
          if (moodle.hasLogs()) {
            CARD_DATES_FIELDS.forEach(function(e, i) {
                var date = moodle.getDate();
                e.min = date.min;
                e.max = date.max;
                e.value = date.selected[i === 0 ? 'min' : 'max'];
            });
            CARD_DATES.show();  
          } else {
            CARD_SYNC.show();
          }
        } else {
          CARD_DATES.hide();
          showPage(moodle);
        }
      });

      /**
       * Confirm date range button
       */

      CARD_DATES_OK.addEventListener('click', function() {
        if (new Date(Date.parse(CARD_DATES_FIELDS[0].value)) - new Date(Date.parse(CARD_DATES_FIELDS[1].value)) <= 0) {
          moodle.setDate({
            min: CARD_DATES_FIELDS[0].value,
            max: CARD_DATES_FIELDS[1].value
          });
        }
        CARD_DATES.hide();
        showPage(moodle);
      });

      /**
       * Page button
       */

      BTN_PAGE.addEventListener('click', function() {
        showPage(moodle, this.hash);
      });

      /**
       * Show page on resize page
       */

      addEventListener('resize', function() {
        showPage(moodle);
      });

      /**
       * Save Moodle data on exit
       */

      addEventListener('unload', function() {
        chrome.runtime.sendMessage({
          cmd: 'SET',
          moodle: moodle.toString()
        });
      });

      /**
       * keys
       */

      addEventListener('keydown', function(e){
        var KEY_F11 = 122;
        switch (e.keyCode) {
          case KEY_F11:
            chrome.downloads.download({
              'url': 'data:text/json;charset=utf-8,' + moodle.toString(),
              'saveAs': false,
              'filename': 'moodle.json'
            });
            break;
        }
        e.preventDefault();
      });

      /**
       * Show default page
       */

      showPage(moodle);

      SPINNER.hide();
    }
  });

  /**
   * Select all users button
   */

  CARD_USERS_SELECT.addEventListener('click', function() {
    var e = $('.mdl-checkbox', CARD_USERS);
    if (!e.length) {
      e = e ? [e] : [];
    }
    e.forEach(function(e) {
      e.MaterialCheckbox.check();
    });
  });

  /**
   * Invert selection users button
   */

  CARD_USERS_INVERT.addEventListener('click', function() {
    var e = $('.mdl-checkbox', CARD_USERS);
    if (!e.length) {
      e = e ? [e] : [];
    }
    e.forEach(function(e) {
      if ($('input', e).checked) {
        e.MaterialCheckbox.uncheck();
      } else {
        e.MaterialCheckbox.check();
      }
    });
  });  

  /**
   * Close drawer on click link
   */

  DRAWER_LINKS.addEventListener('click', function() {
    DRAWER.classList.toggle('is-visible');
  });

  /**
   * Upgrade DOM (Material Design)
   */

  function upgradeDom() {
    componentHandler.upgradeDom();
  }

  /**
   * =========================================================================
   * Functions
   * =========================================================================
   */

  /**
   * Sync Course data
   */

  function sync(moodle, course) {
    CARDS.hide();
    SPINNER.show();
    moodle.sync(function(response) {
      SPINNER.hide();
      switch (response) {
        case moodle.response.SUCCESS:
          showPage(moodle);
          break;
        case moodle.response.ERROR_MOODLE_PERMISSION:
          CARD_SYNC_COURSE_ERROR.html(__('synchronize_error_permission'));
          CARD_SYNC_COURSE.show();
          break;
        case moodle.response.ERROR_NOT_SYNC_USERS:
          CARD_SYNC_COURSE_ERROR.html(__('synchronize_error_users'));
          CARD_SYNC_COURSE.show();
          break;
        default:
          CARD_SYNC_COURSE_ERROR.html(__('synchronize_error_access'));
          CARD_SYNC_COURSE.show();
      }
    }, course);
  }

  /**
   * Show Page
   */

  function showPage(moodle, hash) {
    CARDS.hide();
    switch ((hash || location.hash).replace('#', '')) {
      case 's':
        CARD_SETTINGS.show();
        break;
      case '2':
        showGraph(__('actions'), function(graph) {
          var data = moodle.getInteractionsSize();
          if (data === moodle.response.ERROR_NO_DATA) {
            CARD_GRAPHICS_BODY.html(__('no_data'));
          } else {
            graph.bubble({
              size: 430,
              data: data
            });
          }
        });
        break;
      case '3':
        showGraph(__('users_interaction'), function(graph) {
          var data = moodle.getUsersInteraction();
          if (data === moodle.response.ERROR_NO_DATA) {
            CARD_GRAPHICS_BODY.html(__('no_data'));
          } else {
            graph.bar({
              data: data
            });
          }
        });
        break;
      default:
        CARDS.hide();
        if (moodle.hasLogs()) {
          var summary = moodle.getSummary();
          CARD_GRAPHICS_TITLE.html(__('summary'));
          var html = '';
          html += '<table class="mdl-data-table mdl-js-data-table mdl-data-table--selectable mdl-shadow--2dp" style="margin: auto">';
          html += '<thead>';
          html += '<tr>';
          html += '<th class="mdl-data-table__cell--non-numeric" style="text-align: center">' + __('metrics') + '</th>';
          html += '<th style="text-align: center">' + __('selected') + '</th>';
          html += '<th style="text-align: center">' + __('recorded') + '</th>';
          html += '</tr>';
          html += '</thead>';
          html += '<tbody>';
          html += '<tr>';
          html += '<td class="mdl-data-table__cell--non-numeric" style="text-align: center; font-size: 9pt">' + __('total_page_views') + ':</td>';
          html += '<td style="text-align: center; font-weight: bold">' + summary.selected.views + '</td>';
          html += '<td style="text-align: center">' + summary.recorded.views + '</td>';
          html += '</tr>';
          html += '<tr>';
          html += '<td class="mdl-data-table__cell--non-numeric" style="text-align: center; font-size: 9pt">' + __('total_unique_users') + ':</td>';
          html += '<td style="text-align: center; font-weight: bold">' + summary.selected.users + '</td>';
          html += '<td style="text-align: center">' + summary.recorded.users + '</td>';
          html += '</tr>';
          html += '<tr>';
          html += '<td class="mdl-data-table__cell--non-numeric" style="text-align: center; font-size: 9pt">' + __('total_unique_actions') + ':</td>';
          html += '<td style="text-align: center; font-weight: bold">' + summary.selected.actions + '</td>';
          html += '<td style="text-align: center">' + summary.recorded.actions + '</td>';
          html += '</tr>';
          html += '<tr>';
          html += '<td class="mdl-data-table__cell--non-numeric" style="text-align: center; font-size: 9pt">' + __('total_unique_pages') + ':</td>';
          html += '<td style="text-align: center; font-weight: bold">' + summary.selected.pages + '</td>';
          html += '<td style="text-align: center">' + summary.recorded.pages + '</td>';
          html += '</tr>';
          html += '<tr>';
          html += '<td class="mdl-data-table__cell--non-numeric" style="text-align: center; font-size: 9pt">' + __('first_activity') + ':</td>';
          html += '<td style="font-weight: bold">' + new Date(summary.selected.date.min).toLocaleDateString() + '</td>';
          html += '<td>' + new Date(summary.recorded.date.min).toLocaleDateString() + '</td>';
          html += '</tr>';
          html += '<tr>';
          html += '<td class="mdl-data-table__cell--non-numeric" style="text-align: center; font-size: 9pt">' + __('last_activity') + ':</td>';
          html += '<td style="font-weight: bold">' + new Date(summary.selected.date.max).toLocaleDateString() + '</td>';
          html += '<td>' + new Date(summary.recorded.date.max).toLocaleDateString() + '</td>';
          html += '</tr>';
          html += '</tbody>';
          html += '</table>';
          CARD_GRAPHICS_BODY.html(html);
          CARD_GRAPHICS.show();
        } else {
          CARD_SYNC.show();
        }
    }
    function showGraph(title, callback) {
      CARDS.hide();
      if (moodle.hasLogs()) {
        CARD_GRAPHICS_TITLE.html(title);
        callback(new Graph({
          context: CARD_GRAPHICS_BODY,
          size: window.innerWidth * 0.91
        }));
        CARD_GRAPHICS.show();
      } else {
        CARD_SYNC.show();
      }
    }
  }

  /**
   * i18n (translate page)
   */

  function __(key, value) {
    var message = chrome.i18n.getMessage(key.replace(/\s/g, '_'), value);
    return message || key;
  }

})(this.chrome, this.Moodle, this.Graph);
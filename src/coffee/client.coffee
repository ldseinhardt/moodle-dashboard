###
# client: dashboard interface
###

class Client
  constructor: ->
    moodle = /[\\?&]moodle=([^&#]*)/.exec(location.search)
    if moodle && moodle.length > 1
      @url = moodle[1]
    @onMessage()
    .translate()
    chrome.tabs.query({currentWindow: true, active : true}, (tab) =>
      @id = tab[0].id
      @sendMessage('getMoodles')
    )
    @navActive()
    .onMenuClick()
    .onKeydown()
    .onResize()
    .onScroll()
    .configDatepickers()
    .dropdownOpened()
    .sendMessage('getHelp')
    .sendMessage('getQuestions')
    .sendMessage('getVersion')
    .sendMessage('getConfig')
    .analytics()
    .onUnload()
    .onChangeConfig()
    $.material.init()

  analytics: (status = 'open') ->
    use = 0
    if status == 'open'
      @started = Date.now()
    else
      use = Date.now() - @started
    @sendMessage('analytics',
      status: status
      use: use
    )
    @

  onChangeConfig: ->
    checkboxes = [
      'search_moodle',
      'sync_metadata',
      'sync_logs',
      'message_error_sync_moodle',
      'message_error_sync_dashboard',
      'message_alert_users_not_found',
      'analytics',
      'message_update'
    ]
    texts = [
      'sync_metadata_interval',
      'sync_logs_interval'
    ]
    for field in checkboxes
      ((field) =>
        $('#input_' + field).change((evt) =>
          args =
            settings: {}
          args.settings[field] = $(evt.target).prop('checked')
          @sendMessage('setConfig', args)
        )
      )(field)
    for field in texts
      ((field) =>
        $('#input_' + field).change((evt) =>
          args =
            settings: {}
          args.settings[field] = $(evt.target).val()
          @sendMessage('setConfig', args)
        )
      )(field)
    $('#others input[name="language"]').change((evt) =>
      @sendMessage('setConfig',
        settings:
          language: $(evt.target).val()
      )
      location.reload()
    )
    @

  setFilters: (filters, lists) ->
    filter_pages = $('.filter-pages')
    filter_activities = $('.filter-activities')
    filter_pages.html('')
    filter_activities.html('')
    toggle  = '<div class="togglebutton">'
    toggle += '<label>'
    toggle += '<input type="checkbox" checked="">'
    toggle += '<span>__key__</span>'
    toggle += '</label>'
    toggle += '</div>'
    if lists.pages && lists.pages.length
      html = ''
      for page in lists.pages
        item = toggle.replace('__key__', page)
        if filters.pages.indexOf(page) >= 0
          item = item.replace(' checked=""', '')
        html += item
      filter_pages.html(html)
      $.material.togglebutton()
      $('.togglebutton', filter_pages).change((evt) =>
        @sendMessage('setConfig',
          settings:
            filter_pages:
              key: $(evt.target).siblings('span').text()
              value: $(evt.target).prop('checked')
        )
      )
    if lists.activities && lists.activities.length
      html = ''
      for activity in lists.activities
        item = toggle.replace('__key__', activity)
        if filters.activities.indexOf(activity) >= 0
          item = item.replace(' checked=""', '')
        html += item
      filter_activities.html(html)
      $.material.togglebutton()
      $('.togglebutton', filter_activities).change((evt) =>
        @sendMessage('setConfig',
          settings:
            filter_activities:
              key: $(evt.target).siblings('span').text()
              value: $(evt.target).prop('checked')
        )
      )
    @

  responseConfig: (message) ->
    $('#input_search_moodle')
      .prop('checked', message.settings.search_moodle)
    $('#input_sync_metadata')
      .prop('checked', message.settings.sync_metadata)
    $('#input_sync_metadata_interval')
      .val(message.settings.sync_metadata_interval)
    $('#input_sync_logs')
      .prop('checked', message.settings.sync_logs)
    $('#input_sync_logs_interval')
      .val(message.settings.sync_logs_interval)
    $('#input_message_error_sync_moodle')
      .prop('checked', message.settings.message_error_sync_moodle)
    $('#input_message_error_sync_dashboard')
      .prop('checked', message.settings.message_error_sync_dashboard)
    $('#input_message_alert_users_not_found')
      .prop('checked', message.settings.message_alert_users_not_found)
    $('#input_analytics')
      .prop('checked', message.settings.analytics)
    $('#input_language_' + langId)
      .prop('checked', true)
    $('#input_message_update')
      .prop('checked', message.settings.message_update)
    @

  responseVersion: (message) ->
    $('#about .data-version').text(message.version)
    @

  responseUpdate: (message) ->
    link  = '&nbsp;(<a href="' + message.url + '" target="_blank">'
    link += message.version + ' ' + __('available').toLowerCase()
    link += '</a>)'
    $('#about .data-update').html(link)
    if message.show
      title  = __('Update') + ' - ' + __('Version') + ' '
      title += message.version + ' ' + __('available').toLowerCase()
      buttons  = '<a href="' + message.url
      buttons += '" target="_blank" class="btn btn-primary">'
      buttons += '<i class="material-icons">&#xE2C4;</i> DOWNLOAD'
      buttons += '</a>'
      @showMessage(title, message.description[langId], buttons)
    @

  responseHelp: (message) ->
    html  = '<div class="panel-group" id="accordionHelp" role="tablist"'
    html += ' aria-multiselectable="true">'
    for item, i in message.help[langId]
      html += '<div class="panel">'
      html += '<div class="panel-heading" role="tab" id="headingHelp' + i + '">'
      html += '<h4 class="panel-title">'
      html += '<a'
      html += ' class="collapsed"' unless i
      html += ' role="button" data-toggle="collapse"'
      html += ' data-parent="#accordionHelp" href="#collapseHelp' + i
      html += '" aria-expanded="'
      html += if i then 'false' else 'true'
      html += '" aria-controls="collapseHelp' + i + '">'
      html += item.title
      html += '</a>'
      html += '</h4>'
      html += '</div>'
      html += '<div id="collapseHelp' + i + '" class="panel-collapse collapse'
      html += ' in' unless i
      html += '" role="tabpanel" aria-labelledby="headingHelp' + i + '">'
      html += '<div class="panel-body">'
      html += item.text
      html += '</div>'
      html += '</div>'
      html += '</div>'
    html += '</div>'
    unless message.help[langId] && message.help[langId].length
      html  = '<div class="default">'
      html += '<i class="material-icons">&#xE80C;</i>'
      html += '<div class="message">' + __('No data') + '</div>'
      html += '</div>'
    $('#help').html(html)
    @


  responseQuestions: (message) ->
    html  = '<div class="panel-group" id="accordionQuestions" role="tablist"'
    html += ' aria-multiselectable="true">'
    for item, i in message.questions[langId]
      html += '<div class="panel">'
      html += '<div class="panel-heading" role="tab" id="headingQuestions'
      html += i + '">'
      html += '<h4 class="panel-title">'
      html += '<a'
      html += ' class="collapsed"' unless i
      html += ' role="button" data-toggle="collapse"'
      html += ' data-parent="#accordionQuestions" href="#collapseQuestions' + i
      html += '" aria-expanded="'
      html += if i then 'false' else 'true'
      html += '" aria-controls="collapseQuestions' + i + '">'
      html += item.title
      html += '</a>'
      html += '</h4>'
      html += '</div>'
      html += '<div id="collapseQuestions'
      html += i + '" class="panel-collapse collapse'
      html += ' in' unless i
      html += '" role="tabpanel" aria-labelledby="headingQuestions' + i + '">'
      html += '<div class="panel-body">'
      html += item.text
      html += '</div>'
      html += '</div>'
      html += '</div>'
    html += '</div>'
    unless message.questions[langId] && message.questions[langId].length
      html  = '<div class="default">'
      html += '<i class="material-icons">&#xE80C;</i>'
      html += '<div class="message">' + __('No data') + '</div>'
      html += '</div>'
    $('#faq').html(html)
    @

  responseMoodles: (message) ->
    unless message.list.length
      unless $('#moodle-error').is(':visible')
        $('.interface').hide()
        $('#moodle-error').show()
      return
    html = ''
    @index = 0
    for moodle, i in message.list
      if moodle.selected
        @index = i
      url = moodle.url.split(/:\/\//)[1]
      title = moodle.title?.replace(/\s-\s|-/, '<br>') || url
      html += '<div class="moodle-item" moodle="' + moodle.url + '">'
      html += '<div class="title">' + title + '</div>'
      html += '<div class="url">' + url + '</div>'
      html += '</div>'
    moodle_list = $('#moodle-select .moodle-list')
    moodle_list.html(html)
    $($('.moodle-item', moodle_list)[@index]).show()
    selected = message.list.filter((moodle) => moodle.url == @url)
    if @url && selected.length
      unless $('#moodle-dashboard').is(':visible')
        sidebar = $('#moodle-dashboard .sidebar')
        url = selected[0].url.split(/:\/\//)[1]
        title = selected[0].title?.replace(/\s-\s|-/, '<br>') || url
        $('header .title').html(title)
        @sendMessage('getCourses')
        $('.interface').hide()
        $('#moodle-dashboard').show()
    else if !$('#moodle-select').is(':visible')
      $('.interface').hide()
      $('#moodle-select').show()
    @

  responseCourses: (message) ->
    html = '<ul class="nav course-list">'
    for course, i in message.courses
      html += '<li><a href="#" index="' + i + '" class="withripple'
      html += ' active' if course.selected
      html += '">' + course.name + '</a></li>'
    html += '</ul>'
    $('#submenu-courses').html(html)
    @navActive()
    .onCourseSelect()
    $('.course-list li a').on('click', (evt) =>
      @onCourseSelect(evt.currentTarget)
    )
    @

  onCourseSelect: (selector) ->
    content  = $('#dashboard-content')
    course = if selector then $(selector) else $('.course-list li .active')
    @course = parseInt(course.attr('index'))
    @role = 0
    if !content.is(':visible') || $('.title', content).text() != course.text()
      $('.title', content).text(course.text())
      $('.main').hide()
      content.show()
      view.resize()
      $('.contents > .more-options').show()
      content.scrollTop(0)
    @sendMessage('getUsers')
    .sendMessage('getDates')
    @

  responseUsers: (message) ->
    html  = '<div class="btn-group more-options users-options">'
    html += '<a class="dropdown-toggle" data-target="#" data-toggle="dropdown">'
    html += '<i class="material-icons">&#xE5D4;</i>'
    html += '</a>'
    html += '<ul class="dropdown-menu dropdown-menu-right">'
    husr  = ''
    for role, i in message.roles
      husr += '<div class="list-group role-users-list"'
      husr += 'style="display: block"' unless i
      husr += '>'
      for user, u  in role.users
        husr += '<div class="list-group-separator"></div>' if u
        husr += '<div class="list-group-item">'
        husr += '<div class="row-picture">'
        husr += '<img class="circle" src="' + user.picture + '" alt="icon" '
        husr += 'title="' + user.name + '">'
        husr += '</div>'
        husr += '<div class="row-content">'
        husr += '<h4 class="list-group-item-heading">'
        husr += user.firstname + ' ' + user.lastname
        husr += '</h4>'
        husr += '<p class="list-group-item-text">'
        husr += '<div class="togglebutton user-selector">'
        husr += '<label><input type="checkbox" value="' + u + '"'
        husr += ' checked' if user.selected
        husr += '></label>'
        husr += '</div>'
        husr += '</p>'
        husr += '</div>'
        husr += '</div>'
      husr += '</div>'
      html += '<li><a href="#" class="role-list'
      html += ' active' unless i
      html += '" index="' + i + '">'
      html += '<i class="material-icons">&#xE7FB;</i> ' + __(role.name)
      html += '</a></li>'
    html += '<li class="divider"></li>'
    html += '<li><a href="#" class="btn-users-select-all not-actived">'
    html += __('Select all') + '</a></li>'
    html += '<li><a href="#" class="btn-users-select-invert not-actived">'
    html += __('Invert selection') + '</a></li>'
    html += '</ul>'
    html += '</div>'
    $('#submenu-users').html(html + husr)
    $.material.togglebutton()
    @navActive()
    $('.role-list').on('click', (evt) =>
      @role = parseInt($(evt.currentTarget).attr('index'))
      unless $($('.role-users-list')[@role]).is(':visible')
        @sendMessage('getData')
        $('.role-users-list').hide()
        $($('.role-users-list')[@role]).show()
    )
    $('.btn-users-select-all').on('click', =>
      index = @getRole()
      $('.user-selector', $('.role-users-list')[index]).each((i, e) ->
        $('input[type="checkbox"]', e).prop('checked', true)
      )
      @sendMessage('setUser',
        action: 'select-all'
      )
      .sendMessage('getData')
    )
    $('.btn-users-select-invert').on('click', =>
      index = @getRole()
      $('.user-selector', $('.role-users-list')[index]).each((i, e) ->
        checkbox = $('input[type="checkbox"]', e)
        checkbox.prop('checked', !checkbox.is(':checked'))
      )
      @sendMessage('setUser',
        action: 'select-invert'
      )
      .sendMessage('getData')
    )
    $('.user-selector').on('change', (evt) =>
      checkbox = $('input[type="checkbox"]', evt.currentTarget)
      @sendMessage('setUser',
        user: parseInt(checkbox.attr('value'))
        selected: checkbox.is(':checked')
      )
      setTimeout(
        => @sendMessage('getData'),
        500
      )
    )
    @sendMessage('getData')
    .sendMessage('syncData')
    @

  responseDates: (message) ->
    if message.dates
      daterange = $('#submenu-daterange')
      $('.date-min, .date-max', daterange).unbind('dp.change')
      @dates = message.dates
      $('.date-min', daterange).data().DateTimePicker
        .minDate(new Date(@dates.min.value))
        .maxDate(new Date(@dates.max.selected))
        .defaultDate(new Date(@dates.min.selected))
      $('.date-max', daterange).data().DateTimePicker
        .minDate(new Date(@dates.min.selected))
        .maxDate(new Date(@dates.max.value))
        .defaultDate(new Date(@dates.max.selected))
      @updateDates()
      $('.date-max', daterange).on('dp.change', (evt) =>
        date_min = $('#submenu-daterange .date-min').data().DateTimePicker
        date_min.maxDate(new Date(evt.date._d.valueOf()))
        if @dates
          @dates.max.selected = evt.date._d.valueOf()
          @sendMessage('setDates', dates: @dates)
          .sendMessage('getData')
          .updateDates()
      )
      $('.date-min', daterange).on('dp.change', (evt) =>
        date_max = $('#submenu-daterange .date-max').data().DateTimePicker
        date_max.minDate(new Date(evt.date._d.valueOf()))
        if @dates
          @dates.min.selected = evt.date._d.valueOf()
          @sendMessage('setDates', dates: @dates)
          .sendMessage('getData')
          .updateDates()
      )
    @

  updateDates: ->
    day = 1000 * 60 * 60 * 24
    total = Math.floor((@dates.max.value - @dates.min.value) / day) + 1
    selected = Math.floor((@dates.max.selected - @dates.min.selected) / day) + 1
    $('#submenu-daterange .message').html(
      selected + ' ' + __('of') + ' ' + total + ' ' + __('days')
    )
    @

  responseData: (message) ->
    unless message.course == @getCourse() && message.role == @getRole()
      return
    content = $('#dashboard-content')
    if !message.data || message.error
      unless $('.default', content).is(':visible')
        $('.data', content).hide()
        $('.default', content).show()
    else
      unless $('.data', content).is(':visible')
        $('.default', content).hide()
        $('.data', content).show()
      view.render(message.data, @download)
      @navActive()
      if message.filters && message.lists
        @setFilters(message.filters, message.lists)
    @

  download: (url, filename = 'chart.png') =>
    chrome.downloads.download(
      url: url
      saveAs: @isNotFullScreen()
      filename: filename
    )

  responseSync: (message) ->
    unless message.course == @getCourse()
      return
    sync = $('#moodle-sync')
    $('.progress', sync).removeClass('progress-striped').removeClass('active')
    $('.progress .progress-bar-success', sync).css('width', '0')
    $('.progress .progress-bar-danger', sync).css('width', '0')
    $('.progress-score', sync).html('')
    progress = message.progress
    success = Math.floor(progress.success / progress.total * 100)
    error = Math.floor(progress.error / progress.total * 100)
    total = progress.success + progress.error
    if !total && message.error
      if !message.silent && message.showError
        @showMessage(__('Error synchronizing'), __('error_synchronizing_msg'))
    else
      if progress.total > 1
        $('.progress .progress-bar-success', sync).css('width', success + '%')
        $('.progress .progress-bar-danger', sync).css('width', error + '%')
        $('.progress-score', sync).html(success + error + '%')
      else if !message.silent
        $('.progress .progress-bar-success', sync).css('width', '60%')
        $('.progress', sync).addClass('progress-striped').addClass('active')
      if !sync.is(':visible') && !message.silent
        $('.modal').not(sync).modal('hide')
        sync.modal('show')
      if total == progress.total
        @sendMessage('getDates')
        .sendMessage('getData')
        setTimeout(
          =>
            $(sync).modal('hide')
            unless message.silent
              if error && message.showError
                @showMessage(
                  __('Error synchronizing'),
                  __('error_synchronizing_msg')
                )
              else if message.users && message.users.length
                html  = '<p>' + __('warning_users_not_found_msg') + '</p>'
                html += '<p>'
                html += __('Participants') + ': '
                html += message.users.join(', ') + '.'
                html += '</p>'
                @showMessage(__('Warning'), html)
          , 1000
        )
    @

  getMoodle: ->
    @url

  getCourse: ->
    @course || 0

  getRole: ->
    @role || 0

  moodleSelect: ->
    moodle_list = $('#moodle-select .moodle-item')
    @refreshURL($(moodle_list[@index]).attr('moodle'))
    unless $('#moodle-dashboard').is(':visible')
      $('.sidebar nav li .active').removeClass('active')
      $('.sidebar nav li .btn-courses').addClass('active')
      $('header .title').html($('.title', moodle_list[@index]).html())
      unless $('#submenu-courses').is(':visible')
        $('.submenu-item').hide()
        $('#submenu-courses').show()
      @sendMessage('getCourses')
      $('.interface').hide()
      $('#moodle-dashboard').show()
    @

  moodlePrev: ->
    moodle_list = $('#moodle-select .moodle-item')
    @index--
    if @index < 0
      @index = moodle_list.length - 1
    unless $(moodle_list[@index]).is(':visible')
      $(moodle_list).hide()
      $(moodle_list[@index]).fadeIn()
    @

  moodleNext: ->
    moodle_list = $('#moodle-select .moodle-item')
    @index++
    if @index >= moodle_list.length
      @index = 0
    unless $(moodle_list[@index]).is(':visible')
      $(moodle_list).hide()
      $(moodle_list[@index]).fadeIn()
    @

  navActiveFn: ->
    unless $(@).hasClass('not-actived')
      $('li .active', $(@).parent().parent()).removeClass('active')
      $(@).addClass('active')

  navActive: ->
    $('ul li a').unbind('click', @navActiveFn)
    $('ul li a').on('click', @navActiveFn)
    @

  dropdownOpened: ->
    $('.dropdown-menu-opened li').click(->
      $(@).parent().parent().toggleClass('open')
    )
    @

  refreshURL: (moodle = '') ->
    if moodle
      @url = moodle
      moodle = '?moodle=' + moodle
    else
      delete @url
    history.pushState(null, $('title').text(), location.pathname + moodle)
    @

  showMessage: (title, message, buttons = '') ->
    moodle_message = $('#moodle-message')
    unless moodle_message.is(':visible')
      $('.modal-title', moodle_message).html(title)
      $('.modal-body', moodle_message).html(message)
      buttons += '<button type="button" class="btn btn-default" data-dismiss="modal">'
      buttons += __('Close')
      buttons += '</button>'
      $('.modal-footer').html(buttons)
      $('.modal').not(moodle_message).modal('hide')
      moodle_message.modal('show')
    @

  onMenuClick: ->
    $('#moodle-select .btn-prev').click(=> @moodlePrev())
    $('#moodle-select .btn-select').click(=> @moodleSelect())
    $('#moodle-select .btn-next').click(=> @moodleNext())
    nav = $('#moodle-dashboard .sidebar .menu')
    $('.btn-home', nav).click(=>
      @refreshURL()
      $('.interface').hide()
      $('#moodle-select').show()
    )
    $('.btn-courses', nav).click(->
      unless $('#submenu-courses').is(':visible')
        $('.submenu-item').hide()
        $('#submenu-courses').show()
    )
    $('#submenu-courses').mouseover(->
      $('.sidebar nav li .active').removeClass('active')
      $('.sidebar nav li .btn-courses').addClass('active')
    )
    $('.btn-users', nav).click(->
      unless $('#submenu-users').is(':visible')
        $('.submenu-item').hide()
        $('#submenu-users').show()
    )
    $('#submenu-users').mouseover(->
      $('.sidebar nav li .active').removeClass('active')
      $('.sidebar nav li .btn-users').addClass('active')
    )
    $('.btn-daterange', nav).click(->
      unless $('#submenu-daterange').is(':visible')
        $('.submenu-item').hide()
        $('#submenu-daterange').show()
    )
    $('#submenu-daterange').mouseover(->
      $('.sidebar nav li .active').removeClass('active')
      $('.sidebar nav li .btn-daterange').addClass('active')
    )
    $('.btn-settings', nav).click(->
      settings = $('#dashboard-settings')
      unless settings.is(':visible')
        $('.main').hide()
        settings.show()
        $('.contents > .more-options').show()
        settings.scrollTop(0)
    )
    $('.btn-help', nav).click(->
      help = $('#dashboard-help')
      unless help.is(':visible')
        $('.main').hide()
        help.show()
        $('.contents > .more-options').show()
        help.scrollTop(0)
    )
    $('.btn-fullscreen').click(=>
      if @isNotFullScreen()
        if (document.documentElement.requestFullScreen)
          document.documentElement.requestFullScreen()
        else if (document.documentElement.mozRequestFullScreen)
          document.documentElement.mozRequestFullScreen()
        else if (document.documentElement.webkitRequestFullScreen)
          document.documentElement.webkitRequestFullScreen(
            Element.ALLOW_KEYBOARD_INPUT
          )
      else
        if (document.cancelFullScreen)
          document.cancelFullScreen()
        else if (document.mozCancelFullScreen)
          document.mozCancelFullScreen()
        else if (document.webkitCancelFullScreen)
          document.webkitCancelFullScreen()
    )
    $('.btn-exit').click(-> close())
    $('.btn-license').click(=>
      $.get(
        chrome.extension.getURL('LICENSE'),
        (data) =>
          @showMessage(
            __('MIT License'),
            '<pre><p style="text-align: left">' + data + '</p></pre>'
          )
      )
    )
    $('.btn-support').click(=>
      name = $('#inputName')
      email = $('#inputEmail')
      message = $('#inputMessage')
      if name.val() && email.val() && message.val()
        @sendMessage('support',
          name: name.val()
          email: email.val()
          subject: __('Support')
          message: message.val()
        )
    )
    $('.btn-data-download').click(->
      alert('Não implementado...')
    )
    $('.btn-delete').click(=>
      @sendMessage('deleteMoodle')
      location.href = location.href.split('?')[0]
    )
    $('.btn-default-setting').click(=>
      @sendMessage('defaultConfig')
      location.reload()
    )
    @

  responseSupport: (message) ->
    html  = '<div class="alert alert-dismissible alert-__type__">'
    html += '<button type="button" class="close" data-dismiss="alert">×</button>'
    html += '<div class="text-center">__message__</div>'
    html += '</div>'
    if message.status
      $('#inputName').val('')
      $('#inputEmail').val('')
      $('#inputMessage').val('')
      html = html
        .replace('__type__', 'success')
        .replace('__message__', __('support_success'))
    else
      html = html
        .replace('__type__', 'danger')
        .replace('__message__', __('support_error'))
    $('#support .message').html(html)
    @

  onKeydown: ->
    $(window).keydown((evt) =>
      if $('#moodle-select').is(':visible')
        switch evt.which
          when 13
            evt.preventDefault()
            @moodleSelect()
          when 37, 38
            evt.preventDefault()
            @moodlePrev()
          when 39, 40
            evt.preventDefault()
            @moodleNext()
    )
    @

  onResize: ->
    $(window).resize(->
      view.resize()
      fullscreen = '<i class="material-icons">'
      if (!window.screenTop && !window.screenY)
        fullscreen += '&#xE5D1;</i> ' + __('Fullscreen (exit)') + '</a>'
      else
        fullscreen += '&#xE5D0;</i> ' + __('Fullscreen') + '</a>'
      $('.btn-fullscreen').html(fullscreen)
    )
    @

  onScroll: ->
    $('.main').scroll(->
      options = $('.contents > .more-options')
      if $(@).scrollTop() > 20
        if options.is(':visible')
          options.hide()
      else if !options.is(':visible')
        options.show()
    )
    @

  onUnload: ->
    $(window).unload(=>
      @analytics('close')
    )
    @

  isNotFullScreen: ->
    doc = document
    doc.fullScreenElement? || (!doc.mozFullScreen && !doc.webkitIsFullScreen)

  configDatepickers: ->
    daterange = $('#submenu-daterange')
    $('.btn-daterange-min', daterange).on('click', ->
      daterange = $('#submenu-daterange')
      datetimepicker = $('.date-min', daterange)
      unless datetimepicker.is(':visible')
        $('.datetimepicker', daterange).hide()
        datetimepicker.show()
    )
    $('.btn-daterange-max', daterange).on('click', ->
      daterange = $('#submenu-daterange')
      datetimepicker = $('.date-max', daterange)
      unless datetimepicker.is(':visible')
        $('.datetimepicker', daterange).hide()
        datetimepicker.show()
    )
    $('.btn-daterange-last-day', daterange).on('click', =>
      if @dates
        $('#submenu-daterange .date-max').data().DateTimePicker
          .minDate(new Date(@dates.min.value))
          .defaultDate(new Date(@dates.max.value))
        $('#submenu-daterange .date-min').data().DateTimePicker
          .maxDate(new Date(@dates.max.value))
          .defaultDate(new Date(@dates.max.value))
        @updateDates()
    )
    $('.btn-daterange-last-week', daterange).on('click', =>
      if @dates
        week = 1000 * 60 * 60 * 24 * (7 - 1) #7d
        min = @dates.max.value - week
        if min < @dates.min.value
          min = @dates.min.value
        $('#submenu-daterange .date-max').data().DateTimePicker
          .minDate(new Date(@dates.min.value))
          .defaultDate(new Date(@dates.max.value))
        $('#submenu-daterange .date-min').data().DateTimePicker
          .maxDate(new Date(@dates.max.value))
          .defaultDate(new Date(min))
    )
    $('.btn-daterange-last-month', daterange).on('click', =>
      if @dates
        month = 1000 * 60 * 60 * 24 * (30 - 1) #30d
        min = @dates.max.value - month
        if min < @dates.min.value
          min = @dates.min.value
        $('#submenu-daterange .date-max').data().DateTimePicker
          .minDate(new Date(@dates.min.value))
          .defaultDate(new Date(@dates.max.value))
        $('#submenu-daterange .date-min').data().DateTimePicker
          .maxDate(new Date(@dates.max.value))
          .defaultDate(new Date(min))
    )
    $('.btn-daterange-select-all', daterange).on('click', =>
      if @dates
        $('#submenu-daterange .date-max').data().DateTimePicker
          .minDate(new Date(@dates.min.value))
          .defaultDate(new Date(@dates.max.value))
        $('#submenu-daterange .date-min').data().DateTimePicker
          .maxDate(new Date(@dates.max.value))
          .defaultDate(new Date(@dates.min.value))
    )
    $('.datetimepicker', daterange).datetimepicker(
      inline: true
      locale: langId
      format: 'L'
      tooltips:
        today: __('Go to today')
        clear: __('Clear selection')
        close: __('Close the picker')
        selectMonth: __('Select Month')
        prevMonth: __('Previous Month')
        nextMonth: __('Next Month')
        selectYear: __('Select Year')
        prevYear: __('Previous Year')
        nextYear: __('Next Year')
        selectDecade: __('Select Decade')
        prevDecade: __('Previous Decade')
        nextDecade: __('Next Decade')
        prevCentury: __('Previous Century')
        nextCentury: __('Next Century')
    )
    @

  translate: ->
    $('html').attr('lang', langId)
    $('*').each((i, e) ->
      list = $(e).attr('class')?.trim().replace(/\s+/g,' ')
      if list && list.length && list.split
        for classname in list.split(/\s/)
          msg = /^__MSG_([^$]*)/.exec(classname)
          if msg && msg.length > 1 && msg[1]
            key = msg[1].replace(/__/g, '').replace(/_/g, ' ')
            key = key.charAt(0).toUpperCase() + key[1..]
            $(e).html(__(key))
        @
    )
    @

  sendMessage: (cmd, msg = {}) ->
    msg.cmd = cmd
    msg.id = @id || 0
    msg.moodle = @getMoodle()
    msg.course = @getCourse()
    msg.role = @getRole()
    chrome.runtime.sendMessage(msg)
    # console.log('sendMessage:', msg)
    @

  onMessage: ->
    chrome.runtime.onMessage.addListener((request) =>
      if request.client
        commands_private = [
          'responseSupport',
          'responseCourses',
          'responseUsers',
          'responseDates',
          'responseData',
          'responseSync'
        ]
        commands_public = [
          'responseConfig',
          'responseVersion',
          'responseUpdate',
          'responseHelp',
          'responseQuestions',
          'responseMoodles'
        ]
        if commands_private.indexOf(request.cmd) >= 0
          if [0, @id].indexOf(request.id) >= 0 && request.moodle == @url
            @[request.cmd](request)
        else if commands_public.indexOf(request.cmd) >= 0
          @[request.cmd](request)
        else
          console.log('message:', request)
    )
    @

@start = -> new Client()

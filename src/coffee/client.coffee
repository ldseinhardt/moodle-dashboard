###
# client: dashboard interface
###

class Client
  constructor: ->
    moodle = /[\\?&]moodle=([^&#]*)/.exec(location.search)
    if moodle && moodle.length > 1
      @url = moodle[1]
    @onMessage()
    chrome.tabs.query({currentWindow: true, active : true}, (tab) =>
      @id = tab[0].id
      @sendMessage('getMoodles')
    )
    @navActive()
    .onMenuClick()
    .onKeydown()
    .onResize()
    .configDatepickers()
    .dropdownOpened()
    $.material.init()

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
    @sendMessage('getUsers')
    .sendMessage('getDates')
    @

  responseUsers: (message) ->
    html  = '<div class="btn-group more-options users-options">'
    html += '<a class="dropdown-toggle" data-target="#" data-toggle="dropdown">'
    html += '<i class="material-icons">more_vert</i>'
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
      html += '<i class="material-icons">people</i> ' + __(role.name)
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
      unless message.silent
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
              if error > 0
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

  showMessage: (title, message) ->
    moodle_message = $('#moodle-message')
    unless moodle_message.is(':visible')
      $('.modal-title', moodle_message).html(title)
      $('.modal-body', moodle_message).html(message)
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
      unless $('#dashboard-settings').is(':visible')
        $('.main').hide()
        $('#dashboard-settings').show()
    )
    $('.btn-help', nav).click(->
      unless $('#dashboard-help').is(':visible')
        $('.main').hide()
        $('#dashboard-help').show()
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
    $(window).on('resize', =>
      view.resize()
      fullscreen = '<i class="material-icons">fullscreen'
      if (!window.screenTop && !window.screenY)
        fullscreen += '_exit</i> ' + __('Fullscreen (exit)') + '</a>'
      else
        fullscreen += '</i> ' + __('Fullscreen') + '</a>'
      $('.btn-fullscreen').html(fullscreen)
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
      locale: __('lang')
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
          'responseCourses',
          'responseUsers',
          'responseDates',
          'responseData',
          'responseSync'
        ]
        commands_public = [
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

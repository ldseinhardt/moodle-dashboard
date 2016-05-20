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
    .configDatepickers()
    .sendMessage('getHelp')
    .sendMessage('getQuestions')
    .sendMessage('getVersion')
    .sendMessage('getConfig')
    .analytics()
    .onUnload()
    .onChangeConfig()
    $.material.init()
    $('[data-toggle=tooltip]').tooltip()

  sendMoodleMessage: (users) ->
    unless users.length
      return @
    html  = '<div style="text-align: left">'
    if users.length > 1
      html += '<p>' + users.map((d) -> d.name).join(', ') + '</p>'
    else
      html += '<img src="' + users[0].picture + '" alt="' + users[0].name + '" title="' + users[0].name + '" style="margin: 5px;">'
      html += users[0].name
    html += '<h4>' + __('Message') + ':</h4>'
    html += '<textarea style="width: 100%; height: 150px; resize: none" id="moodle-send-message"></textarea>'
    html += '</div>'
    buttons  = '<a href="#" class="btn btn-primary" id="btn-send-message">'
    buttons += __('Send')
    buttons += '</a>'
    @showMessage(__('Send message'), html, buttons)
    $('#btn-send-message').click((evt) =>
      message = $('#moodle-send-message').val()
      if message != ''
        @sendMessage('sendMessageToMoodle',
          users: users.map((d) -> d.id)
          message: message
        )
        $('#moodle-message').modal('hide')
    )
    @

  analytics: ->
    if @started
      @sendMessage('analytics',
        open: @started
        close: Date.now()
      )
    else
      @started = Date.now()
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

  setFilters: (filters) ->
    @filters = filters.filtrated
    filter = $('.filter-activities')
    filter.html('<div class="text">' + __('No data') + '</div>')
    if Object.keys(filters.list).length
      filter.html('<table class="table table-striped table-hover"></table>')
      if langId == 'pt-br'
        __activities = {}
      data = []
      for key, value of filters.list
        event = value.event.replace(/\./g, '')
        page = value.page || __('Untitled')
        page = page[..0].toUpperCase() + page[1..]
        activity = __(event)
        activity = activity[..0].toUpperCase() + activity[1..]
        data.push(
          state: $.inArray(key, @filters) != -1
          value: key
          activity: __(event)
          page: page
        )
        if langId == 'pt-br' && event == __(event) && !__activities[event]
          __activities[event.toLowerCase()] = 1
      $('table', filter).bootstrapTable(
        columns: [
          {
            field: 'state'
            checkbox: true
            halign: 'center'
            valign: 'middle'
            align: 'center'
          },
          {
            field: 'value'
            visible: false
          },
          {
            field: 'activity'
            title: __('Activity')
            sortable: true
            halign: 'center'
            valign: 'middle'
          },
          {
            field: 'page'
            title: __('Page')
            sortable: true
            halign: 'center'
            valign: 'middle'
          },
        ]
        data: data
        sortName: 'activity'
        search: true
        clickToSelect: true
        pagination: true
        pageList: [10, 25, 50, 100, 'ALL']
        locale: langId
        onAll: (name, args) =>
          switch name
            when 'check.bs.table'
              if @filters.indexOf(args[0].value) == -1
                @filters.push(args[0].value)
                @sendMessage('setConfig',
                  settings:
                    filters:
                      key: args[0].value
                      value: false
                )
            when 'uncheck.bs.table'
              index = @filters.indexOf(args[0].value)
              if index != -1
                @filters.splice(index, 1)
                @sendMessage('setConfig',
                  settings:
                    filters:
                      key: args[0].value
                      value: true
                )
            when 'check-all.bs.table'
              $.each(args[0], (i, row) =>
                if @filters.indexOf(row.value) == -1
                  @filters.push(row.value)
                  @sendMessage('setConfig',
                    settings:
                      filters:
                        key: row.value
                        value: false
                  )
              )
            when 'uncheck-all.bs.table'
              $.each(args[0], (i, row) =>
                index = @filters.indexOf(row.value)
                if index != -1
                  @filters.splice(index, 1)
                  @sendMessage('setConfig',
                    settings:
                      filters:
                        key: row.value
                        value: true
                  )
              )
            when 'pre-body.bs.table'
              $.each(args[0], (i, row) =>
                row.state = $.inArray(row.value, @filters) != -1
                @
              )
      )
      if langId == 'pt-br'
        values = Object.keys(__activities).sort((a, b) ->
          x = a.toLowerCase()
          y = b.toLowerCase()
          if x < y
            return -1
          if x > y
            return 1
          return 0
        )
        if values.length
          text = ''
          for value in values
            text += '"' + value.replace(/\s/g, '_') + '": {\n'
            text += '  "message": "' + value + '"\n'
            text += '},\n\n'
          console.log(text)
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
    link += message.version + ' ' + __('available', true)
    link += '</a>)'
    $('#about .data-update').html(link)
    if message.show
      title  = __('Update') + ' - ' + __('Version') + ' '
      title += message.version + ' ' + __('available', true)
      buttons  = '<a href="' + message.url
      buttons += '" target="_blank" class="btn btn-primary">'
      buttons += '<i class="material-icons">&#xE2C4;</i> DOWNLOAD'
      buttons += '</a>'
      @showMessage(title, message.description[langId], buttons)
    @

  responseHelp: (message) ->
    html  = '<div class="row">'
    html += '<div class="col-md-12">'
    html += '<div class="panel-group" id="accordionHelp" role="tablist"'
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
    html  = '<div class="row">'
    html += '<div class="col-md-12">'
    html += '<div class="panel-group" id="accordionQuestions" role="tablist"'
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
      title = moodle.title?.replace(/\s\-\s|\-|\s\_\s|\_/, '<br>') || url
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
        title = selected[0].title?.replace(/\s\-\s|\-|\s\_\s|\_/, '<br>') || url
        $('header .title').html(
          '<a href="' + selected[0].url + '" target="_blank">' + title + '</a>'
        )
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
      html += '">' + course.name + '</a></li>'
    html += '</ul>'
    $('#submenu-courses').html(html)
    @navActive()
    $('.course-list li a').on('click', (evt) =>
      @onCourseSelect($(evt.currentTarget))
    )
    @

  onCourseSelect: (course) ->
    content  = $('#dashboard-content')
    title = $('.header > .box > .title', content)
    subtitle = $('.header > .box > .subtitle', content)
    if title.html() == course.html()
      unless content.is(':visible')
        $('.main').hide()
        content.show()
    else
      @course = parseInt(course.attr('index'))
      @role = 0
      title.html(course.html())
      subtitle.html('')
      if content.is(':visible')
        $('.data', content).hide()
        $('.default', content).show()
      else
        $('.main').hide()
        content.show()
      @sendMessage('getUsers')
      .sendMessage('getDates')
      .sendMessage('getData')
      .sendMessage('getLogs')
    @sendMessage('syncData')
    $('.default .message', content).html(__('Loading') + ' ...')
    @

  responseUsers: (message) ->
    if message.roles && message.roles.length
      html  = '<div class="btn-group more-options users-options" data-toggle="tooltip" data-placement="bottom" data-original-title="' + __('More options') + '">'
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
      $('#submenu-users [data-toggle=tooltip]').tooltip()
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
    else
      $('#submenu-users').html("""
        <div class="default">
          <i class="material-icons">&#xE80C;</i>
          <div class="message">#{__('No data')}</div>
        </div>
      """)
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
      selected + ' ' + __('of') + ' ' + total + ' ' + __('days', true)
    )
    @

  responseLogs: (message) ->
    unless message.course == @getCourse()
      return
    logs = $('#logs')
    $('.data', logs).hide()
    $('.default', logs).show()
    $('.data', logs).html('')
    if message.logs && message.logs.length
      template = """
        <div class="col-md-12">
          <div class="panel panel-default">
            <div class="panel-heading">
              <div class="panel-title">
                <div class="title" data-toggle="tooltip" data-placement="right" data-original-title="Logs">Logs</div>
              </div>
              <div class="panel-options">
                <div class="btn-group">
                  <a class="btn-download">
                    <i class="material-icons">&#xE2C4;</i>
                  </a>
                </div>
                <i class="material-icons info" data-toggle="tooltip" data-placement="left" data-original-title="#{__('data_logs_description')}">&#xE88E;</i>
              </div>
            </div>
            <div class="panel-body">
              <table class="table table-striped table-hover"></table>
            </div>
          </div>
        </div>
      """
      $('.data', logs).html(template)
      $('[data-toggle=tooltip]', logs).tooltip()
      columns = []
      for column, i in Object.keys(message.logs[0])
        columns.push(
          field: column
          title: __(column)
          sortable: true
          halign: 'center'
          valign: 'middle'
        )
      $('table', logs).bootstrapTable(
        columns: columns
        data: message.logs
        search: true
        pagination: true
        pageList: [10, 25, 50, 100]
        showToggle: true
        showColumns: true
        locale: langId
      )
      $('.default', logs).hide()
      $('.data', logs).show()
      $('.btn-download', logs).click(=>
        @sendMessage('downloadLogs', saveAs: @isNotFullScreen())
      )
    @

  responseData: (message) ->
    unless message.course == @getCourse() && message.role == @getRole()
      return
    if message.filters
      @setFilters(message.filters)
    content = $('#dashboard-content')
    if !message.data || message.error
      $('.data', content).hide()
      $('.default', content).show()
    else
      unless $('.data', content).is(':visible')
        $('.default', content).hide()
        $('.data', content).show()
      view.render(
        message.data,
        message.role,
        message.filters.filtrated
      )
      @navActive()
    $('.default .message', content).html(__('No data'))
    @

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
              @sendMessage('getLogs')
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
      title = $('.title', moodle_list[@index]).html()
      url = $('.url', moodle_list[@index]).html()
      @sendMessage('getCourses')
      if $('header .title').html().indexOf(title) == -1
        $('#dashboard-content > .header > .box > .title').html(__('Course title'))
        $('#dashboard-content > .header > .box > .subtitle').html('')
        $('#submenu-users').html("""
          <div class="default">
            <i class="material-icons">&#xE80C;</i>
            <div class="message">#{__('Select course')}</div>
          </div>
        """)
        $('#submenu-daterange .message').html('')
        $('#filters .filter-activities').html('')
        $('#dashboard-content .data > .row').html('')
        $('#dashboard-content .data').hide()
        $('#dashboard-content .default .message').html(__('Select course'))
        $('#dashboard-content .default').show()
      $('header .title').html(
        '<a href="http://' + url + '" target="_blank">' + title + '</a>'
      )
      unless $('#submenu-courses').is(':visible')
        $('.submenu-item').hide()
        $('#submenu-courses').show()
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
    $('ul:not([role=menu]) li a').on('click', @navActiveFn)
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
    )
    $('.btn-help', nav).click(->
      help = $('#dashboard-help')
      unless help.is(':visible')
        $('.main').hide()
        help.show()
    )
    $('.btn-back').click(=>
      $('.main').hide()
      $('#dashboard-content').show()
      $('.sidebar nav li .active').removeClass('active')
      $('.sidebar nav li .btn-courses').addClass('active')
      if $('.sidebar .course-list li .active').length
        @sendMessage('getData')
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
    $('.btn-data-download').click(=>
      alert('Não implementado...')
    )
    $('.btn-delete').click(=>
      buttons  = '<a href="#" class="btn btn-primary btn-delete-confirm">'
      buttons += '<i class="material-icons">&#xE872;</i> ' + __('Remove')
      buttons += '</a>'
      @showMessage(__('Remove data'), __('remove_data_confirm'), buttons)
      $('.btn-delete-confirm').click((evt) =>
        @sendMessage('deleteMoodle')
        location.href = location.href.split('?')[0]
      )
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
    $(window).resize(=>
      view.resize(@isNotFullScreen())
      fullscreen = '<i class="material-icons">'
      if (!screenTop && !screenY)
        fullscreen += '&#xE5D1;</i> ' + __('Fullscreen (exit)') + '</a>'
      else
        fullscreen += '&#xE5D0;</i> ' + __('Fullscreen') + '</a>'
      $('.btn-fullscreen').html(fullscreen)
    )
    @

  onUnload: ->
    $(window).unload(=> @analytics())
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
    $('[data-i18n]').each((i, e) ->
      text = __($(e).attr('data-i18n'))
      if $(e).html() == ''
        $(e).html(text)
      if $(e).attr('data-original-title') == 'i18n'
        $(e).attr('data-original-title', text)
    )
    @

  sendMessage: (cmd, msg = {}) ->
    msg.cmd = cmd
    msg.id = @id || 0
    msg.moodle = @getMoodle()
    msg.course = @getCourse()
    msg.role = @getRole()
    chrome.runtime.sendMessage(msg)
    @

  onMessage: ->
    chrome.runtime.onMessage.addListener((request) =>
      if request.client
        commands_private = [
          'responseSupport',
          'responseCourses',
          'responseUsers',
          'responseDates',
          'responseLogs',
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

@start = => @client = new Client()

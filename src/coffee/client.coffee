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
      html += '<li><a href="#" index="' + i + '"'
      html += ' class="active"' if course.selected
      html += '>' + course.name + '</a></li>'
    html += '</ul>'
    $('#submenu-courses').html(html)
    @navActive()
    $('.course-list li a').on('click',
      ((self) ->
        -> self.onCourseSelect(@)
      )(@)
    )
    @onCourseSelect()
    @

  onCourseSelect: (evt) ->
    content  = $('#dashboard-content')
    course = if evt then $(evt) else $('.course-list li .active')
    @course = parseInt(course.attr('index'))
    @role = 0
    if !content.is(':visible') || $('.title', content).text() != course.text()
      $('.title', content).text(course.text())
      $('.main').hide()
      content.show()
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
    $.material.init()
    @navActive()
    $('.role-list').on('click',
      ((self) ->
        ->
          self.role = parseInt($(@).attr('index'))
          index = self.role
          unless $($('.role-users-list')[index]).is(':visible')
            self.sendMessage('getData')
            $('.role-users-list').hide()
            $($('.role-users-list')[index]).show()
      )(@)
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
      .sendMessage('getData')
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
    total = Math.floor(
      (@dates.max.value - @dates.min.value) / (1000 * 60 * 60 * 24)
    ) + 1
    selected = Math.floor(
      (@dates.max.selected - @dates.min.selected) / (1000 * 60 * 60 * 24)
    ) + 1
    $('#submenu-daterange .message').html(
      selected + ' ' + __('of') + ' ' + total + ' ' + __('days')
    )
    @

  responseData: (message) ->
    unless message.course == @getCourse() && message.role == @getRole()
      return
    @data =
      error: message.error
    unless message.error
      for key, value of message.data
        @data[key] = value
    @updateData()
    $(window).trigger('resize')
    @

  updateData: ->
    content = $('#dashboard-content')
    $('.data-options a', content).unbind('click')
    $('.data-options .togglebutton').unbind('change')
    if !@data || @data.error
      unless $('.default', content).is(':visible')
        $('.data', content).hide()
        $('.default', content).show()
    else
      content_width = $('body').innerWidth() - (380 + 100)
      colors = [
        '#0074d9', '#ff4136', '#ffdc00', '#3d9970',
        '#85144b', '#39cccc', '#b10dc9', '#01ff70',
        '#111111', '#ff851b', '#001f3f', '#f012be',
        '#dddddd', '#7fdbff', '#2ecc40', '#aaaaaa'
      ]
      download = (url, filename) =>
        chrome.downloads.download(
          url: url
          saveAs: @isNotFullScreen()
          filename: filename
        )
      if @data.summary
        dataGroup = [
          {
            title: __('Total page views')
            unity: __('page views')
            data: @data.summary.pageViews
          },
          {
            title: __('Total users')
            unity: __('users')
            data: @data.summary.uniqueUsers
          },
          {
            title: __('Total unique activities')
            unity: __('activities')
            data: @data.summary.uniqueActivities
          },
          {
            title: __('Total unique page views')
            unity: __('pages')
            data: @data.summary.uniquePages
          },
          {
            title: __('Mean session length')
            unity: __('Time (min)')
            data: @data.summary.meanSession
          },
          {
            title: __('Activity time')
            unity: __('days')
            data: @data.summary.dateRange
          }
        ]
        options =
          width: $('.data-summary .graph', content).innerWidth() ||
            Math.floor(content_width * .25)
          height: 214
          colors: colors
          legend: 'bottom'
          hAxis:
            textPosition: 'none'
          vAxis:
            minValue: 0
            format: 'decimal'
            viewWindowMode: 'maximized'
          tooltip:
            isHtml: true
        buttons = $('.data-summary .btn-download', content)
        graphics = $('.data-summary .graph', content)
        for item, i in dataGroup
          options.title = item.title
          options.vAxis.title = item.unity
          data = new google.visualization.DataTable()
          data.addColumn('string', 'id')
          data.addColumn('number', __('Saved'))
          data.addColumn('number', __('Selected'))
          data.addRows([[options.title].concat(item.data)])
          chart = new google.visualization.ColumnChart(graphics[i])
          chart.draw(data, options)
          $(buttons[i]).click(
            ((chart) ->
              -> download(chart.getImageURI(), 'chart.png')
            )(chart)
          )
      else
        $('.data-summary .graph', content).html(
          '<span>' + __('content_default_msg') + '</span>'
        )
      if @data.activity
        data = new google.visualization.DataTable()
        data.addColumn('string', 'id')
        data.addColumn('number', __('Total page views'))
        data.addRows(@data.activity.pageViews.total)
        options =
          title:  __('total page views per day')
          width: $('.data-activity .graph', content).innerWidth() ||
            Math.floor(content_width * .75) + 50
          height: 450
          colors: colors
          legend: 'top'
          hAxis:
            title: __('days')
          vAxis:
            title: __('page views')
            minValue: 0
            format: 'decimal'
            viewWindowMode: 'maximized'
          tooltip:
            isHtml: true
        if @data.activity.pageViews.total.length > 7
           options.hAxis.slantedText = true
           options.hAxis.slantedTextAngle = 45
        chart = new google.visualization.LineChart(
          $('.data-activity .graph', content)[0]
        )
        if @view?.activity
          [data, options] = @view?.activity?(data, options, @data.activity)
        chart.draw(data, options)
        $('.data-activity .btn-data-page-views', content).click(
          ((chart, data, options, activity) =>
            =>
              unless @view
                @view = {}
              @view.activity = (data, options, activity) ->
                data = new google.visualization.DataTable()
                data.addColumn('string', 'id')
                data.addColumn('number', __('Total page views'))
                data.addRows(activity.pageViews.total)
                options.title = __('Total page views per day')
                options.vAxis.title = __('page views')
                [data, options]
              [data, options] = @view.activity(data, options, activity)
              chart.draw(data, options)
          )(chart, data, options, @data.activity)
        )
        $('.data-activity .btn-data-page-views-users', content).click(
          ((chart, data, options, activity) =>
            =>
              unless @view
                @view = {}
              @view.activity = (data, options, activity) ->
                data = new google.visualization.DataTable()
                data.addColumn('string', 'id')
                for user in activity.users
                  data.addColumn('number', user)
                data.addRows(activity.pageViews.parcial)
                options.title = __('Total page views per day (users)')
                options.vAxis.title = __('page views')
                [data, options]
              [data, options] = @view.activity(data, options, activity)
              chart.draw(data, options)
          )(chart, data, options, @data.activity)
        )
        $('.data-activity .btn-data-unique-users', content).click(
          ((chart, data, options, activity) =>
            =>
              unless @view
                @view = {}
              @view.activity = (data, options, activity) ->
                data = new google.visualization.DataTable()
                data.addColumn('string', 'id')
                data.addColumn('number', __('Total users'))
                data.addRows(activity.uniqueUsers)
                options.title = __('User access per day')
                options.vAxis.title = __('users')
                [data, options]
              [data, options] = @view.activity(data, options, activity)
              chart.draw(data, options)
          )(chart, data, options, @data.activity)
        )
        $('.data-activity .btn-data-unique-activities', content).click(
          ((chart, data, options, activity) =>
            =>
              unless @view
                @view = {}
              @view.activity = (data, options, activity) ->
                data = new google.visualization.DataTable()
                data.addColumn('string', 'id')
                data.addColumn('number', __('Total unique activities'))
                data.addRows(activity.uniqueActivities.total)
                options.title = __('Total unique activities per day')
                options.vAxis.title = __('activities')
                [data, options]
              [data, options] = @view.activity(data, options, activity)
              chart.draw(data, options)
          )(chart, data, options, @data.activity)
        )
        $('.data-activity .btn-data-unique-activities-users', content).click(
          ((chart, data, options, activity) =>
            =>
              unless @view
                @view = {}
              @view.activity = (data, options, activity) ->
                data = new google.visualization.DataTable()
                data.addColumn('string', 'id')
                for user in activity.users
                  data.addColumn('number', user)
                data.addRows(activity.uniqueActivities.parcial)
                options.title = __('Total unique activities per day (users)')
                options.vAxis.title = __('activities')
                [data, options]
              [data, options] = @view.activity(data, options, activity)
              chart.draw(data, options)
          )(chart, data, options, @data.activity)
        )
        $('.data-activity .btn-data-unique-pages', content).click(
          ((chart, data, options, activity) =>
            =>
              unless @view
                @view = {}
              @view.activity = (data, options, activity) ->
                data = new google.visualization.DataTable()
                data.addColumn('string', 'id')
                data.addColumn('number', __('Total unique page views'))
                data.addRows(activity.uniquePages.total)
                options.title = __('Total unique page views per day')
                options.vAxis.title = __('page views')
                [data, options]
              [data, options] = @view.activity(data, options, activity)
              chart.draw(data, options)
          )(chart, data, options, @data.activity)
        )
        $('.data-activity .btn-data-unique-pages-users', content).click(
          ((chart, data, options, activity) =>
            =>
              unless @view
                @view = {}
              @view.activity = (data, options, activity) ->
                data = new google.visualization.DataTable()
                data.addColumn('string', 'id')
                for user in activity.users
                  data.addColumn('number', user)
                data.addRows(activity.uniquePages.parcial)
                options.title = __('Total unique page views per day (users)')
                options.vAxis.title = __('page views')
                [data, options]
              [data, options] = @view.activity(data, options, activity)
              chart.draw(data, options)
          )(chart, data, options, @data.activity)
        )
        $('.data-activity .btn-download', content).click(
          ((chart) ->
            -> download(chart.getImageURI(), 'chart.png')
          )(chart)
        )
      else
        $('.data-activity .graph', content).html(
          '<span>' + __('content_default_msg') + '</span>'
        )
      if @data.dayTime
        options =
          title:  __('Total activities per hour')
          width: $('.data-day-time .graph', content).innerWidth() ||
            Math.floor(content_width * .75) + 50
          height: 300
          colors: colors
          legend: 'top'
          hAxis:
            title: __('hour')
            ticks: [0..23]
            format: '#h'
          vAxis:
            title: __('activities')
            minValue: 0
            format: 'decimal'
            viewWindowMode: 'maximized'
          tooltip:
            isHtml: true
        unless @view
          @view = {}
        unless @view.dayTime
          @view.dayTime = {}
          for i in [0..7]
            @view.dayTime[i] = !i
        showDayTime = (options) =>
          temp = []
          for _, i in @data.dayTime[0]
            row = [i]
            for n, hours of @data.dayTime
              p = parseInt(n)
              if @view.dayTime[p]
                row.push(hours[i])
            temp.push(row)
          if temp[0].length == 1
            return
          data = new google.visualization.DataTable()
          data.addColumn('number', 'id')
          labels = [
            'All days',
            'Sunday',
            'Monday',
            'Tuesday',
            'Wednesday',
            'Thursday',
            'Friday',
            'Saturday'
          ]
          for i, selected of @view.dayTime
            if selected
              data.addColumn('number', __(labels[parseInt(i)]))
          data.addRows(temp)
          new google.visualization.NumberFormat(pattern: '#h').format(data, 0)
          chart = new google.visualization.LineChart(
            $('.data-day-time .graph', content)[0]
          )
          chart.draw(data, options)
          $('.data-day-time .btn-download', content).unbind('click')
          $('.data-day-time .btn-download', content).click(
            ((chart) ->
              -> download(chart.getImageURI(), 'chart.png')
            )(chart)
          )
        unless showDayTime(options)
          $('.data-day-time .graph', content).html(
            '<span>' + __('content_default_msg') + '</span>'
          )
        buttons = $('.data-day-time .togglebutton')
        for button, i in buttons
          $(button).on('change',
            ((i, options) =>
              (evt) =>
                checked = $('input[type="checkbox"]', evt.currentTarget)
                  .is(':checked')
                @view.dayTime[i] = checked
                unless showDayTime(options)
                  $('.data-day-time .graph', content).html(
                    '<span>' + __('content_default_msg') + '</span>'
                  )
            )(i, options)
          )
      else
        $('.data-day-time .graph', content).html(
          '<span>' + __('content_default_msg') + '</span>'
        )
      if @data.ranking
        options =
          width: $('.data-ranking .graph', content).innerWidth() ||
            Math.floor(content_width * .375) + 15
          height: 600
          colors: colors
          legend: 'top'
          title: __('Top users')
          vAxis:
            minValue: 0
            fotmat: 'decimal'
            viewWindowMode: 'maximized'
          tooltip:
            isHtml: true
        if @data.ranking.users.length > 7
           options.hAxis =
              slantedText: true
              slantedTextAngle: 45
        data = new google.visualization.DataTable()
        data.addColumn('string', 'id')
        data.addColumn('number', __('Total page views'))
        data.addColumn('number', __('Total unique activities'))
        data.addColumn('number', __('Total unique page views'))
        data.addColumn('number', __('Total days'))
        data.addRows(@data.ranking.users)
        chart = new google.visualization.ColumnChart(
          $('.data-ranking .graph', content)[0]
        )
        @view?.ranking?(data)
        chart.draw(data, options)
        buttons = $('.data-ranking .btn-sort', content)
        for button, i in buttons
          $(button).click(
            ((chart, data, options, i) =>
              =>
                unless @view
                  @view = {}
                @view.ranking = (data) ->
                  data.sort([{column: i, desc: i > 0}])
                @view.ranking(data)
                chart.draw(data, options)
            )(chart, data, options, i)
          )
        $('.data-ranking .btn-download', content).click(
          ((chart) ->
            -> download(chart.getImageURI(), 'chart.png')
          )(chart)
        )
      else
        $('.data-ranking .graph', content).html(
          '<span>' + __('content_default_msg') + '</span>'
        )
      unless $('.data', content).is(':visible')
        $('.default', content).hide()
        $('.data', content).show()
      @navActive()
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
    $('.dropdown-menu-opened li').on('click', ->
      $(@).parent().parent().toggleClass('open')
    )
    @

  refreshURL: (moodle = '') ->
    if moodle
      @url = moodle
      moodle = '?moodle=' + moodle
    else
      delete @url
    window.history.pushState(
      null,
      $('title').text(),
      location.pathname + moodle
    )
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
        $('#submenu-courses').fadeIn()
    )
    $('#submenu-courses').mouseover(->
      $('.sidebar nav li .active').removeClass('active')
      $('.sidebar nav li .btn-courses').addClass('active')
    )
    $('.btn-users', nav).click(->
      unless $('#submenu-users').is(':visible')
        $('.submenu-item').hide()
        $('#submenu-users').fadeIn()
    )
    $('#submenu-users').mouseover(->
      $('.sidebar nav li .active').removeClass('active')
      $('.sidebar nav li .btn-users').addClass('active')
    )
    $('.btn-daterange', nav).click(->
      unless $('#submenu-daterange').is(':visible')
        $('.submenu-item').hide()
        $('#submenu-daterange').fadeIn()
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
      @updateData()
      fullscreen = '<i class="material-icons">fullscreen'
      if (!window.screenTop && !window.screenY)
        fullscreen += '_exit</i> ' + __('Fullscreen (exit)') + '</a>'
      else
        fullscreen += '</i> ' + __('Fullscreen') + '</a>'
      $('.btn-fullscreen').html(fullscreen)
    )
    @

  isNotFullScreen: ->
    document.fullScreenElement? ||
      (!document.mozFullScreen && !document.webkitIsFullScreen)

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
    console.log('sendMessage:', msg)
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

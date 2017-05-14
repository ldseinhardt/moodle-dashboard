###
# activity
###

class Activity extends ViewBase
  constructor: (@name, @group, @view) ->
    super(@name, @group)

  init: (@course, @role, @filters) ->
    super(@course, @role, @filters)
    @_data =
      users: []
      pageViews:
        total: []
        parcial: []
      uniqueUsers: []
      uniqueActivities:
        total: []
        parcial: []
      uniquePages:
        total: []
        parcial: []
      meanSession:
        total: []
        parcial: []
      bounceRate: []
    @_selected =
      users: {}
      tree: {}
    @report =
      headers: [],
      data: []
    @

  selected: (row) ->
    if @filter(row.event, row.page)
      return @
    unless @_selected.users[row.user]
      @_selected.users[row.user] = 1
    unless @_selected.tree[row.day]
      @_selected.tree[row.day] =
        users: {}
        activities: {}
        pages: {}
    unless @_selected.tree[row.day].users[row.user]
      @_selected.tree[row.day].users[row.user] =
        pageViews: 0
        sessions: []
    @_selected.tree[row.day].users[row.user].sessions.push(row.time / 1000)
    unless @_selected.tree[row.day].activities[row.event.fullname]
      @_selected.tree[row.day].activities[row.event.fullname] = {}
    unless @_selected.tree[row.day].activities[row.event.fullname][row.user]
      @_selected.tree[row.day].activities[row.event.fullname][row.user] = 1
    if /view/.test(row.event.name) || /view/.test(row.description)
      @_selected.tree[row.day].users[row.user].pageViews += row.size
      unless @_selected.tree[row.day].pages[row.page]
        @_selected.tree[row.day].pages[row.page] = {}
      unless @_selected.tree[row.day].pages[row.page][row.user]
        @_selected.tree[row.day].pages[row.page][row.user] = 1
    @

  getData: ->
    unless Object.keys(@_selected.users).length
      return
    for i of @_selected.users
      user = @course.users[@role].list[i]
      @_data.users.push(user.firstname + ' ' + user.lastname)
    timelist = Object.keys(@_selected.tree)
    timelist.sort((a, b) ->
      if a < b
        return -1
      if a > b
        return 1
      return 0
    )
    for day in timelist
      value = @_selected.tree[day]
      pageViews = []
      activities = []
      pages = []
      sessions =
        total:
          value: 0
          users: 0
        parcial: []
      bounce =
        value: 0
        total: 0
      for i of @_selected.users
        count = 0
        session = 0
        if value.users[i]
          count = value.users[i].pageViews
          times = value.users[i].sessions.sort((a, b) ->
            if a < b
              return -1
            if a > b
              return 1
            return 0
          )
          _sessions = []
          a = times[0]
          b = times[0]
          for t in times
            if t - b > @sessiontime
              _sessions.push(b - a)
              a = t
            b = t
          _sessions.push(b - a)
          bounce.total += _sessions.length
          bounce.value += _sessions.filter((e) -> e == 0).length
          minutes = _sessions.reduce((a, b) -> a + b) / (_sessions.length * 60)
          session = Math.round(minutes * 100) / 100
          sessions.total.value += minutes
          sessions.total.users++
        pageViews.push(count)
        sessions.parcial.push(session)
        count = 0
        for activitie, users of value.activities
          if users[i]
            count++
        activities.push(count)
        count = 0
        for page, users of value.pages
          if users[i]
            count++
        pages.push(count)
      date = new Date(parseInt(day)).toLocaleString().split(/\s/)[0]
      @_data.pageViews.total.push([date, pageViews.reduce((a, b) -> a + b)])
      @_data.uniqueActivities.total
        .push([date, Object.keys(value.activities).length])
      @_data.uniquePages.total.push([date, Object.keys(value.pages).length])
      minutes = sessions.total.value / sessions.total.users
      @_data.meanSession.total.push([date, Math.round(minutes * 100) / 100])
      pageViews.unshift(date)
      activities.unshift(date)
      pages.unshift(date)
      sessions.parcial.unshift(date)
      @_data.pageViews.parcial.push(pageViews)
      @_data.uniqueUsers.push([date, Object.keys(value.users).length])
      @_data.uniqueActivities.parcial.push(activities)
      @_data.uniquePages.parcial.push(pages)
      @_data.meanSession.parcial.push(sessions.parcial)
      @_data.bounceRate
        .push([date, Math.round((bounce.value / bounce.total) * 100) / 100])
    unless @_data.pageViews?.total[0]?.length > 1
      return
    @_data

  template: (title, views) ->
    html = """
      <div class="col-md-12">
        <div class="panel panel-default">
          <div class="panel-heading">
            <div class="panel-title" style="margin-right: -250px; padding-right: 250px;">
              <div class="title" data-toggle="tooltip" data-placement="right" data-original-title="#{__(title)}">#{__(title)}</div>
            </div>
            <div class="panel-options" style="width: 250px;">
              <div class="btn-group">
                <a class="dropdown-toggle" data-target="#" data-toggle="dropdown">
                  <i class="material-icons">&#xE8F4;</i>
                </a>
                <ul class="dropdown-menu dropdown-menu-right">
    """
    for view, i in views
      actived = if @view.index == i then ' active' else ''
      html += """
                  <li>
                    <a href="#" class="btn-view#{actived}">#{__(view)}</a>
                  </li>
      """
    html += """
                </ul>
              </div>
              <div class="btn-group">
                <a class="btn-zoom">
                  <i class="material-icons">&#xE900;</i>
                </a>
              </div>
              <div class="btn-group">
                <a href="#" class="btn-download">
                  <i class="material-icons">&#xE80D;</i>
                </a>
              </div>
              <div class="btn-group">
                <a href="#" class="btn-report">
                  <i class="material-icons">&#xE2C4;</i>
                </a>
              </div>
              <i class="material-icons info" data-toggle="tooltip" data-placement="left" data-original-title="#{__('data_' + title + '_description')}">&#xE88E;</i>
            </div>
          </div>
          <div class="panel-body">
            <div class="graph"></div>
            <div class="panel-controls">
              <a class="btn-prev">
                <span class="glyphicon glyphicon-chevron-left"></span>
              </a>
              <a class="btn-next">
                <span class="glyphicon glyphicon-chevron-right"></span>
              </a>
            </div>
          </div>
        </div>
      </div>
    """

  render: ->
    data = @getData()
    unless data
      @ctx.html('')
      return
    @views = [
      {
        title: 'Total page views per day'
        unity: __('page views', true)
        labels: [__('Total page views')]
        data: data.pageViews.total
      },
      {
        title: 'Total page views per day (participants)'
        unity: __('page views', true)
        labels: data.users
        data: data.pageViews.parcial
      },
      {
        title: 'Total unique participants per day'
        unity: __('participants', true)
        labels: [__('Total participants')]
        data: data.uniqueUsers
      },
      {
        title: 'Total unique activities per day'
        unity: __('activities', true)
        labels: [__('Total unique activities')]
        data: data.uniqueActivities.total
      },
      {
        title: 'Total unique activities per day (participants)'
        unity: __('activities', true)
        labels: data.users
        data: data.uniqueActivities.parcial
      },
      {
        title: 'Total unique page views per day'
        unity: __('page views', true)
        labels: [__('Total unique page views')]
        data: data.uniquePages.total
      },
      {
        title: 'Total unique page views per day (participants)'
        unity: __('page views', true)
        labels: data.users
        data: data.uniquePages.parcial
      },
      {
        title: 'Mean session length per day'
        unity: __('time (min)', true)
        labels: [__('Mean session length')]
        format: '# min'
        data: data.meanSession.total
      },
      {
        title: 'Mean session length per day (participants)'
        unity: __('time (min)', true)
        labels: data.users
        format: '# min'
        data: data.meanSession.parcial
      },
      {
        title: 'Bounce rate per day'
        unity: __('% of sessions')
        labels: [__('Bounce rate')]
        format: '#%'
        formatter: new google.visualization.NumberFormat(pattern: '#%')
        data: data.bounceRate
      }
    ]
    options =
      height: 350
      legend:
        position: 'top'
        textStyle:
          fontSize: 11
          color: '#111'
      chartArea:
        top: 30
        left: 100
      hAxis:
        title: __('days', true)
        textStyle :
          fontSize: 11
          color: '#111'
      vAxis:
        minValue: 0
        format: 'decimal'
        viewWindowMode: 'maximized'
        textStyle :
          fontSize: 11
          color: '#111'
      explorer:
        maxZoomOut: 1
        keepInBounds: true
    @extendOptions(options)
    title = @views[@view.index].title
    views = []
    for view in @views
      views.push(view.title)
    @ctx.html(@template(title, views))
    $('[data-toggle=tooltip]', @ctx).tooltip()
    @chart = new google.visualization.LineChart($('.graph', @ctx)[0])
    @show()
    $('.btn-download', @ctx).click(=> @download(
      @chart.getImageURI(),
      __(@views[@view.index].title).replace(/\s/g, '_') + '.png'
    ))
    $('.btn-report', @ctx).click(=> @download(
      @table(@report.headers, @report.data),
      __(@views[@view.index].title).replace(/\s/g, '_') + '.csv'
    ))
    buttons = $('.btn-view', @ctx)
    for button, i in buttons
      $(button).click(
        ((i) =>
          => @show(i)
        )(i)
      )
    if @max > 7
      unless $('.panel-controls', @ctx).is(':visible')
        $('.panel-controls', @ctx).show()
      google.visualization.events.addListener(@chart, 'select', =>
        if @options.hAxis.viewWindow.min == 0 && @options.hAxis.viewWindow.max == @max
          $('.btn-zoom > i', @ctx).html('zoom_out')
          $('.panel-controls', @ctx).show()
          row = @chart.getSelection()[0].row + 1
          @zoom.min = row - 4
          @zoom.max = row + 3
          dif = @zoom.max - @max
          if dif > 0
            @zoom.min -= dif
            @zoom.max -= dif
          dif = @zoom.min
          if dif < 0
            @zoom.min += dif * -1
            @zoom.max += dif * -1
          @options.hAxis.viewWindow = @zoom
          @chart.draw(@data, @options)
      )
      $('.btn-zoom', @ctx).click(=>
        if @chart
          if @options.hAxis.viewWindow.min == 0 && @options.hAxis.viewWindow.max == @max
            $('.btn-zoom > i', @ctx).html('zoom_out')
            $('.panel-controls', @ctx).show()
            @options.hAxis.viewWindow = @zoom
          else
            $('.btn-zoom > i', @ctx).html('zoom_in')
            $('.panel-controls', @ctx).hide()
            @zoom = @options.hAxis.viewWindow
            @options.hAxis.viewWindow =
              min: 0
              max: @max
          @chart.draw(@data, @options)
      )
      $('.btn-prev', @ctx).click(=>
        if @chart && @options.hAxis.viewWindow.min > 0
          @options.hAxis.viewWindow.min--
          @options.hAxis.viewWindow.max--
          @chart.draw(@data, @options)
      )
      $('.btn-next', @ctx).click(=>
        if @chart && @options.hAxis.viewWindow.max < @max
          @options.hAxis.viewWindow.min++
          @options.hAxis.viewWindow.max++
          @chart.draw(@data, @options)
      )
    else
      $('.panel-controls', @ctx).hide()
    @

  resize: (isNotFullScreen) ->
    super(isNotFullScreen)
    if @chart && @ctx.is(':visible')
      @options.width = $('.graph', @ctx).innerWidth()
      @options.chartArea.width = @options.width - @options.chartArea.left - 30
      @show()
    @

  show: (index) ->
    @view.index = index if index?
    view = @views[@view.index]
    @report =
      headers: [__('Date')].concat(view.labels)
      data: JSON.parse(JSON.stringify(view.data)).map((e) =>
        e[0] = new Date(e[0]).toLocaleDateString(langId)
        e
      )
    @data = new google.visualization.DataTable()
    @data.addColumn('string', 'id')
    for label in view.labels
      @data.addColumn('number', label)
    @data.addRows(view.data)
    if view.format
      @options.vAxis.format = view.format
    else
      delete @options.vAxis.format
    view.formatter?.format(@data, 1)
    title = $('.title', @ctx)
    title.html(__(view.title))
    title.attr('data-original-title', __(view.title))
    description = __('data_' + view.title.toLowerCase() + '_description')
    $('.panel-options > .info', @ctx).attr('data-original-title', description)
    unless @max && @max == view.data.length
      @max = view.data.length
      @zoom =
        min: if @max - 7 < 0 then 0 else @max - 7
        max: @max
    @options.hAxis.viewWindow = @zoom
    @options.vAxis.title = view.unity
    @options.vAxis.minValue = if @view.index == 2 then 1 else 0
    @options.chartArea.width = $('.graph', @ctx).innerWidth() - @options.chartArea.left - 30
    if @ctx.is(':visible')
      @chart.draw(@data, @options)
    $('.btn-view.active', @ctx).removeClass('active')
    $($('.btn-view', @ctx)[@view.index]).addClass('active')
    @

view =
  index: 0

@view.register(
  new Activity('activity', 'general', view),
  new Activity('activity', 'course', view),
  new Activity('activity', 'content', view),
  new Activity('activity', 'assign', view),
  new Activity('activity', 'forum', view),
  new Activity('activity', 'chat', view),
  new Activity('activity', 'choice', view),
  new Activity('activity', 'quiz', view),
  new Activity('activity', 'blog', view),
  new Activity('activity', 'wiki', view)
)

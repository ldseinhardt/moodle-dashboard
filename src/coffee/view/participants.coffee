###
# participants: participants view
###

class Participants extends ViewBase
  constructor: (@name, @group, @view) ->
    super(@name, @group)

  init: (@users, @dates, @role) ->
    super(@users, @dates, @role)
    @_data =
      totalViews: []
      activities: []
      pages: []
      dates: []
      bounceRate: []
    @_selected = {}
    @

  selected: (row) ->
    if @filter(row.event, row.page)
      return @
    unless @_selected[row.user]
      @_selected[row.user] =
        totalViews: 0
        activities: {}
        pages: {}
        dates: {}
    unless @_selected[row.user].dates[row.day]
      @_selected[row.user].dates[row.day] = []
    @_selected[row.user].dates[row.day].push(row.time / 1000)
    unless @_selected[row.user].activities[row.event.fullname]
      @_selected[row.user].activities[row.event.fullname] = 1
    if /view/.test(row.event.name)
      @_selected[row.user].totalViews += row.size
      unless @_selected[row.user].pages[row.page]
        @_selected[row.user].pages[row.page] = 1
      @

  getData: ->
    unless Object.keys(@_selected).length
      return
    for i, values of @_selected
      user = @users[i]
      name = user.firstname + ' ' + user.lastname
      @_data.totalViews.push([name, values.totalViews])
      @_data.activities.push([name, Object.keys(values.activities).length])
      @_data.pages.push([name, Object.keys(values.pages).length])
      @_data.dates.push([name, Object.keys(values.dates).length])
      _sessions = []
      for day, times of values.dates
        times.sort((a, b) ->
          if a < b
            return -1
          if a > b
            return 1
          return 0
        )
        a = times[0]
        b = times[0]
        for t in times
          if t - a > @sessiontime
            _sessions.push(b - a)
            a = t
          b = t
        _sessions.push(b - a)
      bounceRate = Math.round(
        (_sessions.filter((e) -> e == 0).length / _sessions.length) * 100
      )
      @_data.bounceRate.push([name, bounceRate])
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
                <a class="dropdown-toggle btn-graph" data-target="#" data-toggle="dropdown">
                  <i class="material-icons">&#xE8F4;</i>
                </a>
                <ul class="dropdown-menu dropdown-menu-right">
    """
    for view, i in views
      html += """
                  <li>
                    <a href="#" class="btn-view">#{__(view)}</a>
                  </li>
      """
    html += """
                </ul>
              </div>
              <div class="btn-group btn-sort">
                <a class="dropdown-toggle" data-target="#" data-toggle="dropdown">
                  <i class="material-icons">&#xE164;</i>
                </a>
                <ul class="dropdown-menu dropdown-menu-right"></ul>
              </div>
              <div class="btn-group">
                <a class="btn-table">
                  <i class="material-icons">&#xE8EF;</i>
                </a>
              </div>
              <div class="btn-group">
                <a class="btn-download">
                  <i class="material-icons">&#xE2C4;</i>
                </a>
              </div>
              <i class="material-icons info" data-toggle="tooltip" data-placement="left" data-original-title="#{__('data_' + title + '_description')}">&#xE88E;</i>
            </div>
          </div>
          <div class="panel-body">
            <div class="graph"></div>
            <div class="tablebox" style="display: none">
              <table class="table table-striped table-hover"></table>
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
        title: __('Page views')
        data: data.totalViews
      },
      {
        title: __('Unique activities')
        data: data.activities
      },
      {
        title: __('Unique page views')
        data: data.pages
      },
      {
        title: __('Days')
        data: data.dates
      },
      {
        title: __('Bounce rate')
        data: data.bounceRate
      }
    ]
    title = 'Top participants'
    views = []
    for view in @views
      views.push(view.title)
    @ctx.html(@template(title, views))
    $('[data-toggle=tooltip]', @ctx).tooltip()
    options =
      legend: 'top'
      vAxis:
        minValue: 0
        format: 'decimal'
        viewWindowMode: 'maximized'
      explorer:
        maxZoomOut: 1
        keepInBounds: true
      seriesType: 'bars'
      series:
        1:
          type: "line",
        2:
          type: "line",
    @extendOptions(options)
    @chart = new google.visualization.BarChart($('.graph', @ctx)[0])
    @show()
    $('.btn-download', @ctx).click(=> @download(
      @chart.getImageURI(),
      (__(title) + '_' +__(@views[@view.index].title, true)).replace(/\s/g, '_') + '.png'
    ))
    buttons = $('.btn-view', @ctx)
    for button, i in buttons
      $(button).click(
        ((i) =>
          => @show(i)
        )(i)
      )
    $('.btn-table', @ctx).click(=>
      @view.graph = false
      @show()
    )
    $('.btn-graph', @ctx).click(=>
      @view.graph = true
      @show()
    )
    keys = [{title: __('Participant')}].concat(@views).map((value) -> value.title)
    data = @views[0].data.map((v) ->
      item = {}
      item[keys[0]] = v[0]
      item[keys[1]] = v[1]
      item
    )
    @views[1].data.map((v, i) -> data[i][keys[2]] = v[1])
    @views[2].data.map((v, i) -> data[i][keys[3]] = v[1])
    @views[3].data.map((v, i) -> data[i][keys[4]] = v[1])
    @views[4].data.map((v, i) -> data[i][keys[5]] = v[1])
    $('.tablebox > table', @ctx).bootstrapTable(
      columns: keys.map((key, i) ->
        column =
          field: key
          title: key
          sortable: true
          halign: 'center'
          valign: 'middle'
          align: 'left'
        if i == keys.length - 1
          column.formatter = (value) -> value + '%'
        if i > 0
          column.align = 'center'
        column
      )
      data: data
      sortName: keys[0]
      search: true
      showToggle: true
      showColumns: true
      locale: langId
    )
    @

  resize: (isNotFullScreen) ->
    super(isNotFullScreen)
    if @chart && @ctx.is(':visible')
      @options.width = $('.graph', @ctx).innerWidth()
      @options.chartArea.width = @options.width - 230
      @show()
    @

  getDataView: (data) ->
    viewWithKey = new google.visualization.DataView(data)
    viewWithKey.setColumns([
      0,
      1,
      {
        type: 'string'
        label: ''
        calc: (d, r) -> ''
      },
      {
        type: 'string'
        label: ''
        calc: (d, r) -> ''
      }
    ])
    groupAVG = google.visualization.data.group(viewWithKey, [2], [{
      column: 1
      id: 'avg'
      label: __('Average')
      aggregation: google.visualization.data.avg
      type: 'number'
    }])
    groupSD = google.visualization.data.group(viewWithKey, [3], [{
      column: 1
      id: 'sd'
      label: __('Standard deviation')
      aggregation: (values) ->
        Math.sqrt(values.map((v) -> Math.pow(v - values.reduce((a, b) -> a + b) / values.length, 2)).reduce((a, b) -> a + b) / (values.length - 1))
      type: 'number'
    }])
    dv = new google.visualization.DataView(data)
    dv.setColumns([
      0,
      1,
      {
        type: 'number'
        label: __('Average')
        calc: (dt, row) -> Math.round(groupAVG.getValue(0, 1) * 100) / 100
      },
      {
        type: 'number'
        label: __('Standard deviation')
        calc: (dt, row) -> Math.round(groupSD.getValue(0, 1) * 100) / 100
      }
    ])
    dv

  show: (index) ->
    @view.index = index if index?
    view = @views[@view.index]
    graph = $('.graph', @ctx)
    table = $('.tablebox', @ctx)
    if @view.graph
      unless graph.is(':visible')
        table.hide()
        graph.show()
      @data = new google.visualization.DataTable()
      @data.addColumn('string', 'id')
      @data.addColumn('number', view.title)
      @data.addRows(view.data)
      chartAreaHeight = @data.getNumberOfRows() * 25
      @options.height = chartAreaHeight + 80
      @options.chartArea =
        left: 200
        height: chartAreaHeight
        width: $('.graph', @ctx).innerWidth() - 230
      @sort()
      if @ctx.is(':visible')
        @chart.draw(@getDataView(@data), @options)
    else if !table.is(':visible')
      graph.hide()
      table.show()
    $('.btn-view.active', @ctx).removeClass('active')
    $($('.btn-view', @ctx)[@view.index]).addClass('active')
    labels = ['name', view.title]
    btn_sort = ''
    for label, i in labels
      actived = if @view.sort == i then ' class="active"' else ''
      btn_sort += """
        <li>
          <a#{actived}>
            #{__('Sort by')} #{__(label, true)}
          </a>
        </li>
      """
    $('.btn-sort ul', @ctx).html(btn_sort)
    buttons = $('.btn-sort ul a', @ctx)
    for button, i in buttons
      $(button).click(
        ((i) =>
          =>
            @sort(i)
            @chart.draw(@getDataView(@data), @options)
            $('.btn-sort ul li .active', @ctx).removeClass('active')
            $($('.btn-sort ul li a', @ctx)[i]).addClass('active')
        )(i)
      )
    @

  sort: (index) ->
    @view.sort = index if index?
    desc = @view.sort > 0
    if @view.index == @views.length - 1
      desc = false
    @data.sort([{column: @view.sort, desc: desc}])
    @

view =
  index: 0
  sort: 1
  graph: true

@view.register(
  new Participants('participants', 'general', view),
  new Participants('participants', 'course', view),
  new Participants('participants', 'content', view),
  new Participants('participants', 'assign', view),
  new Participants('participants', 'forum', view),
  new Participants('participants', 'chat', view),
  new Participants('participants', 'choice', view),
  new Participants('participants', 'quiz', view),
  new Participants('participants', 'blog', view),
  new Participants('participants', 'wiki', view)
)

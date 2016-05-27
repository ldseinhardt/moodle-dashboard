###
# summary
###

class Summary extends ViewBase
  init: (@course, @role, @filters) ->
    super(@course, @role, @filters)
    @_data =
      pageViews: [0, 0]
      meanSession: [0, 0]
    @_recorded =
      activities: {}
      pages: {}
      sessions: {}
    @_selected =
      activities: {}
      pages: {}
      sessions: {}
    @

  selected: (row) ->
    if @filter(row.event, row.page)
      return @
    unless @_selected.sessions[row.user]
      @_selected.sessions[row.user] = {}
    unless @_selected.sessions[row.user][row.day]
      @_selected.sessions[row.user][row.day] = []
    @_selected.sessions[row.user][row.day].push(row.time / 1000)
    unless @_selected.activities[row.event.fullname]
      @_selected.activities[row.event.fullname] = 1
    if /view/.test(row.event.name) || /view/.test(row.description)
      @_data.pageViews[1] += row.size
      unless @_selected.pages[row.page]
        @_selected.pages[row.page] = 1
    @

  recorded: (row) ->
    if @filter(row.event, row.page)
      return @
    unless @_recorded.sessions[row.user]
      @_recorded.sessions[row.user] = {}
    unless @_recorded.sessions[row.user][row.day]
      @_recorded.sessions[row.user][row.day] = []
    @_recorded.sessions[row.user][row.day].push(row.time / 1000)
    unless @_recorded.activities[row.event.fullname]
      @_recorded.activities[row.event.fullname] = 1
    if /view/.test(row.event.name) || /view/.test(row.description)
      @_data.pageViews[0] += row.size
      unless @_recorded.pages[row.page]
        @_recorded.pages[row.page] = 1
    @

  getData: ->
    for type, i in ['_recorded', '_selected']
      sessions = []
      for user, days of @[type].sessions
        for day, times of days
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
            if t - b > @sessiontime
              sessions.push(b - a)
              a = t
            b = t
          sessions.push(b - a)
      if sessions.length
        minutes = sessions.reduce((a, b) -> a + b) / (sessions.length * 60)
        @_data.meanSession[i] = Math.round(minutes * 100) / 100
    @_data.uniqueActivities = [
      Object.keys(@_recorded.activities).length,
      Object.keys(@_selected.activities).length
    ]
    @_data.uniquePages = [
      Object.keys(@_recorded.pages).length,
      Object.keys(@_selected.pages).length
    ]
    @_data

  template: (title) ->
    """
      <div class="col-md-3">
        <div class="panel panel-default">
          <div class="panel-heading">
            <div class="panel-title">
              <div class="title" data-toggle="tooltip" data-placement="right" data-original-title="#{__(title)}">#{__(title)}</div>
            </div>
            <div class="panel-options">
              <div class="btn-group">
                <a href="#" class="btn-download">
                  <i class="material-icons">&#xE2C4;</i>
                </a>
              </div>
              <i class="material-icons info" data-toggle="tooltip" data-placement="left" data-original-title="#{__('data_' + title + '_description')}">&#xE88E;</i>
            </div>
          </div>
          <div class="panel-body">
            <div class="graph"></div>
          </div>
        </div>
      </div>
    """

  render: ->
    data = @getData()
    unless data.pageViews[0]
      $('#' + @group + ' > .data').hide()
      $('#' + @group + ' > .default').show()
      return
    @views = [
      {
        title: 'Total page views'
        unity: __('page views', true)
        data: data.pageViews
      },
      {
        title: 'Total unique activities'
        unity: __('activities', true)
        data: data.uniqueActivities
      },
      {
        title: 'Total unique page views'
        unity: __('pages', true)
        data: data.uniquePages
      },
      {
        title: 'Mean session length'
        unity: __('time (min)', true)
        data: data.meanSession
      }
    ]
    options =
      legend:
        position: 'top'
        textStyle:
          fontSize: 11
          color: '#111'
      chartArea:
        top: 30
      hAxis:
        textPosition: 'none'
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
    @extendOptions(options)
    template = ''
    for view, i in @views
      template += @template(view.title)
    @ctx.html(template)
    $('[data-toggle=tooltip]', @ctx).tooltip()
    graphics = $('.graph', @ctx)
    buttons = $('.btn-download', @ctx)
    for view, i in @views
      title = __(view.title)
      @options.vAxis.title = view.unity
      data = new google.visualization.DataTable()
      data.addColumn('string', 'id')
      data.addColumn('number', __('Saved'))
      data.addColumn('number', __('Selected'))
      data.addRows([[title].concat(view.data)])
      @views[i] =
        options: @clone(@options)
        data: data
        chart: new google.visualization.ColumnChart(graphics[i])
      view = @views[i]
      if @ctx.is(':visible')
        view.chart.draw(view.data, view.options)
      $(buttons[i]).click(
        ((chart, title) =>
          => @download(chart.getImageURI(), title + '.png')
        )(view.chart, title.replace(/\s/g, '_'))
      )
    @

  resize: (isNotFullScreen) ->
    super(isNotFullScreen)
    if @views && @ctx.is(':visible')
      width = $('.graph', @ctx).innerWidth()
      for view in @views
        view.options.width = width
        view.chart.draw(view.data, view.options)
    @

@view.register(
  new Summary('summary', 'general'),
  new Summary('summary', 'course'),
  new Summary('summary', 'content'),
  new Summary('summary', 'assign'),
  new Summary('summary', 'forum'),
  new Summary('summary', 'chat'),
  new Summary('summary', 'choice'),
  new Summary('summary', 'quiz'),
  new Summary('summary', 'blog'),
  new Summary('summary', 'wiki')
)

###
# metrics comparation
###

class MetricsComparation extends ViewBase
  constructor: (@name, @group, @view) ->
    super(@name, @group)

  init: (@course, @role, @filters) ->
    super(@course, @role, @filters)
    @labels = [
      __('Page views'),
      __('Unique activities'),
      __('Unique page views'),
      __('Number of sessions'),
      __('Mean session length'),
      __('Bounce rate'),
      __('Accessed days')
    ]
    @_data =
      users: []
      roles: []
      pageViews: []
      activities: []
      pages: []
      numberSessions: []
      meanSession: []
      bounceRate: []
      dates: []
    for role in @course.users
      for user in role.list
        @_data.users.push(user.name)
        @_data.roles.push(__(role.role))
        d =
          pageViews: 0
          dates: {}
          activities: {}
          pages: {}
        if user.selected && user.data
          for day, components of user.data
            if @min.selected <= day <= @max.selected
              d.dates[day] = []
              for component, eventnames of components
                for eventname, eventcontexts of eventnames
                  for eventcontext, descriptions of eventcontexts
                    evtfullname = eventname + ' (' + eventcontext + ')'
                    for description, hours of descriptions
                      page = eventcontext
                      page = description if /^http/.test(page)
                      if @filters.indexOf(evtfullname) == -1
                        d.activities[evtfullname] = 1
                        for time, size of hours
                          d.dates[day].push(time / 1000)
                          if /view/.test(eventname) || /view/.test(description)
                            d.pageViews += size
                            d.pages[page] = 1
        @_data.pageViews.push(d.pageViews)
        @_data.dates.push(Object.keys(d.dates).length)
        @_data.activities.push(Object.keys(d.activities).length)
        @_data.pages.push(Object.keys(d.pages).length)
        _sessions = []
        for day, times of d.dates
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
        if _sessions.length
          minutes = _sessions.reduce((a, b) -> a + b) / (_sessions.length * 60)
          @_data.numberSessions.push(_sessions.length)
          @_data.meanSession.push(Math.round(minutes * 100) / 100)
          @_data.bounceRate.push(Math.round(
            (_sessions.filter((e) -> e == 0).length / _sessions.length) * 100
          ))
        else
          @_data.numberSessions.push(0)
          @_data.meanSession.push(0)
          @_data.bounceRate.push(100)
    @

  getData: (a, b) ->
    users = @_data.users
    roles = @_data.roles
    metrics = [
      @_data.pageViews
      @_data.activities
      @_data.pages
      @_data.numberSessions
      @_data.meanSession
      @_data.bounceRate
      @_data.dates
    ]
    x = metrics[a]
    y = metrics[b]
    data =
      rows: []
      x:
        label: @labels[a]
        min: Math.min.apply(null, x)
        max: Math.max.apply(null, x)
      y:
        label: @labels[b]
        min: Math.min.apply(null, y)
        max: Math.max.apply(null, y)
    _data = users.map((v, i) -> [v, x[i], y[i], roles[i]])
    for row in _data
      filter = data.rows.filter((d) ->
        row[1] == d[1] && row[2] == d[2] && row[3] == d[3]
      )
      if filter.length
        filter[0][0] += ', ' + row[0]
      else
        data.rows.push(row)
    data

  template: ->
    html = """
      <div class="col-md-12">
        <div class="panel panel-default">
          <div class="panel-heading">
            <div class="panel-title" style="margin-right: -340px; padding-right: 340px;">
              <div class="title" data-toggle="tooltip" data-placement="right" data-original-title=""></div>
            </div>
            <div class="panel-options" style="width: 340px;">
              <select style="position: relative; top: -10px" class="selectpicker" multiple data-max-options="2" title="#{__('Select 2 metrics')}" data-selected-text-format="static" data-width="240">
    """
    for label, i in @labels
      html += """
                <option value="#{i}">#{label}</option>
      """
    html += """
              </select>
              <div class="btn-group">
                <a href="#" class="btn-download">
                  <i class="material-icons">&#xE2C4;</i>
                </a>
              </div>
              <i class="material-icons info" data-toggle="tooltip" data-placement="left" data-original-title="#{__('data_metrics_comparation_description')}">&#xE88E;</i>
            </div>
          </div>
          <div class="panel-body">
            <div class="graph"></div>
            <div class="text-center">#{__('private_message_notify')}</div>
          </div>
        </div>
      </div>
    """

  render: ->
    @ctx.html(@template())
    $($('select option', @ctx)[@view.a]).prop('selected', true)
    $($('select option', @ctx)[@view.b]).prop('selected', true)
    $('.selectpicker').selectpicker()
    $('[data-toggle=tooltip]', @ctx).tooltip()
    width = $('.graph', @ctx).innerWidth()
    options =
      width: width
      height: 300
      colors: @getColors()
      chartArea:
        top: 30
        left: 50
        width: width - 50
      legend:
        position: 'top'
        textStyle:
          fontSize: 11
          color: '#111'
      hAxis:
        textStyle :
          fontSize: 11
          color: '#111'
      vAxis:
        textStyle :
          fontSize: 11
          color: '#111'
      sizeAxis:
        minSize: 5
        maxSize: 5
      bubble:
        textStyle:
          fontSize: 11
      explorer:
        maxZoomOut: 1
        keepInBounds: true
    @extendOptions(options)
    @chart = new google.visualization.BubbleChart($('.graph', @ctx)[0])
    google.visualization.events.addListener(@chart, 'select', =>
      selected = @chart.getSelection()[0]
      if selected
        names = @data.getValue(selected.row || 0, 0).split(', ')
        group = @data.getValue(selected.row || 0, 3)
        roles = @course.users.filter((d) -> __(d.role) == group)
        if names.length && roles.length
          window.client.sendMoodleMessage(
            roles[0].list.filter((d) -> names.indexOf(d.name) != -1)
          )
    )
    @show()
    $('select', @ctx).change((evt) =>
      options = $('option:selected', evt.currentTarget)
      if options.length == 2
        @view =
          a: $(options[0]).val()
          b: $(options[1]).val()
        @show()
    )
    $('.btn-download', @ctx).click(=> @download(
      @chart.getImageURI(),
      __(@title).replace(/\s/g, '_') + '.png'
    ))
    @

  resize: (isNotFullScreen) ->
    super(isNotFullScreen)
    if @chart && @ctx.is(':visible')
      @options.width = $('.graph', @ctx).innerWidth()
      @options.chartArea.width = @options.width - @options.chartArea.left
      @chart.draw(@data, @options)
    @

  show: ->
    data = @getData(@view.a, @view.b)
    @title = "#{data.x.label} vs. #{data.y.label}"
    $('.title', @ctx).html(@title)
    $('.title', @ctx).attr('data-original-title', @title)
    @data = new google.visualization.DataTable()
    @data.addColumn('string', 'Id')
    @data.addColumn('number', data.x.label)
    @data.addColumn('number', data.y.label)
    @data.addColumn('string', __('Role'))
    @data.addRows(data.rows)
    @options.hAxis.title = data.x.label
    @options.hAxis.minValue = data.x.min - 5
    @options.hAxis.maxValue = data.x.max + 5
    @options.vAxis.title = data.y.label
    @options.vAxis.minValue = data.y.min - 5
    @options.vAxis.maxValue = data.y.max + 5
    @chart.draw(@data, @options)
    @

view =
  a: 0
  b: 1

@view.register(
  new MetricsComparation('metrics_comparation', 'general', view)
)

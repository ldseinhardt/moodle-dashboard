###
# activity: activity view
###

class Activity extends ViewBase
  constructor: (@name, @group) ->
    super(@name, @group)
    @view_index = 0

  template: (title, views) ->
    html = """
      <div class="col-md-12">
        <div class="panel panel-default">
          <div class="panel-heading">
            <div class="panel-title" style="margin-right: -150px; padding-right: 150px;">
              <div class="title" data-toggle="tooltip" data-placement="right" data-original-title="#{__(title)}">#{__(title)}</div>
            </div>
            <div class="panel-options" style="width: 150px;">
              <div class="btn-group">
                <a class="dropdown-toggle" data-target="#" data-toggle="dropdown">
                  <i class="material-icons">&#xE8F4;</i>
                </a>
                <ul class="dropdown-menu dropdown-menu-right">
    """
    for view, i in views
      actived = if @view_index == i then ' active' else ''
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
                <a class="btn-download">
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

  render: (data) ->
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
      legend: 'top'
      chartArea:
        top: 30
      hAxis:
        title: __('days', true)
      vAxis:
        minValue: 0
        format: 'decimal'
        viewWindowMode: 'maximized'
      explorer:
        maxZoomOut: 1
        keepInBounds: true
    @extendOptions(options)
    title = @views[@view_index].title
    views = []
    for view in @views
      views.push(view.title)
    @ctx.html(@template(title, views))
    $('[data-toggle=tooltip]', @ctx).tooltip()
    @chart = new google.visualization.LineChart($('.graph', @ctx)[0])
    @show()
    $('.btn-download', @ctx).click(=> @download(
      @chart.getImageURI(),
      __(@views[@view_index].title).replace(/\s/g, '_') + '.png'
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
        $('.panel-controls', @ctx).fadeIn()
      google.visualization.events.addListener(@chart, 'select', =>
        if @options.hAxis.viewWindow.min == 0 && @options.hAxis.viewWindow.max == @max
          $('.btn-zoom > i', @ctx).html('zoom_out')
          $('.panel-controls', @ctx).fadeIn()
          row = @chart.getSelection()[0].row + 1
          @zoom.min = row - 4
          @zoom.max = row + 3
          dif = @zoom.max - @max
          if dif > 0
            @zoom.min -= dif
            @zoom.max -= dif
          @options.hAxis.viewWindow = @zoom
          @chart.draw(@data, @options)
      )
      $('.btn-zoom', @ctx).click((evt) =>
        if @chart
          if @options.hAxis.viewWindow.min == 0 && @options.hAxis.viewWindow.max == @max
            $(evt.target).html('zoom_out')
            $('.panel-controls', @ctx).fadeIn()
            @options.hAxis.viewWindow = @zoom
          else
            $(evt.target).html('zoom_in')
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
      @chart.draw(@data, @options)
    @

  show: (index) ->
    @view_index = index if index?
    view = @views[@view_index]
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
    @max = view.data.length
    @zoom =
      min: if @max - 7 < 0 then 0 else @max - 7
      max: @max
    @options.hAxis.viewWindow = @zoom
    @options.vAxis.title = view.unity
    @options.vAxis.minValue = if @view_index == 2 then 1 else 0
    @chart.draw(@data, @options)
    @

@view.register(new Activity('activity', 'general'))

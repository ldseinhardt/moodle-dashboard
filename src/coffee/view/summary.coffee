###
# summary: summary view
###

class Summary extends ViewBase
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

  render: (data) ->
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
      legend: 'top'
      chartArea:
        top: 30
      hAxis:
        textPosition: 'none'
      vAxis:
        minValue: 0
        format: 'decimal'
        viewWindowMode: 'maximized'
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

@view.register(new Summary('summary', 'general'))

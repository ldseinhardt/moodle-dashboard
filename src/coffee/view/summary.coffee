###
# summary: summary view
###

class Summary
  render: (data, @options, @ctx, download) ->
    @views = [
      {
        title: __('Total page views')
        unity: __('page views')
        data: data.pageViews
      },
      {
        title: __('Total users')
        unity: __('users')
        data: data.uniqueUsers
      },
      {
        title: __('Total unique activities')
        unity: __('activities')
        data: data.uniqueActivities
      },
      {
        title: __('Total unique page views')
        unity: __('pages')
        data: data.uniquePages
      },
      {
        title: __('Mean session length')
        unity: __('Time (min)')
        data: data.meanSession
      }
    ]
    options =
      height: 175
      legend: 'bottom'
      hAxis:
        textPosition: 'none'
      vAxis:
        minValue: 0
        format: 'decimal'
        viewWindowMode: 'maximized'
    for key, val of options
      @options[key] = val
    graphics = $('.graph', @ctx)
    buttons = $('.btn-download', @ctx)
    for view, i in @views
      @options.title = view.title
      @options.vAxis.title = view.unity
      data = new google.visualization.DataTable()
      data.addColumn('string', 'id')
      data.addColumn('number', __('Saved'))
      data.addColumn('number', __('Selected'))
      data.addRows([[view.title].concat(view.data)])
      @views[i] =
        options: JSON.parse(JSON.stringify(@options))
        data: data
        chart: new google.visualization.ColumnChart(graphics[i])
      view = @views[i]
      view.chart.draw(view.data, view.options)
      $(buttons[i]).click(
        ((chart) ->
          -> download(chart.getImageURI())
        )(view.chart)
      )
    @

  resize: ->
    if @views
      width = $('.graph', @ctx).innerWidth()
      for view in @views
        view.options.width = width
        view.chart.draw(view.data, view.options)
    @

@view.register('summary', new Summary())

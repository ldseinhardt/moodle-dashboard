###
# activity: activity view
###

class Activity
  constructor: ->
    @view_index = 0

  render: (data, @options, @ctx, download) ->
    @views = [
      {
        title: __('Total page views per day')
        unity: __('page views')
        labels: [__('Total page views')]
        data: data.pageViews.total
      },
      {
        title: __('Total page views per day (users)')
        unity: __('page views')
        labels: data.users
        data: data.pageViews.parcial
      },
      {
        title: __('Total unique users per day')
        unity: __('users')
        labels: [__('Total users')]
        data: data.uniqueUsers
      },
      {
        title: __('Total unique activities per day')
        unity: __('activities')
        labels: [__('Total unique activities')]
        data: data.uniqueActivities.total
      },
      {
        title: __('Total unique activities per day (users)')
        unity: __('activities')
        labels: data.users
        data: data.uniqueActivities.parcial
      },
      {
        title: __('Total unique page views per day')
        unity: __('page views')
        labels: [__('Total unique page views')]
        data: data.uniquePages.total
      },
      {
        title: __('Total unique page views per day (users)')
        unity: __('page views')
        labels: data.users
        data: data.uniquePages.parcial
      },
      {
        title: __('Mean session length per day')
        unity: __('time (min)')
        labels: [__('Mean session length')]
        format: '# min'
        data: data.meanSession.total
      },
      {
        title: __('Mean session length per day (users)')
        unity: __('time (min)')
        labels: data.users
        format: '# min'
        data: data.meanSession.parcial
      },
      {
        title: __('Bounce rate per day')
        unity: __('% of sessions')
        labels: [__('Bounce rate')]
        format: '#%'
        formatter: new google.visualization.NumberFormat(pattern: '#%')
        data: data.bounceRate
      }
    ]
    options =
      height: 500
      legend: 'top'
      hAxis:
        title: __('days')
      vAxis:
        minValue: 0
        format: 'decimal'
        viewWindowMode: 'maximized'
      explorer:
        maxZoomOut: 1
        keepInBounds: true
    if data.pageViews.total.length > 7
       options.hAxis.slantedText = true
       options.hAxis.slantedTextAngle = 45
    for key, val of options
      @options[key] = val
    @chart = new google.visualization.LineChart($('.graph', @ctx)[0])
    @show()
    $('.btn-download', @ctx).click(=> download(@chart.getImageURI()))
    buttons = $('.btn-view', @ctx)
    for button, i in buttons
      $(button).click(
        ((i) =>
          => @show(i)
        )(i)
      )
    @

  resize: ->
    if @chart
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
    @options.title = view.title
    @options.vAxis.title = view.unity
    @options.vAxis.minValue = if @view_index == 2 then 1 else 0
    @chart.draw(@data, @options)

@view.register('activity', new Activity())

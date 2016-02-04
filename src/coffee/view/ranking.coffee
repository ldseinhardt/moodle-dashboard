###
# ranking: ranking view
###

class Ranking
  constructor: ->
    @view_index = 0
    @sort_index = 0

  render: (data, @options, @ctx, download) ->
    @views = [
      {
        title: __('Top users (page views)')
        label: __('Total page views')
        unity: __('page views')
        data: data.users.totalViews
      },
      {
        title: __('Top users (unique activities)')
        label: __('Total unique activities')
        unity: __('activities')
        data: data.users.activities
      },
      {
        title: __('Top users (unique page views)')
        label: __('Total unique page views')
        unity: __('pages')
        data: data.users.pages
      },
      {
        title: __('Top users (days)')
        label: __('Total days')
        unity: __('days')
        data: data.users.dates
      },
      {
        title: __('Top users (bounce rate)')
        label: __('Bounce rate')
        unity: __('% of sessions')
        format: '#%'
        formatter: new google.visualization.NumberFormat(pattern: '#%')
        data: data.users.bounceRate
      },
      {
        title: __('Top pages (page views)')
        label: __('Total page views')
        unity: __('page views')
        data: data.pages.totalViews
      },
      {
        title: __('Top pages (users)')
        label: __('Total users')
        unity: __('users')
        data: data.pages.users
      },
      {
        title: __('Top pages (unique activities)')
        label: __('Total unique activities')
        unity: __('activities')
        data: data.pages.activities
      },
      {
        title: __('Top pages (days)')
        label: __('Total days')
        unity: __('days')
        data: data.pages.dates
      },
      {
        title: __('Top pages (bounce rate)')
        label: __('Bounce rate')
        unity: __('% of sessions')
        format: '#%'
        formatter: new google.visualization.NumberFormat(pattern: '#%')
        data: data.pages.bounceRate
      },
      {
        title: __('Top activities (page views)')
        label: __('Total page views')
        unity: __('page views')
        data: data.activities.totalViews
      },
      {
        title: __('Top activities (users)')
        label: __('Total users')
        unity: __('users')
        data: data.activities.users
      },
      {
        title: __('Top activities (days)')
        label: __('Total days')
        unity: __('days')
        data: data.activities.dates
      },
      {
        title: __('Top activities (bounce rate)')
        label: __('Bounce rate')
        unity: __('% of sessions')
        format: '#%'
        formatter: new google.visualization.NumberFormat(pattern: '#%')
        data: data.activities.bounceRate
      }
    ]
    options =
      height: 500
      legend: 'top'
      vAxis:
        minValue: 0
        fotmat: 'decimal'
        viewWindowMode: 'maximized'
      explorer:
        maxZoomOut: 1
        keepInBounds: true
    for key, val of options
      @options[key] = val
    @show()
    $('.btn-download', @ctx).click(=> download(@chart.getImageURI()))
    buttons = $('.btn-sort', @ctx)
    for button, i in buttons
      $(button).click(
        ((i) =>
          => @chart.draw(@sort(i), @options)
        )(i)
      )
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
    @data.addColumn('number', view.label)
    @data.addRows(view.data)
    if view.format
      @options.vAxis.format = view.format
    else
      delete @options.vAxis.format
    view.formatter?.format(@data, 1)
    @options.title = view.title
    @options.vAxis.title = view.unity
    @chart = new google.visualization.ColumnChart($('.graph', @ctx)[0])
    @chart.draw(@sort(), @options)
    $($('.btn-sort span', @ctx)[1]).text(__('Sort by') + ' ' + view.unity)

  sort: (index) ->
    @sort_index = index if index?
    @data.sort([{column: @sort_index, desc: @sort_index > 0}])
    @data

@view.register('ranking', new Ranking())

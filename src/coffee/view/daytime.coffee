###
# daytime: daytime view
###

class DayTime
  constructor: ->
    @view = {}
    for i in [0..7]
      @view[i] = !i

  render: (data, @options, @ctx, download) ->
    options =
      title: __('Total activities per hour')
      height: 250
      legend: 'top'
      hAxis:
        title: __('hour')
        ticks: [0..23]
        format: '#h'
      vAxis:
        title: __('activities').toLowerCase()
        minValue: 0
        format: 'decimal'
        viewWindowMode: 'maximized'
      explorer:
        maxZoomOut: 1
        keepInBounds: true
    for key, val of options
      @options[key] = val
    if @show(data)
      $('.btn-download', @ctx).click(=> download(@chart.getImageURI()))
      buttons = $('.togglebutton', @ctx)
      for button, i in buttons
        $(button).change(
          ((i, data) =>
            (evt) =>
              checkbox = $('input[type="checkbox"]', evt.currentTarget)
              @view[i] = checkbox.is(':checked')
              views = Object.keys(@view).map((k) => @view[k])
              if views.filter((e) -> e == true).length
                @show(data)
              else
                checkbox.prop('checked', @view[i] = true)
          )(i, data)
        )
    @

  resize: ->
    if @chart
      @options.width = $('.graph', @ctx).innerWidth()
      @chart.draw(@data, @options)
    @

  show: (data) ->
    temp = []
    for _, i in data[0]
      row = [i]
      for n, hours of data
        if @view[n]
          row.push(hours[i])
      temp.push(row)
    if temp[0].length == 1
      $('.graph', @ctx).html('<span>' + __('No data') + '</span>')
      return
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
    @data = new google.visualization.DataTable()
    @data.addColumn('number', 'id')
    for i, selected of @view
      if selected
        @data.addColumn('number', __(labels[i]))
    @data.addRows(temp)
    new google.visualization.NumberFormat(pattern: '#h').format(@data, 0)
    @chart = new google.visualization.LineChart($('.graph', @ctx)[0])
    @chart.draw(@data, @options)
    @chart

@view.register('daytime', new DayTime())

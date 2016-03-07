###
# daytime: daytime view
###

class DayTime extends ViewBase
  constructor: (@name, @group) ->
    super(@name, @group)
    @view = {}
    for i in [0..7]
      @view[i] = !i
    @labels = [
      'All days',
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday'
    ]

  template: (title) ->
    html = """
      <div class="col-md-12">
        <div class="panel panel-default">
          <div class="panel-heading">
            <div class="panel-title" style="margin-right: -100px; padding-right: 100px;">
              <div class="title" data-toggle="tooltip" data-placement="right" data-original-title="#{__(title)}">#{__(title)}</div>
            </div>
            <div class="panel-options" style="width: 100px;">
              <div class="btn-group">
                <a class="dropdown-toggle" data-target="#" data-toggle="dropdown">
                  <i class="material-icons">&#xE8F4;</i>
                </a>
                <ul class="dropdown-menu dropdown-menu-right dropdown-menu-opened">
    """
    for label, i in @labels
      checked = if @view[i] then ' checked=""' else ''
      html += """
                  <li>
                    <div class="togglebutton">
                      <label>
                        <input type="checkbox"#{checked}>
                        <span>#{__(label)}</span>
                      </label>
                    </div>
                  </li>
      """
    html += """
                </ul>
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
          </div>
        </div>
      </div>
    """

  render: (data) ->
    options =
      legend: 'top'
      chartArea:
        top: 30
      hAxis:
        title: __('hour', true)
        ticks: [0..23]
        format: '#h'
      vAxis:
        title: __('activities', true)
        minValue: 0
        format: 'decimal'
        viewWindowMode: 'maximized'
      explorer:
        maxZoomOut: 1
        keepInBounds: true
      curveType: 'function'
    @extendOptions(options)
    title = 'Total activities per hour'
    @ctx.html(@template(title))
    $('[data-toggle=tooltip]', @ctx).tooltip()
    $.material.togglebutton()
    $('.dropdown-menu-opened li').click(->
      $(@).parent().parent().toggleClass('open')
    )
    if @show(data)
      $('.btn-download', @ctx).click(=> @download(
        @chart.getImageURI(),
        __(title).replace(/\s/g, '_') + '.png'
      ))
      buttons = $('.togglebutton', @ctx)
      for button, i in buttons
        $(button).change(
          ((i, data) =>
            (evt) =>
              checkbox = $(evt.target)
              @view[i] = checkbox.is(':checked')
              views = Object.keys(@view).map((k) => @view[k])
              if views.filter((e) -> e == true).length
                @show(data)
              else
                checkbox.prop('checked', @view[i] = true)
          )(i, data)
        )
    @

  resize: (isNotFullScreen) ->
    super(isNotFullScreen)
    if @chart && @ctx.is(':visible')
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
    @data = new google.visualization.DataTable()
    @data.addColumn('number', 'id')
    for i, selected of @view
      if selected
        @data.addColumn('number', __(@labels[i]))
    @data.addRows(temp)
    if @view[0]
      @options.series = {0: {lineDashStyle: [2, 2]}}
    else
      delete @options.series
    new google.visualization.NumberFormat(pattern: '#h').format(@data, 0)
    @chart = new google.visualization.LineChart($('.graph', @ctx)[0])
    @chart.draw(@data, @options)
    @chart

@view.register(new DayTime('daytime', 'general'))

###
# daytime
###

class DayTime extends ViewBase
  constructor: (@name, @group, @view) ->
    super(@name, @group)
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

  init: (@course, @role, @filters) ->
    super(@course, @role, @filters)
    @_data = {}
    for i in [0..7]
      @_data[i] = []
      for n in [0..23]
        @_data[i].push(0)
    @

  selected: (row) ->
    if @filter(row.event, row.page)
      return @
    day = parseInt(row.day)
    week = new Date(day).getDay() + 1
    hour = new Date(day + parseInt(row.time)).getHours()
    @_data[week][hour] += row.size
    @_data[0][hour] += row.size
    @

  getData: ->
    total = 0
    for size in @_data[0]
      total += size
      if total > 0
        break
    unless total
      return
    @_data

  template: (title) ->
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
                <ul class="dropdown-menu dropdown-menu-right dropdown-menu-opened">
    """
    for label, i in @labels
      html += """
                  <li>
                    <div class="togglebutton">
                      <label>
                        <input type="checkbox">
                        <span>#{__(label)}</span>
                      </label>
                    </div>
                  </li>
      """
    html += """
                </ul>
              </div>
              <div class="btn-group">
                <a class="dropdown-toggle" data-target="#" data-toggle="dropdown">
                  <i class="material-icons">&#xE8EF;</i>
                </a>
                <ul class="dropdown-menu dropdown-menu-right">
                  <li>
                    <a href="#" class="btn-table">#{__('Hours x days of the week')}</a>
                  </li>
                  <li>
                    <a href="#" class="btn-table">#{__('Days of the week x hours')}</a>
                  </li>
                </ul>
              </div>
              <div class="btn-group">
                <a href="#" class="btn-download">
                  <i class="material-icons">&#xE80D;</i>
                </a>
              </div>
              <div class="btn-group">
                <a href="#" class="btn-report">
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
            <div class="tablebox" style="display: none">
              <table class="table table-striped table-hover"></table>
            </div>
          </div>
        </div>
      </div>
    """

  render: ->
    unless @getData()
      @ctx.html('')
      return
    options =
      legend:
        position: 'top'
        textStyle:
          fontSize: 11
          color: '#111'
      chartArea:
        top: 30
        left: 70
      hAxis:
        title: __('hour', true)
        ticks: [0..23]
        format: '#h'
        textStyle :
          fontSize: 11
          color: '#111'
      vAxis:
        title: __('activities', true)
        minValue: 0
        format: 'decimal'
        viewWindowMode: 'maximized'
        textStyle :
          fontSize: 11
          color: '#111'
      explorer:
        maxZoomOut: 1
        keepInBounds: true
      curveType: 'function'
    @extendOptions(options)
    title = 'Activities per hour'
    @ctx.html(@template(title))
    $('[data-toggle=tooltip]', @ctx).tooltip()
    $.material.togglebutton()
    $('.dropdown-menu-opened li', @ctx).click(->
      $(@).parent().parent().toggleClass('open')
    )
    @chart = new google.visualization.LineChart($('.graph', @ctx)[0])
    @show()
    $('.btn-download', @ctx).click(=> @download(
      @chart.getImageURI(),
      __(title).replace(/\s/g, '_') + '.png'
    ))
    buttons = $('.togglebutton', @ctx)
    for button, i in buttons
      $(button).change(
        ((i) =>
          (evt) =>
            checkbox = $(evt.target)
            @view.days[i] = checkbox.is(':checked')
            views = Object.keys(@view.days).map((k) => @view.days[k])
            if views.filter((e) -> e == true).length
              @show()
            else
              checkbox.prop('checked', @view.days[i] = true)
        )(i)
      )
    tables =
      boxes: $('.tablebox', @ctx)
      tables: $('.tablebox > table', @ctx)
      columns: [
        [
          field: 'hours'
          title: __('hours')
          sortable: true
          sorter: (a, b) ->
            a = parseInt(a.replace(/h/, ''))
            b = parseInt(b.replace(/h/, ''))
            if a > b
              return 1
            if a < b
              return -1
            return 0
          halign: 'center'
          valign: 'middle'
          align: 'center'
        ],
        [
          {
            field: 'Days of week'
            title: __('Days of week')
            sortable: true
            sorter: (a, b) ->
              a = /\<span\sindex\=\"([0-6])\"\>(.+)\<\/span\>/.exec(a)[1]
              b = /\<span\sindex\=\"([0-6])\"\>(.+)\<\/span\>/.exec(b)[1]
              if a > b
                return 1
              if a < b
                return -1
              return 0
            halign: 'center'
            valign: 'middle'
            align: 'center'
          },
          {
            field: 'All day'
            title: __('All day')
            sortable: true
            halign: 'center'
            valign: 'middle'
            align: 'center'
          }
        ]
      ]
      data: [[], []]
    for label in @labels
      tables.columns[0].push(
        field: label
        title: __(label)
        sortable: true
        halign: 'center'
        valign: 'middle'
        align: 'center'
      )
    for i in [0..23]
      item = {}
      item[tables.columns[0][0].field] = i + 'h'
      for label, p in @labels
        item[label] = @_data[p][i]
      tables.data[0].push(item)
      tables.columns[1].push(
        field: i
        title: i + 'h'
        sortable: true
        halign: 'center'
        valign: 'middle'
        align: 'center'
      )
    for key, i in Object.keys(@_data)[1..]
      item = {}
      label = '<span index="' + i + '">' + __(@labels[key]) + '</span>'
      item[tables.columns[1][0].field] = label
      total = 0
      for activities, i in @_data[key]
        item[i] = activities
        total += activities
      item[tables.columns[1][1].field] = total
      tables.data[1].push(item)
    $(tables.tables[0]).bootstrapTable(
      columns: tables.columns[0]
      data: tables.data[0]
      sortName: tables.columns[0][1].field
      search: true
      showToggle: true
      showColumns: true
      locale: langId
    )
    $(tables.tables[1]).bootstrapTable(
      columns: tables.columns[1]
      data: tables.data[1]
      sortName: tables.columns[1][1].field
      sortOrder: 'desc'
      search: true
      showToggle: true
      showColumns: true
      locale: langId
    )
    $('.btn-graph', @ctx).click(=> @show(0))
    buttons = $('.btn-table', @ctx)
    for button, i in buttons
      $(button).click(
        ((index) =>
          => @show(index)
        )(i + 1)
      )
    $('.btn-report', @ctx).click(=> @download(
      @table(tables.columns[1].map((e) => e.title), tables.data[1].map((e) =>
        list = []
        _headers = tables.columns[1];
        for header in _headers
          list.push(String(e[header.field]).replace(/<\/?[^>]+(>|$)/g, ''))
        list
      )),
      __(title).replace(/\s/g, '_') + '.csv'
    ))
    @

  resize: (isNotFullScreen) ->
    super(isNotFullScreen)
    if @chart && @ctx.is(':visible')
      @options.width = $('.graph', @ctx).innerWidth()
      @options.chartArea.width = @options.width - @options.chartArea.left - 30
      @show()
    @

  show: (index) ->
    @view.index = index if index?
    graph = $('.graph', @ctx)
    tableboxes = $('.tablebox', @ctx)
    if @view.index == 0
      $('.btn-table.active', @ctx).removeClass('active')
      unless graph.is(':visible')
        tableboxes.hide()
        graph.show()
      temp = []
      for _, i in @_data[0]
        row = [i]
        for n, hours of @_data
          if @view.days[n]
            row.push(hours[i])
        temp.push(row)
      @data = new google.visualization.DataTable()
      @data.addColumn('number', 'id')
      colors = []
      for i, selected of @view.days
        if selected
          @data.addColumn('number', __(@labels[i]))
          colors.push(@getColors()[i])
      @data.addRows(temp)
      @options.colors = colors
      @options.chartArea.width = $('.graph', @ctx).innerWidth() - @options.chartArea.left - 30
      if @view.days[0]
        @options.series = {0: {lineDashStyle: [2, 2]}}
      else
        delete @options.series
      new google.visualization.NumberFormat(pattern: '#h').format(@data, 0)
      if @ctx.is(':visible')
        @chart.draw(@data, @options)
    else if !$(tableboxes[@view.index - 1]).is(':visible')
      $('.btn-table.active', @ctx).removeClass('active')
      $($('.btn-table', @ctx)[@view.index - 1]).addClass('active')
      graph.hide()
      tableboxes.hide()
      $(tableboxes[@view.index - 1]).show()
    buttons = $('.togglebutton', @ctx)
    for i, selected of @view.days
      $('input[type=checkbox]', buttons[i]).prop('checked', selected)
    @

view =
  index: 0
  days: {}
for i in [0..7]
  view.days[i] = !i

@view.register(
  new DayTime('daytime', 'general', view),
  new DayTime('daytime', 'course', view),
  new DayTime('daytime', 'content', view),
  new DayTime('daytime', 'assign', view),
  new DayTime('daytime', 'forum', view),
  new DayTime('daytime', 'chat', view),
  new DayTime('daytime', 'choice', view),
  new DayTime('daytime', 'quiz', view),
  new DayTime('daytime', 'blog', view),
  new DayTime('daytime', 'wiki', view)
)

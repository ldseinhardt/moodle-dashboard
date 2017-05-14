###
# daytime heatmap
###

class DayTimeHeatmap extends ViewBase
  init: (@course, @role, @filters) ->
    super(@course, @role, @filters)
    @_data = {}
    for i in [0..6]
      @_data[i] = []
      for n in [0..23]
        @_data[i].push(0)
    @

  selected: (row) ->
    if @filter(row.event, row.page)
      return @
    day = parseInt(row.day)
    week = new Date(day).getDay()
    hour = new Date(day + parseInt(row.time)).getHours()
    @_data[week][hour] += row.size
    @

  getData: ->
    data = []
    total = 0
    for d, hs of @_data
      for h, v of hs
        data.push(
          day: parseInt(d)
          hour: parseInt(h)
          value: v
        )
        total += v
    unless total
      return
    data

  template: ->
    html = """
      <div class="col-md-12">
        <div class="panel panel-default">
          <div class="panel-heading">
            <div class="panel-title" style="margin-right: -150px; padding-right: 150px;">
              <div class="title" data-toggle="tooltip" data-placement="right" data-original-title="#{__('Activities per hour (Heatmap)')}">#{__('Activities per hour (Heatmap)')}</div>
            </div>
            <div class="panel-options" style="width: 150px;">
            <div class="btn-group">
              <a href="#" class="btn-download">
                <i class="material-icons">&#xE80D;</i>
              </a>
            </div>
              <i class="material-icons info" data-toggle="tooltip" data-placement="left" data-original-title="#{__('data_activities_per_hour_description')}">&#xE88E;</i>
            </div>
          </div>
          <div class="panel-body">
            <div class="graph"></div>
          </div>
        </div>
      </div>
    """

  show: (data) ->
    @options.width = $('.graph', @ctx).innerWidth()
    @options.chartArea.width = @options.width - @options.chartArea.left - @options.chartArea.right
    @options.heatmap.gridSize = Math.floor(@options.chartArea.width / 24)
    @options.height = @options.chartArea.top + @options.chartArea.bottom + @options.heatmap.gridSize * 7
    @options.chartArea.height = @options.height - @options.chartArea.top - @options.chartArea.bottom
    @options.legend.elementWidth = @options.heatmap.gridSize * 1.5

    $('.graph', @ctx).html('')
    svg = d3.select($('.graph', @ctx)[0]).append('svg')
      .attr('xmlns', 'http://www.w3.org/2000/svg')
      .attr('width', @options.width)
      .attr('height', @options.height)
      .style('background', '#fff')
      .append('g')
      .attr('transform', 'translate(' + @options.chartArea.left + ',' + @options.chartArea.top + ')')

    xAxis = svg.selectAll('.xAxis')
      .data(@options.vAxis.ticks)
      .enter().append('text')
        .text((d) -> d)
        .attr('x', 0)
        .attr('y', (d, i) => i * @options.heatmap.gridSize)
        .style('text-anchor', 'end')
        .attr('transform', 'translate(-6,' + @options.heatmap.gridSize / 1.5 + ')')
        .style('color', '#111')
        .style('font-size', '11pt')

    yAxis = svg.selectAll('.yAxis')
      .data(@options.hAxis.ticks)
      .enter().append('text')
        .text((d) -> d)
        .attr('x', (d, i) => i * @options.heatmap.gridSize)
        .attr('y', 0)
        .style('text-anchor', 'middle')
        .attr('transform', 'translate(' + @options.heatmap.gridSize / 2 + ', -6)')
        .style('color', '#111')
        .style('font-size', '11pt')

    colorScale = d3.scale.quantile()
      .domain([0, @options.heatmap.buckets - 1, d3.max(data, (d) -> d.value)])
      .range(@options.colors)

    cards = svg.selectAll('.hour')
      .data(data, (d) ->  d.day + ':' + d.hour)

    cards.append('title')

    cards.enter().append('rect')
      .attr('x', (d) => d.hour * @options.heatmap.gridSize)
      .attr('y', (d) => d.day * @options.heatmap.gridSize)
      .attr('rx', 4)
      .attr('ry', 4)
      .style('stroke', '#e6e6e6')
      .style('stroke-width', '2px')
      .attr('width', @options.heatmap.gridSize)
      .attr('height', @options.heatmap.gridSize)
      .style('fill', @options.colors[0])
      .append('title')
        .data(data, (d) -> d.day + ':' + d.hour)

    cards.transition().duration(1000)
      .style('fill', (d) -> colorScale(d.value))

    cards.select('title').text((d) -> d.value)

    cards.exit().remove()

    legend = svg.selectAll('.legend')
      .data([0].concat(colorScale.quantiles()), (d) -> d)

    legend.enter().append('g')

    legend.append('rect')
      .attr('x', (d, i) => @options.legend.elementWidth * i)
      .attr('y', @options.chartArea.height + 10)
      .attr('width', @options.legend.elementWidth)
      .attr('height', 15)
      .style('fill', (d, i) => @options.colors[i])

    legend.append('text')
      .style('font-size', '9pt')
      .style('font-family', 'Consolas, courier')
      .style('fill', '#111')
      .text((d) -> '≥ ' + Math.round(d))
      .attr('x', (d, i) => @options.legend.elementWidth * i)
      .attr('y', @options.chartArea.height + 45)

    legend.exit().remove()
    @

  render: ->
    @data = @getData()
    unless @data
      @ctx.html('')
      return
    @options =
      chartArea:
        top: 20
        right: 0
        bottom: 50
        left: 40
      colors: [
        '#ffffd9',
        '#edf8b1',
        '#c7e9b4',
        '#7fcdbb',
        '#41b6c4',
        '#1d91c0',
        '#225ea8',
        '#253494',
        '#081d58'
      ]
      heatmap:
        buckets: 9
      legend: {}
      hAxis:
        ticks: [0..23].map((d) -> d + 'h')
      vAxis:
        ticks: __('Su_Mo_Tu_We_Th_Fr_Sa').split('_')
    @ctx.html(@template())
    $('[data-toggle=tooltip]', @ctx).tooltip()
    if @data && @ctx.is(':visible')
      @show(@data)

    svg_to_png_data = ($target) ->
      img = new Image()
      img.src = 'data:image/svg+xml,' + encodeURIComponent($target.html())
      canvas = document.createElement('canvas')
      canvas.width = $('svg', $target).width()
      canvas.height = $('svg', $target).height()
      canvas.getContext('2d').drawImage(img, 0, 0)
      canvas.toDataURL('image/png')

    $('.btn-download', @ctx).click(=> @download(
      'data:image/svg+xml,' + encodeURIComponent($('.graph', @ctx).html())
      __('Activities per hour (Heatmap)').replace(/\s/g, '_') + '.svg'
    ))
    @

  resize: (isNotFullScreen) ->
    super(isNotFullScreen)
    if @data && @ctx.is(':visible')
      @show(@data)
    @

@view.register(
  new DayTimeHeatmap('daytime_heatmap', 'general'),
  new DayTimeHeatmap('daytime_heatmap', 'course'),
  new DayTimeHeatmap('daytime_heatmap', 'content'),
  new DayTimeHeatmap('daytime_heatmap', 'assign'),
  new DayTimeHeatmap('daytime_heatmap', 'forum'),
  new DayTimeHeatmap('daytime_heatmap', 'chat'),
  new DayTimeHeatmap('daytime_heatmap', 'choice'),
  new DayTimeHeatmap('daytime_heatmap', 'quiz'),
  new DayTimeHeatmap('daytime_heatmap', 'blog'),
  new DayTimeHeatmap('daytime_heatmap', 'wiki')
)

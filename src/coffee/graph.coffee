###
# graph: graphic interface
###

class Graph
  constructor: (options) ->
    if options
      for key, value of options
        @[key] = value

  show: (type) ->
    if type
      @type = type
    @[@type]?()

  ###
  # Bubble graphic
  ###
  bubble: ->
    unless @data && @size && @context
      return

    # Define formatação e escala de cores
    format = d3.format('.d')
    color = d3.scale.category20c()

    # Define o layout do gráfico
    bubble = d3.layout.pack()
      .sort(null)
      .size([@size, @size])
      .padding(1.5)
    # Cria o svg e insere na página
    svg = d3.select(@context)
      .html('')
      .append('div')
        .attr('class', 'graph graph-bubble')
      .append('svg')
        .attr('width', @size)
        .attr('height', @size)

    # Cria e insere os nodos
    node = svg.selectAll('.node')
      .data(bubble.nodes(@data).filter((d) -> !d.children))
      .enter()
      .append('g')
        .attr('class', 'node')
        .attr('transform', (d) -> 'translate(' + d.x + ',' + d.y + ')')

    # Isere um titulo para cada nodo
    node.append('title')
      .text((d) -> d.className + ': ' + format(d.value))

    # Insere as bolhas (circulos) para cada nodo
    node.append('circle')
      .attr('class', 'circle')
      .attr('r', (d) -> d.r)
      .style('fill', (d) -> color(d.packageName))

    # Insere o texto (descrição) para cada nodo
    node.append('text')
      .attr('dy', '.3em')
      .style('text-anchor', 'middle')
      .text((d) -> d.className.substring(0, d.r / 3))

    @

  ###
  # Bar graphic
  ###
  bar: ->
    unless @data && @size && @context
      return

    # Define valores padrão para argumentos
    width = @size

    # Define largura das barras
    barHeight = 15

    # Define as margens
    margin =
      top: 20
      bottom: 20
      left: 0
      right: 20

    for user in @data
      if user.name.length > margin.left
        margin.left = user.name.length

    margin.left *= 5.5
    margin.left += 20

    # Ajusta o tamanho
    width -= margin.left + margin.right
    height = @data.length * barHeight

    # Define a escala para x e y
    x = d3.scale.linear()
      .range([0, width])

    y = d3.scale.ordinal()
      .rangeRoundBands([0, height], .1)

    # Define o dominio para x e y
    x.domain([0, d3.max(@data, (d) -> d.size)])
    y.domain(@data.map((d) -> d.name))

    # Define os eixos x e y
    xAxis = d3.svg.axis()
      .scale(x)
      .orient('top')

    yAxis = d3.svg.axis()
      .scale(y)
      .tickSize(5, 0)
      .orient('left')

    # Cria o svg e insere na página
    svg = d3.select(@context)
      .html('')
      .append('div')
        .attr('class', 'graph graph-bar')
      .append('svg')
        .attr('width', width + margin.left + margin.right)
        .attr('height', height + margin.top + margin.bottom)
      .append('g')
        .attr('transform', 'translate(' + margin.left + ',' + margin.top + ')')

    # Insere os eixos
    svg.append('g')
      .attr('class', 'x axis')
      .call(xAxis)

    svg.append('g')
      .attr('class', 'y axis')
      .attr('transform', 'translate(-10, 0)')
      .call(yAxis)
      .selectAll('text')
      .data(@data)
      .text((d) -> d.name)
      .attr('dy', '.35em')
      .style('text-anchor', 'left')
      .append('title')
        .text((d) -> d.name)

    # Insere as barras
    svg.selectAll('.bar')
      .data(@data)
      .enter()
      .append('rect')
        .attr('class', 'bar')
        .attr('y', (d) -> y(d.name))
        .attr('width', (d) -> x(d.size))
        .attr('height', barHeight - 2)
      .append('title')
        .text((d) -> d.name + ': ' + d.size)

    @

@Graph = Graph

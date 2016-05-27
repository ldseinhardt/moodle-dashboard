###
# categories
###

class Categories extends ViewBase
  init: (@course, @role, @filters) ->
    super(@course, @role, @filters)
    @_selected =
      course: 0
      content: 0
      assign: 0
      forum: 0
      chat: 0
      choice: 0
      quiz: 0
      blog: 0
      wiki: 0
    @_groups =
      content: /^(content|conteúdo|book|livro|chapter|capítulo|imscp|page|página|url|label|rótulo|folder|pasta|resource|recurso|arquivo|lesson|lição)/
      assign: /^(assign|tarefa|avaliação)/
      forum: /^(forum|fórum|post|postagem|discussion|discussão)/
      chat: /^(chat|bate|message|mensagem)/
      choice: /^(choice|escolha)/
      quiz: /^(quiz|checklist|questionário)/
      blog: /^(blog|diário)/
      wiki: /^wiki/
    @

  selected: (row) ->
    if /view/.test(row.event.name) || /view/.test(row.description)
      key = 'course'
      for group, e of @_groups
        if e.test(row.event.name.toLowerCase) || e.test(row.page.toLowerCase())
          key = group
      @_selected[key] += row.size
    @

  getData: ->
    [
      [__('Course'), @_selected.course],
      [__('Content'), @_selected.content],
      [__('Assignment'), @_selected.assign],
      [__('Forum'), @_selected.forum],
      [__('Chat'), @_selected.chat],
      [__('Choice'), @_selected.choice],
      [__('Quiz'), @_selected.quiz],
      [__('Blog'), @_selected.blog],
      [__('Wiki'), @_selected.wiki]
    ]

  template: ->
    html = """
      <div class="col-md-6">
        <div class="panel panel-default">
          <div class="panel-heading">
            <div class="panel-title">
              <div class="title" data-toggle="tooltip" data-placement="right" data-original-title="#{__('Page views by area')}">#{__('Page views by area')}</div>
            </div>
            <div class="panel-options">
              <div class="btn-group">
                <a href="#" class="btn-download">
                  <i class="material-icons">&#xE2C4;</i>
                </a>
              </div>
              <i class="material-icons info" data-toggle="tooltip" data-placement="left" data-original-title="#{__('data_components_description')}">&#xE88E;</i>
            </div>
          </div>
          <div class="panel-body">
            <div class="graph"></div>
          </div>
        </div>
      </div>
    """

  render: ->
    data = @getData()
    @ctx.html(@template())
    $('[data-toggle=tooltip]', @ctx).tooltip()
    width = $('.graph', @ctx).innerWidth()
    options =
      width: width
      height: 300
      colors: @getColors()
      pieSliceText: 'label'
      legend:
        position: 'right'
        textStyle:
          fontSize: 11
          color: '#111'
      hAxis:
        textStyle :
          fontSize: 11
          color: '#111'
      vAxis:
        textStyle :
          fontSize: 11
          color: '#111'
    @extendOptions(options)
    @chart = new google.visualization.PieChart($('.graph', @ctx)[0])
    @data = new google.visualization.DataTable()
    @data.addColumn('string', 'Id')
    @data.addColumn('number', __('Page views'))
    @data.addRows(data)
    @chart.draw(@data, @options)
    $('.btn-download', @ctx).click(=> @download(
      @chart.getImageURI(),
      __('Page views by area').replace(/\s/g, '_') + '.png'
    ))
    @

  resize: (isNotFullScreen) ->
    super(isNotFullScreen)
    if @chart && @ctx.is(':visible')
      @options.width = $('.graph', @ctx).innerWidth()
      @chart.draw(@data, @options)
    @

@view.register(
  new Categories('categories', 'general')
)

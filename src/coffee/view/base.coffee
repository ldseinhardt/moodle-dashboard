###
# view base
###

class ViewBase
  constructor: (@name, @group = 'dashboard-content') ->
    unless @group == 'dashboard-content'
      unless $('#' + @group).length
        selected = if @group == 'general' then ' active in' else ''
        $('#dashboard-content .tab-content').append("""
          <div class="tab-pane#{selected}" id="#{@group}">
            <div class="default">
              <i class="material-icons">&#xE80C;</i>
              <div class="message" data-i18n="Select course"></div>
            </div>
            <div class="data"></div>
          </div>
        """)
      $('#' + @group + ' .data')
        .append('<div class="row data-' + @name + '"></div>')
    @ctx = $('#' + @group + ' .data-' + @name)
    @isNotFullScreen = true
    @daytime = 1000 * 60 * 60 * 24
    @sessiontime = 60 * 90 # * 1000 -> 90min

  getName: ->
    @name

  getGroup: ->
    @group

  getColors: ->
    [
      '#0074d9', '#ff4136', '#ffdc00', '#3d9970',
      '#85144b', '#39cccc', '#b10dc9', '#01ff70',
      '#111111', '#ff851b', '#001f3f', '#f012be',
      '#dddddd', '#7fdbff', '#2ecc40', '#aaaaaa'
    ]

  extendOptions: (options) ->
    _options =
      colors: @getColors()
    @options = @clone(_options)
    for key, value of options
      @options[key] = value
    @

  clone: (obj) ->
    JSON.parse(JSON.stringify(obj))

  download: (url, filename = 'chart.png') ->
    chrome.downloads.download(
      url: url
      saveAs: @isNotFullScreen
      filename: filename
    )
    @

  init: (@course, @role, @filters) ->
    @dates = @course.dates
    @min = @dates.min
    @max = @dates.max
    @

  selected: (row) ->
    @

  recorded: (row) ->
    @

  filter: (event, page) ->
    name = event.name.toLowerCase()
    page = page.toLowerCase()
    groups =
      content: /^(content|conteúdo|book|livro|chapter|capítulo|imscp|page|página|url|label|rótulo|folder|pasta|resource|recurso|arquivo|lesson|lição)/
      assign: /^(assign|tarefa|avaliação)/
      forum: /^(forum|fórum|post|postagem|discussion|discussão)/
      chat: /^(chat|bate|message|mensagem)/
      choice: /^(choice|escolha)/
      quiz: /^(quiz|checklist|questionário)/
      blog: /^(blog|diário)/
      wiki: /^wiki/
    if @group == 'course'
      for group, e of groups
        if e.test(name) || e.test(page)
          return true
    else if groups[@group]
      if !groups[@group].test(name) && !groups[@group].test(page)
        return true
    false

  render: ->
    @

  table: (headers, rows) ->
    header = headers.map((e) => '"' + e + '"').join(',') + "\r\n"
    content = rows.map((e) => e.map((e) => '"' + e + '"').join(',')).join("\r\n") + "\r\n"
    'data:text/csv;base64,' + btoa(unescape(encodeURIComponent(header + content)))

  resize: (isNotFullScreen) ->
    if isNotFullScreen?
      @isNotFullScreen = isNotFullScreen
    @

  clear: ->
    @ctx.html('')
    @

@ViewBase = ViewBase

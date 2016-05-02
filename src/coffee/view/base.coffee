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
              <div class="message __MSG_select_course__"></div>
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
    page = page.toLowerCase()
    groups =
      content: /^(content|book|chapter|imscp|page|url|label|folder|resource|lesson)/
      assign: /^assign/
      forum: /^(forum|post|discussion)/
      chat: /^(chat|message)/
      choice: /^choice/
      quiz: /^quiz/
      blog: /^blog/
      wiki: /^wiki/
    if @group == 'course'
      for group, e of groups
        if e.test(event.name) || e.test(page)
          return true
    else if groups[@group]
      if !groups[@group].test(event.name) && !groups[@group].test(page)
        return true
    false

  render: ->
    @

  resize: (isNotFullScreen) ->
    if isNotFullScreen?
      @isNotFullScreen = isNotFullScreen
    @

  clear: ->
    @ctx.html('')
    @

@ViewBase = ViewBase

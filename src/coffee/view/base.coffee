###
# view: view base
###

class ViewBase
  constructor: (@name, @group = 'dashboard-content') ->
    @ctx = $('#' + @group + ' .data-' + @name)
    @isNotFullScreen = false

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
      tooltip:
        isHtml: true
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

  render: (data) ->
    @

  resize: (isNotFullScreen) ->
    if isNotFullScreen?
      @isNotFullScreen = isNotFullScreen
    @

  clear: ->
    @ctx.html('')
    @

@ViewBase = ViewBase

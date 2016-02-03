###
# view: view collection
###

class View
  constructor: ->
    @views = {}
    @options =
      colors: [
        '#0074d9', '#ff4136', '#ffdc00', '#3d9970',
        '#85144b', '#39cccc', '#b10dc9', '#01ff70',
        '#111111', '#ff851b', '#001f3f', '#f012be',
        '#dddddd', '#7fdbff', '#2ecc40', '#aaaaaa'
      ]
      tooltip:
        isHtml: true

  register: (name, view) ->
    @views[name] = view

  render: (data, download) ->
    content = $('#dashboard-content')
    $('.data-options a', content).unbind('click')
    $('.data-options .togglebutton', content).unbind('change')
    for name, view of @views
      ctx = $('.data-' + name, content)
      if data[name]
        @options.width = $('.graph', ctx).innerWidth()
        view.render(
          data[name],
          JSON.parse(JSON.stringify(@options)),
          ctx,
          download
        )
      else
        $('.graph', ctx).html('<span>' + __('content_default_msg') + '</span>')
    @resize()

  resize: ->
    for _, view of @views
      view.resize()
    @

@view = new View()

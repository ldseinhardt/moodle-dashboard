###
# view: view collection
###

class View
  constructor: ->
    @views = {}
    $('#dashboard-content .nav-tabs').on('shown.bs.tab', (evt) =>
      @resizeGroup($(evt.target).attr('href')[1..])
    )

  register: ->
    for view in arguments
      unless @views[view.getGroup()]
        @views[view.getGroup()] = {}
      @views[view.getGroup()][view.getName()] = view
    @

  render: (data) ->
    for group, views of @views
      for name, view of views
        view.clear()
        if data[group]
          if data[group][name]
            view.render(data[group][name])
        else if !$('#' + group + ' > .default').is(':visible')
          $('#' + group + ' > .default').hide()
          $('#' + group + ' > .data').show()
    @

  resize: (isNotFullScreen) ->
    for _, views of @views
      for _, view of views
        view.resize(isNotFullScreen)
    @

  resizeGroup: (group) ->
    for _, view of @views[group]
      view.resize()
    @

@view = new View()

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

  render: (course, role, filters) ->
    for group, views of @views
      for name, view of views
        view.init(course, role, filters)
    dates = course.dates
    for user, userid in course.users[role].list
      if user.data
        for day, components of user.data
          for component, eventnames of components
            for eventname, eventcontexts of eventnames
              for eventcontext, descriptions of eventcontexts
                for description, hours of descriptions
                  for time, size of hours
                    row =
                      user: userid
                      day: day
                      component: component
                      event:
                        name: eventname
                        context: eventcontext
                        fullname: eventname + ' (' + eventcontext + ')'
                      description: description
                      page: eventcontext
                      time: time
                      size: size
                    row.page = description if /^http/.test(eventcontext)
                    for _, views of @views
                      for _, view of views
                        view.recorded(row)
                        if (user.selected && filters.indexOf(row.event.fullname) < 0 &&
                          dates.min.selected <= day <= dates.max.selected
                        )
                          view.selected(row)
    for _, views of @views
      for _, view of views
        view.render()
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

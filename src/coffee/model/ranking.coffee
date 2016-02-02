###
# ranking: ranking model
###

class Ranking
  constructor: (@course, @role) ->
    @d =
      users:
        totalViews: []
        activities: []
        pages: []
        dates: []
      pages:
        totalViews: []
        users: []
        activities: []
        dates: []
      activities:
        totalViews: []
        users: []
        dates: []
    @s =
      users: {}
      pages: {}
      activities: {}

  selected: (d) ->
    event = d.event.name + ' (' + d.event.context + ')'
    unless @s.users[d.user]
      @s.users[d.user] =
        totalViews: 0
        activities: {}
        pages: {}
        dates: {}
    unless @s.users[d.user].dates[d.day]
      @s.users[d.user].dates[d.day] = 1
    unless @s.users[d.user].activities[event]
      @s.users[d.user].activities[event] = 1
    unless @s.activities[event]
      @s.activities[event] =
        totalViews: 0
        users: {}
        dates: {}
    unless @s.activities[event].users[d.user]
      @s.activities[event].users[d.user] = 1
    unless @s.activities[event].dates[d.day]
      @s.activities[event].dates[d.day] = 1
    if /view/.test(d.event.name)
      @s.users[d.user].totalViews += d.size
      unless @s.users[d.user].pages[d.page]
        @s.users[d.user].pages[d.page] = 1
      @s.activities[event].totalViews += d.size
      unless @s.pages[d.page]
        @s.pages[d.page] =
          totalViews: 0
          users: {}
          activities: {}
          dates: {}
      @s.pages[d.page].totalViews += d.size
      unless @s.pages[d.page].users[d.user]
        @s.pages[d.page].users[d.user] = 1
      unless @s.pages[d.page].activities[event]
        @s.pages[d.page].activities[event] = 1
      unless @s.pages[d.page].dates[d.day]
        @s.pages[d.page].dates[d.day] = 1

  data: ->
    unless Object.keys(@s.users).length
      return
    for i, values of @s.users
      user = @course.users[@role].list[i]
      name = user.firstname + ' ' + user.lastname
      counts =
        totalViews: values.totalViews
        activities: Object.keys(values.activities).length
        pages: Object.keys(values.pages).length
        dates: Object.keys(values.dates).length
      for key, val of counts
        if val > 0
          @d.users[key].push([name, val])
    for page, values of @s.pages
      if page.length > 0
        counts =
          totalViews: values.totalViews
          users: Object.keys(values.users).length
          activities: Object.keys(values.activities).length
          dates: Object.keys(values.dates).length
        for key, val of counts
          if val > 0
            @d.pages[key].push([page, val])
    for activity, values of @s.activities
      counts =
        totalViews: values.totalViews
        users: Object.keys(values.users).length
        dates: Object.keys(values.dates).length
      for key, val of counts
        if val > 0
          @d.activities[key].push([activity, val])
    @d

model.register('ranking', Ranking)

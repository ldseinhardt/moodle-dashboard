###
# summary: summary model
###

class Summary
  constructor: (@course, @role) ->
    day = 1000 * 60 * 60 * 24
    min = @course.dates.min
    max = @course.dates.max
    users = @course.users[@role].list
    @d =
      pageViews: [0, 0]
      uniqueUsers: [
        users.length,
        users.filter((user) -> user.selected).length
      ]
      meanSession: [0, 0]
    @r =
      activities: {}
      pages: {}
      sessions: {}
    @s =
      activities: {}
      pages: {}
      sessions: {}
  selected: (d) ->
    unless @s.sessions[d.user]
      @s.sessions[d.user] = {}
    unless @s.sessions[d.user][d.day]
      @s.sessions[d.user][d.day] = []
    @s.sessions[d.user][d.day].push(d.time / 1000)
    event = d.event.name + ' (' + d.event.context + ')'
    unless @s.activities[event]
      @s.activities[event] = 1
    if /view/.test(d.event.name)
      @d.pageViews[1] += d.size
      unless @s.pages[d.page]
        @s.pages[d.page] = 1

  recorded: (d) ->
    unless @r.sessions[d.user]
      @r.sessions[d.user] = {}
    unless @r.sessions[d.user][d.day]
      @r.sessions[d.user][d.day] = []
    @r.sessions[d.user][d.day].push(d.time / 1000)
    event = d.event.name + ' (' + d.event.context + ')'
    unless @r.activities[event]
      @r.activities[event] = 1
    if /view/.test(d.event.name)
      @d.pageViews[0] += d.size
      unless @r.pages[d.page]
        @r.pages[d.page] = 1

  data: ->
    for type, i in ['r', 's']
      sessions = []
      for user, days of @[type].sessions
        for day, times of days
          a = times[0]
          b = times[0]
          for t in times.sort()
            if t - a > 5400
              sessions.push(b - a)
              a = t
            b = t
          sessions.push(b - a)
      if sessions.length
        minutes = sessions.reduce((a, b) -> a + b) / (sessions.length * 60)
        @d.meanSession[i] = Math.round(minutes * 100) / 100
    @d.uniqueActivities = [
      Object.keys(@r.activities).length,
      Object.keys(@s.activities).length
    ]
    @d.uniquePages = [
      Object.keys(@r.pages).length,
      Object.keys(@s.pages).length
    ]
    @d

model.register('summary', Summary)

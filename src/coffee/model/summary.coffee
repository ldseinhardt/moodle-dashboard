###
# summary: summary model
###

class Summary extends ModelBase
  init: (@course, @role) ->
    @data =
      pageViews: [0, 0]
      meanSession: [0, 0]
    @_recorded =
      activities: {}
      pages: {}
      sessions: {}
    @_selected =
      activities: {}
      pages: {}
      sessions: {}
    @

  selected: (row) ->
    unless @_selected.sessions[row.user]
      @_selected.sessions[row.user] = {}
    unless @_selected.sessions[row.user][row.day]
      @_selected.sessions[row.user][row.day] = []
    @_selected.sessions[row.user][row.day].push(row.time / 1000)
    unless @_selected.activities[row.event.fullname]
      @_selected.activities[row.event.fullname] = 1
    if /view/.test(row.event.name)
      @data.pageViews[1] += row.size
      unless @_selected.pages[row.page]
        @_selected.pages[row.page] = 1
    @

  recorded: (row) ->
    unless @_recorded.sessions[row.user]
      @_recorded.sessions[row.user] = {}
    unless @_recorded.sessions[row.user][row.day]
      @_recorded.sessions[row.user][row.day] = []
    @_recorded.sessions[row.user][row.day].push(row.time / 1000)
    unless @_recorded.activities[row.event.fullname]
      @_recorded.activities[row.event.fullname] = 1
    if /view/.test(row.event.name)
      @data.pageViews[0] += row.size
      unless @_recorded.pages[row.page]
        @_recorded.pages[row.page] = 1
    @

  getData: ->
    for type, i in ['_recorded', '_selected']
      sessions = []
      for user, days of @[type].sessions
        for day, times of days
          times.sort((a, b) ->
            if a < b
              return -1
            if a > b
              return 1
            return 0
          )
          a = times[0]
          b = times[0]
          for t in times
            if t - b > @sessiontime
              sessions.push(b - a)
              a = t
            b = t
          sessions.push(b - a)
      if sessions.length
        minutes = sessions.reduce((a, b) -> a + b) / (sessions.length * 60)
        @data.meanSession[i] = Math.round(minutes * 100) / 100
    @data.uniqueActivities = [
      Object.keys(@_recorded.activities).length,
      Object.keys(@_selected.activities).length
    ]
    @data.uniquePages = [
      Object.keys(@_recorded.pages).length,
      Object.keys(@_selected.pages).length
    ]
    @data

model.register(new Summary('summary', 'general'))

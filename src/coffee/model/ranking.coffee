###
# ranking: ranking model
###

class Ranking extends ModelBase
  init: (@course, @role) ->
    @data =
      users: []
      pages: []
      activities: []
    @_selected =
      users: {}
      pages: {}
      activities: {}

  selected: (row) ->
    unless @_selected.users[row.user]
      @_selected.users[row.user] =
        totalViews: 0
        activities: {}
        pages: {}
        dates: {}
    unless @_selected.users[row.user].dates[row.day]
      @_selected.users[row.user].dates[row.day] = []
    @_selected.users[row.user].dates[row.day].push(row.time / 1000)
    unless @_selected.users[row.user].activities[row.event.fullname]
      @_selected.users[row.user].activities[row.event.fullname] = 1
    unless @_selected.activities[row.event.fullname]
      @_selected.activities[row.event.fullname] =
        page : row.page
        activity : row.event.name
        totalViews: 0
        sessions:
          count: 0
          users: {}
        users: {}
        dates: {}
    @_selected.activities[row.event.fullname].sessions.count++
    unless @_selected.activities[row.event.fullname].sessions.users[row.user]
      @_selected.activities[row.event.fullname].sessions.users[row.user] = {}
    unless @_selected.activities[row.event.fullname].sessions.users[row.user][row.day]
      @_selected.activities[row.event.fullname].sessions.users[row.user][row.day] = []
    @_selected.activities[row.event.fullname].sessions.users[row.user][row.day]
      .push(row.time / 1000)
    unless @_selected.activities[row.event.fullname].users[row.user]
      @_selected.activities[row.event.fullname].users[row.user] = 1
    unless @_selected.activities[row.event.fullname].dates[row.day]
      @_selected.activities[row.event.fullname].dates[row.day] = 1
    if /view/.test(row.event.name)
      @_selected.users[row.user].totalViews += row.size
      unless @_selected.users[row.user].pages[row.page]
        @_selected.users[row.user].pages[row.page] = 1
      @_selected.activities[row.event.fullname].totalViews += row.size
      unless @_selected.pages[row.page]
        @_selected.pages[row.page] =
          totalViews: 0
          sessions:
            count: 0
            users: {}
          users: {}
          activities: {}
          dates: {}
      @_selected.pages[row.page].totalViews += row.size
      @_selected.pages[row.page].sessions.count++
      unless @_selected.pages[row.page].sessions.users[row.user]
        @_selected.pages[row.page].sessions.users[row.user] = {}
      unless @_selected.pages[row.page].sessions.users[row.user][row.day]
        @_selected.pages[row.page].sessions.users[row.user][row.day] = []
      @_selected.pages[row.page].sessions.users[row.user][row.day]
        .push(row.time / 1000)
      unless @_selected.pages[row.page].users[row.user]
        @_selected.pages[row.page].users[row.user] = 1
      unless @_selected.pages[row.page].activities[row.event.fullname]
        @_selected.pages[row.page].activities[row.event.fullname] = 1
      unless @_selected.pages[row.page].dates[row.day]
        @_selected.pages[row.page].dates[row.day] = 1
    @

  getData: ->
    unless Object.keys(@_selected.users).length
      return
    for i, values of @_selected.users
      user = @course.users[@role].list[i]
      name = user.firstname + ' ' + user.lastname
      counts =
        totalViews: values.totalViews
        activities: Object.keys(values.activities).length
        pages: Object.keys(values.pages).length
        dates: Object.keys(values.dates).length
        bounceRate: 0
      _sessions = []
      for day, times of values.dates
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
          if t - a > @sessiontime
            _sessions.push(b - a)
            a = t
          b = t
        _sessions.push(b - a)
      bounce = _sessions.filter((e) -> e == 0).length
      counts.bounceRate = Math.round((bounce / _sessions.length) * 100)
      line =
        user:
          value: name
      for key, value of counts
        line[key] =
          value: value
      @data.users.push(line)
    for page, values of @_selected.pages
      if page.length > 0
        counts =
          totalViews: values.totalViews
          users: Object.keys(values.users).length
          activities: Object.keys(values.activities).length
          dates: Object.keys(values.dates).length
          bounceRate: 0
        _sessions = []
        for user, days of values.sessions.users
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
              if t - a > @sessiontime
                _sessions.push(b - a)
                a = t
              b = t
            _sessions.push(b - a)
        bounce = _sessions.filter((e) -> e == 0).length / values.sessions.count
        counts.bounceRate = Math.round(bounce * 100)
        line =
          page:
            value: page
        for key, value of counts
          line[key] =
            value: value
        @data.pages.push(line)
    for _, values of @_selected.activities
      counts =
        totalViews: values.totalViews
        users: Object.keys(values.users).length
        dates: Object.keys(values.dates).length
        bounceRate: 0
      _sessions = []
      for user, days of values.sessions.users
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
            if t - a > @sessiontime
              _sessions.push(b - a)
              a = t
            b = t
          _sessions.push(b - a)
      bounce = _sessions.filter((e) -> e == 0).length / values.sessions.count
      counts.bounceRate = Math.round(bounce * 100)
      line =
        activity:
          value: values.activity
        page:
          value: values.page
      for key, value of counts
        line[key] =
          value: value
      @data.activities.push(line)
    @data

model.register(new Ranking('ranking', 'general'))

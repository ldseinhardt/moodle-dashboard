###
# ranking: ranking model
###

class Ranking
  constructor: (@course, @role) ->
    @session_timeout = 90 * 60 #90min
    @d =
      users:
        totalViews: []
        activities: []
        pages: []
        dates: []
        bounceRate: []
      pages:
        totalViews: []
        users: []
        activities: []
        dates: []
        bounceRate: []
      activities:
        totalViews: []
        users: []
        dates: []
        bounceRate: []
    @s =
      users: {}
      pages: {}
      activities: {}

  selected: (d) ->
    unless @s.users[d.user]
      @s.users[d.user] =
        totalViews: 0
        activities: {}
        pages: {}
        dates: {}
    unless @s.users[d.user].dates[d.day]
      @s.users[d.user].dates[d.day] = []
    @s.users[d.user].dates[d.day].push(d.time / 1000)
    unless @s.users[d.user].activities[d.event.fullname]
      @s.users[d.user].activities[d.event.fullname] = 1
    unless @s.activities[d.event.fullname]
      @s.activities[d.event.fullname] =
        totalViews: 0
        sessions:
          count: 0
          users: {}
        users: {}
        dates: {}
    @s.activities[d.event.fullname].sessions.count++
    unless @s.activities[d.event.fullname].sessions.users[d.user]
      @s.activities[d.event.fullname].sessions.users[d.user] = {}
    unless @s.activities[d.event.fullname].sessions.users[d.user][d.day]
      @s.activities[d.event.fullname].sessions.users[d.user][d.day] = []
    @s.activities[d.event.fullname].sessions.users[d.user][d.day]
      .push(d.time / 1000)
    unless @s.activities[d.event.fullname].users[d.user]
      @s.activities[d.event.fullname].users[d.user] = 1
    unless @s.activities[d.event.fullname].dates[d.day]
      @s.activities[d.event.fullname].dates[d.day] = 1
    if /view/.test(d.event.name)
      @s.users[d.user].totalViews += d.size
      unless @s.users[d.user].pages[d.page]
        @s.users[d.user].pages[d.page] = 1
      @s.activities[d.event.fullname].totalViews += d.size
      unless @s.pages[d.page]
        @s.pages[d.page] =
          totalViews: 0
          sessions:
            count: 0
            users: {}
          users: {}
          activities: {}
          dates: {}
      @s.pages[d.page].totalViews += d.size
      @s.pages[d.page].sessions.count++
      unless @s.pages[d.page].sessions.users[d.user]
        @s.pages[d.page].sessions.users[d.user] = {}
      unless @s.pages[d.page].sessions.users[d.user][d.day]
        @s.pages[d.page].sessions.users[d.user][d.day] = []
      @s.pages[d.page].sessions.users[d.user][d.day].push(d.time / 1000)
      unless @s.pages[d.page].users[d.user]
        @s.pages[d.page].users[d.user] = 1
      unless @s.pages[d.page].activities[d.event.fullname]
        @s.pages[d.page].activities[d.event.fullname] = 1
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
          if t - a > @session_timeout
            _sessions.push(b - a)
            a = t
          b = t
        _sessions.push(b - a)
      bounce = _sessions.filter((e) -> e == 0).length
      counts.bounceRate = Math.round((bounce / _sessions.length) * 100) / 100
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
              if t - a > @session_timeout
                _sessions.push(b - a)
                a = t
              b = t
            _sessions.push(b - a)
        bounce = _sessions.filter((e) -> e == 0).length / values.sessions.count
        counts.bounceRate = Math.round(bounce * 100) / 100
        for key, val of counts
          if val > 0
            @d.pages[key].push([page, val])
    for activity, values of @s.activities
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
            if t - a > @session_timeout
              _sessions.push(b - a)
              a = t
            b = t
          _sessions.push(b - a)
      bounce = _sessions.filter((e) -> e == 0).length / values.sessions.count
      counts.bounceRate = Math.round(bounce * 100) / 100
      for key, val of counts
        if val > 0
          @d.activities[key].push([activity, val])
    @d

model.register('ranking', Ranking)

###
# activity: activity model
###

class Activity
  constructor: (@course, @role) ->
    @d =
      users: []
      pageViews:
        total: []
        parcial: []
      uniqueUsers: []
      uniqueActivities:
        total: []
        parcial: []
      uniquePages:
        total: []
        parcial: []
      meanSession:
        total: []
        parcial: []
    @s =
      users: {}
      tree: {}

  selected: (d) ->
    unless @s.users[d.user]
      @s.users[d.user] = 1
    unless @s.tree[d.day]
      @s.tree[d.day] =
        users: {}
        activities: {}
        pages: {}
    unless @s.tree[d.day].users[d.user]
      @s.tree[d.day].users[d.user] =
        pageViews: 0
        sessions: []
    @s.tree[d.day].users[d.user].sessions.push(d.time / 1000)
    event = d.event.name + ' (' + d.event.context + ')'
    unless @s.tree[d.day].activities[event]
      @s.tree[d.day].activities[event] = {}
    unless @s.tree[d.day].activities[event][d.user]
      @s.tree[d.day].activities[event][d.user] = 1
    if /view/.test(d.event.name)
      @s.tree[d.day].users[d.user].pageViews += d.size
      unless @s.tree[d.day].pages[d.page]
        @s.tree[d.day].pages[d.page] = {}
      unless @s.tree[d.day].pages[d.page][d.user]
        @s.tree[d.day].pages[d.page][d.user] = 1

  data: ->
    unless Object.keys(@s.users).length
      return
    for i of @s.users
      user = @course.users[@role].list[i]
      @d.users.push(user.firstname + ' ' + user.lastname)
    timelist = Object.keys(@s.tree)
    timelist.sort((a, b) ->
      if (a < b)
        return -1
      if (a > b)
        return 1
      return 0
    )
    for day in timelist
      value = @s.tree[day]
      pageViews = []
      activities = []
      pages = []
      sessions =
        total:
          value: 0
          users: 0
        parcial: []
      for i of @s.users
        count = 0
        session = 0
        if value.users[i]
          count = value.users[i].pageViews
          times = value.users[i].sessions.sort((a, b) ->
            if (a < b)
              return -1
            if (a > b)
              return 1
            return 0
          )
          _sessions = []
          a = times[0]
          b = times[0]
          for t in times
            if t - a > 5400
              _sessions.push(b - a)
              a = t
            b = t
          _sessions.push(b - a)
          minutes = _sessions.reduce((a, b) -> a + b) / (_sessions.length * 60)
          session = Math.round(minutes * 100) / 100
          sessions.total.value += minutes
          sessions.total.users++
        pageViews.push(count)
        sessions.parcial.push(session)
        count = 0
        for activitie, users of value.activities
          if users[i]
            count++
        activities.push(count)
        count = 0
        for page, users of value.pages
          if users[i]
            count++
        pages.push(count)
      date = new Date(parseInt(day)).toLocaleString().split(/\s/)[0]
      @d.pageViews.total.push([date, pageViews.reduce((a, b) -> a + b)])
      @d.uniqueActivities.total
        .push([date, Object.keys(value.activities).length])
      @d.uniquePages.total.push([date, Object.keys(value.pages).length])
      minutes = sessions.total.value / sessions.total.users
      @d.meanSession.total.push([date, Math.round(minutes * 100) / 100])
      pageViews.unshift(date)
      activities.unshift(date)
      pages.unshift(date)
      sessions.parcial.unshift(date)
      @d.pageViews.parcial.push(pageViews)
      @d.uniqueUsers.push([date, Object.keys(value.users).length])
      @d.uniqueActivities.parcial.push(activities)
      @d.uniquePages.parcial.push(pages)
      @d.meanSession.parcial.push(sessions.parcial)
    unless @d.pageViews?.total[0]?.length > 1
      return
    @d

model.register('activity', Activity)

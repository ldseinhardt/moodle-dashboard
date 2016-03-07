###
# activity: activity model
###

class Activity extends ModelBase
  init: (@course, @role) ->
    @data =
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
      bounceRate: []
    @_selected =
      users: {}
      tree: {}
    @

  selected: (row) ->
    unless @_selected.users[row.user]
      @_selected.users[row.user] = 1
    unless @_selected.tree[row.day]
      @_selected.tree[row.day] =
        users: {}
        activities: {}
        pages: {}
    unless @_selected.tree[row.day].users[row.user]
      @_selected.tree[row.day].users[row.user] =
        pageViews: 0
        sessions: []
    @_selected.tree[row.day].users[row.user].sessions.push(row.time / 1000)
    unless @_selected.tree[row.day].activities[row.event.fullname]
      @_selected.tree[row.day].activities[row.event.fullname] = {}
    unless @_selected.tree[row.day].activities[row.event.fullname][row.user]
      @_selected.tree[row.day].activities[row.event.fullname][row.user] = 1
    if /view/.test(row.event.name)
      @_selected.tree[row.day].users[row.user].pageViews += row.size
      unless @_selected.tree[row.day].pages[row.page]
        @_selected.tree[row.day].pages[row.page] = {}
      unless @_selected.tree[row.day].pages[row.page][row.user]
        @_selected.tree[row.day].pages[row.page][row.user] = 1
    @

  getData: ->
    unless Object.keys(@_selected.users).length
      return
    for i of @_selected.users
      user = @course.users[@role].list[i]
      @data.users.push(user.firstname + ' ' + user.lastname)
    timelist = Object.keys(@_selected.tree)
    timelist.sort((a, b) ->
      if a < b
        return -1
      if a > b
        return 1
      return 0
    )
    for day in timelist
      value = @_selected.tree[day]
      pageViews = []
      activities = []
      pages = []
      sessions =
        total:
          value: 0
          users: 0
        parcial: []
      bounce =
        value: 0
        total: 0
      for i of @_selected.users
        count = 0
        session = 0
        if value.users[i]
          count = value.users[i].pageViews
          times = value.users[i].sessions.sort((a, b) ->
            if a < b
              return -1
            if a > b
              return 1
            return 0
          )
          _sessions = []
          a = times[0]
          b = times[0]
          for t in times
            if t - b > @sessiontime
              _sessions.push(b - a)
              a = t
            b = t
          _sessions.push(b - a)
          bounce.total += _sessions.length
          bounce.value += _sessions.filter((e) -> e == 0).length
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
      @data.pageViews.total.push([date, pageViews.reduce((a, b) -> a + b)])
      @data.uniqueActivities.total
        .push([date, Object.keys(value.activities).length])
      @data.uniquePages.total.push([date, Object.keys(value.pages).length])
      minutes = sessions.total.value / sessions.total.users
      @data.meanSession.total.push([date, Math.round(minutes * 100) / 100])
      pageViews.unshift(date)
      activities.unshift(date)
      pages.unshift(date)
      sessions.parcial.unshift(date)
      @data.pageViews.parcial.push(pageViews)
      @data.uniqueUsers.push([date, Object.keys(value.users).length])
      @data.uniqueActivities.parcial.push(activities)
      @data.uniquePages.parcial.push(pages)
      @data.meanSession.parcial.push(sessions.parcial)
      @data.bounceRate
        .push([date, Math.round((bounce.value / bounce.total) * 100) / 100])
    unless @data.pageViews?.total[0]?.length > 1
      return
    @data

model.register(new Activity('activity', 'general'))

###
# moodle: moodle data
###

class Moodle
  constructor: (options) ->
    if options
      options = @parse(options) if typeof options == 'string' && options.length
      for key, value of options
        @[key] = value
    console.log('Moodle:', @)

  syncTitle: (response) ->
    $.ajax(
      url: @url
      success: (data) =>
        parser = new DOMParser()
        doc = parser.parseFromString(data, 'text/html')
        @title = $($('*[class="tree_item branch"] *[title]', doc)[0])
          .attr('title')?.trim()
        unless @title
          @title = $('title', doc).text()?.trim()
        response(Moodle.response().success)
    )
    @

  sync: (response) ->
    $.ajax(
      url: @url + '/my'
      success: (data) =>
        parser = new DOMParser()
        doc = parser.parseFromString(data, 'text/html')
        courses = $('.course_list a[href*="course/view.php"]', doc)
        unless courses.length
          return response(
            Moodle.response().sync_no_courses,
            Moodle.response().sync_courses
          )
        unless @courses
          @courses = []
        courses.each((i, course) =>
          id = parseInt(/[\\?&]id=([^&#]*)/.exec($(course).prop('href'))[1])
          name = $(course).text().trim()
          equal = false
          for c in @courses
            if c.id == id
              c.name = name
              equal = true
              break
          unless equal
            @courses.push(
              id: id
              name: name
              selected: (i == 0)
              users: []
              errors: []
            )
        )
        for course in @courses
          @syncUsers(course, response)
        response(
          Moodle.response().success,
          Moodle.response().sync_courses
        )
      error: ->
        response(
          Moodle.response().sync_no_moodle_access,
          Moodle.response().sync_courses
        )
    )
    @

  syncUsers: (course, response) ->
    $.ajax(
      url: @url + '/enrol/users.php'
      data:
        id: course.id
      success: (data) =>
        parser = new DOMParser()
        doc = parser.parseFromString(data, 'text/html')
        list = $('table > tbody > tr', doc)
        unless list.length
          return response(
            Moodle.response().sync_no_users,
            Moodle.response().sync_users
          )
        a = $('*[class*="picture"] a', list)
        b = $('*[class*="name"]', list)
        c = $('*[class*="email"]', list)
        d = $('*[class*="roles"]', list)
        unless a.length || b.length || c.length || d.length
          return response(
            Moodle.response().sync_no_users,
            Moodle.response().sync_users
          )
        list.each((i) =>
          roles = []
          $('*[class^="role"]', d[i]).each((i_r, role) ->
            id = 0
            value = []
            if $(role).attr('rel')
              value = $(role).attr('rel').match(/\d+/)
            unless value.length
              value = $(role).attr('class').match(/\d+/)
            if value.length
              id = parseInt(value[0])
            roles.push(
              id: id
              role: $(role).text().trim()
            )
          )
          unless roles.length
            roles.push(
              id: 0
              role: 'Participant'
            )
          for role, rid in roles
            ur = course.users.filter((user) => user.id == role.id)
            if ur.length
              user = ur[0]
            else
              p = course.users.push(
                id: role.id
                role: role.role
                list: []
                selected: rid == 0
              ) - 1
              user = course.users[p]
            usr =
              id: parseInt(/[\\?&]id=([^&#]*)/.exec($(a[i]).prop('href'))[1])
              picture: $('img', a[i]).prop('src')
              name: $(b[i]).text().trim()
              email: $(c[i]).text().trim()
              selected: true
            names = usr.name.toLowerCase().split(/\s/)
            usr.firstname = names[0].replace(/\S/, (e) ->
              e.toUpperCase()
            )
            if names.length > 1
              usr.lastname = names[names.length - 1].replace(/\S/, (e) ->
                e.toUpperCase()
              )
            equal = false
            for u in user.list
              if u.id == usr.id
                u.picture = usr.picture
                u.name = usr.name
                u.firstname = usr.firstname
                u.lastname = usr.lastname
                u.email = usr.email
                equal = true
                break
            unless equal
              user.list.push(usr)
              user.list.sort((a, b) ->
                x = a.name.toLowerCase()
                y = b.name.toLowerCase()
                if (x < y)
                  return -1;
                if (x > y)
                  return 1;
                return 0;
              )
            return
        )
        @upLastAccess()
        response(
          Moodle.response().success,
          Moodle.response().sync_users
        )
      error: =>
        response(
          Moodle.response().sync_no_moodle_access
          Moodle.response().sync_users
        )
    )
    @

  syncDates: (response) ->
    unless @hasCourses()
      return response(
        Moodle.response().sync_no_courses,
        Moodle.response().sync_dates
      )
    unless @hasUsers()
      return response(
        Moodle.response().sync_no_users,
        Moodle.response().sync_dates
      )
    course = @getCourse()
    $.ajax(
      url: @url + '/report/log'
      data:
        id: course.id
      success: (data) =>
        parser = new DOMParser()
        doc = parser.parseFromString(data, 'text/html')
        list = $('select[name="date"] option', doc)
        timelist = []
        list.each((i, e) =>
          if $(e).val()
            timelist.unshift(parseInt($(e).val()))
        )
        unless timelist.length
          return response(
            Moodle.response().sync_no_dates,
            Moodle.response().sync_dates
          )
        first = timelist[0] * 1000
        last = timelist[timelist.length - 1] * 1000
        if course.dates
          old = @clone(course.dates)
          timelist = timelist[timelist.indexOf(old.max.value / 1000)..]
          course.dates.min.value = first
          course.dates.max.value = last
          if old.max.selected == old.max.value
            course.dates.max.selected = last
            if old.min.selected != old.min.value
              dif = last - old.max.value
              if dif > 0
                course.dates.min.selected += dif
        else
          course.dates =
            min:
              value: first
              selected: first
            max:
              value: last
              selected: last
        course.users_not_found = {}
        console.log('timelist:', timelist, course.errors)
        timelist = timelist.concat(course.errors)
        course.errors = []
        for time in timelist
          @syncData(course, time, response)
        response(
          Moodle.response().success,
          Moodle.response().sync_dates,
          timelist.length
        )
      error: ->
        response(
          Moodle.response().sync_no_moodle_access,
          Moodle.response().sync_dates
        )
    )
    @

  syncData: (course, time, response) ->
    $.ajax(
      url: @url + '/report/log'
      data:
        id: course.id
        date: time
        chooselog: 1
        logformat: 'downloadascsv'
        download: 'tsv'
        lang: 'en'
      success: (data, textStatus, request) =>
        type = request.getResponseHeader('content-type')
        if /application\/download/.test(type)
          @processRaw(course, time, data)
        else if /text\/tab-separated-values/.test(type)
          if data.length > 0
            @processRaw(course, time, data)
        else
          if data.length > 0
            course.errors.push(time)
            return response(
              Moodle.response().sync_no_moodle_access,
              Moodle.response().sync_data
            )
        response(
          Moodle.response().success,
          Moodle.response().sync_data
        )
      error: ->
        response(
          Moodle.response().sync_no_moodle_access,
          Moodle.response().sync_data
        )
    )
    @

  processRaw: (course, time, data) ->
    logs = data.replace(/\"Saved\sat\:(.+)\s/, '')
    users = {}
    d3.tsv.parse(logs).forEach(
      (row) ->
        username = row['User full name'].trim()
        unless users[username]
          users[username] = []
        users[username].push(row)
    )
    for user, rows of users
      es = @getUser(course, user)
      if es.length
        for e in es
          realtime = time * 1000
          unless e.data
            e.data = {}
          e.data[realtime] = @processRow(rows, realtime)
      else
        course.users_not_found[user] = Date.now()
    @

  processRow: (rows, realtime) ->
    data = {}
    for row in rows
      action = (row['Event name'] || row['Action'])
      eventname = action.split(/\s\(/)?[0].trim()
      eventcontext = (
          row['Event context'] || action.split(/\s\(/)?[1].slice(0, -1)
        ).trim()
      component = (row['Component'] || action.split(/\s/)?[0]).trim()
      description = (row['Description'] || row['Information']).trim()
      hour = row['Time'].split(/,\s/)?[1]?.trim()
      date = new Date(realtime).toISOString().split(/T/)[0]
      time = Date.parse(date + ' ' + hour) - Date.parse(date)
      unless data[component]
        data[component] = {}
      unless data[component][eventname]
        data[component][eventname] = {}
      unless data[component][eventname][eventcontext]
        data[component][eventname][eventcontext] = {}
      unless data[component][eventname][eventcontext][description]
        data[component][eventname][eventcontext][description] = {}
      unless data[component][eventname][eventcontext][description][time]
        data[component][eventname][eventcontext][description][time] = 0
      data[component][eventname][eventcontext][description][time]++
    data

  setDefaultLang: ->
    $.ajax(
      url: @url
      data:
        lang: @lang
      method: 'HEAD'
    )
    @

  setCourse: (id) ->
    for course, i in @courses
      course.selected = (i == id)
    @

  setUser: (role, user, selected) ->
    users = @getCourse().users[role].list
    users[user].selected = selected
    @

  setUsersAll: (role) ->
    users = @getCourse().users[role].list
    for user in users
      user.selected = true
    @

  setUsersInvert: (role) ->
    users = @getCourse().users[role].list
    for user in users
      user.selected = !user.selected
    @

  setDates: (dates) ->
    @getCourse().dates = dates
    @

  upLastAccess: ->
    @last_sync = Date.now()
    @

  upLastSync: ->
    @getCourse().last_sync = Date.now()
    @

  select: (url) ->
    @selected = @equals(url) && @hasUsers()
    @

  getData: (role) ->
    unless @hasData()
      return
    course = @getCourse()
    callbacks =
      summary: @getSummary()
      activity: @getActivity()
      dayTime: @getDayTime()
      usersInteraction: @getUsersInteraction()
    data = {}
    temp = {}
    for name, method of callbacks
      [data[name], temp[name]] = method.init(course, role)
    @loop(
      role
      (row) ->
        for name, method of callbacks
          method.selected?(row, data[name], temp[name])
      (row) ->
        for name, method of callbacks
          method.recorded?(row, data[name], temp[name])
    )
    for name, method of callbacks
      data[name] = method.end(course, role, data[name], temp[name])
      delete temp[name]
    data

  getSummary: ->
    init: (course, role) ->
      dates = course.dates
      timeday = 1000 * 60 * 60 * 24
      [
        {
          uniqueUsers: [
            course.users[role].list.length,
            course.users[role].list.filter((user) -> user.selected).length
          ]
          dateRange: [
            Math.floor(
              (dates.max.value - dates.min.value) / timeday
            ) + 1,
            Math.floor(
              (dates.max.selected - dates.min.selected) / timeday
            ) + 1
          ]
          pageViews: [0, 0]
          meanSession: [15.8, 10] # not implemented
        },
        {
          recorded:
            activities: {}
            pages: {}
          selected:
            activities: {}
            pages: {}
        }
      ]
    selected: (row, data, temp) ->
      event = row.event.name + ' (' +  row.event.context + ')'
      unless temp.selected.activities[event]
        temp.selected.activities[event] = 1
      if /view/.test(row.event.name)
        data.pageViews[1] += row.size
        unless temp.selected.pages[event]
          temp.selected.pages[event] = 1
    recorded: (row, data, temp) ->
      event = row.event.name + ' (' +  row.event.context + ')'
      unless temp.recorded.activities[event]
        temp.recorded.activities[event] = 1
      if /view/.test(row.event.name)
        data.pageViews[0] += row.size
        unless temp.recorded.pages[event]
          temp.recorded.pages[event] = 1
    end: (course, role, data, temp) ->
      data.uniqueActivities = [
        Object.keys(temp.recorded.activities).length,
        Object.keys(temp.selected.activities).length
      ]
      data.uniquePages = [
        Object.keys(temp.recorded.pages).length,
        Object.keys(temp.selected.pages).length
      ]
      data

  getActivity: ->
    init: (course, role) ->
      [
        {
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
        },
        {
          users: {}
          tree: {}
        }
      ]
    selected: (row, data, temp) ->
      unless temp.users[row.user]
        temp.users[row.user] = 1
      unless temp.tree[row.day]
        temp.tree[row.day] =
          users: {}
          activities: {}
          pages: {}
      unless temp.tree[row.day].users[row.user]
        temp.tree[row.day].users[row.user] = 0
      event = row.event.name + ' (' +  row.event.context + ')'
      unless temp.tree[row.day].activities[event]
        temp.tree[row.day].activities[event] = {}
      unless temp.tree[row.day].activities[event][row.user]
        temp.tree[row.day].activities[event][row.user] = 1
      if /view/.test(row.event.name)
        temp.tree[row.day].users[row.user] += row.size
        unless temp.tree[row.day].pages[event]
          temp.tree[row.day].pages[event] = {}
        unless temp.tree[row.day].pages[event][row.user]
          temp.tree[row.day].pages[event][row.user] = 1
    end: (course, role, data, temp) ->
      unless Object.keys(temp.users).length
        return
      for i of temp.users
        user = course.users[role].list[i]
        data.users.push(user.firstname + ' ' + user.lastname)
      timelist = Object.keys(temp.tree)
      timelist.sort((a, b) ->
        if a < b
          return -1
        if a > b
          return 1
        return 0
      )
      for day in timelist
        value = temp.tree[day]
        pageViews = []
        activities = []
        pages = []
        for i of temp.users
          pageViews.push(value.users[i] || 0)
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
        data.pageViews.total.push([date, pageViews.reduce((a, b) -> a + b)])
        data.uniqueActivities.total
          .push([date, Object.keys(value.activities).length])
        data.uniquePages.total.push([date, Object.keys(value.pages).length])
        pageViews.unshift(date)
        activities.unshift(date)
        pages.unshift(date)
        data.pageViews.parcial.push(pageViews)
        data.uniqueUsers.push([date, Object.keys(value.users).length])
        data.uniqueActivities.parcial.push(activities)
        data.uniquePages.parcial.push(pages)
      unless data.pageViews?.total[0]?.length > 1
        return
      data

  getDayTime: ->
    init: (course, role) ->
      data = {}
      for i in [0..7]
        data[i] = []
        for n in [0..23]
          data[i].push(0)
      [data, {}]
    selected: (row, data, temp) ->
      day = parseInt(row.day)
      week = new Date(day).getDay() + 1
      hour = new Date(day + parseInt(row.time)).getHours()
      data[week][hour] += row.size
      data[0][hour] += row.size
    end: (course, role, data, temp) ->
      total = 0
      for size in data[0]
        total += size
        if total > 0
          break
      unless total
        return
      data

  getUsersInteraction: ->
    init: (course, role) ->
      [[], {}]
    selected: (row, data, temp) ->
      unless temp[row.user]
        temp[row.user] = 0
      temp[row.user] += row.size
    end: (course, role, data, temp) ->
      unless Object.keys(temp).length
        data = null
        return
      for i, size of temp
        user = course.users[role].list[i]
        data.push([user.firstname + ' ' + user.lastname, size])
        data.sort((a, b) ->
          if a[1] > b[1]
            return -1
          if a[1] < b[1]
            return 1
          return 0
        )
      data

  loop: (role, selected, recorded) ->
    course = @getCourse()
    min = course.dates.min.selected
    max = course.dates.max.selected
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
                      description: description
                      time: time
                      size: size
                    recorded?(row)
                    if user.selected && min <= day <= max
                      selected?(row)
    @

  getTitle: ->
    @title

  getURL: ->
    @url

  getCourse: ->
    for course in @courses
      if course.selected
        return course

  getCourseList: ->
    for course in @courses
      name: course.name
      selected: course.selected

  getRoles: ->
    for role in @getCourse().users
      name: role.role

  getUser: (course, username) ->
    list = []
    for role in course.users
      for user in role.list
        if user.name == username
          list.push(user)
    list

  getUsers: ->
    roles = @getRoles()
    for role, i in roles
      role.users = []
      for user in @getCourse().users[i].list
        role.users.push(
          id: user.id
          picture: user.picture
          email: user.email
          name: user.name
          firstname: user.firstname
          lastname: user.lastname
          selected: user.selected
        )
    roles

  getUsersNotFound: ->
    course = @getCourse()
    if course.users_not_found
      Object.keys(course.users_not_found)
    else
      []

  getDates: ->
    @getCourse().dates

  getLastAccess: ->
    @last_sync || 0

  getLastSync: ->
    @getCourse().last_sync || 0

  hasCourses: ->
    @courses?

  hasUsers: ->
    unless @hasCourses()
      return false
    @getCourse().users.length > 0

  hasDates: ->
    unless @hasCourses()
      return false
    @getCourse().dates?

  hasErrors: ->
    unless @hasCourses()
      return false
    @getCourse().errors.length > 0

  hasData: ->
    @hasDates() && @getLastSync() > 0

  isSelected: ->
    @selected

  equals: (url) ->
    @url == url

  classes: (root) ->
    classes = []
    recurse = (name, node) ->
      if node.children
        node.children.forEach((child) -> recurse(node.name, child))
      else
        classes.push(
          packageName: name
          className: node.name
          value: node.size
        )
    recurse(null, root)
    classes = classes.filter((d) -> d.value > 0)
    children: classes

  toString: ->
    JSON.stringify(@)

  parse: (str) ->
    JSON.parse(str)

  clone: (obj) ->
    JSON.parse(JSON.stringify(obj))

  @response: ->
    success: 'SUCCESS'
    sync_no_moodle_access: 'SYNC_NO_MOODLE_ACCESS'
    sync_no_courses: 'SYNC_NO_COURSES'
    sync_no_users: 'SYNC_NO_USERS'
    sync_no_dates: 'SYNC_NO_DATES'
    sync_no_data: 'SYNC_NO_DATA'
    sync_courses: 'SYNC_COURSES'
    sync_users: 'SYNC_USERS'
    sync_dates: 'SYNC_DATES'
    sync_data: 'SYNC_DATA'

@Moodle = Moodle

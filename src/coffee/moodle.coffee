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
    # default = /my, cafeead moodle = /disciplinas
    $.ajax(
      url: @url + '/disciplinas'
      type: 'HEAD'
      success: =>
        @syncCourses(response, 'disciplinas')
      error: =>
        @syncCourses(response)
    )
    @

  syncCourses: (response, path = 'my') ->
    $.ajax(
      url: @url + '/' + path
      data:
        mynumber: -2
      success: (data) =>
        parser = new DOMParser()
        doc = parser.parseFromString(data, 'text/html')
        courses = $('h2 > a[href*="course/view.php?id="]', doc)
        unless courses.length
          courses = $('h4 > a[href*="course/view.php?id="]', doc)
        unless courses.length
          courses = $('li > a[href*="course/view.php?id="]', doc)
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
              selected: false
              users: []
              errors: []
            )
        )
        @courses.sort((a, b) ->
          if a.id > b.id
            return -1
          if a.id < b.id
            return 1
          return 0
        )
        @courses[0].selected = true;
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
          for role in roles
            ur = course.users.filter((user) => user.id == role.id)
            if ur.length
              user = ur[0]
            else
              p = course.users.push(
                id: role.id
                role: role.role
                list: []
                selected: false
              ) - 1
              user = course.users[p]
            usr =
              id: parseInt(/[\\?&]id=([^&#]*)/.exec($(a[i]).prop('href'))[1])
              picture: $('img', a[i]).prop('src')
              name: $(b[i]).text().replace(/\s\s/g, ' ').trim()
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
                if x < y
                  return -1
                if x > y
                  return 1
                return 0
              )
            return
        )
        course.users.sort((a, b) ->
          if a.list.length > b.list.length
            return -1
          if a.list.length < b.list.length
            return 1
          return 0
        )
        course.users[0].selected = true
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
      url: @url + '/report/log/'
      data:
        id: course.id
      success: (data) =>
        parser = new DOMParser()
        doc = parser.parseFromString(data, 'text/html')
        list = $('select[name="date"] option', doc)
        timelist = []
        list.each((i, e) =>
          if $(e).val()
            timelist.push(parseInt($(e).val()))
        )
        unless timelist.length
          return response(
            Moodle.response().sync_no_dates,
            Moodle.response().sync_dates
          )
        timelist.sort((a, b) ->
          if a < b
            return -1
          if a > b
            return 1
          return 0
        )
        first = timelist[0] * 1000
        last = timelist[timelist.length - 1] * 1000
        if course.dates
          old = @clone(course.dates)
          timelist = timelist[timelist.indexOf(old.max.value / 1000)..]
          course.dates.max.value = last
          if old.max.selected == old.max.value
            course.dates.max.selected = last
            if old.min.selected != old.min.value
              dif = last - old.max.value
              if dif > 0
                course.dates.min.selected += dif
          if course.dates.min.selected < course.dates.min.value
            course.dates.min.selected = course.dates.min.value
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
      url: @url + '/report/log/'
      data:
        id: course.id
        date: time
        chooselog: 1
        logformat: 'downloadascsv'
        download: 'csv'
        lang: 'en'
      success: (data, textStatus, request) =>
        type = request.getResponseHeader('content-type')
        if /application\/download/.test(type)
          @processRaw(course, time, data, 'tsv')
        else if /text\/tab-separated-values/.test(type)
          if data.length > 0
            @processRaw(course, time, data, 'tsv')
        else if /text\/csv/.test(type)
          if data.length > 0
            @processRaw(course, time, data, 'csv')
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
      error: (request) ->
        if request.status >= 400
          return response(
            Moodle.response().success,
            Moodle.response().sync_data
          );
        course.errors.push(time)
        response(
          Moodle.response().sync_no_moodle_access,
          Moodle.response().sync_data
        )
    )
    @

  processRaw: (course, time, data, type) ->
    realtime = time * 1000
    logs = data.replace(/\"Saved\sat\:(.+)\s/, '')
    unless course.logs
      course.logs = {}
    course.logs[realtime] = d3[type].parse(logs)
    users = {}
    for row in course.logs[realtime]
      username = (row['User full name'] || row['Nome completo']).trim()
      unless users[username]
        users[username] = []
      users[username].push(row)
    for user, rows of users
      es = @getUser(course, user)
      if es.length
        for e in es
          unless e.data
            e.data = {}
          e.data[realtime] = @processRow(rows, realtime)
      else
        course.users_not_found[user] = Date.now()
    @

  processRow: (rows, realtime) ->
    data = {}
    for row in rows
      action = (row['Event name'] || row['Action'] || row['Nome do evento'])
      eventname = action.split(/\s\(/)?[0].trim()
      eventcontext = (
          row['Event context'] || row['Contexto do Evento'] || action.split(/\s\(/)?[1].slice(0, -1)
        ).trim()
      component = (row['Component'] || row['Componente'] || action.split(/\s/)?[0]).trim()
      if component.toLowerCase() == 'logs'
        continue
      description = (row['Description'] || row['Information'] || row['Descrição'])
      if description
        description = description.trim()
      hour = /([0-9]{1,2}:[0-9]{1,2})(\s(A|P)M)?/.exec((row['Time'] || row['Hora']).toUpperCase())[0]
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

  getSessKey: (response) ->
    $.ajax(
      url: @url
      success: (data, textStatus, request) ->
        parser = new DOMParser()
        doc = parser.parseFromString(data, 'text/html')
        sesskey = /"sesskey":"([^"]*)/.exec($('head', doc).html())
        if sesskey && sesskey.length > 1 && sesskey[1]
          return response(sesskey[1])
        response()
      error: -> response()
    )
    @

  sendMessageToUser: (user, message, sesskey, response) ->
    $.ajax(
      url: @url + '/message/index.php'
      data:
        id: user
        message: message
        sesskey: sesskey
        _qf__send_form: 1
        submitbutton: 'send'
      method: 'POST'
      success: (data, textStatus, request) -> response()
      error: -> response()
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

  getActivities: (role) ->
    unless @hasData()
      return
    course = @getCourse()
    data = {}
    for user, userid in course.users[role].list
      if user.data
        for day, components of user.data
          for component, eventnames of components
            for eventname, eventcontexts of eventnames
              for eventcontext, descriptions of eventcontexts
                for description, hours of descriptions
                  page = eventcontext
                  if /^http/.test(page)
                    page = description
                  event = eventname + ' (' + eventcontext + ')'
                  unless data[event]
                    data[event] =
                      page: page
                      event: eventname
    data

  getAssignments: () ->
    unless @hasData()
      return
    course = @getCourse()
    data = {}
    assings = {}
    for role, roleid in course.users
      for user, userid in role.list
        if user.data
          for day, components of user.data
            for component, eventnames of components
              for eventname, eventcontexts of eventnames
                for eventcontext, descriptions of eventcontexts
                  for description, hours of descriptions
                    page = eventcontext
                    if /^http/.test(page)
                      page = description
                    if /^assign/.test(eventname) || /^assign/.test(page.toLowerCase())
                      unless data[roleid]
                        data[roleid] =
                          data: []
                          events: {}
                      unless data[roleid].events[eventname]
                        data[roleid].events[eventname] = 0
                      data[roleid].events[eventname]++
                      data[roleid].data.push(
                        user: user.name
                        page: page
                        event: eventname
                        context: eventcontext
                        description: description
                        component: component
                      )
    data

  getLogs: ->
    course = @getCourse()
    unless course.logs && Object.keys(course.logs).length
      return
    days = Object.keys(course.logs).sort((a, b) ->
      a = parseInt(a)
      b = parseInt(b)
      if a > b
        return -1
      if a < b
        return 1
      return 0
    )
    logs = []
    for day in days
      logs = logs.concat(course.logs[day])
    logs

  getCourseData: ->
    unless @hasData()
      return
    @getCourse()

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

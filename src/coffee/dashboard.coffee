###
# dashboard: moodle list
###

class Dashboard
  constructor: () ->
    @load()
    .onMessage()
    console.log('Dashboard:', @)

  sync: ({url, lang}) ->
    time_access = 1000 * 60 * 5 #5m
    unless @contains(url)
      @list.push(new Moodle(
        url: url
        lang: lang
      ).syncTitle(=> @save()))
    moodle = @getMoodle(url)
    if (Date.now() - moodle.getLastAccess()) > time_access
      moodle.sync((status, scope) =>
        if status == Moodle.response().success
          @getMoodles()
          @save()
        else if !moodle.hasUsers()
          @notification(url, 'error', status)
          console.log('[' + url + ']', scope + ':', status)
      )
    @

  syncData: (message) ->
    time_sync = 1000 * 60 * 60 * 1 #1h
    progress =
      success: 0
      error: 0
      total: 0
    moodle = @getMoodle(message.moodle)
    moodle.setCourse(message.course)
    moodle.syncDates((status, scope, total) =>
      message.cmd = 'responseSync'
      message.error = status != Moodle.response().success
      message.status = status
      message.silent = moodle.hasData() && (
        Date.now() - moodle.getLastSync() <= time_sync
      )
      if scope == Moodle.response().sync_dates
        unless message.error
          progress.total = total
      else
        if message.error
          progress.error++
        else
          progress.success++
        if progress.success + progress.error == progress.total
          if !message.error && !progress.error
            moodle.upLastSync()
          moodle.setDefaultLang()
          message.users = moodle.getUsersNotFound()
      message.progress = progress
      @sendMessage(message)
      @save()
      unless status == Moodle.response().success
        console.log('[' + message.moodle + ']', scope + ': ', status)
    )
    @

  select: (url) ->
    for moodle in @list
      moodle.select(url)
    @

  getMoodles: (message = {}) ->
    if message.moodle
      @select(message.moodle)
    message.cmd = 'responseMoodles'
    message.list = []
    for moodle in @list
      if moodle.hasUsers()
        message.list.push(
          title: moodle.getTitle()
          url: moodle.getURL()
          selected: moodle.isSelected()
          access: moodle.getLastAccess()
        )
    message.list.sort((a, b) -> b.access - a.access);
    @sendMessage(message)
    @

  getCourses: (message) ->
    moodle = @getMoodle(message.moodle)
    message.cmd = 'responseCourses'
    message.courses = moodle.getCourseList()
    @sendMessage(message)
    @

  getUsers: (message) ->
    moodle = @getMoodle(message.moodle)
    moodle.setCourse(message.course)
    message.cmd = 'responseUsers'
    message.roles = moodle.getUsers()
    @sendMessage(message)
    @

  setUser: (message) ->
    moodle = @getMoodle(message.moodle).setCourse(message.course)
    switch message.action
      when 'select-all'
        moodle.setUsersAll(message.role)
      when 'select-invert'
        moodle.setUsersInvert(message.role)
      else
        moodle.setUser(message.role, message.user, message.selected)
    @

  getDates: (message) ->
    moodle = @getMoodle(message.moodle)
    moodle.setCourse(message.course)
    message.cmd = 'responseDates'
    if moodle.hasDates()
      message.dates = moodle.getDates()
    @sendMessage(message)
    @

  setDates: (message) ->
    moodle = @getMoodle(message.moodle)
    moodle.setCourse(message.course)
    if moodle.hasDates()
      moodle.setDates(message.dates)
    @

  getData: (message) ->
    moodle = @getMoodle(message.moodle)
    moodle.setCourse(message.course)
    message.cmd = 'responseData'
    message.error = !moodle.hasData()
    unless message.error
      role = message.role
      message.data = moodle.getData(role)
    @sendMessage(message)
    @

  getSelected: ->
    for moodle in @list
      if moodle.isSelected()
        return moodle

  getMoodle: (url) ->
    for moodle in @list
      if moodle.equals(url)
        return moodle

  contains: (url) ->
    for moodle in @list
      if moodle.equals(url)
        return true
    return false

  toString: ->
    JSON.stringify(@list)

  parse: (str) ->
    for e in JSON.parse(str)
      new Moodle(e)

  load: ->
    chrome.storage.local.get(list: '[]', (items) =>
      @list = @parse(items.list)
    )
    @

  save: ->
    chrome.storage.local.set(list: @toString())
    @

  notification: (url, type, code) ->
    chrome.tabs.query(
      url: url + '/*'
      (tabs) ->
        if tabs && tabs.length && tabs[0].id
          chrome.tabs.sendMessage(tabs[0].id,
            cmd: 'notification'
            type: type
            code: code
          )
    )
    @

  sendMessage: (message) ->
    message.client = true
    chrome.runtime.sendMessage(message)
    @

  onMessage: ->
    chrome.runtime.onMessage.addListener((request) =>
      unless request.client
        commands = [
          'sync',
          'getMoodles',
          'getCourses',
          'getUsers',
          'setUser',
          'getDates',
          'setDates',
          'getData',
          'syncData'
        ]
        if commands.indexOf(request.cmd) >= 0
          @[request.cmd](request)
          @save()
        else
          console.log('message:', request)
    )
    @

new Dashboard()

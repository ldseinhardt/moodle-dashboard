###
# dashboard: moodle collection
###

class Dashboard
  constructor: () ->
    @load(=>
      @onMessage()
      console.log('Dashboard:', @)
    )

  sync: ({url, lang}) ->
    if !@contains(url) && @settings.search_moodle
      @list.push(new Moodle(
        url: url
        lang: lang
      ).syncTitle(=> @save()))
    moodle = @getMoodle(url)
    sync = moodle && @settings.sync_metadata
    time = @settings.sync_metadata_interval
    if sync && (Date.now() - moodle.getLastAccess()) > (1000 * 60 * time)
      moodle.sync((status, scope) =>
        if status == Moodle.response().success
          @getMoodles()
          @save()
        else if !moodle.hasUsers() && @settings.message_error_sync_moodle
          @notification(url, 'error', status)
          console.log('[' + url + ']', scope + ':', status)
      )
    @

  syncData: (message) ->
    if @settings.sync_logs
      time = 1000 * 60 * 60 * @settings.sync_logs_interval
      progress =
        success: 0
        error: 0
        total: 0
      moodle = @getMoodle(message.moodle)
      moodle.setCourse(message.course)
      moodle.syncDates((status, scope, total) =>
        message.cmd = 'responseSync'
        message.error = status != Moodle.response().success
        message.showError = @settings.message_error_sync_dashboard
        message.status = status
        message.silent = moodle.hasData() && (
          Date.now() - moodle.getLastSync() <= time
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
            if @settings.message_alert_users_not_found
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
    message.list.sort((a, b) -> b.access - a.access)
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
      message.data = moodle
        .getData(role, @settings.filters)
      message.filters =
        list: moodle.getActivities(role)
        filtrated: @settings.filters
    @sendMessage(message)
    @

  getHelp: (message) ->
    message.cmd = 'responseHelp'
    message.help = @help.langs
    @sendMessage(message)
    @

  getQuestions: (message) ->
    message.cmd = 'responseQuestions'
    message.questions = @questions.langs
    @sendMessage(message)
    @

  getVersion: (message) ->
    message_version = @clone(message)
    message_version.cmd = 'responseVersion'
    message_version.version = @settings.version
    @sendMessage(message_version)
    .checkUpdate((data) =>
      if data.client
        message_update = @clone(message)
        message_update.cmd = 'responseUpdate'
        message_update.url = data.client.url
        message_update.version = data.client.version
        message_update.description = data.client.description
        message_update.show = (
          @settings.message_update && @settings.newVersion != data.client.version
        )
        @settings.newVersion = data.client.version
        @sendMessage(message_update)
      if data.help
        @getHelp(@clone(message))
      if data.questions
        @getQuestions(@clone(message))
    )
    @

  checkUpdate: (response) ->
    $.getJSON(@settings.server, {
      request: JSON.stringify(
        command: 'update'
        client: @settings.version
        help: @help.version
        questions: @questions.version
      )
    }, (data) =>
      if data
        if data.help
          @help = data.help
        if data.questions
          @questions = data.questions
        response?(data)
    )
    @

  support: (message) ->
    moodle = @getMoodle(message.moodle)
    message.cmd = 'responseSupport'
    $.post(@settings.server, {
      request: JSON.stringify(
        command: 'message'
        name: message.name
        email: message.email
        subject: message.subject
        message: message.message
        moodle:
          title: moodle.getTitle()
          url: moodle.getURL()
      )
    }, =>
      message.status = true
      @sendMessage(message)
    ).fail(=>
      message.status = false
      @sendMessage(message)
    )
    @

  analytics: (message) ->
    moodle = @getMoodle(message.moodle)
    if moodle && @settings.analytics
      $.post(@settings.server, {
        request: JSON.stringify(
          command: 'analytics'
          open: new Date(message.open).toISOString()[..18].replace(/T/, ' ')
          close: new Date(message.close).toISOString()[..18].replace(/T/, ' ')
          zone: new Date().getTimezoneOffset()
          moodle:
            title: moodle.getTitle()
            url: moodle.getURL()
        )
      })
    @

  getConfig: (message) ->
    message.cmd = 'responseConfig'
    message.settings = @settings
    @sendMessage(message)
    @

  setConfig: (message) ->
    if message.settings.filters
      index = @settings.filters.indexOf(message.settings.filters.key)
      if message.settings.filters.value && index >= 0
        @settings.filters.splice(index, 1)
      else if index < 0
        @settings.filters.push(message.settings.filters.key)
    settings = [
      'search_moodle',
      'sync_metadata',
      'sync_metadata_interval',
      'sync_logs',
      'sync_logs_interval',
      'message_error_sync_moodle',
      'message_error_sync_dashboard',
      'message_alert_users_not_found',
      'analytics',
      'message_update'
    ]
    for setting in settings
      if message.settings.hasOwnProperty(setting)
        @settings[setting] = set[setting]
    if message.settings.language
      chrome.storage.local.set(language: message.settings.language)
    @

  defaultConfig: (message) ->
    $.getJSON(chrome.extension.getURL('settings.json'), (@settings) => @)
    @

  deleteMoodle: (message) ->
    index = -1
    for moodle, i in @list
      if moodle.equals(message.moodle)
        index = i
    if index >= 0
      @list.splice(index, 1)
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
    JSON.stringify(@)

  parse: (str) ->
    for key, value of JSON.parse(str)
      @[key] = value
    @list = ((list) ->
      new Moodle(e) for e in list
    )(@list)
    @

  clone: (obj) ->
    JSON.parse(JSON.stringify(obj))

  load: (onload) ->
    @list = []
    $.when(
      $.getJSON(chrome.extension.getURL('help.json')),
      $.getJSON(chrome.extension.getURL('questions.json')),
      $.getJSON(chrome.extension.getURL('settings.json'))
    ).done((helpArgs, questionsArgs, settingsArgs) =>
      @help = helpArgs[0]
      @questions = questionsArgs[0]
      @settings = settingsArgs[0]
      chrome.storage.local.get(data: @toString(), (items) =>
        @parse(items.data)
        @settings.version = settingsArgs[0].version
        @settings.server = settingsArgs[0].server
        onload?()
      )
    )
    @

  save: ->
    chrome.storage.local.set(data: @toString())
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
          'syncData',
          'support',
          'analytics',
          'getHelp',
          'getQuestions',
          'getVersion',
          'getConfig',
          'setConfig',
          'deleteMoodle',
          'defaultConfig'
        ]
        if commands.indexOf(request.cmd) >= 0
          @[request.cmd](request)
          @save()
        else
          console.log('message:', request)
    )
    @

new Dashboard()

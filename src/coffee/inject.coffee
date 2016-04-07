###
# inject: detect moodle
###

class Inject
  constructor: ->
    if @isMoodle()
      @showButton()
      .onMessage()
      .sendNotify()

  isMoodle: ->
    if /^http/.test(location.protocol)
      keywords = $('meta[name="keywords"]').attr('content')
      if keywords && /^moodle/.test(keywords)
        root = /"wwwroot":"([^"]*)/.exec($('head').html())
        if root && root.length > 1 && root[1]
          @url = root[1].replace(/\\(.)/g, '$1')
    @url

  getLang: ->
    $('html').attr('lang').replace('-', '_')

  showButton: ->
    title = __('Access dashboard')
    link  = chrome.extension.getURL('main.html')
    link += '?moodle=' + @url
    html  = '<span class="moodle-dashboard">'
    html += '<div class="button">'
    html += '<a href="' + link + '" target="_blank" title="' + title + '">'
    html += '<img src="' + chrome.extension.getURL('icon.png') + '">'
    html += '</a>'
    html += '</div>'
    html += '<span class="message">'
    html += '<span class="update"></span>'
    html += '<div class="error"></div>'
    html += '</span>'
    html += '</span>'
    $('body').append(html)
    $('.moodle-dashboard .message > *').click(-> $(@).fadeOut())
    @

  onMessage: ->
    chrome.runtime.onMessage.addListener((request) ->
      if request.cmd == 'notification'
        $('.moodle-dashboard img').addClass('tada')
        message = $('.moodle-dashboard .message')
        switch request.type
          when 'error'
            func = -> $('.error', message).fadeIn().html(__(request.data))
          when 'update'
            func = ->
              update = $('.update', message)
              data = request.data
              update.fadeIn().html(__('Version') + ' ' + data.version + ' ' + __('available', true) + '.')
              update.click(-> open(data.url))
        setTimeout(func, 500)
    )
    @

  sendNotify: ->
    chrome.runtime.sendMessage(
      cmd: 'sync'
      url: @url
      lang: @getLang()
    )

@start = -> new Inject()

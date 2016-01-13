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
    html += '<span class="message"></span>'
    html += '</span>'
    $('body').append(html)
    $('.moodle-dashboard')
      .on('mouseover', -> $(@).animate(opacity: 1.0, 1))
      .on('mouseout', -> $(@).animate(opacity: 0.7, 1))
    $('.moodle-dashboard .message')
      .on('click', -> $(@).fadeOut().html(''))
    @

  onMessage: ->
    chrome.runtime.onMessage.addListener((request) ->
      if request.cmd == 'notification'
        $('.moodle-dashboard img').addClass('tada')
        setTimeout(
          -> $('.moodle-dashboard .message').fadeIn().html(__(request.code)),
          500
        )
    )
    @

  sendNotify: ->
    chrome.runtime.sendMessage(
      cmd: 'sync'
      url: @url
      lang: @getLang()
    )

@start = -> new Inject()

###
# i18n: internationalization
###

@__ = (msg) ->
  key = msg.toLowerCase().replace(/[\(\)]/g, '').replace(/[\s\-\(\)]/g, '_')
  text = chrome.i18n.getMessage(key)
  unless text
    text = if (@lang && @lang[key]) then @lang[key].message else msg
  text.replace(/\n/g, '<br>')

$.getJSON(chrome.extension.getURL('_locales/' + __('lang') + '.json'))
  .done((lang) =>
    @lang = lang
    $('*').each((i, e) ->
      list = $(e).attr('class')?.trim().replace(/\s+/g,' ')
      if list && list.length && list.split
        for classname in list.split(/\s/)
          msg = /^__MSG_([^$]*)/.exec(classname)
          if msg && msg.length > 1 && msg[1]
            key = msg[1].replace(/__/g, '').replace(/_/g, ' ')
            key = key.charAt(0).toUpperCase() + key[1..]
            $(e).html(__(key))
        @
    )
    start()
  )

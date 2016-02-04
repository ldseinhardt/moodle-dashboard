@__ = (msg) ->
  key = msg.toLowerCase().replace(/[\(\)]/g, '').replace(/[\s\-\(\)]/g, '_')
  text = chrome.i18n.getMessage(key)
  unless text
    text = (@lang && @lang[key] && @lang[key].message) || msg
  text.replace(/\n/g, '<br>')

$.getJSON(chrome.extension.getURL('_locales/' + __('lang') + '.json'))
  .done((@lang) => start())

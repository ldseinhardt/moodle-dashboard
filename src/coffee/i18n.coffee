@__ = (msg) ->
  key = msg.toLowerCase().replace(/[\(\)]/g, '').replace(/[\s\-\(\)]/g, '_')
  text = chrome.i18n.getMessage(key)
  unless text
    text = (@lang && @lang[key] && @lang[key].message) || msg
  text.replace(/\n/g, '<br>')

chrome.storage.local.get(language: __('lang'), (items) =>
  @langId = items.language
  $.getJSON(
    chrome.extension.getURL('_locales/' + items.language + '.json'),
    (@lang) => start()
  )
)

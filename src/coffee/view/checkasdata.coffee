###
# check as data
###

class CheckAsData extends ViewBase
  init: (@course, @role, @filters) ->
    super(@course, @role, @filters)
    @views = 0
    @

  selected: (row) ->
    if @filter(row.event, row.page)
      return @
    if /view/.test(row.event.name)
      @views += row.size
    @

  render: ->
    unless @views
      $('#' + @group + ' > .data').hide()
      $('#' + @group + ' > .default').show()
    @

@view.register(
  new CheckAsData('checkasdata', 'general'),
  new CheckAsData('checkasdata', 'course'),
  new CheckAsData('checkasdata', 'content'),
  new CheckAsData('checkasdata', 'assign'),
  new CheckAsData('checkasdata', 'forum'),
  new CheckAsData('checkasdata', 'chat'),
  new CheckAsData('checkasdata', 'choice'),
  new CheckAsData('checkasdata', 'quiz'),
  new CheckAsData('checkasdata', 'blog'),
  new CheckAsData('checkasdata', 'wiki')
)

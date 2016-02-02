###
# summary: summary model
###

class Summary
  constructor: (@course, @role) ->
    day = 1000 * 60 * 60 * 24
    min = @course.dates.min
    max = @course.dates.max
    users = @course.users[@role].list
    @d =
      pageViews: [0, 0]
      uniqueUsers: [
        users.length,
        users.filter((user) -> user.selected).length
      ]
      meanSession: [15.8, 10] # not implemented
    @r =
      activities: {}
      pages: {}
    @s =
      activities: {}
      pages: {}

  selected: (d) ->
    event = d.event.name + ' (' + d.event.context + ')'
    unless @s.activities[event]
      @s.activities[event] = 1
    if /view/.test(d.event.name)
      @d.pageViews[1] += d.size
      unless @s.pages[d.page]
        @s.pages[d.page] = 1

  recorded: (d) ->
    event = d.event.name + ' (' + d.event.context + ')'
    unless @r.activities[event]
      @r.activities[event] = 1
    if /view/.test(d.event.name)
      @d.pageViews[0] += d.size
      unless @r.pages[d.page]
        @r.pages[d.page] = 1

  data: ->
    @d.uniqueActivities = [
      Object.keys(@r.activities).length,
      Object.keys(@s.activities).length
    ]
    @d.uniquePages = [
      Object.keys(@r.pages).length,
      Object.keys(@s.pages).length
    ]
    @d

model.register('summary', Summary)

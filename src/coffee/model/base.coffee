###
# model: model base
###

class ModelBase
  constructor: (@name, @group = 'dashboard-content') ->
    @

  getName: ->
    @name

  getGroup: ->
    @group

  init: (@course, @role) ->
    @daytime = 1000 * 60 * 60 * 24
    @sessiontime = 60 * 90 # * 1000 -> 90min
    @min = @course.dates.min
    @max = @course.dates.max
    @users = @course.users[@role]
    @

  selected: (row) ->
    @

  recorded: (row) ->
    @

  getData: ->
    @data

@ModelBase = ModelBase

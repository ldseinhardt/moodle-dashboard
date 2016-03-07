###
# model: model collection
###

class Model
  constructor: ->
    @models = {}

  register: ->
    for model in arguments
      unless @models[model.getGroup()]
        @models[model.getGroup()] = {}
      @models[model.getGroup()][model.getName()] = model
    @

  list: (course, role) ->
    for group, models of @models
      for name, model of models
        model.init(course, role)
    @models

@model = new Model()

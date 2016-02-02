###
# model: model collection
###

class Model
  constructor: ->
    @models = {}

  register: (name, model) ->
    @models[name] = model

  list: (course, role) ->
    list = {}
    for name, data of @models
      list[name] = new data(course, role)
    list

@model = new Model()

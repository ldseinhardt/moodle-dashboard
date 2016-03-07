###
# daytime: daytime model
###

class DayTime extends ModelBase
  init: (@course, @role) ->
    @data = {}
    for i in [0..7]
      @data[i] = []
      for n in [0..23]
        @data[i].push(0)
    @

  selected: (row) ->
    day = parseInt(row.day)
    week = new Date(day).getDay() + 1
    hour = new Date(day + parseInt(row.time)).getHours()
    @data[week][hour] += row.size
    @data[0][hour] += row.size
    @

  getData: ->
    total = 0
    for size in @data[0]
      total += size
      if total > 0
        break
    unless total
      return
    @data

model.register(new DayTime('daytime', 'general'))

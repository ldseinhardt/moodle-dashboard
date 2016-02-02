###
# daytime: daytime model
###

class DayTime
  constructor: (@course, @role) ->
    @d = {}
    for i in [0..7]
      @d[i] = []
      for n in [0..23]
        @d[i].push(0)

  selected: (d) ->
    day = parseInt(d.day)
    week = new Date(day).getDay() + 1
    hour = new Date(day + parseInt(d.time)).getHours()
    @d[week][hour] += d.size
    @d[0][hour] += d.size

  data: ->
    total = 0
    for size in @d[0]
      total += size
      if total > 0
        break
    unless total
      return
    @d

model.register('daytime', DayTime)

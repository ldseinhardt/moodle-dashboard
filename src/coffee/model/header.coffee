###
# subtitle: subtitle model
###

class Header extends ModelBase
  init: (@course, @role) ->
    super(@course, @role)
    @data =
      date:
        min: new Date(@min.selected).toLocaleString().split(/\s/)[0]
        max: new Date(@max.selected).toLocaleString().split(/\s/)[0]
        value: Math.floor((@max.value - @min.value) / @daytime) + 1
        selected: Math.floor((@max.selected - @min.selected) / @daytime) + 1
      users:
        role: @users.role
        value: @users.list.length
        selected: @users.list.filter((user) -> user.selected).length
    @

model.register(new Header('header'))

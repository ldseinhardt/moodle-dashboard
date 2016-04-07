###
# header: header view
###

class Header extends ViewBase
  getData: ->
    date:
      min: new Date(@min.selected).toLocaleString().split(/\s/)[0]
      max: new Date(@max.selected).toLocaleString().split(/\s/)[0]
      value: Math.floor((@max.value - @min.value) / @daytime) + 1
      selected: Math.floor((@max.selected - @min.selected) / @daytime) + 1
    users:
      role: @role
      value: @users.length
      selected: @users.filter((user) -> user.selected).length

  template: (date, users) ->
    """
      <strong> #{__('Date range')}:</strong> #{date.min} - #{date.max} (#{date.selected} #{ __('of')} #{date.value} #{__('days', true)}), <strong> #{__('Category')}:</strong> #{users.role} (#{users.selected} #{__('of')} #{users.value} #{__('participants', true)})
    """

  render: ->
    data = @getData()
    @ctx.html(@template(data.date, data.users))
    @

@view.register(new Header('header'))

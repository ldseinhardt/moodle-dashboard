###
# header: header view
###

class Header extends ViewBase
  template: (date, users) ->
    """
      <strong> #{__('Date range')}:</strong> #{date.min} - #{date.max} (#{date.selected} #{ __('of')} #{date.value} #{__('days', true)}), <strong> #{__('Category')}:</strong> #{users.role} (#{users.selected} #{__('of')} #{users.value} #{__('participants', true)})
    """

  render: (data) ->
    @ctx.html(@template(data.date, data.users))
    @

@view.register(new Header('header'))

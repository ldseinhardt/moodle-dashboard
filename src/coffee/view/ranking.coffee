###
# ranking: ranking view
###

class Ranking extends ViewBase
  constructor: (@name, @group) ->
    super(@name, @group)
    @view_index = 0
    @getValue = (v) ->
      if /\<span\sclass\=\"value\"\>/.test(v)
        v = parseInt(/\<span\sclass\=\"value\"\>(.+)\<\/span\>/.exec(v)[1])
      v
    @setValue = (v, c = '', m = '') ->
      unless /\<span\sclass\=\"value\"\>/.test(v)
        h  = '<span class="' + c + '">'
        h += '<span class="value">' + v + '</span>' + m
        h += '</span>'
        v = h
      v
    @sorter = (a, b) =>
      a = @getValue(a)
      b = @getValue(b)
      if a > b
        return 1
      if a < b
        return -1
      return 0

  template: (title, views) ->
    html = """
      <div class="col-md-12">
        <div class="panel panel-default">
          <div class="panel-heading">
            <div class="panel-title">
              <div class="title" data-toggle="tooltip" data-placement="right" data-original-title="#{__(title)}">#{__(title)}</div>
            </div>
            <div class="panel-options">
              <div class="btn-group">
                <a class="dropdown-toggle" data-target="#" data-toggle="dropdown">
                  <i class="material-icons">&#xE8F4;</i>
                </a>
                <ul class="dropdown-menu dropdown-menu-right">
    """
    for view, i in views
      actived = if @view_index == i then ' active' else ''
      html += """
                  <li>
                    <a href="#" class="btn-view#{actived}">#{__(view)}</a>
                  </li>
      """
    html += """
                </ul>
              </div>
              <i class="material-icons info" data-toggle="tooltip" data-placement="left" data-original-title="#{__('data_' + title + '_description')}">&#xE88E;</i>
            </div>
          </div>
          <div class="panel-body">
            <div class="tablebox" style="display: none">
              <table class="table table-striped table-hover"></table>
            </div>
            <div class="tablebox" style="display: none">
              <table class="table table-striped table-hover"></table>
            </div>
            <div class="tablebox" style="display: none">
              <table class="table table-striped table-hover"></table>
            </div>
          </div>
        </div>
      </div>
    """

  render: (data) ->
    @views = [
      {
        title: 'Top participants'
        values: [
          {
            label: __('Participant')
            key: 'user'
          },
          {
            label: __('Page views')
            key: 'totalViews'
            sorter: @sorter
          },
          {
            label: __('Unique activities')
            key: 'activities'
            sorter: @sorter
          },
          {
            label: __('Unique page views')
            key: 'pages'
            sorter: @sorter
          },
          {
            label: __('Days')
            key: 'dates'
            sorter: @sorter
          },
          {
            label: __('Bounce rate')
            key: 'bounceRate'
            sorter: @sorter
          }
        ]
        data: data.users
      },
      {
        title: 'Top pages'
        values: [
          {
            label: __('Page')
            key: 'page'
          },
          {
            label: __('Page views')
            key: 'totalViews'
            sorter: @sorter
          },
          {
            label: __('Participants')
            key: 'users'
            sorter: @sorter
          },
          {
            label: __('Unique activities')
            key: 'activities'
            sorter: @sorter
          },
          {
            label: __('Days')
            key: 'dates'
            sorter: @sorter
          },

          {
            label: __('Bounce rate')
            key: 'bounceRate'
            sorter: @sorter
          }
        ]
        data: data.pages
      },
      {
        title: 'Top activities'
        values: [
          {
            label: __('Activity')
            key: 'activity'
          },
          {
            label: __('Page')
            key: 'page'
          },
          {
            label: __('Page views')
            key: 'totalViews'
            sorter: @sorter
          },
          {
            label: __('Participants')
            key: 'users'
            sorter: @sorter
          },
          {
            label: __('Days')
            key: 'dates'
            sorter: @sorter
          },
          {
            label: __('Bounce rate')
            key: 'bounceRate'
            sorter: @sorter
          }
        ]
        data: data.activities
      }
    ]
    title = @views[@view_index].title
    views = []
    for view in @views
      views.push(view.title)
    @ctx.html(@template(title, views))
    $('[data-toggle=tooltip]', @ctx).tooltip()
    tables = $('.tablebox > table', @ctx)
    for view, viewId in @views
      _columns = []
      for value, i in view.values
        item =
          field: value.key
          title: value.label
          sortable: true
          halign: 'center'
          valign: 'middle'
        if viewId == 2
          item.align = if i > 1 then 'center' else 'left'
        else
          item.align = if i then 'center' else 'left'
        if value.sorter
          item.sorter = value.sorter
        _columns.push(item)
      _data = []
      for content in view.data
        item = {}
        for value in view.values
          v = content[value.key].value
          if value.key == 'page'
            v ||= __('Untitled')
          if viewId == 2 && value.key == 'activity' || value.key == 'page'
            v = v[..0].toUpperCase() + v[1..]
          item[value.key] = if viewId == 2 && value.key == 'activity' then __(v) else v
        _data.push(item)
      $(tables[viewId]).bootstrapTable(
        columns: _columns
        data: _data
        sortName: view.values[0].key
        search: true
        pagination: true
        pageList: [10, 25, 50, 100, 'ALL']
        showToggle: true
        showColumns: true
        locale: langId
        onPreBody: (data) =>
          columns = [
            {
              key: 'totalViews'
              compare: (a, b) -> a < b
              total: 0
            },
            {
              key: 'activities'
              compare: (a, b) -> a < b
              total: 0
            },
            {
              key: 'pages'
              compare: (a, b) -> a < b
              total: 0
            },
            {
              key: 'users'
              compare: (a, b) -> a < b
              total: 0
            },
            {
              key: 'dates'
              compare: (a, b) -> a < b
              total: 0
            },
            {
              key: 'bounceRate'
              compare: (a, b) -> a > b
              formatter: '%'
              total: 0
            }
          ]
          $.each(data, (i, row) =>
            for column in columns
              if row.hasOwnProperty(column.key)
                column.total += @getValue(row[column.key])
            @
          )
          for column in columns
            column.media = column.total / data.length
          $.each(data, (i, row) =>
            for column in columns
              if row.hasOwnProperty(column.key)
                column.value = @getValue(row[column.key])
                if column.compare(column.value, column.media)
                  column.classname = 'text-danger'
                else
                  column.classname = ''
                row[column.key] = @setValue(
                  row[column.key], column.classname, column.formatter
                )
            @
          )
      )
    @show()
    buttons = $('.btn-view', @ctx)
    for button, i in buttons
      $(button).click(
        ((i) =>
          =>
            @show(i)
        )(i)
      )
    @

  show: (index) ->
    @view_index = index if index?
    view = @views[@view_index]
    title = $('.title', @ctx)
    title.html(__(view.title))
    title.attr('data-original-title', __(view.title))
    description = __('data_' + view.title + '_description')
    $('.panel-options > .info', @ctx).attr('data-original-title', description)
    tableboxes = $('.tablebox', @ctx)
    unless $(tableboxes[@view_index]).is(':visible')
      tableboxes.hide()
      $(tableboxes[@view_index]).show()
    @

@view.register(new Ranking('ranking', 'general'))

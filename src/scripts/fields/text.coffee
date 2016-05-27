Formbuilder.registerField 'text',

  order: 30
  name: '填空题'
  # size: 'medium'
  # view: """
  #   <input type='text' class='rf-size-<%= rf.get(Formbuilder.options.mappings.SIZE) %>' />
  # """

  view: """
    <input type='text' class='rf-size-medium' />
  """

  edit: """
  """

  other: """
    <%= Formbuilder.templates['edit/min_max_length']() %>
  """

  addButton: """
    <span class='symbol'><span class='fa fa-font'></span></span> 填空题
  """

  defaultAttributes: (attrs) ->
    attrs[Formbuilder.options.mappings.REQUIRED] = false

    attrs

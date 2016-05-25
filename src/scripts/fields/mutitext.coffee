Formbuilder.registerField 'mutitext',

  order: 40
  name: '简答题'

  # view: """
  #   <textarea class='rf-size-<%= rf.get(Formbuilder.options.mappings.SIZE) %>' />
  # """
  view: """
    <textarea class='rf-size-medium' />
  """

  edit: """
  """

  other: """
    <%= Formbuilder.templates['edit/min_max_length']() %>
  """

  addButton: """
    <span class='symbol'>&#182;</span> 简答题
  """

  defaultAttributes: (attrs) ->
    attrs

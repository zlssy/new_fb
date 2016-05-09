Formbuilder.registerField 'mutitext',

  order: 40
  name: '简答题'

  view: """
    <textarea class='rf-size-<%= rf.get(Formbuilder.options.mappings.SIZE) %>' />
  """

  edit: """
    <%= Formbuilder.templates['edit/min_max_length']() %>
  """

  addButton: """
    <span class='symbol'>&#182;</span> 简答题
  """

  defaultAttributes: (attrs) ->
    attrs.field_options.size = 'medium'
    attrs

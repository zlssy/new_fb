Formbuilder.registerField 'section_break',

  order: 0
  name: '分割线'

  type: 'non_input'

  view: """
    <label class='section-name'><%= rf.get(Formbuilder.options.mappings.LABEL) %></label>
    <p><%= rf.get(Formbuilder.options.mappings.DESCRIPTION) %></p>
  """

  edit: """
  """

  other: """
  """

  addButton: """
    <span class='symbol'><span class='fa fa-minus'></span></span> 分割线
  """

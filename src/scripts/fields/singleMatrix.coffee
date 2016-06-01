Formbuilder.registerField 'singleMatrix',

  order: 50
  name: '单选矩阵题'

  view: """
    <table class='table table-bordered'>
      <thead>
        <tr>
          <th>&nbsp;</th>
          <% for (i in (rf.get(Formbuilder.options.mappings.COLS) || [])) { %>
          <th><%= rf.get(Formbuilder.options.mappings.COLS)[i].label%></th>
          <% } %>
        </tr>
      <tbody>
      <% for (i in (rf.get(Formbuilder.options.mappings.ROWS) || [])) { %>
      <tr>
        <td><%= rf.get(Formbuilder.options.mappings.ROWS)[i].label%></td>
        <% for (j in (rf.get(Formbuilder.options.mappings.COLS) || [])) { %>
        <td><input type='radio' /></td>
        <% } %>
      </tr>
      <% } %>
      </tbody>
    </table>    
  """

  edit: """
    <%= Formbuilder.templates['edit/matrix']({ rf: rf }) %>
  """

  other: """
  """

  addButton: """
    <span class="symbol"><span class="glyphicon glyphicon-th"></span></span> 单选矩阵题
  """

  defaultAttributes: (attrs) ->
    # @todo
    attrs.field_options.rows = [
      label: ""
    ,
      label: ""
    ]

    attrs.field_options.cols = [
      label: ""
    ,
      label: "" 
    ]

    attrs
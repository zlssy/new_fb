Formbuilder.registerField 'singlePic',

  order: 60
  name: '图片单选题'

  view: """
    <div class="pic_list">
    <% for (i in (rf.get(Formbuilder.options.mappings.OPTIONS) || [])) { %>
      <div class="col-xs-3">
        <label class='fb-option'>
          <div><img src="<%= rf.get(Formbuilder.options.mappings.OPTIONS)[i].thumb %>" /></div>
          <input type='radio' <%= rf.get(Formbuilder.options.mappings.OPTIONS)[i].checked && 'checked' %> onclick="javascript: return false;" />
          <%= rf.get(Formbuilder.options.mappings.OPTIONS)[i].label %>
        </label>
      </div>
    <% } %>
    </div>
  """

  edit: """
    <%= Formbuilder.templates['edit/pic']({ rf: rf }) %>
  """

  other: """
  """

  addButton: """
    <span class="symbol"><span class="glyphicon glyphicon-picture"></span></span> 图片单选题
  """

  defaultAttributes: (attrs) ->
    # @todo
    attrs.field_options.options = []

    attrs
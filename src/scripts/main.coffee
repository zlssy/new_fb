﻿class FormbuilderModel extends Backbone.DeepModel
  sync: -> # noop
  indexInDOM: ->
    $wrapper = $(".fb-field-wrapper").filter ( (_, el) => $(el).data('cid') == @cid  )
    $(".fb-field-wrapper").index $wrapper
  is_input: ->
    Formbuilder.inputFields[@get(Formbuilder.options.mappings.FIELD_TYPE)]?


class FormbuilderCollection extends Backbone.Collection
  initialize: ->
    @on 'add', @copyCidToModel

  model: FormbuilderModel

  comparator: (model) ->
    model.indexInDOM()

  copyCidToModel: (model) ->
    model.attributes.cid = model.cid


class ViewFieldView extends Backbone.View
  className: "fb-field-wrapper"

  events:
    'click .subtemplate-wrapper': 'focusEditView'
    'click .js-duplicate': 'duplicate'
    'click .js-clear': 'clear'

  initialize: (options) ->
    {@parentView} = options
    @listenTo @model, "change", @render
    @listenTo @model, "destroy", @remove

  render: ->
    @$el.addClass('response-field-' + @model.get(Formbuilder.options.mappings.FIELD_TYPE)).removeClass('error')
        .data('cid', @model.cid)
        .html(Formbuilder.templates["view/base#{if !@model.is_input() then '_non_input' else ''}"]({rf: @model}))

    return @

  focusEditView: ->
    @parentView.createAndShowEditView(@model)

  clear: (e) ->
    e.preventDefault()
    e.stopPropagation()

    cb = =>
      @parentView.handleFormUpdate()
      @model.destroy()

    x = Formbuilder.options.CLEAR_FIELD_CONFIRM

    switch typeof x
      when 'string'
        if confirm(x) then cb()
      when 'function'
        x(cb)
      else
        cb()

  duplicate: ->
    attrs = _.clone(@model.attributes)
    delete attrs['id']
    attrs['label'] += ' 复制项'
    @parentView.createField attrs, { position: @model.indexInDOM() + 1 }


class EditFieldView extends Backbone.View
  className: "edit-response-field"

  events:
    'click .js-add-option': 'addOption'
    'keypress .option-label-input:last': (e) ->
      key = e.keyCode or e.which
      @addOption e if key == 13
    'click .js-remove-option': 'removeOption'
    'click .js-default-updated': 'defaultUpdated'
    'input .option-label-input': 'forceRender'

  initialize: (options) ->
    {@parentView} = options
    @listenTo @model, "destroy", @remove

  render: ->
    @$el.html(Formbuilder.templates["edit/base#{if !@model.is_input() then '_non_input' else ''}"]({rf: @model}))
    rivets.bind @$el, { model: @model }
    return @

  remove: ->
    @parentView.editView = undefined
    @parentView.$el.find("[data-target=\"#addField\"]").click()
    super

  # @todo this should really be on the model, not the view
  addOption: (e) ->
    $el = $(e.currentTarget)
    i = @$el.find('.option').index($el.closest('.option'))
    options = @model.get(Formbuilder.options.mappings.OPTIONS) || []
    newOption = {label: "", checked: false}

    if i > -1
      options.splice(i + 1, 0, newOption)
    else
      options.push newOption

    @model.set Formbuilder.options.mappings.OPTIONS, options
    @model.trigger "change:#{Formbuilder.options.mappings.OPTIONS}"
    @forceRender()

  removeOption: (e) ->
    $el = $(e.currentTarget)
    index = @$el.find(".js-remove-option").index($el)
    options = @model.get Formbuilder.options.mappings.OPTIONS
    options.splice index, 1
    @model.set Formbuilder.options.mappings.OPTIONS, options
    @model.trigger "change:#{Formbuilder.options.mappings.OPTIONS}"
    @forceRender()

  defaultUpdated: (e) ->
    $el = $(e.currentTarget)

    unless @model.get(Formbuilder.options.mappings.FIELD_TYPE) == 'checkboxes' # checkboxes can have multiple options selected
      @$el.find(".js-default-updated").not($el).attr('checked', false).trigger('change')

    @forceRender()

  forceRender: ->
    @model.trigger('change')


class BuilderView extends Backbone.View
  SUBVIEWS: []

  events:
    'click .js-save-form': 'saveForm'
    'click .fb-tabs a': 'showTab'
    'click .fb-add-field-types a': 'addField'
    'mouseover .fb-add-field-types': 'lockLeftWrapper'
    'mouseout .fb-add-field-types': 'unlockLeftWrapper'
    'input #title': 'forceRender'
    'input #cnt1': 'forceRender'

  initialize: (options) ->
    {selector, @formBuilder, @bootstrapData, callback} = options

    # This is a terrible idea because it's not scoped to this view.
    if selector?
      @setElement $(selector)

    # Create the collection, and bind the appropriate events
    @collection = new FormbuilderCollection
    @collection.bind 'add', @addOne, @
    @collection.bind 'reset', @reset, @
    @collection.bind 'change', @handleFormUpdate, @
    @collection.bind 'destroy add reset', @hideShowNoResponseFields, @
    @collection.bind 'destroy', @ensureEditViewScrolled, @

    title = @bootstrapData.title
    content = @bootstrapData.content
    fields = @bootstrapData.fields
    starttime = @bootstrapData.starttime
    endtime = @bootstrapData.endtime
    @render()
    @collection.reset(fields)
    $('input[name=title]').val title
    $('textarea[name=content]').text content
    $('#start_date').val starttime
    $('#end_date').val endtime

    _.isFunction(callback) && callback(@)
    @bindSaveEvent()

  bindSaveEvent: ->
    @formSaved = false
    @saveFormButton = @$el.find(".js-save-form")
    @saveFormButton.attr('disabled', false).text(Formbuilder.options.dict.SAVE_FORM)

    unless !Formbuilder.options.AUTOSAVE
      setInterval =>
        @saveForm.call(@)
      , 5000

    $(window).bind 'beforeunload', =>
      if @formSaved then undefined else Formbuilder.options.dict.UNSAVED_CHANGES

  reset: ->
    @$responseFields.html('')
    @addAll()

  render: ->
    @$el.html Formbuilder.templates['page']()

    # Save jQuery objects for easy use
    @$fbLeft = @$el.find('.fb-left')
    @$responseFields = @$el.find('.fb-response-fields')

    @bindWindowScrollEvent()
    @hideShowNoResponseFields()

    # Render any subviews (this is an easy way of extending the Formbuilder)
    new subview({parentView: @}).render() for subview in @SUBVIEWS

    return @

  bindWindowScrollEvent: ->
    $(window).on 'scroll , resize', =>
      # return if @$fbLeft.data('locked') == true
      newMargin = Math.max(0, $(window).scrollTop() - @$el.offset().top)
      maxMargin = @$responseFields.height()

      @$fbLeft.css
        'margin-top': Math.min(maxMargin, newMargin)

  showTab: (e) ->
    $el = $(e.currentTarget)
    target = $el.data('target')
    $el.closest('li').addClass('active').siblings('li').removeClass('active')
    $(target).addClass('active').siblings('.fb-tab-pane').removeClass('active')

    @unlockLeftWrapper() unless target == '#editField'

    if target == '#editField' && !@editView && (first_model = @collection.models[0])
      @createAndShowEditView(first_model)

    if target == '#baseField'
      $('#q_edit_view').show();
      $('#q_see_view').hide();
    else
      $('#q_see_view').html('<h1>'+$('#title').val()+'</h1>\r\n<div class="desc gray">'+$('#cnt1').text()+'</div>').show();
      $('#q_edit_view').hide();

  addOne: (responseField, _, options) ->
    view = new ViewFieldView
      model: responseField
      parentView: @

    #####
    # Calculates where to place this new field.
    #
    # Are we replacing a temporarily drag placeholder?
    if options.$replaceEl?
      options.$replaceEl.replaceWith(view.render().el)

    # Are we adding to the bottom?
    else if !options.position? || options.position == -1
      @$responseFields.append view.render().el

    # Are we adding to the top?
    else if options.position == 0
      @$responseFields.prepend view.render().el

    # Are we adding below an existing field?
    else if ($replacePosition = @$responseFields.find(".fb-field-wrapper").eq(options.position))[0]
      $replacePosition.before view.render().el

    # Catch-all: add to bottom
    else
      @$responseFields.append view.render().el

  setSortable: ->
    @$responseFields.sortable('destroy') if @$responseFields.hasClass('ui-sortable')
    @$responseFields.sortable
      forcePlaceholderSize: true
      placeholder: 'sortable-placeholder'
      stop: (e, ui) =>
        if ui.item.data('field-type')
          rf = @collection.create Formbuilder.helpers.defaultFieldAttrs(ui.item.data('field-type')), {$replaceEl: ui.item}
          @createAndShowEditView(rf)

        @handleFormUpdate()
        return true
      update: (e, ui) =>
        # ensureEditViewScrolled, unless we're updating from the draggable
        @ensureEditViewScrolled() unless ui.item.data('field-type')

    @setDraggable()

  setDraggable: ->
    $addFieldButtons = @$el.find("[data-field-type]")

    $addFieldButtons.draggable
      connectToSortable: @$responseFields
      helper: =>
        $helper = $("<div class='response-field-draggable-helper' />")
        $helper.css
          width: @$responseFields.width() # hacky, won't get set without inline style
          height: '80px'

        $helper

  addAll: ->
    @collection.each @addOne, @
    @setSortable()

  hideShowNoResponseFields: ->
    @$el.find(".fb-no-response-fields")[if @collection.length > 0 then 'hide' else 'show']()

  addField: (e) ->
    field_type = $(e.currentTarget).data('field-type')
    @createField Formbuilder.helpers.defaultFieldAttrs(field_type)

  createField: (attrs, options) ->
    rf = @collection.create attrs, options
    @createAndShowEditView(rf)
    @handleFormUpdate()

  createAndShowEditView: (model) ->
    $responseFieldEl = @$el.find(".fb-field-wrapper").filter( -> $(@).data('cid') == model.cid )
    $responseFieldEl.addClass('editing').siblings('.fb-field-wrapper').removeClass('editing')

    if @editView
      if @editView.model.cid is model.cid
        @$el.find(".fb-tabs a[data-target=\"#editField\"]").click()
        @scrollLeftWrapper($responseFieldEl)
        return

      @editView.remove()

    @editView = new EditFieldView
      model: model
      parentView: @

    $newEditEl = @editView.render().$el
    @$el.find(".fb-edit-field-wrapper").html $newEditEl
    @$el.find(".fb-tabs a[data-target=\"#editField\"]").click()
    @scrollLeftWrapper($responseFieldEl)
    return @

  mode_error: (m, e)->
    $wrapper = @$el.find(".fb-field-wrapper").filter( -> $(@).data('cid') == m.cid )
    $wrapper.addClass 'error'
    $error_parent = $wrapper.find('.cover').siblings('label')
    if $error_parent.find('.errormsg').size() then $error_parent.find('.errormsg').html e else $error_parent.append '<span class="errormsg">'+e+'</span>' if e

  ensureEditViewScrolled: ->
    return unless @editView
    @scrollLeftWrapper $(".fb-field-wrapper.editing")

  scrollLeftWrapper: ($responseFieldEl) ->
    @unlockLeftWrapper()
    return unless $responseFieldEl[0]
    $.scrollWindowTo ((@$el.offset().top + $responseFieldEl.offset().top) - @$responseFields.offset().top), 200, =>
      @lockLeftWrapper()

  lockLeftWrapper: ->
    @$fbLeft.data('locked', true)

  unlockLeftWrapper: ->
    @$fbLeft.data('locked', false)

  forceRender: ->
    @collection.trigger('change')

  handleFormUpdate: ->
    return if @updatingBatch
    @formSaved = false
    @saveFormButton.removeAttr('disabled').text(Formbuilder.options.dict.SAVE_FORM)

  saveForm: (e) ->
    return if @formSaved
    title = $('input[name=title]')
    content = $('textarea[name=content').val()
    start_date = $('#start_date')
    end_date = $('#end_date')
    if title.val() == ''
      $('a[data-target="#baseField"]').trigger('click')
      show_alert '问卷标题不能为空'
      title.addClass('error').focus()
      return 0
    if start_date.val() == ''
      $('a[data-target="#baseField"]').trigger('click')
      show_alert '请填写问卷开始时间'
      start_date.focus()
      start_date.parents('.input-group').addClass('has-error')
      return 0
    if end_date.val() == ''
      $('a[data-target="#baseField"]').trigger('click')
      show_alert '请填写问卷结束时间'
      end_date.focus()
      end_date.parents('.input-group').addClass('has-error')
      return 0
    if @collection.models.length == 0
      show_alert '您一个题目都还没添加哦~'
      return 0
    check_result = check_options @collection.models
    if(check_result != true)
      @mode_error (if first then item.mod else first = item.mod), item.msg for item in check_result
      @createAndShowEditView first
      return 0
    @collection.sort()
    payload = JSON.stringify
      title: title.val()
      content: content
      starttime: start_date.val()
      endtime: end_date.val()
      fields: @collection.toJSON()

    if Formbuilder.options.HTTP_ENDPOINT then @doAjaxSave(payload)
    @formBuilder.trigger 'save', payload
    @updateFormButton 'saving'

  updateFormButton: (s)->
    if s is 'saving'
      @formSaved = true
      @saveFormButton.attr('disabled', true).text(Formbuilder.options.dict.SAVEING)
    if s is 'saved'
      @formSaved = true
      @saveFormButton.attr('disabled', true).text(Formbuilder.options.dict.ALL_CHANGES_SAVED)
    if s is 'ready'
      @formSaved = false
      @saveFormButton.attr('disabled', false).text(Formbuilder.options.dict.SAVE_FORM)

  doAjaxSave: (payload) ->
    $.ajax
      url: Formbuilder.options.HTTP_ENDPOINT
      type: Formbuilder.options.HTTP_METHOD
      data: payload
      contentType: "application/json"
      success: (data) =>
        @updatingBatch = true

        for datum in data
          # set the IDs of new response fields, returned from the server
          @collection.get(datum.cid)?.set({id: datum.id})
          @collection.trigger 'sync'

        @updatingBatch = undefined


class Formbuilder
  @helpers:
    defaultFieldAttrs: (field_type) ->
      attrs = {}
      attrs[Formbuilder.options.mappings.LABEL] = ''
      attrs[Formbuilder.options.mappings.FIELD_TYPE] = field_type
      attrs[Formbuilder.options.mappings.REQUIRED] = true
      attrs['field_options'] = {}
      Formbuilder.fields[field_type].defaultAttributes?(attrs) || attrs

    simple_format: (x) ->
      x?.replace(/\n/g, '<br />')

  @options:
    BUTTON_CLASS: 'fb-button'
    CHOICE_BUTTON: 'choice'
    HTTP_ENDPOINT: ''
    HTTP_METHOD: 'POST'
    AUTOSAVE: false
    CLEAR_FIELD_CONFIRM: false

    mappings:
      SIZE: 'field_options.size'
      UNITS: 'field_options.units'
      LABEL: 'label'
      FIELD_TYPE: 'field_type'
      REQUIRED: 'required'
      ADMIN_ONLY: 'admin_only'
      OPTIONS: 'field_options.options'
      DESCRIPTION: 'field_options.description'
      INCLUDE_OTHER: 'field_options.include_other_option'
      INCLUDE_BLANK: 'field_options.include_blank_option'
      INTEGER_ONLY: 'field_options.integer_only'
      MIN: 'field_options.min'
      MAX: 'field_options.max'
      MINLENGTH: 'field_options.minlength'
      MAXLENGTH: 'field_options.maxlength'
      LENGTH_UNITS: 'field_options.min_max_length_units'

    dict:
      ALL_CHANGES_SAVED: '问卷已保存'
      SAVEING: '正在保存...'
      SAVE_FORM: '保存'
      UNSAVED_CHANGES: '你还没有保存你的问卷，确定要离开？离开问卷数据将丢失。'

  @fields: {}
  @inputFields: {}
  @nonInputFields: {}

  @registerField: (name, opts) ->
    for x in ['view', 'edit']
      opts[x] = _.template(opts[x])

    opts.field_type = name

    Formbuilder.fields[name] = opts

    if opts.type == 'non_input'
      Formbuilder.nonInputFields[name] = opts
    else
      Formbuilder.inputFields[name] = opts

  constructor: (opts={}) ->
    _.extend @, Backbone.Events
    args = _.extend opts, {formBuilder: @}
    @mainView = new BuilderView args

window.Formbuilder = Formbuilder
show_alert = (m) ->
  if AWS then AWS.show_tips(m, 5000) else alert(m)
check_options = (opts)->
  r = []
  for opt in opts
    msg = []
    if opt.attributes.field_type isnt 'section_break'
      msg.push '标题不能为空' if opt.attributes.label == ''
    if opt.attributes.field_type is 'radio' or opt.attributes.field_type is 'checkboxes'
      has = false
      for o in opt.attributes.field_options.options
        has = true if o.label != ''
      msg.push ' 至少要填一个选项' if !has
    r.push {mod: opt, msg: '('+msg.join(' , ')+')'} if msg.length
  if r.length then r else true

if module?
  module.exports = Formbuilder
else
  window.Formbuilder = Formbuilder

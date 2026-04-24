_ = require 'underscore'
Backbone = require 'backbone'
$modelUtils = require './model.utils'
$configs = require './model.configs'
$viewUtils = require './view.utils'
$icons = require './view.icons'
$hxl = require './view.rowDetail.hxlDict'
ResizeSensor = require 'css-element-queries/src/ResizeSensor'

$viewRowDetailSkipLogic = require './view.rowDetail.SkipLogic'
$viewTemplates = require './view.templates'

module.exports = do ->
  viewRowDetail = {}

  class viewRowDetail.DetailView extends Backbone.View
    ###
    The DetailView class is a base class for details
    of each row of the XLForm. When the view is initialized,
    a mixin from "DetailViewMixins" is applied.
    ###
    className: "card__settings__fields__field  dt-view dt-view--depr"
    initialize: ({@rowView})->
      unless @model.key
        throw new Error "RowDetail does not have key"

      modelKey = @model.key
      if modelKey == 'bind::oc:itemgroup'
        modelKey = 'oc_item_group'
      else if modelKey == 'bind::oc:external'
        modelKey = 'oc_external'
      else if modelKey == 'bind::oc:briefdescription'
        modelKey = 'oc_briefdescription'
      else if modelKey == 'bind::oc:description'
        modelKey = 'oc_description'

      @modelKey = modelKey
      @extraClass = "xlf-dv-#{modelKey}"
      _.extend(@, viewRowDetail.DetailViewMixins[modelKey] || viewRowDetail.DetailViewMixins.default)
      @$el.addClass(@extraClass)

      Backbone.on('ocCustomEvent', @onOcCustomEvent, @)
      Backbone.on('ocConsentRowsEvent', @onOcConsentRowsEvent, @)

      return

    render: ()->
      rendered = @html()
      if rendered
        @$el.html rendered

      @afterRender && @afterRender()
      return @

    html: ()->
      $viewTemplates.$$render('xlfDetailView', @)

    listenForCheckboxChange: (opts={})->
      el = opts.el || @$('input[type=checkbox]').get(0)
      $el = $(el)
      changing = false
      _requiredBox = @model.key is "required"

      reflectValueInEl = ()=>
        if !changing
          val = @model.get('value')
          if val is true or val in $configs.truthyValues
            $el.prop('checked', true)
      @model.on 'change:value', reflectValueInEl
      reflectValueInEl()

      $el.on 'change', ()=>
        changing = true
        @model.set('value', $el.prop('checked'))
        if _requiredBox
          $el.parents('.card').eq(0).toggleClass('card--required', $el.prop('checked'))
        changing = false
      return

    listenForInputChange: (opts={})->
      # listens to checkboxes and input fields and ensures
      # the model's value is reflected in the element and changes
      # to the element are reflected in the model (with transformFn
      # applied)
      el = opts.el || @$('input').get(0) || @$('textarea').get(0)

      $el = $(el)
      transformFn = opts.transformFn || false
      inputType = opts.inputType
      inTransition = false

      changeModelValue = ($elVal)=>
        # preventing race condition
        if !inTransition
          inTransition = true
          @model.set('value', $elVal)
          reflectValueInEl(true)
          inTransition = false

      reflectValueInEl = (force=false)=>
        # This should never change the model value
        if force || !inTransition
          modelVal = @model.get('value')
          if inputType is 'checkbox'
            if !_.isBoolean(modelVal)
              modelVal = modelVal in $configs.truthyValues
            # triggers element change event
            $el.prop('checked', modelVal)
          else
            # triggers element change event
            $el.val(modelVal)

      reflectValueInEl()
      @model.on 'change:value', reflectValueInEl

      detectAndChangeValue = () =>
        $elVal = $el.val()
        if transformFn
          $elVal = transformFn($elVal)
        changeModelValue($elVal)

      $el.on 'change', ()=>
        detectAndChangeValue()

      $el.on 'blur', ()=>
        detectAndChangeValue()

      $el.on 'keyup', (evt) =>
        if evt.key is 'Enter' or evt.keyCode is 13
          $el.blur()
        else
          if not transformFn
            detectAndChangeValue()

      return

    _insertInDOM: (where, how) ->
      where[how || 'append'](@el)
    insertInDOM: (rowView)->
      advancedKeys = [
        'default'
        'oc_item_group'
        'calculation'
        'trigger'
        'readonly'
      ]

      rightColumnKeys = [
        'appearance'
        'oc_description'
        'oc_external'
      ]

      target = rowView.defaultRowDetailParent
      if rowView.advancedRowDetailParent? and (@modelKey in advancedKeys)
        target = rowView.advancedRowDetailParent
      else if rowView.primaryRowDetailParentRight? and (@modelKey in rightColumnKeys)
        target = rowView.primaryRowDetailParentRight

      @_insertInDOM target

    makeFieldCheckCondition: (opts={}) ->
      el = opts.el || @$('input').get(0) || @$('textarea').get(0)
      $el = $(el)
      fieldClass = opts.fieldClass || 'input-error'
      message = opts.message || "This field is required"
      checkIfNotEmpty = opts.checkIfNotEmpty || false

      showMessage =() =>
        $el.closest('div').addClass(fieldClass)
        if $el.siblings('.message').length is 0
          $message = $('<div/>').addClass('message').text(message)
          $el.after($message)

      hideMessage =() =>
        $el.closest('div').removeClass(fieldClass)
        $el.siblings('.message').remove()

      showOrHideCondition = () =>
        if checkIfNotEmpty
          if $el.val() != ''
            showMessage()
          else
            hideMessage()
        else
          if $el.val() == ''
            showMessage()
          else
            hideMessage()

      $el.on 'blur', ->
        showOrHideCondition()

      $el.on 'keyup', ->
        showOrHideCondition()

      showOrHideCondition()

      return

    removeFieldCheckCondition: (opts={}) ->
      el = opts.el || @$('input').get(0) || @$('textarea').get(0)
      $el = $(el)
      fieldClass = opts.fieldClass || 'input-error'

      $el.off 'blur'
      $el.off 'keyup'
      $el.closest('div').removeClass(fieldClass)
      $el.siblings('.message').remove()

      return

    makeRequired: (opts={}) ->
      @makeFieldCheckCondition()

    removeRequired: (opts={}) ->
      @removeFieldCheckCondition()


  viewRowDetail.Templates = {
    textbox: (cid, key, key_label = key, input_class = '', placeholder_text='', max_length = '') ->
      # if placeholder_text is not ''
      #   placeholder_text = t(placeholder_text)
      if max_length is ''
        @field """<input type="text" name="#{key}" id="#{cid}" class="#{input_class}" placeholder="#{placeholder_text}" />""", cid, key_label
      else
        @field """<input type="text" name="#{key}" id="#{cid}" class="#{input_class}" placeholder="#{placeholder_text}" maxlength="#{max_length}" />""", cid, key_label

    textarea: (cid, key, key_label = key, input_class = '', placeholder_text='', max_length = '') ->
      # if placeholder_text is not ''
      #   placeholder_text = t(placeholder_text)
      if max_length is ''
        @field """<textarea name="#{key}" id="#{cid}" class="#{input_class}" placeholder="#{placeholder_text}" />""", cid, key_label
      else
        @field """<textarea name="#{key}" id="#{cid}" class="#{input_class}" placeholder="#{placeholder_text}" maxlength="#{max_length}" />""", cid, key_label

    checkbox: (cid, key, key_label = key, input_label = t("Yes")) ->
      input_label = input_label
      @field """<input type="checkbox" name="#{key}" id="#{cid}"/> <label for="#{cid}">#{input_label}</label>""", cid, key_label

    radioButton: (cid, key, options, key_label = key, default_value = '') ->
      buttons = ""
      for option in options
        buttons += """<input type="radio" name="#{key}" id="option_#{option.label}" value="#{option.value}">"""
        buttons += """<label id="label_#{option.label}" for="#{option.label}">#{option.label}</label>"""

      @field buttons, cid, key_label

    dropdown: (cid, key, values, key_label = key) ->
      select = """<select name="#{key}" id="#{cid}">"""

      for value in values
        if typeof value == 'object'
          select += """<option value="#{value.value}">#{value.text}</option>"""
        else
          select += """<option value="#{value}">#{value}</option>"""

      select += "</select>"

      @field select, cid, key_label

    hxlTags: (cid, key, key_label = key, value = '', hxlTag = '', hxlAttrs = '') ->
      tags = """<input type="text" name="#{key}" id="#{cid}" class="hxlValue hidden" value="#{value}"  />"""
      tags += """ <div class="settings__hxl"><input id="#{cid}-tag" class="hxlTag" value="#{hxlTag}" type="hidden" />"""
      tags += """ <input id="#{cid}-attrs" class="hxlAttrs" value="#{hxlAttrs}" type="hidden" /></div>"""

      @field tags, cid, key_label

    field: (input, cid, key_label) ->
      """
      <div class="card__settings__fields__field">
        <label for="#{cid}">#{key_label}:</label>
        <span class="settings__input">
          #{input}
        </span>
      </div>
      """
  }

  viewRowDetail.DetailViewMixins = {}

  viewRowDetail.DetailViewMixins.type =
    html: -> false
    insertInDOM: (rowView)->
      typeStr = @model.get("typeId")
      if !(@model._parent.constructor.kls is "Group")
        iconClassName = $icons.get(typeStr)?.get("iconClassName")
        iconLabel = $icons.get(typeStr)?.get("label")
        if !iconClassName
          console?.error("could not find icon for type: #{typeStr}")
          iconClassName = "k-icon k-icon-alert"
        rowView.$el.find(".card__header-icon").addClass('k-icon').addClass(iconClassName)
        rowView.$el.find(".card__indicator__icon").attr("data-tip", "#{iconLabel}")
      return


  viewRowDetail.DetailViewMixins.label =
    html: -> false
    insertInDOM: (rowView)->
      cht = rowView.$label
      cht.value = @model.get('value')
      return @
    afterRender: ->
      @listenForInputChange({
        el: this.rowView.$label,
        transformFn: (value) ->
          value = value.replace(new RegExp(String.fromCharCode(160), 'g'), '')
          value = value.replace /\t/g, ' '
          return value
      })

      $textarea = $(this.rowView.$label)

      if $textarea.closest('.card__text').length == 0
        return

      $textarea.css("min-height", 20)

      resizableOpts = {
        containment: "parent",
        handles: "s",
        minHeight: 27
      }
      if @model.get("value")?
        setTimeout =>
          maxLine = 3
          textareaScrollHeight = $textarea.prop('scrollHeight')
          textAreaLineHeight = parseInt($textarea.css('line-height'))
          textAreaSetHeight = Math.min(textareaScrollHeight, (textAreaLineHeight * maxLine)) + 7
          $textarea.css("height", "")
          $textarea.css("height", textAreaSetHeight)
          $textarea.resizable(resizableOpts)
        , 1
      else
        $textarea.resizable(resizableOpts)

      targetNode = $textarea.closest('.card__text')[0]
      new ResizeSensor(targetNode, =>
        card_text_width = targetNode.clientWidth
        $textarea.width(card_text_width)
        $textarea.siblings('.ui-resizable-s').width(card_text_width)
        $textarea.closest('.ui-wrapper').width(card_text_width)
      )

      return

  viewRowDetail.DetailViewMixins.hint =
    html: -> false
    insertInDOM: (rowView) ->
      hintEl = rowView.$hint
      hintEl.value = @model.get("value")
      return @
    afterRender: ->
      @listenForInputChange({
        el: this.rowView.$hint
      })
      return

  viewRowDetail.DetailViewMixins.guidance_hint =
    html: ->
      @$el.addClass("card__settings__fields--active")
      viewRowDetail.Templates.textbox @cid, @model.key, t("Guidance hint"), 'text'
    afterRender: ->
      @listenForInputChange()

  viewRowDetail.DetailViewMixins.constraint_message =
    html: ->
      @$el.addClass("card__settings__fields--active")
      viewRowDetail.Templates.textbox @cid, @model.key, t("Constraint Message"), 'text'
    insertInDOM: (rowView)->
      @_insertInDOM rowView.cardSettingsWrap.find('.js-card-settings-validation-criteria').eq(0)
    afterRender: ->
      @listenForInputChange()

  # parameters are handled per case
  viewRowDetail.DetailViewMixins.parameters =
    html: -> false
    insertInDOM: (rowView)-> return

  # body::accept is handled in custom view
  viewRowDetail.DetailViewMixins['body::accept'] =
    html: -> false
    insertInDOM: (rowView)-> return

  viewRowDetail.DetailViewMixins.relevant =
    html: ->
      @$el.addClass("card__settings__fields--active")
      """
      <div class="card__settings__fields__field relevant__editor">
      </div>
      """

    afterRender: ->
      @$el.find(".relevant__editor").html("""
        <div class="skiplogic__main"></div>
        <p class="skiplogic__extras">
        </p>
      """)

      @target_element = @$('.skiplogic__main')

      @model.facade.render @target_element

    insertInDOM: (rowView) ->
      @_insertInDOM rowView.cardSettingsWrap.find('.js-card-settings-skip-logic').eq(0)

  viewRowDetail.DetailViewMixins.constraint =
    html: ->
      @$el.addClass("card__settings__fields--active")
      """
      <div class="card__settings__fields__field constraint__editor">
      </div>
      """
    afterRender: ->
      @$el.find(".constraint__editor").html("""
        <div class="skiplogic__main"></div>
        <p class="skiplogic__extras">
        </p>
      """)

      @target_element = @$('.skiplogic__main')

      @model.facade.render @target_element

    insertInDOM: (rowView) ->
      @_insertInDOM rowView.cardSettingsWrap.find('.js-card-settings-validation-criteria')

  viewRowDetail.DetailViewMixins.name =
    isInGroup: ->
      @model._parent.constructor.key == 'group'
    changeHeaderName: ->
      @$el.closest('.survey__row__item').find('.card__header-name').html(@model.getValue())
    html: ->
      @fieldMaxLength = 36
      @fieldTab = "active"
      @$el.addClass("card__settings__fields--#{@fieldTab}")
      @model.set 'value', (@model.deduplicate @model.getSurvey(), @model.getSurvey().rowItemNameMaxLength)
      rowItemNameMaxLength = @model.getSurvey().rowItemNameMaxLength
      model_value = @model.get 'value'
      if (@model.get('value').length > rowItemNameMaxLength) and (model_value.charAt(model_value.length - 4) != '_')
        @model.set 'value', @model.get('value').slice(0, rowItemNameMaxLength)
      if @isInGroup()
        viewRowDetail.Templates.textbox @cid, @model.key, t("Layout Group Name"), 'text', 'Enter layout group name'
      else
        viewRowDetail.Templates.textbox @cid, @model.key, t("Item Name"), 'text', 'Enter variable name', '40'
    afterRender: ->
      @listenForInputChange(transformFn: (value)=>
        value_chars = value.split('')
        if !/[\w_]/.test(value_chars[0])
          value_chars.unshift('_')

        @model.set 'value', value
        @model.deduplicate @model.getSurvey(), @model.getSurvey().rowItemNameMaxLength
      )
      @model.on 'change:value', () =>
        @changeHeaderName()

      update_view = () => @$el.find('input').eq(0).val(@model.get("value") || '')
      update_view()

      setTimeout =>
        @changeHeaderName() if !@isInGroup()
      , 1

      if @model._parent.get('label')?
        @model._parent.get('label').on 'change:value', update_view
      @makeRequired()
  # insertInDom: (rowView)->
    #   # default behavior...
    #   rowView.defaultRowDetailParent.append(@el)

  viewRowDetail.DetailViewMixins.tags =
    html: ->
      @fieldTab = "active"
      @$el.addClass("card__settings__fields--#{@fieldTab}")
      label = t("HXL")
      if (@model.get("value"))
        tags = @model.get("value")
        hxlTag = ''
        hxlAttrs = []
        hxlAttrsString = ''

        if _.isArray(tags)
          _.map(tags, (_t, i)->
            if (_t.indexOf('hxl:') > -1)
              _t = _t.replace('hxl:','')
              if (_t.indexOf('#') > -1)
                hxlTag = _t
              if (_t.indexOf('+') > -1)
                _t = _t.replace('+','')
                hxlAttrs.push(_t)
          )

        if _.isArray(hxlAttrs)
          hxlAttrsString = hxlAttrs.join(',')

        viewRowDetail.Templates.hxlTags @cid, @model.key, label, @model.get("value"), hxlTag, hxlAttrsString
      else
        viewRowDetail.Templates.hxlTags @cid, @model.key, label
    afterRender: ->
      @$el.find('input.hxlTag').select2({
          tags:$hxl.dict,
          maximumSelectionSize: 1,
          placeholder: t("#tag"),
          tokenSeparators: ['+',',', ':'],
          formatSelectionTooBig: t("Only one HXL tag allowed per question. ")
          createSearchChoice: @_hxlTagCleanup
        })
      @$el.find('input.hxlAttrs').select2({
          tags:[],
          tokenSeparators: ['+',',', ':'],
          formatNoMatches: t("Type attributes for this tag"),
          placeholder: t("Attributes"),
          createSearchChoice: @_hxlAttrCleanup
          allowClear: 1
        })

      @$el.find('input.hxlTag').on 'change', () => @_hxlUpdate()
      @$el.find('input.hxlAttrs').on 'change', () => @_hxlUpdate()

      @$el.find('input.hxlTag').on 'select2-selecting', (e) => @_hxlTagSelecting(e)
      @$el.find('.hxlTag input.select2-input').on 'keyup', (e) => @_hxlTagSanitize(e)

      @listenForInputChange({el: @$el.find('input.hxlValue').eq(0)})

    _hxlUpdate: (e)->
      tag = @$el.find('input.hxlTag').val()

      attrs = @$el.find('input.hxlAttrs').val()
      attrs = attrs.replace(/,/g, '+')
      hxlArray = [];

      if (tag)
        @$el.find('input.hxlAttrs').select2('enable', true)
        hxlArray.push('hxl:' + tag)
        if (attrs)
          aA = attrs.split('+')
          _.map(aA, (_a)->
            hxlArray.push('hxl:+' + _a)
          )
      else
        @$el.find('input.hxlAttrs').select2('enable', false)

      @model.set('value', hxlArray)
      @model.trigger('change')

    _hxlTagCleanup: (term)->
      if term.length >= 2
        regex = /\W+/g
        term = "#" + term.replace(regex, '').toLowerCase()
        return {id: term, text: term}

    _hxlTagSanitize: (e)->
      if e.target.value.length >= 2
        regex = /\W+/g
        e.target.value = "#" + e.target.value.replace(regex, '')

    _hxlTagSelecting: (e)->
      if e.val.length < 2
        e.preventDefault()

    _hxlAttrCleanup: (term)->
      regex = /\W+/g
      term = term.replace(regex, '').toLowerCase()
      return {id: term, text: term}

  viewRowDetail.DetailViewMixins.default =
    html: ->
      @fieldTab = "active"
      @$el.addClass("card__settings__fields--#{@fieldTab}")
      label = if @model.key == 'default' then t("Default value") else @model.key.replace(/_/g, ' ')
      viewRowDetail.Templates.textarea @cid, @model.key, label, 'text', t('Enter Text')
    changeModelValue: () ->
      $textarea = $(@$('textarea').get(0))
      $elVal = $textarea.val().replace(/\n/g, "")
      @model.set('value', $elVal)
    afterRender: ->
      $textarea = $(@$('textarea').get(0))
      $textarea.val(@model.get("value"))
      if @model.get("value")?
        setTimeout =>
          textareaScrollHeight = $textarea.prop('scrollHeight')
          $textarea.css("height", "")
          $textarea.css("height", textareaScrollHeight)
        , 1
      $textarea.on 'blur', () =>
        @changeModelValue()
      $textarea.on 'change', () =>
        @changeModelValue()
      $textarea.on 'keyup', () =>
        @changeModelValue()
      $textarea.on 'keypress', (evt) =>
        if evt.key is 'Enter' or evt.keyCode is 13
          evt.preventDefault()
          $textarea.blur()

  viewRowDetail.DetailViewMixins._isRepeat =
    onOcCustomEvent: (ocCustomEventArgs) ->
      questionId = @model._parent.cid
      sender = ocCustomEventArgs.sender
      senderValue = ocCustomEventArgs.value
      senderQuestionId = sender._parent.cid
      if (sender.key is 'repeat_count') and (questionId is senderQuestionId)
        @$repeat_count.val(senderValue)
    html: ->
      @$label_repeat_count = $('<span/>', { style: 'display: block; margin-top: 10px;' }).text(t('Automatic Repeat Count') + ":")
      @$repeat_count = $('<input/>', { style: 'margin-top: 10px; width:85%;' }).attr('placeholder', t('(leave blank to allow users to add and remove repeats)'))
      @$el.addClass("card__settings__fields--active")
      viewRowDetail.Templates.checkbox @cid, @model.key, t("Repeat"), t("Repeat this group if necessary")
    afterRender: ->
      @$('.settings__input').append(@$label_repeat_count)
      @$('.settings__input').append(@$repeat_count)
      @$repeat_count.attr('disabled', true)

      if @model.getValue()?
        @$repeat_count.attr('disabled', @model.getValue() == false)

      changeRepeatCountValue: ->
        Backbone.trigger('ocCustomEvent', { sender: @model, value: @$repeat_count.val() })

      @model.on 'change:value', () =>
        @$repeat_count.attr('disabled', @model.getValue() == false)
        if @model.getValue() == false
          @$repeat_count.val('')
          @changeRepeatCountValue()

      @$repeat_count.on 'blur', () =>
        @changeRepeatCountValue()
      @$repeat_count.on 'change', () =>
        @changeRepeatCountValue()
      @$repeat_count.on 'keyup', () =>
        @changeRepeatCountValue()
      @$repeat_count.on 'keypress', (evt) =>
        if evt.key is 'Enter' or evt.keyCode is 13
          evt.preventDefault()
          @$repeat_count.blur()

      @listenForCheckboxChange()

  viewRowDetail.DetailViewMixins.repeat_count =
    onOcCustomEvent: (ocCustomEventArgs) ->
      questionId = @model._parent.cid
      sender = ocCustomEventArgs.sender
      senderValue = ocCustomEventArgs.value
      senderQuestionId = sender._parent.cid
      if (sender.key is '_isRepeat') and (questionId is senderQuestionId)
        @model.set('value', senderValue)
    html: ->
      setTimeout =>
          modelValue = @model.getValue()
          Backbone.trigger('ocCustomEvent', { sender: @model, value: modelValue })
        , 1
      false

  # handled by mandatorySettingSelector
  viewRowDetail.DetailViewMixins.required =
    getOptions: () ->
      options = [
        {
          label: 'Always',
          value: 'yes'
        },
        {
          label: 'Conditional'
          value: 'conditional'
        },
        {
          label: 'Never',
          value: ''
        }
      ]
      options
    html: ->
      @$el.addClass("card__settings__fields--active")
      viewRowDetail.Templates.radioButton @cid, @model.key, @getOptions(), t("Required")
    afterRender: ->
      options = @getOptions()
      el = @$("input[type=radio][name=#{@model.key}]")
      $el = $(el)
      $input = $('<input/>', {class:'text', type: 'text', style: 'width: auto; margin-left: 5px;'})
      changing = false

      reflectValueInEl = ()=>
        if !changing
          modelValue = @model.get('value')
          if modelValue == ''
            willSelectedEl = @$("input[type=radio][name=#{@model.key}][id='option_Never']")
          else if modelValue == 'yes'
            willSelectedEl = @$("input[type=radio][name=#{@model.key}][value=#{modelValue}]")
          else
            willSelectedEl = @$("input[type=radio][name=#{@model.key}][id='option_Conditional']")
            @$('#label_Conditional').append $input
            @listenForInputChange el: $input

          $willSelectedEl = $(willSelectedEl)
          $willSelectedEl.prop('checked', true)

      @model.on 'change:value', reflectValueInEl
      reflectValueInEl()

      $el.on 'change', ()=>
        changing = true
        selectedEl = @$("input[type=radio][name=#{@model.key}]:checked")
        $selectedEl = $(selectedEl)
        selectedVal = $selectedEl.val()
        if selectedVal is 'conditional'
          @model.set('value', '')
          @$('#label_Conditional').append $input
          @listenForInputChange el: $input
        else
          @model.set('value', selectedVal)
          $input.remove()
        changing = false

  viewRowDetail.DetailViewMixins.appearance =
    getTypes: () ->
      types =
        text: ['multiline']
        select_one: ['minimal', 'columns', 'columns-pack', 'columns-4', 'columns no-buttons', 'columns-pack no-buttons', 'columns-4 no-buttons', 'likert', 'image-map']
        select_multiple: ['minimal', 'columns', 'columns-pack', 'columns-4', 'columns no-buttons', 'columns-pack no-buttons', 'columns-4 no-buttons', 'image-map']
        image: ['draw', 'annotate', 'signature']
        date: ['month-year', 'year']
        integer: ['analog-scale horizontal', 'analog-scale horizontal no-ticks', 'analog-scale vertical', 'analog-scale vertical no-ticks', 'analog-scale vertical show-scale']

      types[@model_type()]
    html: ->
      @$checkbox_samescreen = $('<input/>', { type: "checkbox", id: "checkbox-samescreen", style: 'margin-top: 10px;' })
      @$label_checkbox_samescreen = $('<span/>', { style: 'margin-left: 4px;' }).text(t('Show all questions in this group on the same screen'))
      @fieldListStr = 'field-list'
      @$select_width = $('<select/>', { id: "select-width" })
      @$label_select_width = $('<label/>', { for: 'select-width' }).text(t('Width') + ":")
      @select_width_default_value = ''
      $('<option />', {value: "select", text: "Width not selected (w4 will be used)"}).appendTo(@$select_width)
      @width_options = []
      for option in [1..10]
        @width_options.push "w#{option}"
      for width_option in @width_options
        $('<option />', {value: "#{width_option}", text: "#{width_option}"}).appendTo(@$select_width)
      @$textbox_other = null
      @is_input_select = false
      @is_input_text_other = false
      @is_checkbox_samescreen = false
      @$el.addClass("card__settings__fields--active")
      if @model_is_group(@model)
        return viewRowDetail.Templates.textbox @cid, @model.key, t("Appearance"), 'text'
      else
        if @model_type() isnt 'calculate'
          appearances = @getTypes()
          if appearances?
            appearances.push 'other'
            appearances.unshift 'select'
            @is_input_select = true
            return viewRowDetail.Templates.dropdown @cid, @model.key, appearances, t("Appearance")
          else
            return viewRowDetail.Templates.textbox @cid, @model.key, t("Appearance"), 'text'

    model_is_group: (model) ->
      model._parent.constructor.key == 'group'

    model_get_parent_group: () ->
      perent_group = null
      if @model._parent._parent._parent? and @model._parent._parent._parent.constructor.key == 'group'
        parent_group = @model._parent._parent._parent
      parent_group

    model_get_parent_group_appearance: () ->
      parent_group = @model_get_parent_group()
      if parent_group?
        parent_group.get('appearance').getValue()

    model_type: () ->
      @model._parent.getValue('type').split(' ')[0]

    is_form_style_exist: () ->
      sessionStorage.getItem('kpi.editable-form.form-style') != ''

    is_form_style: (style) ->
      sessionStorage.getItem('kpi.editable-form.form-style').indexOf(style) isnt -1

    is_form_style_pages: () ->
      @is_form_style('pages')

    is_form_style_theme_grid: () ->
      @is_form_style('theme-grid')

    not_group_inputs_change_handler: () ->
      model_set_value = ''

      if @is_input_select
        if @is_input_text_other
          textbox_other_value = @$textbox_other.val().trim()
          model_set_value = textbox_other_value
        else
          $select = @$('select').not('#select-width')
          select_value = $select.val()
          select_value = '' if select_value == 'select'
          model_set_value = select_value
      else # input text
        $input = @$('input')
        input_value = $input.val().trim()
        model_set_value = input_value

      select_width_value = @$select_width.val()
      select_width_value = @select_width_default_value if select_width_value == 'select'
      if model_set_value != ''
        if select_width_value != ''
          model_set_value += " #{select_width_value}"
      else
        model_set_value = select_width_value

      @model.set 'value', model_set_value

    group_inputs_change_handler: () ->
      model_set_value = ''

      if @is_checkbox_samescreen
        show_samescreen = @$checkbox_samescreen.prop('checked')
        if show_samescreen
          model_set_value = @fieldListStr

      $input = @$('input')
      input_value = $input.val().trim()
      if model_set_value != ''
        if input_value != ''
          model_set_value += " #{input_value}"
      else
        model_set_value = input_value

      select_width_value = @$select_width.val()
      select_width_value = @select_width_default_value if select_width_value == 'select'
      if model_set_value != ''
        if select_width_value != ''
          model_set_value += " #{select_width_value}"
      else
        model_set_value = select_width_value

      @model.set 'value', model_set_value

    add_input_text_change_handler: ($input, handler) ->
      handler = handler.bind @
      $input.off 'change'
      $input.on 'change', () =>
        handler()
      $input.off 'blur'
      $input.on 'blur', () =>
        handler()
      $input.off 'keyup'
      $input.on 'keyup', (evt) =>
        if evt.key is 'Enter' or evt.keyCode is 13
          $input.blur()
        else
          handler()

    is_same_screen_in_model_value: () ->
      modelValue = @model.get 'value'
      (modelValue.indexOf @fieldListStr) > -1

    get_width_from_model_value: () ->
      modelValue = @model.get 'value'
      model_width = null
      for width_option in @width_options
        model_width = width_option if ((modelValue.indexOf width_option) > -1)
      model_width

    get_select_value_from_model_value: () ->
      modelValue = @model.get 'value'
      select_value = null
      select_values = []
      for type in @getTypes()
        select_values.push(type) if ((modelValue.indexOf type) > -1)

      if select_values.length > 0
        if select_values.length == 1
          select_value = select_values[0]
        else
          for value in select_values
            if ((modelValue.indexOf value) > -1)
              if select_value?
                if select_value.length < value.length
                  select_value = value
              else
                select_value = value

      select_value

    afterRender: ->
      modelValue = @model.get 'value'
      if @model_is_group(@model)
        $input = @$('input')

        if @is_form_style_theme_grid()
          $width_field = $("""<div class="card__settings__fields__field xlf-dv-width-row">
            <label for="select-width">#{t('Width')}:</label>
            <span class="settings__input"></span>
          </div>""")
          $width_field.find('.settings__input').append(@$select_width)
          @$el.append($width_field)

        if @is_form_style_exist() and @is_form_style_pages()
          $container_checkbox_samescreen = $('<div/>')
          $container_checkbox_samescreen.append(@$checkbox_samescreen)
          $container_checkbox_samescreen.append(@$label_checkbox_samescreen)
          @$('.settings__input').append($container_checkbox_samescreen)
          @is_checkbox_samescreen = true

        if modelValue? and modelValue != '' # Parse existing value
          modelValue = modelValue.trim()
          samescreen_value = null
          text_input_value = null
          select_width_value = null

          if @is_same_screen_in_model_value()
            samescreen_value = @fieldListStr
            modelValue = modelValue.split(samescreen_value).join('') # remove samescreen_value from modelValue

          width_model_value = @get_width_from_model_value()
          if width_model_value?
            select_width_value = width_model_value
            modelValue = modelValue.split(select_width_value).join('') # remove select_width_value from modelValue

          modelValue = modelValue.trim()
          if modelValue != ''
            text_input_value = modelValue

        if samescreen_value?
          @$checkbox_samescreen.prop('checked', true)
        if text_input_value?
          $input.val(text_input_value)
        if select_width_value?
          @$select_width.val(select_width_value)

        @add_input_text_change_handler($input, @group_inputs_change_handler)

        @$select_width.off 'change'
        @$select_width.on 'change', () =>
          @group_inputs_change_handler()

        @$checkbox_samescreen.off 'change'
        @$checkbox_samescreen.on 'change', () =>
          @group_inputs_change_handler()

      else # not group. this is question item appearance settings
        if @is_form_style_theme_grid()
          $width_field = $("""<div class="card__settings__fields__field xlf-dv-width-row">
            <label for="select-width">#{t('Width')}:</label>
            <span class="settings__input"></span>
          </div>""")
          $width_field.find('.settings__input').append(@$select_width)
          @$el.append($width_field)

          parent_column = 4
          if @model_get_parent_group()? and @model_get_parent_group_appearance() != ''
            parent_group_appearance = @model_get_parent_group_appearance()
            if parent_group_appearance.indexOf(' ') == -1 # no space in parent_group_appearance
              if parent_group_appearance in @width_options
                parent_column = parent_group_appearance.slice(1)
            else
              parent_group_appearance_last_value = parent_group_appearance.slice(parent_group_appearance.lastIndexOf(' ') + 1)
              if parent_group_appearance_last_value in @width_options
                parent_column = parent_group_appearance_last_value.slice(1)

          parent_column = parseInt parent_column, 10
          text_parent_columns = "Parent group has #{parent_column} columns"
          if parent_column == 1
            text_parent_columns = text_parent_columns.replace('columns', 'column')
          $help_field = $("""<div class="card__settings__fields__field card__settings__fields__field--help-text-row">
            <label></label>
            <span class="settings__input"></span>
          </div>""")
          $help_field.find('.settings__input').text(text_parent_columns)
          @$el.append($help_field)

        $select = @$('select').not('#select-width')
        if $select.length > 0 # Question item appearance is dropdown
          @$textbox_other = $('<input/>', { class:'text', type: 'text', width: 'auto', style: 'display: block; margin-top: 5px;' })

          if modelValue? and modelValue != '' # Parse existing value
            modelValue = modelValue.trim()
            select_value = null
            other_value = null
            select_width_value = null

            select_model_value = @get_select_value_from_model_value()
            if select_model_value?
              select_value = select_model_value
              modelValue = modelValue.split(select_value).join('') # remove select_value from modelValue

            width_model_value = @get_width_from_model_value()
            if width_model_value?
              select_width_value = width_model_value
              modelValue = modelValue.split(select_width_value).join('') # remove select_width_value from modelValue

            modelValue = modelValue.trim()
            if modelValue != ''
              other_value = modelValue

            if select_value?
              $select.val(select_value)
            if select_width_value?
              @$select_width.val(select_width_value)
            if other_value?
              $select.val('other')
              @$textbox_other.insertAfter $select
              @$textbox_other.val(other_value)
              @is_input_text_other = true
              @add_input_text_change_handler(@$textbox_other, @not_group_inputs_change_handler)

          @$select_width.on 'change', () =>
            @not_group_inputs_change_handler()

          $select.on 'change', () =>
            if $select.val() == 'other'
              @$textbox_other.insertAfter $select
              @is_input_text_other = true
              @add_input_text_change_handler(@$textbox_other, @not_group_inputs_change_handler)
            else
              @$textbox_other.val('')
              @$textbox_other.remove()
              @is_input_text_other = false
              @not_group_inputs_change_handler()

        else # Question item appearance is text input
          $input = @$('input')
          if modelValue? and modelValue != '' # Parse existing value
            modelValue = modelValue.trim()
            input_value = null
            select_width_value = null

            width_model_value = @get_width_from_model_value()
            if width_model_value?
              select_width_value = width_model_value
              modelValue = modelValue.split(select_width_value).join('') # remove select_width_value from modelValue

            modelValue = modelValue.trim()
            if modelValue != ''
              input_value = modelValue

            if input_value?
              $input.val(input_value)
            if select_width_value?
              @$select_width.val(select_width_value)

          @add_input_text_change_handler($input, @group_inputs_change_handler)

          @$select_width.on 'change', () =>
            @group_inputs_change_handler()

  viewRowDetail.DetailViewMixins.oc_item_group =
    onOcCustomEvent: (ocCustomEventArgs) ->
      questionId = @model._parent.cid
      sender = ocCustomEventArgs.sender
      senderValue = ocCustomEventArgs.value
      senderQuestionId = sender._parent.cid
      if (sender.key is 'bind::oc:external') and (questionId is senderQuestionId)
        @$el.siblings(".message").remove();
        @$el.closest('div').removeClass("input-error")
        if senderValue in ['clinicaldata', 'contactdata', 'identifier']
          @removeRequired()
          @makeFieldCheckCondition({
            checkIfNotEmpty: true,
            message: 'This field must be empty if Use External Value is being used'
          })
        else
          @$el.removeClass('hidden')
          @makeRequired()
      else
        @makeRequired()
    html: ->
      @fieldTab = "active"
      @$el.addClass("card__settings__fields--#{@fieldTab}")
      viewRowDetail.Templates.textbox @cid, @model.key, t("Item Group"), 'text', 'Enter data set name'
    afterRender: ->
      @listenForInputChange()
      @makeRequired()

  viewRowDetail.DetailViewMixins.oc_briefdescription =
    html: ->
      @fieldTab = "active"
      @$el.addClass("card__settings__fields--#{@fieldTab}")
      viewRowDetail.Templates.textbox @cid, @model.key, t("Item Brief Description"), 'text', t('Enter Text'), '40'
    afterRender: ->
      @listenForInputChange()

  viewRowDetail.DetailViewMixins.oc_description =
    html: ->
      @fieldTab = "active"
      @$el.addClass("card__settings__fields--#{@fieldTab}")
      viewRowDetail.Templates.textbox @cid, @model.key, t("Item Description"), 'text', t('Enter Text'), '3999'
    afterRender: ->
      @listenForInputChange()

  viewRowDetail.DetailViewMixins.oc_external =
    onOcConsentRowsEvent: (ocConsentRowsEventArgs) ->
      if (ocConsentRowsEventArgs.type == 'consentRows')
        $select = @$('select')

        if (ocConsentRowsEventArgs.message != '')
          @hideErrorMessage()

          @showMessage(ocConsentRowsEventArgs.message, 'input-error')
          @model.getSurvey().errorMessage = ocConsentRowsEventArgs.message
        else
          @model.getSurvey().errorMessage = null
          @hideErrorMessage()

          if $select.val() == 'signature'
            @showSignatureMessage()

    showMessage: (message, fieldClass) ->
      $select = @$('select')
      $select.closest('div').addClass(fieldClass)
      if $select.siblings('.message').length is 0
        $message = $('<div/>').addClass('message').text(message)
        $select.after($message)

    showErrorMessage: () ->
      errorMessage = t("Constraint / Constraint Message is not empty")
      errorFieldClass = 'input-error'
      @showMessage(errorMessage, errorFieldClass)

    showSignatureMessage: () ->
      signatureMessage = t("Signature items must be Select Multiple questions with one option")
      fieldClass = ''
      if (@model.getSurvey().errorMessage?)
        signatureMessage = @model.getSurvey().errorMessage
        fieldClass = 'input-error'
      @showMessage(signatureMessage, fieldClass)

    hideMessage: (fieldClass) ->
      $select = @$('select')
      if (fieldClass != '')
        if ($select.closest('div').hasClass(fieldClass))
          $select.closest('div').removeClass(fieldClass)
      $select.siblings('.message').remove()

    hideErrorMessage: () ->
      @hideMessage('input-error')

    model_type: () ->
      @model._parent.getValue('type').split(' ')[0]
    getOptions: () ->
      types =
        text: ['contactdata', 'identifier']
        calculate: ['clinicaldata']
        select_multiple: ['signature']
      types[@model_type()]
    html: ->
      @fieldTab = "active"
      @$el.addClass("card__settings__fields--#{@fieldTab}")

      if @model_type() in ['calculate', 'text'] or (@model_type() == 'select_multiple' and @model._parent.isConsentItem())
        options = @getOptions()
        if options?
            options.unshift 'No'
        return viewRowDetail.Templates.dropdown @cid, @model.key, options, t("Use External Value")
    afterRender: ->
      $select = @$('select')

      @contact_data_type_class_name = 'contact-data-type'
      @$label_select_contact_data_type = $('<span/>', { class: @contact_data_type_class_name, style: 'display: block; margin-top: 10px;' }).text(t('Contact Data Type') + ":")
      @$select_contact_data_type = $('<select/>', { class: @contact_data_type_class_name, style: 'margin-top: 5px;' })
      $('<option />', {value: "select", text: "- select -"}).appendTo(@$select_contact_data_type)
      @contact_data_type_options = ['firstname', 'lastname', 'email', 'mobilenumber', 'secondaryid']
      for contact_data_type_option in @contact_data_type_options
        $('<option />', {value: "#{contact_data_type_option}", text: "#{contact_data_type_option}"}).appendTo(@$select_contact_data_type)

      @identifier_type_class_name = 'identifier-type'
      @$label_select_identifier_type = $('<span/>', { class: @identifier_type_class_name, style: 'display: block; margin-top: 10px;' }).text(t('Identifier Type') + ":")
      @$select_identifier_type = $('<select/>', { class: @identifier_type_class_name, style: 'margin-top: 5px;' })
      $('<option />', {value: "select", text: "- select -"}).appendTo(@$select_identifier_type)
      @identifier_type_options = ['participantid']
      for identifier_type_option in @identifier_type_options
        $('<option />', {value: "#{identifier_type_option}", text: "#{identifier_type_option}"}).appendTo(@$select_identifier_type)


      addSelectContactDataType = () =>
        @$('.settings__input').append(@$label_select_contact_data_type)
        @$('.settings__input').append(@$select_contact_data_type)

        instance_contactdata_value = @rowView.model.attributes['instance::oc:contactdata'].get 'value'
        if instance_contactdata_value != '' and (instance_contactdata_value in @contact_data_type_options)
          @$select_contact_data_type.val(instance_contactdata_value)

        @$select_contact_data_type.change () =>
          if @$select_contact_data_type.val() == 'select'
            @rowView.model.attributes['instance::oc:contactdata'].set 'value', ''
          else
            @rowView.model.attributes['instance::oc:contactdata'].set 'value', @$select_contact_data_type.val()

      addSelectIdentifierType = () =>
        @$('.settings__input').append(@$label_select_identifier_type)
        @$('.settings__input').append(@$select_identifier_type)

        instance_identifier_value = @rowView.model.attributes['instance::oc:identifier'].get 'value'
        if instance_identifier_value != '' and (instance_identifier_value in @identifier_type_options)
          @$select_identifier_type.val(instance_identifier_value)

        @$select_identifier_type.change () =>
          if @$select_identifier_type.val() == 'select'
            @rowView.model.attributes['instance::oc:identifier'].set 'value', ''
          else
            @rowView.model.attributes['instance::oc:identifier'].set 'value', @$select_identifier_type.val()

      resetInstanceValues = () =>
        @rowView.model.attributes['instance::oc:contactdata'].set 'value', ''
        @rowView.model.attributes['instance::oc:identifier'].set 'value', ''

      modelValue = @model.get 'value'
      if $select.length > 0
        if modelValue == ''
          if @model._parent.isConsentItem()
            $select.val('signature')
            @model.set 'value', $select.val()
            @showSignatureMessage()
          else
            $select.val('No')
        else
          $select.val(modelValue)
          Backbone.trigger('ocCustomEvent', { sender: @model, value: modelValue })

          if modelValue == 'contactdata'
            addSelectContactDataType()
          else if modelValue == 'identifier'
            addSelectIdentifierType()
          else if modelValue == 'signature'
            @showSignatureMessage()

        $select.change () =>
          Backbone.trigger('ocCustomEvent', { sender: @model, value: $select.val() })

          if $select.siblings(".#{@contact_data_type_class_name}").length > 0
            $select.siblings(".#{@contact_data_type_class_name}").remove()

          if $select.siblings(".#{@identifier_type_class_name}").length > 0
            $select.siblings(".#{@identifier_type_class_name}").remove()

          if $select.val() == 'No'
            @model.set 'value', ''
            resetInstanceValues()
            @hideErrorMessage()
          else
            @model.set 'value', $select.val()
            resetInstanceValues()
            if $select.val() == 'contactdata'
              addSelectContactDataType()
              constraint_value = @rowView.model.attributes.constraint.getValue()
              constraint_message_value = @rowView.model.attributes.constraint_message.getValue()
              if (constraint_value != '') or (constraint_message_value != '')
                @showMessage()
            else if $select.val() == 'identifier'
              addSelectIdentifierType()
            else if $select.val() == 'signature'
              @showSignatureMessage()

  viewRowDetail.DetailViewMixins.readonly =
    html: ->
      @fieldTab = "active"
      @$el.addClass("card__settings__fields--#{@fieldTab}")
      viewRowDetail.Templates.checkbox @cid, @model.key, t("Read only")
    afterRender: ->
      @listenForCheckboxChange()

  viewRowDetail.DetailViewMixins.calculation =
    html: ->
      @fieldTab = "active"
      @$el.addClass("card__settings__fields--#{@fieldTab}")
      viewRowDetail.Templates.textarea @cid, @model.key, t("Calculation"), 'text', t('Enter Text')
    changeModelValue: () ->
      $textarea = $(@$('textarea').get(0))
      $elVal = $textarea.val().replace(/\n/g, "")
      @model.set('value', $elVal)
    afterRender: ->
      $textarea = $(@$('textarea').get(0))
      $textarea.val(@model.get("value"))

      if @model.get("value")?
        setTimeout =>
          textareaScrollHeight = $textarea.prop('scrollHeight')
          $textarea.css("height", "")
          $textarea.css("height", textareaScrollHeight)
        , 1

      questionType = @model._parent.get('type').get('typeId')
      if questionType is 'calculate'
        @makeRequired()

      $textarea.on 'blur', () =>
        @changeModelValue()
      $textarea.on 'change', () =>
        @changeModelValue()
      $textarea.on 'keyup', () =>
        @changeModelValue()
      $textarea.on 'keypress', (evt) =>
        if evt.key is 'Enter' or evt.keyCode is 13
          evt.preventDefault()
          $textarea.blur()

  viewRowDetail.DetailViewMixins.select_one_from_file_filename =
    html: ->
      @fieldTab = "active"
      @$el.addClass("card__settings__fields--#{@fieldTab}")
      viewRowDetail.Templates.textbox @cid, @model.key, t("External List Filename"), 'text', 'Enter external list filename'
    afterRender: ->
      @listenForInputChange()
      @makeRequired()

  viewRowDetail.DetailViewMixins.trigger =
    getOptions: () ->
      currentQuestion = @model._parent
      non_selectable = ['datetime', 'time', 'note', 'group', 'kobomatrix', 'repeat', 'rank', 'score', 'calculate']

      questions = []
      currentQuestion.getSurvey().forEachRow (question) =>
        if (question.getValue('type') not in non_selectable) and (question.cid != currentQuestion.cid)
          questions.push question
      , includeGroups:true

      options = []
      options = _.map(questions, (row) ->

        try
          labelValue = row.getValue('label')
        catch e
          labelValue = ''

        return {
          value: "${#{row.getValue('name')}}"
          text: "#{labelValue} (${#{row.getValue('name')}})"
        }
      )
      # add placeholder message/option
      options.unshift({
        value: ''
        text: t("No Trigger")
      })
      options
    html: ->
      @fieldTab = "active"
      @$el.addClass("card__settings__fields--#{@fieldTab}")
      options = @getOptions()

      return viewRowDetail.Templates.dropdown @cid, @model.key, options, t("Calculation trigger")
    afterRender: ->
      $select = @$('select')
      modelValue = @model.get 'value'
      if $select.length > 0
        if modelValue != ''
          $select.val(modelValue)

        $select.change () =>
          @model.set 'value', $select.val()

  viewRowDetail

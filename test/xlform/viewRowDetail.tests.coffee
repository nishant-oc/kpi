{expect} = require('../helper/fauxChai')
$ = require('jquery')

# Provide translation stub (no Django runtime in tests)
window.t ?= (str) -> str

$configs = require('../../jsapp/xlform/src/model.configs')

do ->
  ###############################################################
  # view.rowDetail.Templates — the raw HTML builders
  ###############################################################
  describe 'view.rowDetail.Templates: textbox()', ->
    beforeEach ->
      # Lazily require inside test scope so window.t is available
      @Templates = require('../../jsapp/xlform/src/view.rowDetail').Templates

    it 'renders an input[type=text] element', ->
      html = @Templates.textbox('cid1', 'name', 'Item Name', 'text', 'Enter variable name', '40')
      expect(html.indexOf('<input')).not.toBe(-1)
      expect(html.indexOf('type="text"')).not.toBe(-1)

    it 'renders the field label', ->
      html = @Templates.textbox('cid1', 'name', 'Item Name')
      expect(html.indexOf('Item Name')).not.toBe(-1)

    it 'renders the placeholder text when provided', ->
      html = @Templates.textbox('cid1', 'name', 'Item Name', 'text', 'Enter variable name')
      expect(html.indexOf('placeholder="Enter variable name"')).not.toBe(-1)

    it 'renders maxlength attribute when provided', ->
      html = @Templates.textbox('cid1', 'name', 'Item Name', 'text', 'Enter variable name', '40')
      expect(html.indexOf('maxlength="40"')).not.toBe(-1)

    it 'does not render maxlength when not provided', ->
      html = @Templates.textbox('cid1', 'name', 'Item Name', 'text', 'Enter variable name', '')
      expect(html.indexOf('maxlength')).toBe(-1)

    it 'renders the id attribute using the provided cid', ->
      html = @Templates.textbox('my_cid', 'name', 'Item Name')
      expect(html.indexOf('id="my_cid"')).not.toBe(-1)

    it 'renders the name attribute', ->
      html = @Templates.textbox('cid1', 'myfield', 'My Field')
      expect(html.indexOf('name="myfield"')).not.toBe(-1)

    it 'wraps the whole thing in a .card__settings__fields__field div', ->
      html = @Templates.textbox('cid1', 'name', 'Item Name')
      expect(html.indexOf('card__settings__fields__field')).not.toBe(-1)

  describe 'view.rowDetail.Templates: textarea()', ->
    beforeEach ->
      @Templates = require('../../jsapp/xlform/src/view.rowDetail').Templates

    it 'renders a <textarea> element', ->
      html = @Templates.textarea('cid2', 'calculation', 'Calculation', 'text')
      expect(html.indexOf('<textarea')).not.toBe(-1)

    it 'renders the field label', ->
      html = @Templates.textarea('cid2', 'calculation', 'Calculation')
      expect(html.indexOf('Calculation')).not.toBe(-1)

    it 'renders the id attribute', ->
      html = @Templates.textarea('cid_calc', 'calculation', 'Calculation')
      expect(html.indexOf('id="cid_calc"')).not.toBe(-1)

    it 'renders maxlength when provided', ->
      html = @Templates.textarea('cid2', 'desc', 'Item Description', 'text', '', '3999')
      expect(html.indexOf('maxlength="3999"')).not.toBe(-1)

    it 'does not render maxlength when not provided', ->
      html = @Templates.textarea('cid2', 'calculation', 'Calculation', 'text', '', '')
      expect(html.indexOf('maxlength')).toBe(-1)

  describe 'view.rowDetail.Templates: checkbox()', ->
    beforeEach ->
      @Templates = require('../../jsapp/xlform/src/view.rowDetail').Templates

    it 'renders an input[type=checkbox]', ->
      html = @Templates.checkbox('cid3', 'readonly', 'Read only')
      expect(html.indexOf('type="checkbox"')).not.toBe(-1)

    it 'renders the field label "Read only"', ->
      html = @Templates.checkbox('cid3', 'readonly', 'Read only')
      expect(html.indexOf('Read only')).not.toBe(-1)

    it 'renders the input label "Yes" by default', ->
      html = @Templates.checkbox('cid3', 'readonly', 'Read only')
      expect(html.indexOf('Yes')).not.toBe(-1)

    it 'renders a custom input label when provided', ->
      html = @Templates.checkbox('cid3', '_isRepeat', 'Repeat', 'Repeat this group if necessary')
      expect(html.indexOf('Repeat this group if necessary')).not.toBe(-1)

  describe 'view.rowDetail.Templates: radioButton()', ->
    beforeEach ->
      @Templates = require('../../jsapp/xlform/src/view.rowDetail').Templates
      @requiredOptions = [
        {label: 'Always', value: 'yes'},
        {label: 'Never', value: ''},
        {label: 'Conditional', value: 'conditional'}
      ]

    it 'renders input[type=radio] for each option', ->
      html = @Templates.radioButton('cid4', 'required', @requiredOptions, 'Required')
      count = (html.match(/type="radio"/g) or []).length
      expect(count).toBe(3)

    it 'renders the "Always" label', ->
      html = @Templates.radioButton('cid4', 'required', @requiredOptions, 'Required')
      expect(html.indexOf('Always')).not.toBe(-1)

    it 'renders the "Never" label', ->
      html = @Templates.radioButton('cid4', 'required', @requiredOptions, 'Required')
      expect(html.indexOf('Never')).not.toBe(-1)

    it 'renders the "Conditional" label', ->
      html = @Templates.radioButton('cid4', 'required', @requiredOptions, 'Required')
      expect(html.indexOf('Conditional')).not.toBe(-1)

    it 'renders the "Required" field label', ->
      html = @Templates.radioButton('cid4', 'required', @requiredOptions, 'Required')
      expect(html.indexOf('Required')).not.toBe(-1)

    it 'renders value="yes" for the Always option', ->
      html = @Templates.radioButton('cid4', 'required', @requiredOptions, 'Required')
      expect(html.indexOf('value="yes"')).not.toBe(-1)

  describe 'view.rowDetail.Templates: dropdown()', ->
    beforeEach ->
      @Templates = require('../../jsapp/xlform/src/view.rowDetail').Templates
      @externalOptions = ['No', 'clinicaldata', 'contactdata', 'identifier']

    it 'renders a <select> element', ->
      html = @Templates.dropdown('cid5', 'bind::oc:external', @externalOptions, 'Use External Value')
      expect(html.indexOf('<select')).not.toBe(-1)

    it 'renders the field label', ->
      html = @Templates.dropdown('cid5', 'bind::oc:external', @externalOptions, 'Use External Value')
      expect(html.indexOf('Use External Value')).not.toBe(-1)

    it 'renders one <option> per item', ->
      html = @Templates.dropdown('cid5', 'bind::oc:external', @externalOptions, 'Use External Value')
      count = (html.match(/<option/g) or []).length
      expect(count).toBe(@externalOptions.length)

    it 'renders "No" as the first option', ->
      html = @Templates.dropdown('cid5', 'bind::oc:external', @externalOptions, 'Use External Value')
      firstOption = html.indexOf('No')
      expect(firstOption).not.toBe(-1)

    it 'renders object options with value and text correctly', ->
      triggerOptions = [
        {value: '', text: 'No Trigger'},
        {value: '${q1}', text: 'Q1 (${q1})'}
      ]
      html = @Templates.dropdown('cid6', 'trigger', triggerOptions, 'Calculation trigger')
      expect(html.indexOf('No Trigger')).not.toBe(-1)
      expect(html.indexOf('value="${q1}"')).not.toBe(-1)

    it 'renders appearance dropdown for select type with "select" placeholder', ->
      appearances = ['select', 'minimal', 'columns', 'other']
      html = @Templates.dropdown('cid7', 'appearance', appearances, 'Appearance')
      expect(html.indexOf('Appearance')).not.toBe(-1)
      count = (html.match(/<option/g) or []).length
      expect(count).toBe(appearances.length)

  describe 'view.rowDetail.Templates: field()', ->
    beforeEach ->
      @Templates = require('../../jsapp/xlform/src/view.rowDetail').Templates

    it 'wraps content in .card__settings__fields__field', ->
      html = @Templates.field('<input type="text"/>', 'cid1', 'My Label')
      expect(html.indexOf('card__settings__fields__field')).not.toBe(-1)

    it 'inserts the provided input HTML', ->
      html = @Templates.field('<input type="text" class="myInput"/>', 'cid1', 'My Label')
      expect(html.indexOf('class="myInput"')).not.toBe(-1)

    it 'renders a label pointing to the cid', ->
      html = @Templates.field('<input/>', 'label_cid', 'Field Label')
      expect(html.indexOf('for="label_cid"')).not.toBe(-1)
      expect(html.indexOf('Field Label')).not.toBe(-1)

  ###############################################################
  # view.rowDetail: DetailViewMixins — html() rendering per field
  # These tests load the actual Mixins and call html() directly
  # after supplying minimal model/survey stubs.
  ###############################################################
  describe 'view.rowDetail.DetailViewMixins: "name" html()', ->
    beforeEach ->
      window.xlfHideWarnings = true
      @viewRowDetail = require('../../jsapp/xlform/src/view.rowDetail')
      $model = require('../../jsapp/xlform/src/_model')
      @survey = new $model.Survey()
      @survey.rows.add(type: 'text', name: 'sample_q', label: 'Sample')
      @row = @survey.rows.at(0)
      @detail = @row.get('name')
      @mixin = @viewRowDetail.DetailViewMixins.name
      @mixin_ctx = $.extend({}, @mixin, {
        cid: 'test_cid'
        $el: $('<div/>')
        model: @detail
        Templates: @viewRowDetail.Templates
      })
    afterEach ->
      window.xlfHideWarnings = false

    it 'name field sets fieldTab to "active"', ->
      @mixin_ctx.html()
      expect(@mixin_ctx.fieldTab).toBe('active')

    it 'name field html contains "Item Name" label', ->
      result = @mixin_ctx.html()
      expect(result.indexOf('Item Name')).not.toBe(-1)

    it 'name field html contains an input[type=text]', ->
      result = @mixin_ctx.html()
      expect(result.indexOf('type="text"')).not.toBe(-1)

    it 'name field html contains the maxlength attribute', ->
      result = @mixin_ctx.html()
      expect(result.indexOf('maxlength')).not.toBe(-1)

  describe 'view.rowDetail.DetailViewMixins: "readonly" html()', ->
    beforeEach ->
      window.xlfHideWarnings = true
      @viewRowDetail = require('../../jsapp/xlform/src/view.rowDetail')
      $model = require('../../jsapp/xlform/src/_model')
      survey = new $model.Survey()
      survey.rows.add(type: 'text', name: 'q1', label: 'Q1')
      @detail = survey.rows.at(0).get('readonly')
      @mixin = @viewRowDetail.DetailViewMixins.readonly
      @mixin_ctx = $.extend({}, @mixin, {
        cid: 'cid_ro'
        $el: $('<div/>')
        model: @detail
        Templates: @viewRowDetail.Templates
      })
    afterEach ->
      window.xlfHideWarnings = false

    it 'readonly html() renders a checkbox', ->
      result = @mixin_ctx.html()
      expect(result.indexOf('type="checkbox"')).not.toBe(-1)

    it 'readonly html() renders "Read only" label', ->
      result = @mixin_ctx.html()
      expect(result.indexOf('Read only')).not.toBe(-1)

    it 'readonly html() sets fieldTab to "active"', ->
      @mixin_ctx.html()
      expect(@mixin_ctx.fieldTab).toBe('active')

  describe 'view.rowDetail.DetailViewMixins: "required" html()', ->
    beforeEach ->
      window.xlfHideWarnings = true
      @viewRowDetail = require('../../jsapp/xlform/src/view.rowDetail')
      $model = require('../../jsapp/xlform/src/_model')
      survey = new $model.Survey()
      survey.rows.add(type: 'text', name: 'q1', label: 'Q1')
      @detail = survey.rows.at(0).get('required')
      @mixin = @viewRowDetail.DetailViewMixins.required
      @mixin_ctx = $.extend({}, @mixin, {
        cid: 'cid_req'
        $el: $('<div/>')
        model: @detail
        Templates: @viewRowDetail.Templates
      })
    afterEach ->
      window.xlfHideWarnings = false

    it 'required html() renders radio buttons', ->
      result = @mixin_ctx.html()
      expect(result.indexOf('type="radio"')).not.toBe(-1)

    it 'required html() includes "Always" option', ->
      result = @mixin_ctx.html()
      expect(result.indexOf('Always')).not.toBe(-1)

    it 'required html() includes "Never" option', ->
      result = @mixin_ctx.html()
      expect(result.indexOf('Never')).not.toBe(-1)

    it 'required html() includes "Conditional" option', ->
      result = @mixin_ctx.html()
      expect(result.indexOf('Conditional')).not.toBe(-1)

    it 'required html() renders "Required" as the field label', ->
      result = @mixin_ctx.html()
      expect(result.indexOf('Required')).not.toBe(-1)

    it 'getOptions() returns 3 options', ->
      opts = @mixin_ctx.getOptions()
      expect(opts.length).toBe(3)

    it 'getOptions() has an option with value "yes" for Always', ->
      opts = @mixin_ctx.getOptions()
      found = opts.find (o) -> o.value is 'yes'
      expect(found).toBeDefined()
      expect(found.label).toBe('Always')

    it 'getOptions() has an option with value "" for Never', ->
      opts = @mixin_ctx.getOptions()
      found = opts.find (o) -> o.value is ''
      expect(found).toBeDefined()
      expect(found.label).toBe('Never')

    it 'getOptions() has a Conditional option', ->
      opts = @mixin_ctx.getOptions()
      found = opts.find (o) -> o.label is 'Conditional'
      expect(found).toBeDefined()

  describe 'view.rowDetail.DetailViewMixins: "calculation" html()', ->
    beforeEach ->
      window.xlfHideWarnings = true
      @viewRowDetail = require('../../jsapp/xlform/src/view.rowDetail')
      $model = require('../../jsapp/xlform/src/_model')
      survey = new $model.Survey()
      survey.rows.add(type: 'calculate', name: 'calc_q', label: 'Calc')
      @detail = survey.rows.at(0).get('calculation')
      @mixin = @viewRowDetail.DetailViewMixins.calculation
      @mixin_ctx = $.extend({}, @mixin, {
        cid: 'cid_calc'
        $el: $('<div/>')
        model: @detail
        Templates: @viewRowDetail.Templates
      })
    afterEach ->
      window.xlfHideWarnings = false

    it 'calculation html() renders a textarea', ->
      result = @mixin_ctx.html()
      expect(result.indexOf('<textarea')).not.toBe(-1)

    it 'calculation html() renders "Calculation" label', ->
      result = @mixin_ctx.html()
      expect(result.indexOf('Calculation')).not.toBe(-1)

    it 'calculation html() sets fieldTab to "active"', ->
      @mixin_ctx.html()
      expect(@mixin_ctx.fieldTab).toBe('active')

  describe 'view.rowDetail.DetailViewMixins: "oc_item_group" html()', ->
    beforeEach ->
      window.xlfHideWarnings = true
      @viewRowDetail = require('../../jsapp/xlform/src/view.rowDetail')
      $model = require('../../jsapp/xlform/src/_model')
      survey = new $model.Survey()
      survey.rows.add(type: 'text', name: 'q1', label: 'Q1')
      @detail = survey.rows.at(0).get('bind::oc:itemgroup')
      @mixin = @viewRowDetail.DetailViewMixins.oc_item_group
      @mixin_ctx = $.extend({}, @mixin, {
        cid: 'cid_grp'
        $el: $('<div/>')
        model: @detail
        Templates: @viewRowDetail.Templates
      })
    afterEach ->
      window.xlfHideWarnings = false

    it 'oc_item_group html() renders an input[type=text]', ->
      result = @mixin_ctx.html()
      expect(result.indexOf('type="text"')).not.toBe(-1)

    it 'oc_item_group html() renders "Item Group" label', ->
      result = @mixin_ctx.html()
      expect(result.indexOf('Item Group')).not.toBe(-1)

    it 'oc_item_group html() renders placeholder "Enter data set name"', ->
      result = @mixin_ctx.html()
      expect(result.indexOf('Enter data set name')).not.toBe(-1)

    it 'oc_item_group html() sets fieldTab to "active"', ->
      @mixin_ctx.html()
      expect(@mixin_ctx.fieldTab).toBe('active')

  describe 'view.rowDetail.DetailViewMixins: "oc_briefdescription" html()', ->
    beforeEach ->
      window.xlfHideWarnings = true
      @viewRowDetail = require('../../jsapp/xlform/src/view.rowDetail')
      $model = require('../../jsapp/xlform/src/_model')
      survey = new $model.Survey()
      survey.rows.add(type: 'text', name: 'q1', label: 'Q1')
      @detail = survey.rows.at(0).get('bind::oc:briefdescription')
      @mixin = @viewRowDetail.DetailViewMixins.oc_briefdescription
      @mixin_ctx = $.extend({}, @mixin, {
        cid: 'cid_brief'
        $el: $('<div/>')
        model: @detail
        Templates: @viewRowDetail.Templates
      })
    afterEach ->
      window.xlfHideWarnings = false

    it 'oc_briefdescription html() renders an input[type=text]', ->
      result = @mixin_ctx.html()
      expect(result.indexOf('type="text"')).not.toBe(-1)

    it 'oc_briefdescription html() renders "Item Brief Description" label', ->
      result = @mixin_ctx.html()
      expect(result.indexOf('Item Brief Description')).not.toBe(-1)

    it 'oc_briefdescription html() renders the correct placeholder', ->
      result = @mixin_ctx.html()
      expect(result.indexOf('Enter variable title')).not.toBe(-1)
      expect(result.indexOf('(optional)')).not.toBe(-1)

    it 'oc_briefdescription html() renders maxlength="40"', ->
      result = @mixin_ctx.html()
      expect(result.indexOf('maxlength="40"')).not.toBe(-1)

  describe 'view.rowDetail.DetailViewMixins: "oc_description" html()', ->
    beforeEach ->
      window.xlfHideWarnings = true
      @viewRowDetail = require('../../jsapp/xlform/src/view.rowDetail')
      $model = require('../../jsapp/xlform/src/_model')
      survey = new $model.Survey()
      survey.rows.add(type: 'text', name: 'q1', label: 'Q1')
      @detail = survey.rows.at(0).get('bind::oc:description')
      @mixin = @viewRowDetail.DetailViewMixins.oc_description
      @mixin_ctx = $.extend({}, @mixin, {
        cid: 'cid_desc'
        $el: $('<div/>')
        model: @detail
        Templates: @viewRowDetail.Templates
      })
    afterEach ->
      window.xlfHideWarnings = false

    it 'oc_description html() renders an input[type=text]', ->
      result = @mixin_ctx.html()
      expect(result.indexOf('type="text"')).not.toBe(-1)

    it 'oc_description html() renders "Item Description" label', ->
      result = @mixin_ctx.html()
      expect(result.indexOf('Item Description')).not.toBe(-1)

    it 'oc_description html() renders the CDASH placeholder', ->
      result = @mixin_ctx.html()
      expect(result.indexOf('CDASH')).not.toBe(-1)

    it 'oc_description html() renders maxlength="3999"', ->
      result = @mixin_ctx.html()
      expect(result.indexOf('maxlength="3999"')).not.toBe(-1)

  describe 'view.rowDetail.DetailViewMixins: "default" (default value) html()', ->
    beforeEach ->
      window.xlfHideWarnings = true
      @viewRowDetail = require('../../jsapp/xlform/src/view.rowDetail')
      $model = require('../../jsapp/xlform/src/_model')
      survey = new $model.Survey()
      survey.rows.add(type: 'text', name: 'q1', label: 'Q1')
      @detail = survey.rows.at(0).get('default')
      @mixin = @viewRowDetail.DetailViewMixins.default
      @mixin_ctx = $.extend({}, @mixin, {
        cid: 'cid_def'
        $el: $('<div/>')
        model: @detail
        Templates: @viewRowDetail.Templates
      })
    afterEach ->
      window.xlfHideWarnings = false

    it 'default html() renders a textarea', ->
      result = @mixin_ctx.html()
      expect(result.indexOf('<textarea')).not.toBe(-1)

    it 'default html() renders "Default value" label', ->
      result = @mixin_ctx.html()
      expect(result.indexOf('Default value')).not.toBe(-1)

    it 'default html() sets fieldTab to "active"', ->
      @mixin_ctx.html()
      expect(@mixin_ctx.fieldTab).toBe('active')

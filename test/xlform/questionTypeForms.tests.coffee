{expect} = require('../helper/fauxChai')
$ = require('jquery')

window.t ?= (str) -> str

$model = require('../../jsapp/xlform/src/_model')
$configs = require('../../jsapp/xlform/src/model.configs')

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

buildSurveyRow = (type) ->
  survey = new $model.Survey()
  survey.rows.add(type: type, name: 'q', label: 'Q')
  row = survey.rows.at(0)
  [survey, row]

# Build a minimal mixin context for an appearance DetailView on a row of given type
buildAppearanceMixinCtx = (type) ->
  viewRowDetail = require('../../jsapp/xlform/src/view.rowDetail')
  [survey, row] = buildSurveyRow(type)
  detail = row.get('appearance')
  mixin = viewRowDetail.DetailViewMixins.appearance
  ctx = $.extend({}, mixin, {
    cid: 'cid_app'
    $el: $('<div/>')
    model: detail
    Templates: viewRowDetail.Templates
  })
  ctx

do ->

  ###############################################################
  # Per-type appearance options (getTypes() per question type)
  ###############################################################
  describe 'questionTypeForms: appearance.getTypes() — per question type', ->

    describe 'text', ->
      it 'returns ["multiline"] for text', ->
        ctx = buildAppearanceMixinCtx('text')
        types = ctx.getTypes()
        expect(Array.isArray(types)).toBe(true)
        expect(types.indexOf('multiline')).not.toBe(-1)

    describe 'select_one', ->
      it 'returns appearance options for select_one', ->
        ctx = buildAppearanceMixinCtx('select_one')
        types = ctx.getTypes()
        expect(Array.isArray(types)).toBe(true)
        expect(types.indexOf('minimal')).not.toBe(-1)
        expect(types.indexOf('columns')).not.toBe(-1)
        expect(types.indexOf('likert')).not.toBe(-1)

      it 'includes "image-map" for select_one', ->
        ctx = buildAppearanceMixinCtx('select_one')
        expect(ctx.getTypes().indexOf('image-map')).not.toBe(-1)

      it 'select_one has at least 5 appearance options', ->
        ctx = buildAppearanceMixinCtx('select_one')
        expect(ctx.getTypes().length >= 5).toBe(true)

    describe 'select_multiple', ->
      it 'returns appearance options for select_multiple', ->
        ctx = buildAppearanceMixinCtx('select_multiple')
        types = ctx.getTypes()
        expect(Array.isArray(types)).toBe(true)
        expect(types.indexOf('minimal')).not.toBe(-1)
        expect(types.indexOf('columns')).not.toBe(-1)

      it 'includes "image-map" for select_multiple', ->
        ctx = buildAppearanceMixinCtx('select_multiple')
        expect(ctx.getTypes().indexOf('image-map')).not.toBe(-1)

    describe 'image', ->
      it 'returns appearance options for image', ->
        ctx = buildAppearanceMixinCtx('image')
        types = ctx.getTypes()
        expect(Array.isArray(types)).toBe(true)
        expect(types.indexOf('draw')).not.toBe(-1)
        expect(types.indexOf('annotate')).not.toBe(-1)
        expect(types.indexOf('signature')).not.toBe(-1)

    describe 'date', ->
      it 'returns appearance options for date', ->
        ctx = buildAppearanceMixinCtx('date')
        types = ctx.getTypes()
        expect(Array.isArray(types)).toBe(true)
        expect(types.indexOf('month-year')).not.toBe(-1)
        expect(types.indexOf('year')).not.toBe(-1)

    describe 'integer', ->
      it 'returns appearance options for integer', ->
        ctx = buildAppearanceMixinCtx('integer')
        types = ctx.getTypes()
        expect(Array.isArray(types)).toBe(true)
        expect(types.indexOf('analog-scale horizontal')).not.toBe(-1)
        expect(types.indexOf('analog-scale vertical')).not.toBe(-1)

    describe 'types with no specific appearance options', ->
      noAppTypes = ['decimal', 'note', 'file', 'audio', 'video']
      for qtype in noAppTypes
        do (qtype) ->
          it "#{qtype} getTypes() returns undefined (textbox fallback)", ->
            ctx = buildAppearanceMixinCtx(qtype)
            types = ctx.getTypes()
            expect(types).toBeUndefined()

      it 'calculate getTypes() returns undefined', ->
        ctx = buildAppearanceMixinCtx('calculate')
        types = ctx.getTypes()
        expect(types).toBeUndefined()

  ###############################################################
  # Per-type appearance html() rendering
  ###############################################################
  describe 'questionTypeForms: appearance.html() — uses dropdown where options exist', ->

    it 'text html() renders a dropdown with at least "select" + "multiline"', ->
      ctx = buildAppearanceMixinCtx('text')
      result = ctx.html()
      expect(result.indexOf('<select')).not.toBe(-1)
      expect(result.indexOf('multiline')).not.toBe(-1)

    it 'select_one html() renders a dropdown', ->
      ctx = buildAppearanceMixinCtx('select_one')
      result = ctx.html()
      expect(result.indexOf('<select')).not.toBe(-1)
      expect(result.indexOf('minimal')).not.toBe(-1)

    it 'select_multiple html() renders a dropdown', ->
      ctx = buildAppearanceMixinCtx('select_multiple')
      result = ctx.html()
      expect(result.indexOf('<select')).not.toBe(-1)
      expect(result.indexOf('columns')).not.toBe(-1)

    it 'image html() renders a dropdown with draw, annotate, signature', ->
      ctx = buildAppearanceMixinCtx('image')
      result = ctx.html()
      expect(result.indexOf('<select')).not.toBe(-1)
      expect(result.indexOf('draw')).not.toBe(-1)
      expect(result.indexOf('signature')).not.toBe(-1)

    it 'date html() renders a dropdown with month-year, year', ->
      ctx = buildAppearanceMixinCtx('date')
      result = ctx.html()
      expect(result.indexOf('<select')).not.toBe(-1)
      expect(result.indexOf('month-year')).not.toBe(-1)

    it 'integer html() renders a dropdown with analog-scale options', ->
      ctx = buildAppearanceMixinCtx('integer')
      result = ctx.html()
      expect(result.indexOf('<select')).not.toBe(-1)
      expect(result.indexOf('analog-scale')).not.toBe(-1)

    it 'calculate html() does not render a dropdown (no predefined appearance options)', ->
      ctx = buildAppearanceMixinCtx('calculate')
      result = ctx.html()
      # calculate has no appearance options; html() returns falsy or no <select>
      expect(!result || result.indexOf('<select') == -1).toBe(true)

    it 'decimal html() renders a textbox input (no predefined options)', ->
      ctx = buildAppearanceMixinCtx('decimal')
      result = ctx.html()
      # Falls through to the textbox branch
      expect(result.indexOf('input')).not.toBe(-1)

  ###############################################################
  # Per-type: select_one_from_file_ has extra "filename" field
  ###############################################################
  describe 'questionTypeForms: select_one_from_file — extra filename field', ->
    beforeEach ->
      window.xlfHideWarnings = true
      [@survey, @row] = buildSurveyRow('select_one_from_file')
    afterEach ->
      window.xlfHideWarnings = false

    it 'has a select_one_from_file_filename RowDetail', ->
      expect(@row.get('select_one_from_file_filename')).toBeDefined()

    it 'filename defaults to empty string', ->
      expect(@row.get('select_one_from_file_filename').get('value')).toBe('')

    it 'can set filename value', ->
      @row.get('select_one_from_file_filename').set('value', 'my_list.csv')
      expect(@row.get('select_one_from_file_filename').get('value')).toBe('my_list.csv')

    it 'filename html() renders "External List Filename" label', ->
      viewRowDetail = require('../../jsapp/xlform/src/view.rowDetail')
      detail = @row.get('select_one_from_file_filename')
      mixin = viewRowDetail.DetailViewMixins.select_one_from_file_filename
      mixin_ctx = $.extend({}, mixin, {
        cid: 'cid_fn'
        $el: $('<div/>')
        model: detail
        Templates: viewRowDetail.Templates
      })
      result = mixin_ctx.html()
      expect(result.indexOf('External List Filename')).not.toBe(-1)
      expect(result.indexOf('type="text"')).not.toBe(-1)

    it 'filename appears in toJSON export when set', ->
      @row.get('select_one_from_file_filename').set('value', 'choices.csv')
      result = @survey.toJSON()
      row = result.survey[0]
      expect(row['select_one_from_file_filename']).toBe('choices.csv')

  ###############################################################
  # Per-type: calculate — calculation field is required
  ###############################################################
  describe 'questionTypeForms: calculate — specific field behavior', ->
    beforeEach ->
      window.xlfHideWarnings = true
      [@survey, @row] = buildSurveyRow('calculate')
    afterEach ->
      window.xlfHideWarnings = false

    it 'calculate row has a calculation RowDetail', ->
      expect(@row.get('calculation')).toBeDefined()

    it 'calculation value can be set', ->
      @row.get('calculation').set('value', '1 + 1')
      expect(@row.get('calculation').get('value')).toBe('1 + 1')

    it 'calculation appears in toJSON when set', ->
      @row.get('calculation').set('value', '${a} + ${b}')
      result = @survey.toJSON()
      row = result.survey[0]
      expect(row['calculation']).toBe('${a} + ${b}')

    it 'calculate row also has a trigger RowDetail', ->
      expect(@row.get('trigger')).toBeDefined()

    it 'trigger getOptions() includes "No Trigger" as first option', ->
      viewRowDetail = require('../../jsapp/xlform/src/view.rowDetail')
      detail = @row.get('trigger')
      mixin = viewRowDetail.DetailViewMixins.trigger
      mixin_ctx = $.extend({}, mixin, {
        cid: 'cid_trig'
        $el: $('<div/>')
        model: detail
        rowView: {model: @row}
        Templates: viewRowDetail.Templates
      })
      opts = mixin_ctx.getOptions()
      expect(opts[0].value).toBe('')
      expect(opts[0].text).toBe('No Trigger')

    it 'trigger getOptions() lists other questions as trigger sources', ->
      window.xlfHideWarnings = true
      survey = new $model.Survey()
      survey.rows.add(type: 'text', name: 'prev_q', label: 'Previous Q')
      survey.rows.add(type: 'calculate', name: 'calc_q', label: 'Calc')
      calcRow = survey.rows.at(1)
      calcRow.linkUp(warnings: [], errors: [])
      viewRowDetail = require('../../jsapp/xlform/src/view.rowDetail')
      detail = calcRow.get('trigger')
      mixin = viewRowDetail.DetailViewMixins.trigger
      mixin_ctx = $.extend({}, mixin, {
        cid: 'cid_trig2'
        $el: $('<div/>')
        model: detail
        rowView: {model: calcRow}
        Templates: viewRowDetail.Templates
      })
      opts = mixin_ctx.getOptions()
      # First option is "No Trigger", then prev_q should be listed
      expect(opts.length).toBe(2)
      expect(opts[1].value).toBe('${prev_q}')
      window.xlfHideWarnings = false

  ###############################################################
  # Per-type: note — required is prevented
  ###############################################################
  describe 'questionTypeForms: note — required field behavior', ->
    beforeEach ->
      window.xlfHideWarnings = true
      [@survey, @row] = buildSurveyRow('note')
    afterEach ->
      window.xlfHideWarnings = false

    it 'note type has preventRequired flag in configs', ->
      typeConfig = $configs.lookupRowType('note')
      expect(typeConfig.preventRequired).toBe(true)

    it 'note row still has the required RowDetail (defaults false)', ->
      expect(@row.get('required').get('value')).toBe('false')

  ###############################################################
  # Per-type: media types (image, audio, video, file) — isMedia flag
  ###############################################################
  describe 'questionTypeForms: media types — isMedia flag in configs', ->

    for mediaType in ['image', 'audio', 'video']
      do (mediaType) ->
        it "#{mediaType} has isMedia=true in lookupRowType", ->
          expect($configs.lookupRowType(mediaType).isMedia).toBe(true)

    it 'file does NOT have isMedia in lookupRowType', ->
      expect($configs.lookupRowType('file').isMedia).toBeUndefined()

  ###############################################################
  # Per-type: select_one and select_multiple — orOtherOption flag
  ###############################################################
  describe 'questionTypeForms: select types — orOtherOption flag', ->

    it 'select_one has orOtherOption=true', ->
      expect($configs.lookupRowType('select_one').orOtherOption).toBe(true)

    it 'select_multiple has orOtherOption=true', ->
      expect($configs.lookupRowType('select_multiple').orOtherOption).toBe(true)

    it 'text does not have orOtherOption', ->
      expect($configs.lookupRowType('text').orOtherOption).toBeUndefined()

  ###############################################################
  # All 13 types: full form field checklist
  ###############################################################
  describe 'questionTypeForms: all 13 types have the full set of form fields', ->

    allTypes = [
      'select_one', 'select_multiple', 'text', 'integer',
      'decimal', 'calculate', 'date', 'note',
      'file', 'image', 'audio', 'video', 'select_one_from_file'
    ]

    requiredFields = [
      'name', 'label', 'required', 'readonly', 'appearance',
      'default', 'calculation', 'trigger', 'hint', 'relevant', 'constraint',
      'bind::oc:itemgroup', 'bind::oc:briefdescription',
      'bind::oc:description', 'bind::oc:external'
    ]

    for qtype in allTypes
      do (qtype) ->
        describe "type: #{qtype}", ->
          beforeEach ->
            window.xlfHideWarnings = true
            [@survey, @row] = buildSurveyRow(qtype)
          afterEach ->
            window.xlfHideWarnings = false

          for fieldKey in requiredFields
            do (fieldKey) ->
              it "has '#{fieldKey}' RowDetail", ->
                expect(@row.get(fieldKey)).toBeDefined()

  ###############################################################
  # Per-type: use_external_value (oc_external) — type-gating
  ###############################################################
  describe 'questionTypeForms: oc_external Use External Value — per-type availability', ->

    it 'text type oc_external has contactdata and identifier options', ->
      viewRowDetail = require('../../jsapp/xlform/src/view.rowDetail')
      [survey, row] = buildSurveyRow('text')
      detail = row.get('bind::oc:external')
      mixin = viewRowDetail.DetailViewMixins.oc_external
      mixin_ctx = $.extend({}, mixin, {
        cid: 'cid_ext'
        $el: $('<div/>')
        model: detail
        rowView: {model: row}
        Templates: viewRowDetail.Templates
      })
      opts = mixin_ctx.getOptions()
      expect(opts.indexOf('contactdata')).not.toBe(-1)
      expect(opts.indexOf('identifier')).not.toBe(-1)

    it 'calculate type oc_external has clinicaldata option', ->
      viewRowDetail = require('../../jsapp/xlform/src/view.rowDetail')
      [survey, row] = buildSurveyRow('calculate')
      detail = row.get('bind::oc:external')
      mixin = viewRowDetail.DetailViewMixins.oc_external
      mixin_ctx = $.extend({}, mixin, {
        cid: 'cid_ext2'
        $el: $('<div/>')
        model: detail
        rowView: {model: row}
        Templates: viewRowDetail.Templates
      })
      opts = mixin_ctx.getOptions()
      expect(opts.indexOf('clinicaldata')).not.toBe(-1)

    it 'integer type oc_external getOptions() returns undefined (not applicable)', ->
      viewRowDetail = require('../../jsapp/xlform/src/view.rowDetail')
      [survey, row] = buildSurveyRow('integer')
      detail = row.get('bind::oc:external')
      mixin = viewRowDetail.DetailViewMixins.oc_external
      mixin_ctx = $.extend({}, mixin, {
        cid: 'cid_ext3'
        $el: $('<div/>')
        model: detail
        rowView: {model: row}
        Templates: viewRowDetail.Templates
      })
      opts = mixin_ctx.getOptions()
      expect(opts).toBeUndefined()

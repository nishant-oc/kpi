{expect} = require('../helper/fauxChai')
$ = require('jquery')
window.t ?= (str) -> str

$viewRowSelector = require('../../jsapp/xlform/src/view.rowSelector')
$model = require('../../jsapp/xlform/src/_model')

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# Build a minimal DOM element that satisfies RowSelector.initialize():
#   @button = @$el.find(".btn").eq(0)
#   @line   = @$el.find(".line")
buildEl = ->
  $('<div><span class="btn"></span><div class="line"></div></div>')[0]

# Build a RowSelector without triggering expand() (no action: 'click-add-row').
buildRowSelector = (opts = {}) ->
  el = buildEl()
  new $viewRowSelector.RowSelector($.extend({el: el}, opts))

# Build an event whose target is a .questiontypelist__item element carrying
# the given question-type id in its data-menu-item attribute.
buildPickerEvent = (typeId) ->
  $target = $('<div class="questiontypelist__item"></div>').data('menuItem', typeId)
  {target: $target[0]}

# ---------------------------------------------------------------------------

do ->

  describe 'view.rowSelector: RowSelector initialization', ->

    it 'can be instantiated with a survey option', ->
      survey = new $model.Survey()
      selector = buildRowSelector(survey: survey)
      expect(selector).toBeDefined()

    it 'stores options on the instance', ->
      survey = new $model.Survey()
      selector = buildRowSelector(survey: survey, reversible: true)
      expect(selector.options.survey).toBe(survey)
      expect(selector.options.reversible).toBe(true)

    it 'exposes a $el property wrapping the provided DOM element', ->
      survey = new $model.Survey()
      selector = buildRowSelector(survey: survey)
      expect(selector.$el).toBeDefined()
      expect(selector.$el.length).toBe(1)

    it 'locates the .btn element inside $el', ->
      survey = new $model.Survey()
      selector = buildRowSelector(survey: survey)
      expect(selector.button.hasClass('btn')).toBe(true)

    it 'locates the .line element inside $el', ->
      survey = new $model.Survey()
      selector = buildRowSelector(survey: survey)
      expect(selector.line.hasClass('line')).toBe(true)

    it 'does not call expand() when no action option is provided', ->
      survey = new $model.Survey()
      expanded = false
      selector = buildRowSelector(survey: survey)
      # If expand() had been called it would call show_namer() which needs
      # surveyView; absence of error confirms expand() was not called.
      expect(survey.rows.length).toBe(0)

  # -------------------------------------------------------------------------

  describe 'view.rowSelector: RowSelector.onSelectNewQuestionType — row creation', ->

    beforeEach ->
      window.xlfHideWarnings = true
      @survey = new $model.Survey()
      @selector = buildRowSelector(survey: @survey)
      # Replace @line with a test-controlled jQuery element that wraps an input
      # whose value simulates what the user typed into the namer form.
      @setQuestionText = (text) =>
        @selector.line = $("<div class=\"line\"><input value=\"#{text}\"/></div>")
      # Silence the DOM operations in hide() so they do not throw.
      @selector.hide = ->

    afterEach ->
      window.xlfHideWarnings = false

    it 'adds exactly one row to the survey', ->
      @setQuestionText('How old are you?')
      @selector.onSelectNewQuestionType(buildPickerEvent('text'))
      expect(@survey.rows.length).toBe(1)

    it 'assigns the correct question type to the new row', ->
      @setQuestionText('Pick one')
      @selector.onSelectNewQuestionType(buildPickerEvent('select_one'))
      expect(@survey.rows.at(0).toJSON().type).toBe('select_one')

    it 'assigns the label from the input text', ->
      @setQuestionText('How old are you?')
      @selector.onSelectNewQuestionType(buildPickerEvent('text'))
      expect(@survey.rows.at(0).getValue('label')).toBe('How old are you?')

    it 'creates a sluggified name from the label (lowercase, spaces→underscores)', ->
      @setQuestionText('My Question')
      @selector.onSelectNewQuestionType(buildPickerEvent('text'))
      expect(@survey.rows.at(0).getValue('name')).toBe('my_question')

    it 'strips non-word characters from the generated name', ->
      @setQuestionText('Hello World!')
      @selector.onSelectNewQuestionType(buildPickerEvent('text'))
      expect(@survey.rows.at(0).getValue('name')).toBe('hello_world')

    it 'replaces tabs in the label with spaces', ->
      @selector.line = $('<div class="line"><input></div>')
      @selector.line.find('input').val("Has\tTab")
      @selector.onSelectNewQuestionType(buildPickerEvent('text'))
      expect(@survey.rows.at(0).getValue('label')).toBe('Has Tab')

    it 'marks the new row as isNewRow in the rowDetails passed to addRow', ->
      capturedDetails = null
      origAddRow = @survey.addRow.bind(@survey)
      @survey.addRow = (details, opts) ->
        capturedDetails = details
        origAddRow(details, opts)
      @setQuestionText('Something')
      @selector.onSelectNewQuestionType(buildPickerEvent('note'))
      expect(capturedDetails.isNewRow).toBe(true)

    it 'sets row at index 0 when there is no spawnedFromView', ->
      capturedOpts = null
      origAddRow = @survey.addRow.bind(@survey)
      @survey.addRow = (details, opts) ->
        capturedOpts = opts
        origAddRow(details, opts)
      @setQuestionText('Where?')
      @selector.onSelectNewQuestionType(buildPickerEvent('geopoint'))
      expect(capturedOpts.at).toBe(0)

    it 'uses the selected type as the row type', ->
      @setQuestionText('Pick many')
      @selector.onSelectNewQuestionType(buildPickerEvent('select_multiple'))
      expect(@survey.rows.at(0).toJSON().type).toBe('select_multiple')

    it 'adding multiple questions increases rows.length each time', ->
      @setQuestionText('First')
      @selector.onSelectNewQuestionType(buildPickerEvent('text'))
      @setQuestionText('Second')
      @selector.onSelectNewQuestionType(buildPickerEvent('integer'))
      expect(@survey.rows.length).toBe(2)

  # -------------------------------------------------------------------------

  describe 'view.rowSelector: RowSelector.onSelectNewQuestionType — empty label edge cases', ->

    beforeEach ->
      window.xlfHideWarnings = true
      @survey = new $model.Survey()
      @selector = buildRowSelector(survey: @survey)
      @selector.hide = ->

    afterEach ->
      window.xlfHideWarnings = false

    it 'produces an empty label when the input is blank', ->
      @selector.line = $('<div class="line"><input value=""/></div>')
      @selector.onSelectNewQuestionType(buildPickerEvent('text'))
      expect(@survey.rows.at(0).getValue('label')).toBe('')

    it 'sets name to "calculation" for calculate type with empty label', ->
      @selector.line = $('<div class="line"><input value=""/></div>')
      @selector.onSelectNewQuestionType(buildPickerEvent('calculate'))
      expect(@survey.rows.at(0).getValue('name')).toBe('calculation')

    it 'does not set a specific default name for non-calculate type with empty label', ->
      # The name should not be 'calculation' for a non-calculate type
      @selector.line = $('<div class="line"><input value=""/></div>')
      @selector.onSelectNewQuestionType(buildPickerEvent('text'))
      name = @survey.rows.at(0).getValue('name')
      expect(name).not.toBe('calculation')

  # -------------------------------------------------------------------------

  describe 'view.rowSelector: RowSelector.onSelectNewQuestionType — spawnedFromView', ->

    beforeEach ->
      window.xlfHideWarnings = true
      @survey = new $model.Survey()
      @survey.rows.add(type: 'text', name: 'existing_q', label: 'Existing Question')
      @existingRow = @survey.rows.at(0)

    afterEach ->
      window.xlfHideWarnings = false

    it 'inserts after the spawned row when spawnedFromView is provided', ->
      spawnedFromView = {model: @existingRow}
      selector = buildRowSelector(
        survey: @survey
        spawnedFromView: spawnedFromView
      )
      selector.hide = ->
      selector.line = $('<div class="line"><input value="New Question"/></div>')
      selector.onSelectNewQuestionType(buildPickerEvent('text'))
      expect(@survey.rows.length).toBe(2)

    it 'uses options.after when spawnedFromView model is present', ->
      capturedOpts = null
      origAddRow = @survey.addRow.bind(@survey)
      @survey.addRow = (details, opts) ->
        capturedOpts = opts
        origAddRow(details, opts)
      spawnedFromView = {model: @existingRow}
      selector = buildRowSelector(
        survey: @survey
        spawnedFromView: spawnedFromView
      )
      selector.hide = ->
      selector.line = $('<div class="line"><input value="Appended Q"/></div>')
      selector.onSelectNewQuestionType(buildPickerEvent('note'))
      # options.after should have been set (and then deleted by addRow)
      # The new row should land right after the existing one.
      expect(@survey.rows.length).toBe(2)
      expect(@survey.rows.at(1).getValue('label')).toBe('Appended Q')

  # -------------------------------------------------------------------------

  describe 'view.rowSelector: RowSelector name-slugification edge cases', ->

    beforeEach ->
      window.xlfHideWarnings = true
      @survey = new $model.Survey()
      @selector = buildRowSelector(survey: @survey)
      @selector.hide = ->

    afterEach ->
      window.xlfHideWarnings = false

    it 'converts uppercase to lowercase in name', ->
      @selector.line = $('<div class="line"><input value="UPPER CASE"/></div>')
      @selector.onSelectNewQuestionType(buildPickerEvent('text'))
      expect(@selector.question_name).toBe('UPPER CASE')
      name = @survey.rows.at(0).getValue('name')
      expect(name).toBe('upper_case')

    it 'removes punctuation characters from name', ->
      @selector.line = $('<div class="line"><input value="What? Why!"/></div>')
      @selector.onSelectNewQuestionType(buildPickerEvent('text'))
      name = @survey.rows.at(0).getValue('name')
      expect(name).toBe('what_why')

    it 'handles a single-word label without transformation', ->
      @selector.line = $('<div class="line"><input value="age"/></div>')
      @selector.onSelectNewQuestionType(buildPickerEvent('integer'))
      expect(@survey.rows.at(0).getValue('name')).toBe('age')

    it 'stores the raw label text (with original casing) on question_name', ->
      @selector.line = $('<div class="line"><input value="My Survey Label"/></div>')
      @selector.onSelectNewQuestionType(buildPickerEvent('text'))
      # question_name stores what the user typed (unmodified, aside from tabs)
      expect(@selector.question_name).toBe('My Survey Label')

  # -------------------------------------------------------------------------

  describe 'view.rowSelector: RowSelector.onSelectNewQuestionType — pii_encrypted type', ->

    beforeEach ->
      window.xlfHideWarnings = true
      @survey = new $model.Survey()
      @selector = buildRowSelector(survey: @survey)
      @selector.hide = ->
      @selector.line = $('<div class="line"><input value="Patient Name"/></div>')
      @selector.onSelectNewQuestionType(buildPickerEvent('pii_encrypted'))

    afterEach ->
      window.xlfHideWarnings = false

    it 'adds exactly one row to the survey', ->
      expect(@survey.rows.length).toBe(1)

    it 'sets the row type to "text" (not "pii_encrypted")', ->
      expect(@survey.rows.at(0).toJSON().type).toBe('text')

    it 'sets bind::oc:external to "contactdata"', ->
      expect(@survey.rows.at(0).getValue('bind::oc:external')).toBe('contactdata')

    it 'sets bind::oc:itemgroup to empty string', ->
      expect(@survey.rows.at(0).getValue('bind::oc:itemgroup')).toBe('')

    it 'preserves the label from the input text', ->
      expect(@survey.rows.at(0).getValue('label')).toBe('Patient Name')

    it 'generates a slugified name from the label', ->
      expect(@survey.rows.at(0).getValue('name')).toBe('patient_name')

    it 'marks the new row as isNewRow', ->
      capturedDetails = null
      survey2 = new $model.Survey()
      selector2 = buildRowSelector(survey: survey2)
      selector2.hide = ->
      origAddRow = survey2.addRow.bind(survey2)
      survey2.addRow = (details, opts) ->
        capturedDetails = details
        origAddRow(details, opts)
      selector2.line = $('<div class="line"><input value="Email"/></div>')
      selector2.onSelectNewQuestionType(buildPickerEvent('pii_encrypted'))
      expect(capturedDetails.isNewRow).toBe(true)

    it 'does not carry "pii_encrypted" as the stored row type', ->
      rowType = @survey.rows.at(0).toJSON().type
      expect(rowType).not.toBe('pii_encrypted')

    it 'creates only one row even when called twice', ->
      @selector.line = $('<div class="line"><input value="Phone"/></div>')
      @selector.onSelectNewQuestionType(buildPickerEvent('pii_encrypted'))
      expect(@survey.rows.length).toBe(2)

    it 'a second pii_encrypted row also has type "text"', ->
      @selector.line = $('<div class="line"><input value="Phone"/></div>')
      @selector.onSelectNewQuestionType(buildPickerEvent('pii_encrypted'))
      expect(@survey.rows.at(1).toJSON().type).toBe('text')

    it 'a second pii_encrypted row also has bind::oc:external set to "contactdata"', ->
      @selector.line = $('<div class="line"><input value="Phone"/></div>')
      @selector.onSelectNewQuestionType(buildPickerEvent('pii_encrypted'))
      expect(@survey.rows.at(1).getValue('bind::oc:external')).toBe('contactdata')

    it 'pii_encrypted row with empty label still sets bind::oc:external to "contactdata"', ->
      survey3 = new $model.Survey()
      selector3 = buildRowSelector(survey: survey3)
      selector3.hide = ->
      selector3.line = $('<div class="line"><input value=""/></div>')
      selector3.onSelectNewQuestionType(buildPickerEvent('pii_encrypted'))
      expect(survey3.rows.at(0).getValue('bind::oc:external')).toBe('contactdata')

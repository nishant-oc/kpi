{expect} = require('../helper/fauxChai')

$model = require('../../jsapp/xlform/src/_model')
$configs = require('../../jsapp/xlform/src/model.configs')

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# Build a survey with a single row of the given type and return [survey, row]
buildSurveyWithRow = (type, extraAttrs = {}) ->
  survey = new $model.Survey()
  survey.rows.add($.extend({type: type, name: 'test_q', label: 'Test Question'}, extraAttrs))
  row = survey.rows.at(0)
  [survey, row]

# Get the RowDetail model for a specific key from a row
getDetail = (row, key) ->
  row.get(key)

do ->
  ###############################################################
  # model.base.RowDetail — value initialisation
  ###############################################################
  describe 'model.base.RowDetail: value initialisation', ->
    beforeEach ->
      window.xlfHideWarnings = true
      [@survey, @row] = buildSurveyWithRow('text')
    afterEach ->
      window.xlfHideWarnings = false

    it 'row has a name RowDetail', ->
      expect(getDetail(@row, 'name')).toBeDefined()

    it 'row has a label RowDetail', ->
      expect(getDetail(@row, 'label')).toBeDefined()

    it 'row has a required RowDetail', ->
      expect(getDetail(@row, 'required')).toBeDefined()

    it 'row has a readonly RowDetail', ->
      expect(getDetail(@row, 'readonly')).toBeDefined()

    it 'row has an appearance RowDetail', ->
      expect(getDetail(@row, 'appearance')).toBeDefined()

    it 'row has a default RowDetail', ->
      expect(getDetail(@row, 'default')).toBeDefined()

    it 'row has a calculation RowDetail', ->
      expect(getDetail(@row, 'calculation')).toBeDefined()

    it 'row has a trigger RowDetail', ->
      expect(getDetail(@row, 'trigger')).toBeDefined()

    it 'row has a bind::oc:itemgroup RowDetail (Item Group)', ->
      expect(getDetail(@row, 'bind::oc:itemgroup')).toBeDefined()

    it 'row has a bind::oc:briefdescription RowDetail (Item Brief Description)', ->
      expect(getDetail(@row, 'bind::oc:briefdescription')).toBeDefined()

    it 'row has a bind::oc:description RowDetail (Item Description)', ->
      expect(getDetail(@row, 'bind::oc:description')).toBeDefined()

    it 'row has a bind::oc:external RowDetail (Use External Value)', ->
      expect(getDetail(@row, 'bind::oc:external')).toBeDefined()

    it 'required defaults to "false" for text questions', ->
      expect(getDetail(@row, 'required').get('value')).toBe('false')

    it 'readonly defaults to empty string for text questions', ->
      expect(getDetail(@row, 'readonly').get('value')).toBe('')

    it 'appearance defaults to empty string for text questions', ->
      expect(getDetail(@row, 'appearance').get('value')).toBe('')

    it 'default value defaults to empty string for text questions', ->
      expect(getDetail(@row, 'default').get('value')).toBe('')

    it 'calculation defaults to empty string for text questions', ->
      expect(getDetail(@row, 'calculation').get('value')).toBe('')

    it 'trigger defaults to empty string for text questions', ->
      expect(getDetail(@row, 'trigger').get('value')).toBe('')

    it 'bind::oc:itemgroup defaults to empty string', ->
      expect(getDetail(@row, 'bind::oc:itemgroup').get('value')).toBe('')

    it 'bind::oc:briefdescription defaults to empty string', ->
      expect(getDetail(@row, 'bind::oc:briefdescription').get('value')).toBe('')

    it 'bind::oc:description defaults to empty string', ->
      expect(getDetail(@row, 'bind::oc:description').get('value')).toBe('')

    it 'bind::oc:external defaults to empty string', ->
      expect(getDetail(@row, 'bind::oc:external').get('value')).toBe('')

  ###############################################################
  # model.base.RowDetail — value mutation and change events
  ###############################################################
  describe 'model.base.RowDetail: value mutation', ->
    beforeEach ->
      window.xlfHideWarnings = true
      [@survey, @row] = buildSurveyWithRow('text')
    afterEach ->
      window.xlfHideWarnings = false

    it 'can set Item Name (name) value', ->
      getDetail(@row, 'name').set('value', 'new_item_name')
      expect(getDetail(@row, 'name').get('value')).toBe('new_item_name')

    it 'can set Item Group (bind::oc:itemgroup) value', ->
      getDetail(@row, 'bind::oc:itemgroup').set('value', 'group1')
      expect(getDetail(@row, 'bind::oc:itemgroup').get('value')).toBe('group1')

    it 'can set Item Brief Description value', ->
      getDetail(@row, 'bind::oc:briefdescription').set('value', 'Short title')
      expect(getDetail(@row, 'bind::oc:briefdescription').get('value')).toBe('Short title')

    it 'can set Item Description value', ->
      getDetail(@row, 'bind::oc:description').set('value', 'CDASH definition')
      expect(getDetail(@row, 'bind::oc:description').get('value')).toBe('CDASH definition')

    it 'can set appearance value', ->
      getDetail(@row, 'appearance').set('value', 'multiline')
      expect(getDetail(@row, 'appearance').get('value')).toBe('multiline')

    it 'can set required to "yes" (Always)', ->
      getDetail(@row, 'required').set('value', 'yes')
      expect(getDetail(@row, 'required').get('value')).toBe('yes')

    it 'can set required to "" (Never)', ->
      getDetail(@row, 'required').set('value', '')
      expect(getDetail(@row, 'required').get('value')).toBe('')

    it 'can set readonly to "true" (Yes)', ->
      getDetail(@row, 'readonly').set('value', 'true')
      expect(getDetail(@row, 'readonly').get('value')).toBe('true')

    it 'can set default value', ->
      getDetail(@row, 'default').set('value', 'some default')
      expect(getDetail(@row, 'default').get('value')).toBe('some default')

    it 'can set calculation expression', ->
      getDetail(@row, 'calculation').set('value', '${a} + ${b}')
      expect(getDetail(@row, 'calculation').get('value')).toBe('${a} + ${b}')

    it 'can set trigger value', ->
      getDetail(@row, 'trigger').set('value', '${prev_q}')
      expect(getDetail(@row, 'trigger').get('value')).toBe('${prev_q}')

    it 'can set Use External Value (bind::oc:external)', ->
      getDetail(@row, 'bind::oc:external').set('value', 'clinicaldata')
      expect(getDetail(@row, 'bind::oc:external').get('value')).toBe('clinicaldata')

    it 'getValue() delegates through RowDetail chain', ->
      getDetail(@row, 'bind::oc:itemgroup').set('value', 'mygroup')
      expect(@row.getValue('bind::oc:itemgroup')).toBe('mygroup')

  ###############################################################
  # model.base.RowDetail — getSurvey()
  ###############################################################
  describe 'model.base.RowDetail: getSurvey()', ->
    beforeEach ->
      window.xlfHideWarnings = true
      [@survey, @row] = buildSurveyWithRow('text')
    afterEach ->
      window.xlfHideWarnings = false

    it 'RowDetail.getSurvey() returns the parent survey', ->
      detail = getDetail(@row, 'name')
      expect(detail.getSurvey()).toBe(@survey)

    it 'getSurvey() works for all OC-specific fields', ->
      for key in ['bind::oc:itemgroup', 'bind::oc:briefdescription',
                  'bind::oc:description', 'bind::oc:external']
        expect(getDetail(@row, key).getSurvey()).toBe(@survey)

  ###############################################################
  # model.base.RowDetail — change:value event propagation
  ###############################################################
  describe 'model.base.RowDetail: change event propagation', ->
    beforeEach ->
      window.xlfHideWarnings = true
      [@survey, @row] = buildSurveyWithRow('text')
    afterEach ->
      window.xlfHideWarnings = false

    it 'changing name fires survey change event', ->
      fired = false
      @survey.on 'change', -> fired = true
      getDetail(@row, 'name').set('value', 'fire_test')
      expect(fired).toBe(true)

    it 'changing bind::oc:itemgroup fires survey change event', ->
      fired = false
      @survey.on 'change', -> fired = true
      getDetail(@row, 'bind::oc:itemgroup').set('value', 'fired_group')
      expect(fired).toBe(true)

    it 'changing readonly fires survey change event', ->
      fired = false
      @survey.on 'change', -> fired = true
      getDetail(@row, 'readonly').set('value', 'true')
      expect(fired).toBe(true)

    it 'changing calculation fires survey change event', ->
      fired = false
      @survey.on 'change', -> fired = true
      getDetail(@row, 'calculation').set('value', '1 + 1')
      expect(fired).toBe(true)

    it 'changing trigger fires survey change event', ->
      fired = false
      @survey.on 'change', -> fired = true
      getDetail(@row, 'trigger').set('value', '${q1}')
      expect(fired).toBe(true)

  ###############################################################
  # model.base.RowDetail — toJSON() output (question settings influence export)
  ###############################################################
  describe 'model.base.RowDetail: JSON export reflects field values', ->
    beforeEach ->
      window.xlfHideWarnings = true
    afterEach ->
      window.xlfHideWarnings = false

    it 'Item Name is present in survey JSON export', ->
      survey = new $model.Survey()
      survey.rows.add(type: 'text', name: 'my_q', label: 'My Q')
      result = survey.toJSON()
      expect(result.survey[0]['name']).toBe('my_q')

    it 'readonly "true" appears in survey JSON export', ->
      survey = new $model.Survey()
      survey.rows.add(type: 'text', name: 'q1', label: 'Q1')
      survey.rows.at(0).get('readonly').set('value', 'true')
      result = survey.toJSON()
      row = result.survey[0]
      expect(row['readonly']).toBe('true')

    it 'empty readonly is omitted from survey JSON export', ->
      survey = new $model.Survey()
      survey.rows.add(type: 'text', name: 'q1', label: 'Q1')
      result = survey.toJSON()
      row = result.survey.find((r) -> r.name is 'q1')
      delete row['$kuid']
      expect(row['readonly']).toBeUndefined()

    it 'bind::oc:itemgroup value is included in JSON export when set', ->
      survey = new $model.Survey()
      survey.rows.add(type: 'text', name: 'q1', label: 'Q1')
      survey.rows.at(0).get('bind::oc:itemgroup').set('value', 'datagroup')
      result = survey.toJSON()
      row = result.survey[0]
      expect(row['bind::oc:itemgroup']).toBe('datagroup')

    it 'bind::oc:briefdescription is included when set', ->
      survey = new $model.Survey()
      survey.rows.add(type: 'text', name: 'q1', label: 'Q1')
      survey.rows.at(0).get('bind::oc:briefdescription').set('value', 'Brief title')
      result = survey.toJSON()
      row = result.survey[0]
      expect(row['bind::oc:briefdescription']).toBe('Brief title')

    it 'bind::oc:description is included when set', ->
      survey = new $model.Survey()
      survey.rows.add(type: 'text', name: 'q1', label: 'Q1')
      survey.rows.at(0).get('bind::oc:description').set('value', 'CDASH def')
      result = survey.toJSON()
      row = result.survey[0]
      expect(row['bind::oc:description']).toBe('CDASH def')

    it 'bind::oc:external is included when set', ->
      survey = new $model.Survey()
      survey.rows.add(type: 'text', name: 'q1', label: 'Q1')
      survey.rows.at(0).get('bind::oc:external').set('value', 'contactdata')
      result = survey.toJSON()
      row = result.survey[0]
      expect(row['bind::oc:external']).toBe('contactdata')

    it 'calculation is included when set', ->
      survey = new $model.Survey()
      survey.rows.add(type: 'calculate', name: 'calc_q', label: 'Calc')
      survey.rows.at(0).get('calculation').set('value', '1 + 1')
      result = survey.toJSON()
      row = result.survey[0]
      expect(row['calculation']).toBe('1 + 1')

    it 'trigger is included in JSON export when set', ->
      survey = new $model.Survey()
      survey.rows.add(type: 'calculate', name: 'trig_q', label: 'Trig')
      survey.rows.at(0).get('trigger').set('value', '${prev}')
      result = survey.toJSON()
      row = result.survey[0]
      expect(row['trigger']).toBe('${prev}')

    it 'default value is included when set', ->
      survey = new $model.Survey()
      survey.rows.add(type: 'text', name: 'q1', label: 'Q1')
      survey.rows.at(0).get('default').set('value', 'init_val')
      result = survey.toJSON()
      row = result.survey[0]
      expect(row['default']).toBe('init_val')

  ###############################################################
  # Per question-type: field defaults for each of the 13 types
  ###############################################################
  describe 'model.base.RowDetail: default field values per question type', ->
    beforeEach ->
      window.xlfHideWarnings = true
    afterEach ->
      window.xlfHideWarnings = false

    types = [
      'select_one', 'select_multiple', 'text', 'integer',
      'decimal', 'calculate', 'date', 'note',
      'file', 'image', 'audio', 'video', 'select_one_from_file'
    ]

    for qtype in types
      do (qtype) ->
        describe "type: #{qtype}", ->
          it 'required defaults to "false"', ->
            [survey, row] = buildSurveyWithRow(qtype)
            expect(getDetail(row, 'required').get('value')).toBe('false')

          it 'readonly defaults to ""', ->
            [survey, row] = buildSurveyWithRow(qtype)
            expect(getDetail(row, 'readonly').get('value')).toBe('')

          it 'has a bind::oc:itemgroup detail', ->
            [survey, row] = buildSurveyWithRow(qtype)
            expect(getDetail(row, 'bind::oc:itemgroup')).toBeDefined()

          it 'has a bind::oc:briefdescription detail', ->
            [survey, row] = buildSurveyWithRow(qtype)
            expect(getDetail(row, 'bind::oc:briefdescription')).toBeDefined()

          it 'has a bind::oc:description detail', ->
            [survey, row] = buildSurveyWithRow(qtype)
            expect(getDetail(row, 'bind::oc:description')).toBeDefined()

          it 'has an appearance detail', ->
            [survey, row] = buildSurveyWithRow(qtype)
            expect(getDetail(row, 'appearance')).toBeDefined()

          it 'has a calculation detail', ->
            [survey, row] = buildSurveyWithRow(qtype)
            expect(getDetail(row, 'calculation')).toBeDefined()

          it 'has a trigger detail', ->
            [survey, row] = buildSurveyWithRow(qtype)
            expect(getDetail(row, 'trigger')).toBeDefined()

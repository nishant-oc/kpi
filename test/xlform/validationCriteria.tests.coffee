{expect} = require('../helper/fauxChai')

window.t ?= (str) -> str

$validationLogic = require('../../jsapp/xlform/src/model.rowDetail.validationLogic')
$validationParser = require('../../jsapp/xlform/src/model.validationLogicParser')
$skipLogic = require('../../jsapp/xlform/src/model.rowDetails.skipLogic')
$model = require('../../jsapp/xlform/src/_model')

do ->

  ###############################################################
  # model.rowDetail.validationLogic: ValidationLogic operator serialization
  # Validation logic uses "." (the current question value) instead of ${name}
  ###############################################################
  describe 'validationCriteria: ValidationLogicBasicOperator.serialize()', ->

    it 'serializes equality: . = value', ->
      op = new $validationLogic.ValidationLogicModelFactory(null).create_operator('basic', '=', 2)
      result = op.serialize('', '42')
      expect(result).toBe('. = 42')

    it 'serializes inequality: . != value', ->
      op = new $validationLogic.ValidationLogicModelFactory(null).create_operator('basic', '!=', 2)
      result = op.serialize('', 'no')
      expect(result).toBe('. != no')

    it 'serializes greater-than: . > value', ->
      op = new $validationLogic.ValidationLogicModelFactory(null).create_operator('basic', '>', 3)
      result = op.serialize('', '18')
      expect(result).toBe('. > 18')

    it 'serializes less-than: . < value', ->
      op = new $validationLogic.ValidationLogicModelFactory(null).create_operator('basic', '<', 3)
      result = op.serialize('', '100')
      expect(result).toBe('. < 100')

    it 'serializes >= correctly', ->
      op = new $validationLogic.ValidationLogicModelFactory(null).create_operator('basic', '>=', 4)
      result = op.serialize('', '5')
      expect(result).toBe('. >= 5')

    it 'serializes <= correctly', ->
      op = new $validationLogic.ValidationLogicModelFactory(null).create_operator('basic', '<=', 4)
      result = op.serialize('', '10')
      expect(result).toBe('. <= 10')

  describe 'validationCriteria: ValidationLogicTextOperator.serialize()', ->

    it 'wraps text value in single quotes', ->
      op = new $validationLogic.ValidationLogicModelFactory(null).create_operator('text', '=', 2)
      result = op.serialize('', 'yes')
      expect(result).toBe(". =  'yes'")

    it 'escapes embedded single quotes', ->
      op = new $validationLogic.ValidationLogicModelFactory(null).create_operator('text', '=', 2)
      result = op.serialize('', "it's")
      expect(result).toBe(". =  'it\\'s'")

    it 'works with != for text', ->
      op = new $validationLogic.ValidationLogicModelFactory(null).create_operator('text', '!=', 2)
      result = op.serialize('', 'no')
      expect(result).toBe(". !=  'no'")

  describe 'validationCriteria: ValidationLogicDateOperator.serialize()', ->

    it 'serializes date comparison: . = date_value', ->
      op = new $validationLogic.ValidationLogicModelFactory(null).create_operator('date', '=', 2)
      result = op.serialize('', "date('2024-01-01')")
      expect(result).toBe(". =  date('2024-01-01')")

    it 'works with > operator for date', ->
      op = new $validationLogic.ValidationLogicModelFactory(null).create_operator('date', '>', 3)
      result = op.serialize('', "date('2000-01-01')")
      expect(result).toBe(". >  date('2000-01-01')")

  describe 'validationCriteria: ValidationLogicExistenceOperator.serialize()', ->

    it 'serializes existence check as . != \'\'', ->
      op = new $validationLogic.ValidationLogicModelFactory(null).create_operator('existence', '!=', 1)
      result = op.serialize()
      expect(result).toBe(". != ''")

    it 'serializes non-existence check as . = \'\'', ->
      op = new $validationLogic.ValidationLogicModelFactory(null).create_operator('existence', '=', 1)
      result = op.serialize()
      expect(result).toBe(". = ''")

  describe 'validationCriteria: ValidationLogicSelectMultipleOperator.serialize()', ->

    it 'serializes selected(., \'val\')', ->
      op = new $validationLogic.ValidationLogicModelFactory(null).create_operator('select_multiple', '=', 2)
      result = op.serialize('', 'option_a')
      expect(result).toBe("selected(., 'option_a')")

    it 'wraps in not() when negated', ->
      op = new $validationLogic.ValidationLogicModelFactory(null).create_operator('select_multiple', '!=', 2)
      result = op.serialize('', 'option_a')
      expect(result).toBe("not(selected(., 'option_a'))")

  ###############################################################
  # model.validationLogicParser: parsing validation expressions
  ###############################################################
  describe 'validationCriteria: parser — equality criterion', ->

    it 'parses . = \'value\' as resp_equals', ->
      result = $validationParser(". = 'yes'")
      expect(result.criteria[0].operator).toBe('resp_equals')
      expect(result.criteria[0].response_value).toBe('yes')

    it 'parses . != \'value\' as resp_notequals', ->
      result = $validationParser(". != 'no'")
      expect(result.criteria[0].operator).toBe('resp_notequals')
      expect(result.criteria[0].response_value).toBe('no')

    it 'parses . > integer as resp_greater', ->
      result = $validationParser('. > 18')
      expect(result.criteria[0].operator).toBe('resp_greater')
      expect(result.criteria[0].response_value).toBe('18')

    it 'parses . < integer as resp_less', ->
      result = $validationParser('. < 100')
      expect(result.criteria[0].operator).toBe('resp_less')

    it 'parses . >= integer as resp_greaterequals', ->
      result = $validationParser('. >= 5')
      expect(result.criteria[0].operator).toBe('resp_greaterequals')

    it 'parses . <= integer as resp_lessequals', ->
      result = $validationParser('. <= 3')
      expect(result.criteria[0].operator).toBe('resp_lessequals')

    it 'parses . != \'\' as ans_notnull', ->
      result = $validationParser(". != ''")
      expect(result.criteria[0].operator).toBe('ans_notnull')

    it 'parses . = \'\' as ans_null', ->
      result = $validationParser(". = ''")
      expect(result.criteria[0].operator).toBe('ans_null')

    it 'parses decimal value', ->
      result = $validationParser('. > 3.14')
      expect(result.criteria[0].response_value).toBe('3.14')

    it 'parses date value', ->
      result = $validationParser(". > date('2020-06-15')")
      expect(result.criteria[0].response_value).toBe('2020-06-15')

  describe 'validationCriteria: parser — select_multiple criterion', ->

    it 'parses selected(., \'val\') as multiplechoice_selected', ->
      result = $validationParser("selected(., 'red')")
      expect(result.criteria[0].operator).toBe('multiplechoice_selected')
      expect(result.criteria[0].response_value).toBe('red')

    it 'parses not(selected(.)) as multiplechoice_notselected', ->
      result = $validationParser("not(selected(., 'blue'))")
      expect(result.criteria[0].operator).toBe('multiplechoice_notselected')
      expect(result.criteria[0].response_value).toBe('blue')

  describe 'validationCriteria: parser — compound criteria', ->

    it 'parses two criteria joined by "and"', ->
      result = $validationParser(". > 18 and . < 65")
      expect(result.criteria.length).toBe(2)
      expect(result.operator).toBe('AND')

    it 'parses two criteria joined by "or"', ->
      result = $validationParser(". = '1' or . = '2'")
      expect(result.criteria.length).toBe(2)
      expect(result.operator).toBe('OR')

    it 'throws when mixing and and or', ->
      fn = -> $validationParser(". > 0 and . < 10 or . = 5")
      expect(fn).toThrow()

  ###############################################################
  # RowDetail: "constraint" (validation criteria) on a survey row
  ###############################################################
  describe 'validationCriteria: constraint RowDetail on a survey row', ->
    beforeEach ->
      window.xlfHideWarnings = true
      @survey = new $model.Survey()
      @survey.rows.add(type: 'text', name: 'q1', label: 'Q1')
      @row = @survey.rows.at(0)
      @constraintDetail = @row.get('constraint')
    afterEach ->
      window.xlfHideWarnings = false

    it 'constraint RowDetail exists on a text row', ->
      expect(@constraintDetail).toBeDefined()

    it 'constraint has the ValidationLogicMixin (serialize is a function)', ->
      expect(typeof @constraintDetail.serialize).toBe('function')

    it 'constraint getValue() returns empty string when blank', ->
      @row.linkUp(warnings: [], errors: [])
      expect(@constraintDetail.getValue()).toBe('')

    it 'constraint_message RowDetail also exists', ->
      expect(@row.get('constraint_message')).toBeDefined()

    it 'constraint is defined on all 13 question types', ->
      types = ['select_one', 'select_multiple', 'text', 'integer',
               'decimal', 'calculate', 'date', 'note',
               'file', 'image', 'audio', 'video', 'select_one_from_file']
      for qtype in types
        survey = new $model.Survey()
        survey.rows.add(type: qtype, name: 'q', label: 'Q')
        expect(survey.rows.at(0).get('constraint')).toBeDefined()

  ###############################################################
  # Validation criteria round-trip: CSV load → export
  ###############################################################
  describe 'validationCriteria: round-trip via Survey.load() CSV', ->
    beforeEach ->
      window.xlfHideWarnings = true
    afterEach ->
      window.xlfHideWarnings = false

    it 'preserves an integer range constraint through load→toJSON', ->
      csv = """
        survey,,,
        ,type,name,label,constraint
        ,integer,age,Age,". >= 0 and . <= 120"
        """
      survey = $model.Survey.load(csv)
      result = survey.toJSON()
      ageRow = result.survey.find (r) -> r.name is 'age'
      expect(ageRow).toBeDefined()
      expect(ageRow['constraint']).toBeDefined()

    it 'preserves text equality constraint through load→toJSON', ->
      csv = """
        survey,,,
        ,type,name,label,constraint
        ,text,answer,Answer,". = 'yes'"
        """
      survey = $model.Survey.load(csv)
      result = survey.toJSON()
      row = result.survey.find (r) -> r.name is 'answer'
      expect(row['constraint']).toBeDefined()

    it 'preserves constraint_message through load→toJSON', ->
      csv = """
        survey,,,
        ,type,name,label,constraint,constraint_message
        ,integer,age,Age,". >= 0","Must be non-negative"
        """
      survey = $model.Survey.load(csv)
      result = survey.toJSON()
      ageRow = result.survey.find (r) -> r.name is 'age'
      expect(ageRow['constraint_message']).toBe('Must be non-negative')

    it 'preserves an existence constraint through load→toJSON', ->
      csv = """
        survey,,,
        ,type,name,label,constraint
        ,text,name,Name,". != ''"
        """
      survey = $model.Survey.load(csv)
      result = survey.toJSON()
      row = result.survey.find (r) -> r.name is 'name'
      expect(row['constraint']).toBeDefined()

  ###############################################################
  # ValidationLogicModelFactory: operator type routing
  ###############################################################
  describe 'validationCriteria: ValidationLogicModelFactory operator routing', ->

    factory = new $validationLogic.ValidationLogicModelFactory(null)

    it 'creates a ValidationLogicBasicOperator for "basic" type', ->
      op = factory.create_operator('basic', '=', 2)
      expect(op instanceof $validationLogic.ValidationLogicBasicOperator).toBe(true)

    it 'creates a ValidationLogicTextOperator for "text" type', ->
      op = factory.create_operator('text', '=', 2)
      expect(op instanceof $validationLogic.ValidationLogicTextOperator).toBe(true)

    it 'creates a ValidationLogicDateOperator for "date" type', ->
      op = factory.create_operator('date', '=', 2)
      expect(op instanceof $validationLogic.ValidationLogicDateOperator).toBe(true)

    it 'creates a ValidationLogicExistenceOperator for "existence" type', ->
      op = factory.create_operator('existence', '!=', 1)
      expect(op instanceof $validationLogic.ValidationLogicExistenceOperator).toBe(true)

    it 'creates a ValidationLogicSelectMultipleOperator for "select_multiple" type', ->
      op = factory.create_operator('select_multiple', '=', 2)
      expect(op instanceof $validationLogic.ValidationLogicSelectMultipleOperator).toBe(true)

    it 'creates an EmptyOperator for "empty" type', ->
      op = factory.create_operator('empty', null, 0)
      expect(op instanceof $skipLogic.EmptyOperator).toBe(true)

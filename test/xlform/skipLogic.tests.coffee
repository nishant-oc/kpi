{expect} = require('../helper/fauxChai')

window.t ?= (str) -> str

$skipLogic = require('../../jsapp/xlform/src/model.rowDetails.skipLogic')
$skipLogicParser = require('../../jsapp/xlform/src/model.skipLogicParser')
$skipLogicHelpers = require('../../jsapp/xlform/src/mv.skipLogicHelpers')
$model = require('../../jsapp/xlform/src/_model')

do ->

  ###############################################################
  # model.rowDetails.skipLogic: Operator serialization
  ###############################################################
  describe 'skipLogic: SkipLogicOperator.serialize()', ->

    it 'serializes equality: ${name} = value', ->
      op = new $skipLogic.SkipLogicOperator('=')
      result = op.serialize('my_question', '42')
      expect(result).toBe('${my_question} = 42')

    it 'serializes inequality: ${name} != value', ->
      op = new $skipLogic.SkipLogicOperator('!=')
      result = op.serialize('q1', 'yes')
      expect(result).toBe('${q1} != yes')

    it 'serializes greater-than: ${name} > value', ->
      op = new $skipLogic.SkipLogicOperator('>')
      result = op.serialize('age', '18')
      expect(result).toBe('${age} > 18')

    it 'serializes less-than: ${name} < value', ->
      op = new $skipLogic.SkipLogicOperator('<')
      result = op.serialize('score', '100')
      expect(result).toBe('${score} < 100')

    it 'serializes greater-than-or-equal: ${name} >= value', ->
      op = new $skipLogic.SkipLogicOperator('>=')
      result = op.serialize('count', '5')
      expect(result).toBe('${count} >= 5')

    it 'serializes less-than-or-equal: ${name} <= value', ->
      op = new $skipLogic.SkipLogicOperator('<=')
      result = op.serialize('level', '3')
      expect(result).toBe('${level} <= 3')

    it 'marks != as negated', ->
      op = new $skipLogic.SkipLogicOperator('!=')
      expect(op.get('is_negated')).toBe(true)

    it 'marks = as not negated', ->
      op = new $skipLogic.SkipLogicOperator('=')
      expect(op.get('is_negated')).toBe(false)

    it 'marks > as not negated', ->
      op = new $skipLogic.SkipLogicOperator('>')
      expect(op.get('is_negated')).toBe(false)

    it 'marks < as negated', ->
      op = new $skipLogic.SkipLogicOperator('<')
      expect(op.get('is_negated')).toBe(true)

  describe 'skipLogic: TextOperator.serialize()', ->

    it 'wraps text value in single quotes', ->
      op = new $skipLogic.TextOperator('=')
      result = op.serialize('fname', 'alice')
      expect(result).toBe("${fname} = 'alice'")

    it 'escapes single quotes inside the value', ->
      op = new $skipLogic.TextOperator('=')
      result = op.serialize('note', "it's here")
      expect(result).toBe("${note} = 'it\\'s here'")

    it 'works with != operator', ->
      op = new $skipLogic.TextOperator('!=')
      result = op.serialize('status', 'closed')
      expect(result).toBe("${status} != 'closed'")

  describe 'skipLogic: DateOperator.serialize()', ->

    it 'wraps bare date string in date() function', ->
      op = new $skipLogic.DateOperator('=')
      result = op.serialize('dob', '2000-01-15')
      expect(result).toBe("${dob} = date('2000-01-15')")

    it 'does not double-wrap if already date() formatted', ->
      op = new $skipLogic.DateOperator('=')
      result = op.serialize('dob', "date('2000-01-15')")
      expect(result.indexOf('date(')).not.toBe(-1)
      expect((result.match(/date\(/g) || []).length).toBe(1)

    it 'works with > operator', ->
      op = new $skipLogic.DateOperator('>')
      result = op.serialize('entry_date', '2024-06-01')
      expect(result).toBe("${entry_date} > date('2024-06-01')")

  describe 'skipLogic: ExistenceSkipLogicOperator.serialize()', ->

    it 'serializes was-answered: ${name} != \'\'', ->
      op = new $skipLogic.ExistenceSkipLogicOperator('!=')
      result = op.serialize('q1')
      expect(result).toBe("${q1} != ''")

    it 'serializes was-not-answered: ${name} = \'\'', ->
      op = new $skipLogic.ExistenceSkipLogicOperator('=')
      result = op.serialize('q1')
      expect(result).toBe("${q1} = ''")

    it 'marks = as negated (was NOT answered)', ->
      op = new $skipLogic.ExistenceSkipLogicOperator('=')
      expect(op.get('is_negated')).toBe(true)

    it 'marks != as not negated (was answered)', ->
      op = new $skipLogic.ExistenceSkipLogicOperator('!=')
      expect(op.get('is_negated')).toBe(false)

  describe 'skipLogic: SelectMultipleSkipLogicOperator.serialize()', ->

    it 'serializes selected()', ->
      op = new $skipLogic.SelectMultipleSkipLogicOperator('=')
      result = op.serialize('colours', 'red')
      expect(result).toBe("selected(${colours}, 'red')")

    it 'wraps in not() when negated', ->
      op = new $skipLogic.SelectMultipleSkipLogicOperator('!=')
      result = op.serialize('colours', 'red')
      expect(result).toBe("not(selected(${colours}, 'red'))")

  describe 'skipLogic: EmptyOperator.serialize()', ->

    it 'returns empty string', ->
      op = new $skipLogic.EmptyOperator()
      result = op.serialize()
      expect(result).toBe('')

    it 'has id 0', ->
      op = new $skipLogic.EmptyOperator()
      expect(op.get('id')).toBe(0)

  ###############################################################
  # model.rowDetails.skipLogic: ResponseModel value validation
  ###############################################################
  describe 'skipLogic: IntegerResponseModel', ->

    it 'accepts a valid integer', ->
      m = new $skipLogic.IntegerResponseModel()
      m.set 'type', 'integer'
      m.set_value('42')
      expect(m.get('value')).toBe('42')

    it 'accepts zero', ->
      m = new $skipLogic.IntegerResponseModel()
      m.set 'type', 'integer'
      m.set_value('0')
      expect(m.get('value')).toBe('0')

    it 'accepts negative integers', ->
      m = new $skipLogic.IntegerResponseModel()
      m.set 'type', 'integer'
      m.set_value('-5')
      expect(m.get('value')).toBe('-5')

    it 'set_value with empty string stores undefined', ->
      m = new $skipLogic.IntegerResponseModel()
      m.set 'type', 'integer'
      m.set_value('')
      expect(m.get('value')).toBeUndefined()

  describe 'skipLogic: DecimalResponseModel', ->

    it 'accepts a valid decimal', ->
      m = new $skipLogic.DecimalResponseModel()
      m.set 'type', 'decimal'
      m.set_value('3.14')
      expect(m.get('value')).toBe(3.14)

    it 'accepts a whole number', ->
      m = new $skipLogic.DecimalResponseModel()
      m.set 'type', 'decimal'
      m.set_value(42)
      expect(m.get('value')).toBe(42)

    it 'stores undefined for empty string (backbone validation rejects null)', ->
      m = new $skipLogic.DecimalResponseModel()
      m.set 'type', 'decimal'
      m.set_value('')
      expect(m.get('value')).toBeUndefined()

  ###############################################################
  # model.skipLogicParser: parsing skip logic expressions
  ###############################################################
  describe 'skipLogic: parser — equality criterion', ->

    it 'parses ${q} = \'value\'', ->
      result = $skipLogicParser("${age} = '21'")
      expect(result.criteria[0].name).toBe('age')
      expect(result.criteria[0].operator).toBe('resp_equals')
      expect(result.criteria[0].response_value).toBe('21')

    it 'parses ${q} != \'value\'', ->
      result = $skipLogicParser("${status} != 'closed'")
      expect(result.criteria[0].name).toBe('status')
      expect(result.criteria[0].operator).toBe('resp_notequals')
      expect(result.criteria[0].response_value).toBe('closed')

    it 'parses ${q} > integer', ->
      result = $skipLogicParser('${age} > 18')
      expect(result.criteria[0].name).toBe('age')
      expect(result.criteria[0].operator).toBe('resp_greater')
      expect(result.criteria[0].response_value).toBe('18')

    it 'parses ${q} < integer', ->
      result = $skipLogicParser('${score} < 100')
      expect(result.criteria[0].operator).toBe('resp_less')

    it 'parses ${q} >= integer', ->
      result = $skipLogicParser('${count} >= 5')
      expect(result.criteria[0].operator).toBe('resp_greaterequals')

    it 'parses ${q} <= integer', ->
      result = $skipLogicParser('${level} <= 3')
      expect(result.criteria[0].operator).toBe('resp_lessequals')

    it 'parses ${q} != \'\'  (was answered)', ->
      result = $skipLogicParser("${q1} != ''")
      expect(result.criteria[0].name).toBe('q1')
      expect(result.criteria[0].operator).toBe('ans_notnull')

    it 'parses ${q} = \'\' (was not answered)', ->
      result = $skipLogicParser("${q1} = ''")
      expect(result.criteria[0].operator).toBe('ans_null')

    it 'parses decimal value', ->
      result = $skipLogicParser('${weight} > 3.14')
      expect(result.criteria[0].response_value).toBe('3.14')

    it 'parses date value date(\'yyyy-mm-dd\')', ->
      result = $skipLogicParser("${dob} = date('2000-01-15')")
      expect(result.criteria[0].response_value).toBe('2000-01-15')

  describe 'skipLogic: parser — select_multiple criterion', ->

    it 'parses selected(${q}, \'val\') as multiplechoice_selected', ->
      result = $skipLogicParser("selected(${colours}, 'red')")
      expect(result.criteria[0].name).toBe('colours')
      expect(result.criteria[0].operator).toBe('multiplechoice_selected')
      expect(result.criteria[0].response_value).toBe('red')

    it 'parses not(selected(...)) as multiplechoice_notselected', ->
      result = $skipLogicParser("not(selected(${colours}, 'red'))")
      expect(result.criteria[0].operator).toBe('multiplechoice_notselected')
      expect(result.criteria[0].response_value).toBe('red')

  describe 'skipLogic: parser — compound criteria', ->

    it 'parses two criteria joined by "and"', ->
      result = $skipLogicParser("${age} > 18 and ${status} = 'active'")
      expect(result.criteria.length).toBe(2)
      expect(result.operator).toBe('AND')

    it 'parses two criteria joined by "or"', ->
      result = $skipLogicParser("${q1} = '1' or ${q2} = '2'")
      expect(result.criteria.length).toBe(2)
      expect(result.operator).toBe('OR')

    it 'throws when mixing "and" and "or"', ->
      fn = -> $skipLogicParser("${a} = '1' and ${b} = '2' or ${c} = '3'")
      expect(fn).toThrow()

  ###############################################################
  # mv.skipLogicHelpers: operator_types catalog
  ###############################################################
  describe 'skipLogic: operator_types catalog', ->

    it 'defines 4 operator types', ->
      expect($skipLogicHelpers.operator_types.length).toBe(4)

    it 'operator id=1 is the existence type ("Was Answered")', ->
      op = $skipLogicHelpers.operator_types[0]
      expect(op.id).toBe(1)
      expect(op.type).toBe('existence')
      expect(op.parser_name.indexOf('ans_notnull')).not.toBe(-1)

    it 'operator id=2 is the equality type', ->
      op = $skipLogicHelpers.operator_types[1]
      expect(op.id).toBe(2)
      expect(op.type).toBe('equality')
      expect(op.parser_name.indexOf('resp_equals')).not.toBe(-1)

    it 'operator id=3 is greater-than', ->
      op = $skipLogicHelpers.operator_types[2]
      expect(op.id).toBe(3)
      expect(op.symbol['resp_greater']).toBe('>')
      expect(op.symbol['resp_less']).toBe('<')

    it 'operator id=4 is greater-than-or-equal', ->
      op = $skipLogicHelpers.operator_types[3]
      expect(op.id).toBe(4)
      expect(op.symbol['resp_greaterequals']).toBe('>=')
      expect(op.symbol['resp_lessequals']).toBe('<=')

    it 'existence operator response_type is "empty"', ->
      op = $skipLogicHelpers.operator_types[0]
      expect(op.response_type).toBe('empty')

  ###############################################################
  # mv.skipLogicHelpers: question_types for each of the 13+
  ###############################################################
  describe 'skipLogic: question_types — per-type operator availability', ->

    qt = $skipLogicHelpers.question_types

    it 'text (default) supports EXISTENCE and EQUALITY operators', ->
      ops = qt.default.operators
      expect(ops.indexOf(1)).not.toBe(-1)   # existence
      expect(ops.indexOf(2)).not.toBe(-1)   # equality

    it 'text (default) has equality_operator_type "text"', ->
      expect(qt.default.equality_operator_type).toBe('text')

    it 'text (default) response_type is "text"', ->
      expect(qt.default.response_type).toBe('text')

    it 'select_one supports EQUALITY, EXISTENCE, GT, GE', ->
      ops = qt.select_one.operators
      expect(ops.indexOf(1)).not.toBe(-1)
      expect(ops.indexOf(2)).not.toBe(-1)
      expect(ops.indexOf(3)).not.toBe(-1)
      expect(ops.indexOf(4)).not.toBe(-1)

    it 'select_one response_type is "dropdown"', ->
      expect(qt.select_one.response_type).toBe('dropdown')

    it 'select_multiple supports EQUALITY and EXISTENCE only', ->
      ops = qt.select_multiple.operators
      expect(ops.indexOf(2)).not.toBe(-1)
      expect(ops.indexOf(1)).not.toBe(-1)
      # Must not have GT or GE
      expect(ops.indexOf(3)).toBe(-1)
      expect(ops.indexOf(4)).toBe(-1)

    it 'select_multiple response_type is "dropdown"', ->
      expect(qt.select_multiple.response_type).toBe('dropdown')

    it 'integer supports GT, EXISTENCE, EQUALITY, GE', ->
      ops = qt.integer.operators
      expect(ops.indexOf(1)).not.toBe(-1)
      expect(ops.indexOf(2)).not.toBe(-1)
      expect(ops.indexOf(3)).not.toBe(-1)
      expect(ops.indexOf(4)).not.toBe(-1)

    it 'integer equality_operator_type is "basic"', ->
      expect(qt.integer.equality_operator_type).toBe('basic')

    it 'integer response_type is "integer"', ->
      expect(qt.integer.response_type).toBe('integer')

    it 'decimal supports EXISTENCE, EQUALITY, GT, GE', ->
      ops = qt.decimal.operators
      expect(ops.indexOf(1)).not.toBe(-1)
      expect(ops.indexOf(2)).not.toBe(-1)
      expect(ops.indexOf(3)).not.toBe(-1)

    it 'decimal response_type is "decimal"', ->
      expect(qt.decimal.response_type).toBe('decimal')

    it 'date supports EQUALITY, GT, GE', ->
      ops = qt.date.operators
      expect(ops.indexOf(2)).not.toBe(-1)
      expect(ops.indexOf(3)).not.toBe(-1)
      expect(ops.indexOf(4)).not.toBe(-1)

    it 'date equality_operator_type is "date"', ->
      expect(qt.date.equality_operator_type).toBe('date')

    it 'image supports EXISTENCE only', ->
      ops = qt.image.operators
      expect(ops.length).toBe(1)
      expect(ops[0]).toBe(1)

    it 'audio supports EXISTENCE only', ->
      ops = qt.audio.operators
      expect(ops.length).toBe(1)
      expect(ops[0]).toBe(1)

    it 'video supports EXISTENCE only', ->
      ops = qt.video.operators
      expect(ops.length).toBe(1)
      expect(ops[0]).toBe(1)

    it 'geopoint supports EXISTENCE only', ->
      ops = qt.geopoint.operators
      expect(ops.length).toBe(1)
      expect(ops[0]).toBe(1)

  ###############################################################
  # RowDetail: "relevant" (skip logic) field on a survey row
  ###############################################################
  describe 'skipLogic: relevant RowDetail on a survey row', ->
    beforeEach ->
      window.xlfHideWarnings = true
      @survey = new $model.Survey()
      @survey.rows.add(type: 'text', name: 'q1', label: 'Q1')
      @row = @survey.rows.at(0)
      @relevantDetail = @row.get('relevant')
    afterEach ->
      window.xlfHideWarnings = false

    it 'relevant RowDetail exists on a text row', ->
      expect(@relevantDetail).toBeDefined()

    it 'relevant RowDetail has the SkipLogicDetailMixin (getValue delegates to serialize)', ->
      expect(typeof @relevantDetail.serialize).toBe('function')

    it 'relevant getValue() returns empty string when no criteria set', ->
      @row.linkUp(warnings: [], errors: [])
      expect(@relevantDetail.getValue()).toBe('')

    it 'relevant RowDetail is defined on all 13 question types', ->
      window.xlfHideWarnings = true
      types = ['select_one', 'select_multiple', 'text', 'integer',
               'decimal', 'calculate', 'date', 'note',
               'file', 'image', 'audio', 'video', 'select_one_from_file']
      for qtype in types
        survey = new $model.Survey()
        survey.rows.add(type: qtype, name: 'q', label: 'Q')
        row = survey.rows.at(0)
        expect(row.get('relevant')).toBeDefined()
      window.xlfHideWarnings = false

    it 'relevant RowDetail serializes to empty string before linkUp', ->
      # Before linkUp, facade.context is not yet initialized
      @row.linkUp(warnings: [], errors: [])
      val = @relevantDetail.getValue()
      expect(typeof val).toBe('string')

  ###############################################################
  # SkipLogic round-trip: set relevant on CSV load → export
  ###############################################################
  describe 'skipLogic: round-trip via Survey.load() CSV', ->
    beforeEach ->
      window.xlfHideWarnings = true
    afterEach ->
      window.xlfHideWarnings = false

    it 'preserves a simple equality skip-logic expression through load→toJSON', ->
      csv = """
        survey,,,
        ,type,name,label,relevant
        ,text,q1,Question 1,
        ,text,q2,Question 2,${q1} = 'yes'
        """
      survey = $model.Survey.load(csv)
      result = survey.toJSON()
      q2 = result.survey.find (r) -> r.name is 'q2'
      expect(q2).toBeDefined()
      expect(q2['relevant']).toBe("${q1} = 'yes'")

    it 'preserves an existence skip-logic expression through load→toJSON', ->
      csv = """
        survey,,,
        ,type,name,label,relevant
        ,text,q1,Question 1,
        ,text,q2,Question 2,${q1} != NULL
        """
      survey = $model.Survey.load(csv)
      result = survey.toJSON()
      q2 = result.survey.find (r) -> r.name is 'q2'
      expect(q2['relevant']).toBe("${q1} != NULL")

    it 'preserves a compound and-joined skip-logic expression', ->
      csv = """
        survey,,,
        ,type,name,label,relevant
        ,text,q1,Question 1,
        ,integer,q2,Age,
        ,text,q3,Question 3,"${q1} = 'yes' and ${q2} > 18"
        """
      survey = $model.Survey.load(csv)
      result = survey.toJSON()
      q3 = result.survey.find (r) -> r.name is 'q3'
      expect(q3).toBeDefined()
      expect(q3['relevant']).toBeDefined()

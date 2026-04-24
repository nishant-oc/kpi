{expect} = require('../helper/fauxChai')

$configs = require('../../jsapp/xlform/src/model.configs')

do ->
  ###############################################################
  # model.configs: newRowDetails — the schema for every question field
  ###############################################################
  describe 'model.configs: newRowDetails schema', ->

    it 'defines the name field with empty string default', ->
      expect($configs.newRowDetails['name']).toBeDefined()
      expect($configs.newRowDetails['name'].value).toBe('')

    it 'defines the type field with default "text"', ->
      expect($configs.newRowDetails['type']).toBeDefined()
      expect($configs.newRowDetails['type'].value).toBe('text')

    it 'defines required with default "false"', ->
      expect($configs.newRowDetails['required']).toBeDefined()
      expect($configs.newRowDetails['required'].value).toBe('false')

    it 'defines readonly with empty string default', ->
      expect($configs.newRowDetails['readonly']).toBeDefined()
      expect($configs.newRowDetails['readonly'].value).toBe('')

    it 'defines appearance with empty string default', ->
      expect($configs.newRowDetails['appearance']).toBeDefined()
      expect($configs.newRowDetails['appearance'].value).toBe('')

    it 'defines default with empty string', ->
      expect($configs.newRowDetails['default']).toBeDefined()
      expect($configs.newRowDetails['default'].value).toBe('')

    it 'defines calculation with empty string default', ->
      expect($configs.newRowDetails['calculation']).toBeDefined()
      expect($configs.newRowDetails['calculation'].value).toBe('')

    it 'defines trigger with empty string default', ->
      expect($configs.newRowDetails['trigger']).toBeDefined()
      expect($configs.newRowDetails['trigger'].value).toBe('')

    it 'defines bind::oc:itemgroup (Item Group) with empty string default', ->
      expect($configs.newRowDetails['bind::oc:itemgroup']).toBeDefined()
      expect($configs.newRowDetails['bind::oc:itemgroup'].value).toBe('')

    it 'defines bind::oc:briefdescription (Item Brief Description) with empty string default', ->
      expect($configs.newRowDetails['bind::oc:briefdescription']).toBeDefined()
      expect($configs.newRowDetails['bind::oc:briefdescription'].value).toBe('')

    it 'defines bind::oc:description (Item Description) with empty string default', ->
      expect($configs.newRowDetails['bind::oc:description']).toBeDefined()
      expect($configs.newRowDetails['bind::oc:description'].value).toBe('')

    it 'defines bind::oc:external (Use External Value) with empty string default', ->
      expect($configs.newRowDetails['bind::oc:external']).toBeDefined()
      expect($configs.newRowDetails['bind::oc:external'].value).toBe('')

    it 'defines hint with empty string default', ->
      expect($configs.newRowDetails['hint']).toBeDefined()
      expect($configs.newRowDetails['hint'].value).toBe('')

    it 'defines relevant with empty string default', ->
      expect($configs.newRowDetails['relevant']).toBeDefined()
      expect($configs.newRowDetails['relevant'].value).toBe('')

    it 'defines constraint with empty string default', ->
      expect($configs.newRowDetails['constraint']).toBeDefined()
      expect($configs.newRowDetails['constraint'].value).toBe('')

    it 'defines select_one_from_file_filename with empty string default', ->
      expect($configs.newRowDetails['select_one_from_file_filename']).toBeDefined()
      expect($configs.newRowDetails['select_one_from_file_filename'].value).toBe('')

    it 'required is hidden unless changed (_hideUnlessChanged)', ->
      expect($configs.newRowDetails['required']._hideUnlessChanged).toBe(true)

    it 'appearance is hidden unless changed', ->
      expect($configs.newRowDetails['appearance']._hideUnlessChanged).toBe(true)

    it 'hint is hidden unless changed', ->
      expect($configs.newRowDetails['hint']._hideUnlessChanged).toBe(true)

    it 'bind::oc:itemgroup is NOT hidden unless changed (always visible)', ->
      expect($configs.newRowDetails['bind::oc:itemgroup']._hideUnlessChanged).toBeUndefined()

    it 'readonly is NOT hidden unless changed (always visible)', ->
      expect($configs.newRowDetails['readonly']._hideUnlessChanged).toBeUndefined()

  ###############################################################
  # model.configs: columns — ordered list of XLSForm columns
  ###############################################################
  describe 'model.configs: columns order', ->

    it 'contains "name" column', ->
      expect($configs.columns.indexOf('name')).not.toBe(-1)

    it 'contains "type" column', ->
      expect($configs.columns.indexOf('type')).not.toBe(-1)

    it 'contains "label" column', ->
      expect($configs.columns.indexOf('label')).not.toBe(-1)

    it 'contains "required" column', ->
      expect($configs.columns.indexOf('required')).not.toBe(-1)

    it 'contains "readonly" column', ->
      expect($configs.columns.indexOf('readonly')).not.toBe(-1)

    it 'contains "appearance" column', ->
      expect($configs.columns.indexOf('appearance')).not.toBe(-1)

    it 'contains "default" column', ->
      expect($configs.columns.indexOf('default')).not.toBe(-1)

    it 'contains "calculation" column', ->
      expect($configs.columns.indexOf('calculation')).not.toBe(-1)

    it 'contains "trigger" column', ->
      expect($configs.columns.indexOf('trigger')).not.toBe(-1)

    it 'contains "bind::oc:itemgroup" column', ->
      expect($configs.columns.indexOf('bind::oc:itemgroup')).not.toBe(-1)

    it 'contains "bind::oc:briefdescription" column', ->
      expect($configs.columns.indexOf('bind::oc:briefdescription')).not.toBe(-1)

    it 'contains "bind::oc:description" column', ->
      expect($configs.columns.indexOf('bind::oc:description')).not.toBe(-1)

    it 'contains "bind::oc:external" column', ->
      expect($configs.columns.indexOf('bind::oc:external')).not.toBe(-1)

    it '"name" comes before "type" in the column order', ->
      expect($configs.columns.indexOf('name') < $configs.columns.indexOf('type')).toBe(true)

    it 'columnOrder() returns a numeric index for a known key', ->
      idx = $configs.columnOrder('name')
      expect(typeof idx).toBe('number')
      expect(idx >= 0).toBe(true)

    it 'columnOrder() appends an unknown key and returns its index', ->
      originalColumns = $configs.columns.slice()
      try
        before = $configs.columns.length
        $configs.columnOrder('__brand_new_test_key__')
        after = $configs.columns.length
        expect(after).toBe(before + 1)
      finally
        $configs.columns.length = 0
        for col in originalColumns
          $configs.columns.push(col)

    it 'calling columnOrder() twice for the same key returns the same index', ->
      idx1 = $configs.columnOrder('readonly')
      idx2 = $configs.columnOrder('readonly')
      expect(idx1).toBe(idx2)

  ###############################################################
  # model.configs: lookupRowType
  ###############################################################
  describe 'model.configs: lookupRowType', ->

    it 'resolves "text" type by name', ->
      result = $configs.lookupRowType('text')
      expect(result).toBeDefined()
      expect(result.name).toBe('text')

    it 'resolves "integer" type', ->
      result = $configs.lookupRowType('integer')
      expect(result.name).toBe('integer')

    it 'resolves "select_one" type', ->
      result = $configs.lookupRowType('select_one')
      expect(result.name).toBe('select_one')

    it 'resolves "select_multiple" type', ->
      result = $configs.lookupRowType('select_multiple')
      expect(result.name).toBe('select_multiple')

    it 'resolves "decimal" type', ->
      expect($configs.lookupRowType('decimal').name).toBe('decimal')

    it 'resolves "calculate" type', ->
      expect($configs.lookupRowType('calculate').name).toBe('calculate')

    it 'resolves "date" type', ->
      expect($configs.lookupRowType('date').name).toBe('date')

    it 'resolves "note" type', ->
      expect($configs.lookupRowType('note').name).toBe('note')

    it 'resolves "file" type', ->
      expect($configs.lookupRowType('file').name).toBe('file')

    it 'resolves "image" type', ->
      expect($configs.lookupRowType('image').name).toBe('image')

    it 'resolves "audio" type', ->
      expect($configs.lookupRowType('audio').name).toBe('audio')

    it 'resolves "video" type', ->
      expect($configs.lookupRowType('video').name).toBe('video')

    it 'resolves "select_one_from_file" type', ->
      expect($configs.lookupRowType('select_one_from_file').name).toBe('select_one_from_file')

    it 'note type has preventRequired flag', ->
      result = $configs.lookupRowType('note')
      expect(result.preventRequired).toBe(true)

    it 'select_one type has orOtherOption flag', ->
      result = $configs.lookupRowType('select_one')
      expect(result.orOtherOption).toBe(true)

    it 'image type has isMedia flag', ->
      result = $configs.lookupRowType('image')
      expect(result.isMedia).toBe(true)

    it 'audio type has isMedia flag', ->
      expect($configs.lookupRowType('audio').isMedia).toBe(true)

    it 'video type has isMedia flag', ->
      expect($configs.lookupRowType('video').isMedia).toBe(true)

    it 'file type does not have isMedia flag', ->
      result = $configs.lookupRowType('file')
      expect(result.isMedia).toBeUndefined()

    it 'typeSelectList() returns a non-empty array', ->
      list = $configs.lookupRowType.typeSelectList()
      expect(Array.isArray(list)).toBe(true)
      expect(list.length > 0).toBe(true)

  ###############################################################
  # model.configs: truthyValues / falsyValues / boolOutputs
  ###############################################################
  describe 'model.configs: boolean representations', ->

    it 'truthyValues contains "yes" and "true"', ->
      expect($configs.truthyValues.indexOf('yes')).not.toBe(-1)
      expect($configs.truthyValues.indexOf('true')).not.toBe(-1)

    it 'falsyValues contains "no" and "false"', ->
      expect($configs.falsyValues.indexOf('no')).not.toBe(-1)
      expect($configs.falsyValues.indexOf('false')).not.toBe(-1)

    it 'boolOutputs maps "true" to "true"', ->
      expect($configs.boolOutputs['true']).toBe('true')

    it 'boolOutputs maps "false" to "false"', ->
      expect($configs.boolOutputs['false']).toBe('false')

  ###############################################################
  # model.configs: defaultsForType — type-specific label overrides
  ###############################################################
  describe 'model.configs: defaultsForType', ->

    it 'geopoint has a default label', ->
      expect($configs.defaultsForType.geopoint.label.value).toBeDefined()
      expect($configs.defaultsForType.geopoint.label.value.length > 0).toBe(true)

    it 'geotrace has a default label', ->
      expect($configs.defaultsForType.geotrace.label.value.length > 0).toBe(true)

    it 'geoshape has a default label', ->
      expect($configs.defaultsForType.geoshape.label.value.length > 0).toBe(true)

    it 'note has an empty string default label (no pre-fill)', ->
      expect($configs.defaultsForType.note.label.value).toBe('')

    it 'integer has an empty string default label', ->
      expect($configs.defaultsForType.integer.label.value).toBe('')

    it 'calculate has an empty string default label', ->
      expect($configs.defaultsForType.calculate.label.value).toBe('')

    it 'xml-external has required hidden unless changed', ->
      expect($configs.defaultsForType['xml-external'].required._hideUnlessChanged).toBe(true)

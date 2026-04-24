{expect} = require('../helper/fauxChai')

$icons = require('../../jsapp/xlform/src/view.icons')

do ->
  describe 'view.icons: QtypeIconCollection', ->

    ###
    # Total count
    ###
    describe 'collection size', ->
      it 'has 13 question type icons in total', ->
        # r1(4) + r2(4) + r3(4) + r4(1) = 13
        expect($icons.length).toBe(13)

    ###
    # Per-model attribute presence
    ###
    describe 'each icon model attributes', ->
      it 'has a label attribute', ->
        $icons.each (icon) ->
          expect(icon.get('label')).toBeDefined()

      it 'has an iconClassName attribute', ->
        $icons.each (icon) ->
          expect(icon.get('iconClassName')).toBeDefined()

      it 'has an iconClassNameLocked attribute', ->
        $icons.each (icon) ->
          expect(icon.get('iconClassNameLocked')).toBeDefined()

      it 'has an id attribute', ->
        $icons.each (icon) ->
          expect(icon.get('id')).toBeDefined()

      it 'has a grouping attribute', ->
        $icons.each (icon) ->
          expect(icon.get('grouping')).toBeDefined()

    ###
    # CSS class naming conventions
    ###
    describe 'icon CSS class naming', ->
      it 'iconClassName starts with "k-icon k-icon-"', ->
        $icons.each (icon) ->
          expect(icon.get('iconClassName').indexOf('k-icon k-icon-')).toBe(0)

      it 'iconClassNameLocked ends with "-lock"', ->
        $icons.each (icon) ->
          lockedClass = icon.get('iconClassNameLocked')
          expect(lockedClass.slice(-5)).toBe('-lock')

      it 'iconClassNameLocked is derived from iconClassName', ->
        $icons.each (icon) ->
          base = icon.get('iconClassName')
          locked = icon.get('iconClassNameLocked')
          expect(locked).toBe(base + '-lock')

    ###
    # Grouping rows
    ###
    describe 'icon groupings (rows)', ->
      it 'row r1 contains exactly 4 icons', ->
        r1 = $icons.filter (icon) -> icon.get('grouping') is 'r1'
        expect(r1.length).toBe(4)

      it 'row r2 contains exactly 4 icons', ->
        r2 = $icons.filter (icon) -> icon.get('grouping') is 'r2'
        expect(r2.length).toBe(4)

      it 'row r3 contains exactly 4 icons', ->
        r3 = $icons.filter (icon) -> icon.get('grouping') is 'r3'
        expect(r3.length).toBe(4)

      it 'row r4 contains exactly 1 icon', ->
        r4 = $icons.filter (icon) -> icon.get('grouping') is 'r4'
        expect(r4.length).toBe(1)

    ###
    # Row 1: basic input types
    ###
    describe 'row r1 question types', ->
      it 'includes select_one in r1', ->
        found = $icons.find (icon) ->
          icon.get('id') is 'select_one' and icon.get('grouping') is 'r1'
        expect(found).toBeDefined()

      it 'includes select_multiple in r1', ->
        found = $icons.find (icon) ->
          icon.get('id') is 'select_multiple' and icon.get('grouping') is 'r1'
        expect(found).toBeDefined()

      it 'includes text in r1', ->
        found = $icons.find (icon) ->
          icon.get('id') is 'text' and icon.get('grouping') is 'r1'
        expect(found).toBeDefined()

      it 'includes integer in r1', ->
        found = $icons.find (icon) ->
          icon.get('id') is 'integer' and icon.get('grouping') is 'r1'
        expect(found).toBeDefined()

    ###
    # Row 2: numeric, calculation, date, note
    ###
    describe 'row r2 question types', ->
      it 'includes decimal in r2', ->
        found = $icons.find (icon) ->
          icon.get('id') is 'decimal' and icon.get('grouping') is 'r2'
        expect(found).toBeDefined()

      it 'includes calculate in r2', ->
        found = $icons.find (icon) ->
          icon.get('id') is 'calculate' and icon.get('grouping') is 'r2'
        expect(found).toBeDefined()

      it 'includes date in r2', ->
        found = $icons.find (icon) ->
          icon.get('id') is 'date' and icon.get('grouping') is 'r2'
        expect(found).toBeDefined()

      it 'includes note in r2', ->
        found = $icons.find (icon) ->
          icon.get('id') is 'note' and icon.get('grouping') is 'r2'
        expect(found).toBeDefined()

    ###
    # Row 3: media types
    ###
    describe 'row r3 question types', ->
      it 'includes file in r3', ->
        found = $icons.find (icon) ->
          icon.get('id') is 'file' and icon.get('grouping') is 'r3'
        expect(found).toBeDefined()

      it 'includes image in r3', ->
        found = $icons.find (icon) ->
          icon.get('id') is 'image' and icon.get('grouping') is 'r3'
        expect(found).toBeDefined()

      it 'includes audio in r3', ->
        found = $icons.find (icon) ->
          icon.get('id') is 'audio' and icon.get('grouping') is 'r3'
        expect(found).toBeDefined()

      it 'includes video in r3', ->
        found = $icons.find (icon) ->
          icon.get('id') is 'video' and icon.get('grouping') is 'r3'
        expect(found).toBeDefined()

    ###
    # Row 4: external file types
    ###
    describe 'row r4 question types', ->
      it 'includes select_one_from_file in r4', ->
        found = $icons.find (icon) ->
          icon.get('id') is 'select_one_from_file' and icon.get('grouping') is 'r4'
        expect(found).toBeDefined()

    ###
    # grouped() method
    ###
    describe 'grouped() method', ->
      it 'returns an Array', ->
        groups = $icons.grouped()
        expect(Array.isArray(groups)).toBe(true)

      it 'returns 4 rows matching the 4 groupings (r1-r4)', ->
        groups = $icons.grouped()
        expect(groups.length).toBe(4)

      it 'each row in grouped() is an Array', ->
        groups = $icons.grouped()
        for row in groups
          expect(Array.isArray(row)).toBe(true)

      it 'first row contains the select_one icon', ->
        groups = $icons.grouped()
        firstRow = groups[0].filter (item) -> item?
        ids = firstRow.map (item) -> item.get('id')
        expect(ids.indexOf('select_one')).not.toBe(-1)

      it 'third row (index 2) contains the text icon', ->
        groups = $icons.grouped()
        thirdRow = groups[2].filter (item) -> item?
        ids = thirdRow.map (item) -> item.get('id')
        expect(ids.indexOf('text')).not.toBe(-1)

      it 'returns equal results on repeated calls (internally cached groups)', ->
        groups1 = $icons.grouped()
        groups2 = $icons.grouped()
        expect(groups1).toEqual(groups2)

      it 'total icons across all rows equals collection length', ->
        groups = $icons.grouped()
        total = 0
        for row in groups
          for item in row when item?
            total += 1
        expect(total).toBe($icons.length)

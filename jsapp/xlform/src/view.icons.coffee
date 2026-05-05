_ = require('underscore')
Backbone = require('backbone')
constants = require('../../js/constants')

module.exports = do ->
  _t = require("utils").t

  addIconToRow = (typeDef, group) ->
    iconDetails.push({
      label: typeDef.label,
      iconClassName: "k-icon k-icon-#{typeDef.icon}",
      iconClassNameLocked: "k-icon k-icon-#{typeDef.icon}-lock",
      grouping: group,
      id: typeDef.id
    })
    return

  iconDetails = []
  # row 1
  addIconToRow(constants.QUESTION_TYPES.select_one,  "r1")
  addIconToRow(constants.QUESTION_TYPES.select_multiple, "r1")
  addIconToRow(constants.QUESTION_TYPES.text, "r1")
  addIconToRow(constants.QUESTION_TYPES.integer, "r1")
  # row 2
  addIconToRow(constants.QUESTION_TYPES.decimal, "r2")
  addIconToRow(constants.QUESTION_TYPES.calculate, "r2")
  addIconToRow(constants.QUESTION_TYPES.date, "r2")
  addIconToRow(constants.QUESTION_TYPES.note, "r2")
  # row 3
  addIconToRow(constants.QUESTION_TYPES.file, "r3")
  addIconToRow(constants.QUESTION_TYPES.image, "r3")
  addIconToRow(constants.QUESTION_TYPES.audio, "r3")
  addIconToRow(constants.QUESTION_TYPES.video, "r3")
  # row 4
  addIconToRow(constants.QUESTION_TYPES.select_one_from_file, "r4")
  addIconToRow(constants.QUESTION_TYPES.pii_encrypted, "r4")
  
  class QtypeIcon extends Backbone.Model
    defaults: {
      iconClassname: "k-icon"
    }

  class QtypeIconCollection extends Backbone.Collection
    model: QtypeIcon
    grouped: () ->
      unless @_groups
        @_groups = []
        grp_keys = []
        @each (model) =>
          grping = model.get("grouping")
          grp_keys.push(grping)  unless grping in grp_keys
          ii = grp_keys.indexOf(grping)
          @_groups[ii] or @_groups[ii] = []
          @_groups[ii].push(model)
      _.zip.apply(null, @_groups)

  new QtypeIconCollection(iconDetails)

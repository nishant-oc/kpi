var chai = require('chai');
var expect = chai.expect;

window.jQuery = window.$ = require('jquery');
require('jquery-ui/ui/widgets/sortable');

require('./xlform/aliases.tests');
require('./xlform/choices.tests');
require('./xlform/configs.tests');
require('./xlform/csv.tests');
require('./xlform/deserializer.tests');
require('./xlform/group.tests');
require('./xlform/icons.tests');
require('./xlform/inputParser.tests');
require('./xlform/questionTypeForms.tests');
require('./xlform/rowDetail.tests');
require('./xlform/rowSelector.tests');
require('./xlform/rowSelectorTemplates.tests');
require('./xlform/skipLogic.tests');
require('./xlform/translations.tests');
require('./xlform/validationCriteria.tests');
require('./xlform/viewRowDetail.tests');
// require('./xlform/integration.tests');
require('./xlform/model.tests');
require('./xlform/survey.tests');
require('./xlform/utils.tests');

require('../jsapp/js/utils.tests');
require('../jsapp/js/components/permissions/permParser.tests');
require('../jsapp/js/components/formBuilder/formBuilderUtils.tests');
require('../jsapp/js/assetUtils.tests');
require('../jsapp/js/components/locking/lockingUtils.tests');
require('../jsapp/js/components/submissions/submissionUtils.tests');
require('../jsapp/js/projects/projectViews/utils.tests');
require('../jsapp/js/components/processing/processingUtils.tests');

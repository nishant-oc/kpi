import React from 'react';
import PropTypes from 'prop-types';
import reactMixin from 'react-mixin';
import autoBind from 'react-autobind';
import Reflux from 'reflux';
import DocumentTitle from 'react-document-title';
import Dropzone from 'react-dropzone';
import Select from 'react-select';
import mixins from 'js/mixins';
import bem, {makeBem} from 'js/bem';
import {stores} from 'js/stores';
import {validFileTypes} from 'utils';
import myLibraryStore from './myLibraryStore';
import libraryTypeFilterStore from './libraryTypeFilterStore';
import ownedCollectionsStore from './ownedCollectionsStore';
import AssetsTable from 'js/components/assetsTable/assetsTable';
import {MODAL_TYPES} from 'js/constants';
import {ROOT_BREADCRUMBS} from 'js/components/library/libraryConstants';
import {ASSETS_TABLE_CONTEXTS} from 'js/components/assetsTable/assetsTableConstants';
import { AssetTypeName } from '../../constants';
import './myLibrary.scss';

bem.LibraryActions = makeBem(null, 'library-actions');
bem.LibraryActionsButtons = makeBem(null, 'library-actions-buttons');
bem.LibraryActionsButtons__button = makeBem(bem.LibraryActionsButtons, 'button', 'a');
bem.LibraryTypeFilter = makeBem(null, 'library-type-filter');

const LIBRARY_MANAGEMENT_SUPPORT_URL = 'https://docs.openclinica.com/oc4/help-index/form-designer/library-management/';

class MyLibraryRoute extends React.Component {
  constructor(props) {
    super(props);
    this.state = this.getFreshState();
    this.unlisteners = [];
    autoBind(this);
  }

  getFreshState() {
    return {
      isLoading: myLibraryStore.data.isFetchingData,
      assets: myLibraryStore.data.assets,
      metadata: myLibraryStore.data.metadata,
      totalAssets: myLibraryStore.data.totalSearchAssets,
      orderColumnId: myLibraryStore.data.orderColumnId,
      orderValue: myLibraryStore.data.orderValue,
      filterColumnId: myLibraryStore.data.filterColumnId,
      filterValue: myLibraryStore.data.filterValue,
      currentPage: myLibraryStore.data.currentPage,
      totalPages: myLibraryStore.data.totalPages,
      showAllTags: false,
      typeFilterVal: libraryTypeFilterStore.getFilterType(),
    };
  }

  componentDidMount() {
    this.unlisteners.push(
      myLibraryStore.listen(this.myLibraryStoreChanged),
      ownedCollectionsStore.listen(this.myLibraryStoreChanged)
    );
  }

  componentWillUnmount() {
    this.unlisteners.forEach((clb) => {clb();});
  }

  myLibraryStoreChanged() {
    this.setState(this.getFreshState());
  }

  onAssetsTableOrderChange(orderColumnId, orderValue) {
    myLibraryStore.setOrder(orderColumnId, orderValue);
  }

  onAssetsTableFilterChange(filterColumnId, filterValue) {
    myLibraryStore.setFilter(filterColumnId, filterValue);
  }

  onAssetsTableSwitchPage(pageNumber) {
    myLibraryStore.setCurrentPage(pageNumber);
  }

  clickShowAllTagsToggle () {
    this.setState((prevState) => {
      return {
        showAllTags: !prevState.showAllTags,
      };
    });
  }

  onTypeFilterChange(evt) {
    if (evt.value !== this.state.typeFilterVal) {
      this.setState({
        typeFilterVal: evt,
      });
      libraryTypeFilterStore.setFilterType(evt);
    }
  }

  /**
   * If only one file was passed, then open a modal for selecting the type.
   * Otherwise just start uploading all files.
   */
  onFileDrop(files, rejectedFiles, evt) {
    if (files.length === 1) {
      stores.pageState.switchModal({
        type: MODAL_TYPES.LIBRARY_UPLOAD,
        file: files[0],
      });
    } else {
      this.dropFiles(files, rejectedFiles, evt);
    }
  }

  render() {
    let contextualEmptyMessage = t('Your search returned no results.');

    if (myLibraryStore.data.totalUserAssets === 0) {
      contextualEmptyMessage = (
        <div>
          {t("Let's get started by creating your first library question, block, template or collection. Click the New button to create it.")}
          <div className='pro-tip'>
            {t('Advanced users: You can also drag and drop XLSForms here and they will be uploaded and converted to library items.')}
          </div>
        </div>
      );
    }

    const TYPE_FILTER_OPTIONS = [
      {value: 'all', label: t('Show All')},
      {value: AssetTypeName.question, label: t('Question')},
      {value: AssetTypeName.block, label: t('Block')},
      {value: AssetTypeName.template, label: t('Template')},
    ];

    return (
      <DocumentTitle title={`${t('Library')} | OpenClinica`}>
        <Dropzone
          onDrop={this.onFileDrop}
          disableClick
          multiple
          className='dropzone'
          activeClassName='dropzone--active'
          accept={validFileTypes()}
        >
          <bem.LibraryActions>
            <bem.LibraryActionsButtons
              m={{
                'display-all-tags': this.state.showAllTags,
              }}
            >
              <bem.LibraryActionsButtons__button
                m='library-help-link'
                href={LIBRARY_MANAGEMENT_SUPPORT_URL}
                target='_blank'
                data-tip={t('Learn more about Library Management')}
                >
                <i className='k-icon k-icon-help'/>
              </bem.LibraryActionsButtons__button>
              <bem.LibraryActionsButtons__button
                m='all-tags-toggle'
                onClick={this.clickShowAllTagsToggle}
                data-tip= {this.state.showAllTags ? t('Hide all labels') : t('Show all labels')}
                >
                <i className='k--icon k-icon-tag'/>
              </bem.LibraryActionsButtons__button>
            </bem.LibraryActionsButtons>
            <bem.LibraryTypeFilter>
              {t('Filter by type:')}
              &nbsp;
              <Select
                className='kobo-select'
                classNamePrefix='kobo-select'
                value={this.state.typeFilterVal}
                isClearable={false}
                isSearchable={false}
                options={TYPE_FILTER_OPTIONS}
                onChange={this.onTypeFilterChange}
              />
            </bem.LibraryTypeFilter>
          </bem.LibraryActions>
          <bem.Breadcrumbs m='gray-wrapper'>
            <bem.Breadcrumbs__crumb>
              {ROOT_BREADCRUMBS.MY_LIBRARY.label}
            </bem.Breadcrumbs__crumb>
            {
              myLibraryStore.getCollectionUid() &&
              <React.Fragment>
                <i className='k-icon k-icon-angle-right'/>
                <bem.Breadcrumbs__crumb>
                  {myLibraryStore.getCollectionData()?.name || t('Collection')}
                </bem.Breadcrumbs__crumb>
              </React.Fragment>
            }
          </bem.Breadcrumbs>

          <AssetsTable
            context={ASSETS_TABLE_CONTEXTS.MY_LIBRARY}
            isLoading={this.state.isLoading}
            assets={this.state.assets}
            totalAssets={this.state.totalAssets}
            metadata={this.state.metadata}
            orderColumnId={this.state.orderColumnId}
            orderValue={this.state.orderValue}
            onOrderChange={this.onAssetsTableOrderChange.bind(this)}
            filterColumnId={this.state.filterColumnId}
            filterValue={this.state.filterValue}
            onFilterChange={this.onAssetsTableFilterChange.bind(this)}
            currentPage={this.state.currentPage}
            totalPages={this.state.totalPages}
            onSwitchPage={this.onAssetsTableSwitchPage.bind(this)}
            emptyMessage={contextualEmptyMessage}
            showAllTags={this.state.showAllTags}
          />

          <div className='dropzone-active-overlay'>
            <i className='k-icon k-icon-upload'/>
            {t('Drop files to upload')}
          </div>
        </Dropzone>
      </DocumentTitle>
    );
  }
}

MyLibraryRoute.contextTypes = {
  router: PropTypes.object,
};

reactMixin(MyLibraryRoute.prototype, mixins.droppable);
reactMixin(MyLibraryRoute.prototype, Reflux.ListenerMixin);

export default MyLibraryRoute;

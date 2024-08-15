/* eslint-disable no-console */
import { LightningElement, wire, track, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import LISTVIEW_MC from '@salesforce/messageChannel/SimpliListViewMessageChannel__c';
import { refreshApex } from '@salesforce/apex';
import { subscribe, unsubscribe, publish, APPLICATION_SCOPE, MessageContext } from 'lightning/messageService';
import { encodeDefaultFieldValues } from 'lightning/pageReferenceUtils';
import currentUserId from '@salesforce/user/Id';
import * as SLVHelper from 'c/simpliUIListViewsHelper';


import Rows from '@salesforce/label/c.Rows';
import Selected from '@salesforce/label/c.Selected';
import Select_Action from '@salesforce/label/c.Select_Action';
import Export_All from '@salesforce/label/c.Export_All';
import Export_Selected from '@salesforce/label/c.Export_Selected';
import Loading from '@salesforce/label/c.Loading';
import Select_Object from '@salesforce/label/c.Select_Object';
import Object from '@salesforce/label/c.Object';
import Select_List_View from '@salesforce/label/c.Select_List_View';
import List_View from '@salesforce/label/c.List_View';
import Go_To_Original from '@salesforce/label/c.Go_To_Original';
import Unpin_List_View from '@salesforce/label/c.Unpin_List_View';
import Pin_List_View from '@salesforce/label/c.Pin_List_View';
import Stop_Auto_Refresh from '@salesforce/label/c.Stop_Auto_Refresh';
import Refresh from '@salesforce/label/c.Refresh';
import List_View_Admin from '@salesforce/label/c.List_View_Admin';
import Sort_By from '@salesforce/label/c.Sort_By';
import Save_All_Data from '@salesforce/label/c.Save_All_Data';
import Reset_All_Data from '@salesforce/label/c.Reset_All_Data';
import Save_Row_Data from '@salesforce/label/c.Save_Row_Data';
import Search_List_Dot from '@salesforce/label/c.Search_List_Dot';
import Reset_Row_Data from '@salesforce/label/c.Reset_Row_Data';

import hasModifyAll from '@salesforce/apex/ListViewController.hasModifyAll';
import hasEnterprise from '@salesforce/apex/ListViewController.hasEnterprise';
import getListViewObjects from '@salesforce/apex/ListViewController.getListViewObjects';
import getObjectListViews from '@salesforce/apex/ListViewController.getObjectListViews';
import getListViewData from '@salesforce/apex/ListViewController.getListViewData';
import getListViewActions from '@salesforce/apex/ListViewController.getListViewActions';
import updateAllListViews from '@salesforce/apex/ListViewController.updateAllListViews';
import updateSingleListView from '@salesforce/apex/ListViewController.updateSingleListView';
import updateObjectListViews from '@salesforce/apex/ListViewController.updateObjectListViews';
import getComponentConfig from '@salesforce/apex/ListViewController.getComponentConfig';
import getUserSortConfigs from '@salesforce/apex/ListViewController.getUserSortConfigs';
import updateUserConfig from '@salesforce/apex/ListViewController.updateUserConfig';
import updateUserConfigListViewWidth from '@salesforce/apex/ListViewController.updateUserConfigListViewWidth';
import isValidListViewDataRequest from '@salesforce/apex/ListViewController.isValidListViewDataRequest';
import getListViewId from '@salesforce/apex/ListViewController.getListViewId';
import updateRecord from '@salesforce/apex/ListViewController.updateRecord';
import updateRecords from '@salesforce/apex/ListViewController.updateRecords';
import getListViewConfigParameter from '@salesforce/apex/ListViewController.getListViewConfigParameter';

import { loadScript } from 'lightning/platformResourceLoader';
import JSPDF from '@salesforce/resourceUrl/JSPDF';
import JSPDF_AUTO_TABLE from '@salesforce/resourceUrl/JSPDF_AUTOTABLE';

export default class simpliUIListViews extends NavigationMixin(LightningElement) {

    //-----------
    //API FIELDS
    //-----------
    @api mode = undefined;    //indicates the mode the page is in for displaying the list view. i.e. app, single etc.
    @api virtual = false;        //indicates whether the list view is displaying data virtually from another org.
    @api pageName = '';           //this is NOT the page name but the COMPONENT name
    @api uniqueComponentId = '';           //identifies the component uniquely so that messages can be handled in a multi-component page.
    @api hasMainTitle = undefined;    //indicates whether the component should display the main title
    @api mainTitle = 'List Views'; //the main title of the component.
    @api includedObjects = '';           //indicates the objects that should be included in the list view
    @api excludedObjects = '';           //indicates the objects that should be excluded in the list view.
    @api joinFieldName = '';           //if the component uses data coming in from the message channel this field identifies the lookup field to use that data for.
    @api useMessageChannel = false;        //identifies if the message channel should be used or not. This is used when components should be passing data between each other for updates.
    @api allowRefresh = false;        //config indicating whether the auto refresh checkbox is made available.
    @api singleClickAutoRefresh = undefined;    //whether clicking a single or double time starts the auto refresh.
    @api allowHorizontalScrolling = false;        //config indicating whether horizontal scrolling is available on the list view
    @api allowInlineEditing = false;        //config indicating whether inline editing is available
    @api displayRecordPopovers = false;        //config indicating whether record popovers should be displayed
    @api allowAdmin = false;        //indicates whether the admin button should display to the user
    @api displayActions = false;
    @api typeAheadListSearch = false;        //indicates whether a straight combobox or typeahead text will be used when selecting list views
    @api typeAheadObjectSearch = false;        //indicates whether a straight combobox or typeahead text will be used when selecting objects
    @api displayReprocess = false;        //indicates whether the reprocessing button should be displayed allowing core list views to be reprocessed
    @api displayURL = false;
    @api displayRowCount = false;
    @api noSorting = false;        //indicates whether any sorting should be allowed on the listview
    @api useSimpleSorting = false;        //indicates whether standard sorting should be used.
    @api displaySelectedCount = false;
    @api displayOrigButton;                         //this is not used....deprecated.
    @api displayModified = false;
    @api displayExportButton = false;
    @api displayTextSearch = false;        //identifies whether the text search field should be displayed.
    @api singleListViewObject = '';           //if in SINGLE mode holds the list view object to use.
    @api singleListViewApiName = '';           //if in SINGLE mode holds the list view API name to use.
    @api excludedRecordPopoverTypes = '';           //Indicates those object types for which record detail popovers should not be displayed when the user moves the mouse over the record URL or name.
    @api displayAllRelatedRecords = false;        //Related List View Mode Only: Indicates whether all records should be displayed or scrolling should be used.
    @api objectList = undefined;    //holds the list of objects from which a user can choose one.
    @api listViewList = undefined;    //holds the set of list views for the chosen object

    @api set actionList(value)                      //if in STANDALONE or VIRTUAL mode used when passing actions directly into the component
    {
        this.objectActionList = value;
        if (this.objectActionList !== undefined && this.objectActionList !== '')
            this.handleListViewActions(0);
    }
    get actionList() {
        return this.objectActionList;
    }

    @api columnData; //DEPRECATED
    _rowData;
    @api set rowData(value)                         //if in STANDALONE or VIRTUAL mode used when passing data rows directly into the component
    {
        this.handleStandAloneRowData(value);
    }
    get rowData() {
        return this._rowData;
    }

    @api set recordId(value)                        //used when component on standard record page. Record page injects record id into component.
    {
        this.relatedRecordId = value;
        this.setJoinCriteria(value);
        if (this.mode === 'Related List View') //we could have other moded components inside a record page
            this.isModeRelatedRecord = true;
    }
    get recordId() {
        return this.relatedRecordId;
    }
    @api set singleListViewObject2(value)           //used where orgs are HUGE and singleListViewObject needs to be entered manually.
    {
        this.singleListViewObject = value;
    }
    get singleListViewObject2() {
        return this.singleListViewObject;
    }

    @api set singleListViewApiName2(value)         //used where orgs are HUGE and singleListViewApiName needs to be entered manually.
    {
        this.singleListViewApiName = value;
    }
    get singleListViewApiName2() {
        return this.singleListViewApiName;
    }

    @api set joinCriteria(value) {
        this.setJoinCriteria(value);
    }
    get joinCriteria() {
        return this.joinData;
    }

    @api set canReprocess(value) {
        console.log('canReprocess= ', value);
    }
    get canReprocess() {
        if (SLVHelper.toBool(this.displayReprocess) === true && this.isCoreListView
            || SLVHelper.toBool(this.displayReprocess) === true && this.selectedObject === undefined && this.selectedListView === undefined && this.isInitialized === true) {
            return true;
        }
        return false;
    }

    @api eventRequest(requestData) {
        if (this.hasEnterprise && requestData !== undefined && requestData !== '') {
            console.log('Event request received (' + this.eventCount + ') - ' + JSON.stringify(requestData));
            this.handleEvent(requestData.type, requestData);
        } else {
            console.log('Empty event request');
        }
    }

    //---------------
    //GET FIELDS
    //---------------
    get hasTitle() { return SLVHelper.toBool(this.hasMainTitle); }
    get isNoSorting() { return SLVHelper.toBool(this.noSorting); }

    //---------------
    //TRACKED FIELDS
    //---------------
    @track isCoreListView = false;
    @track isCustomListView = false;

    @track isModeSplitView = false;  //indicates whether the current mode is SPLIT_VIEW
    @track isModeRelatedRecord = false;  //indicates over and above being a related list view whether the page is a RECORD PAGE
    @track isModeRelated = false;  //indicates whether the current mode is RELATED LIST VIEW
    @track isModeSingle = false;  //indicates whether the current mode is SINGLE LIST VIEW
    @track isModeApp = false;  //indicates whether the current mode is APP PAGE
    @track isModeSingleObject = false;  //indicates whether the current mode is SINGLE OBJECT. This displays list views from a single specified object
    @track isModeStandAlone = false;  //indicates whether the current mode is STANDALONE. This indicates that data is passed into the component at initialization

    @track listviewdropdownstyle = 'regularlistviewdropdown';
    @track objectlistdropdownstyle = 'regularobjectlistdropdown';
    @track listwrapperstyle = 'applistscrollwrapper';
    @track tablestyle = 'slds-table slds-table_bordered slds-table_fixed-layout slds-table_resizable-cols tablenohorizontalscroll'; //the style applied to the list view table
    @track relatedRecordId;             //holds the record Id if set by the API.
    @track hasEnterprise = false;  //indicates if the salesforce org has the enterprise edition of SLV
    @track hasModifyAll = false;  //indicates whether the current user is allowed to modify all data.
    @track textSearchText = '';         //holds the current value for text searching.
    @track joinData = '';     //holds the join data coming in from an external list view.....if it exists.
    @track modifiedText;                //holds the last modified text that should be displayed based on the component config
    @track userSortConfigs;             //holds all user sort configuration for this named component.
    @track componentConfig;             //holds all user and org wide configuration for this named component.
    @track selectedListView;            //holds the selected list view name
    @track selectedListViewId;          //holds the id of the selected list view record (used by typeahead only on initialization)
    @track massCreateListView;          //holds the list view to display in the mass create if an alternate list view is provided than the currently displayed list view.
    @track selectedListViewExportName;  //holds the selected list view name + .csv
    @track selectedObject;              //holds the selected object name
    @track listViewListObject = '';     //holds the object that this list view list is associated with. Used for caching.
    @track listViewData;                //holds the set of data returned for a given object and list view.
    @track listViewDataRows;            //holds ALL PAGES of data that are returned.
    @track listViewDataRowsSize;        //holds total for ALL PAGES of data that are returned.
    @track hasListViewDataRows = false; //identifies if the list view has data rows or not.
    @track selectedAction;              //holds the selected action complex object if one is chosen.
    @track selectedActionKey;           //holds the selected action API name if one is chosen.
    @track selectedActionLabel;         //holds the selected action label if one is chosen.
    @track objectActionList;            //holds the (Complex Object) list of available actions for the selected object
    @track displayedActionList = [];    //holds the (Complex Object) list of available actions for the selected object based on the number of selected records
    @track showMassCreateModal;         //indicates whether the mass create action modal form should be displayed.
    @track showEmailTemplateModal;      //indicates whether the email template modal form should be displayed.
    @track emailTemplateFolder;         //indicates the email folder that holds the templates if the action selected has one.
    @track emailTemplateWhatIdField;    //indicates the whatId, if it exists, which will be processed along with the template.
    @track showActionModal;             //indicates whether the action modal form should be displayed.
    @track showFlowModal;               //indicates whether the flow modal form should be displayed.
    @track showAdminModal;              //indicates whether the admin modal form should be displayed.
    @track selectedRecordIdsStr;        //holds the set of record ids that have been selected as a string
    @track selectedRecordIds;           //holds the set of record ids that have been selected
    @track selectedRecordCount = 0;     //the number of records selected. Passed into the modal dialog.  
    @track isPinned = false;            //identifies whether this list view and object have been pinned.
    @track pinnedListView = undefined;  //the list view that is pinned if there is a pinned list view.
    @track pinnedObject = undefined;    //the object that is pinned if there is a pinned list view.
    @track isRefreshing = false;        //identifies whether this list views data is being refreshed AT INTERVALS.
    @track refreshTime = Date.now();    //the timestamp for when the data was refreshed.
    @track spinner = false;             //identifies if the PAGE spinner should be displayed or not.
    @track dataSpinner = false;         //identifies if the DATA spinner should be displayed or not.
    @track firstListViewGet = true;     //indicates whether this is the first time the list views are being retrieved.
    @track canDisplayActions = false;   //indicates whether the page is in a position where the actions list is active
    @track canPin = false;              //indicates whether pinning can occur. Only available for App Page, Single Object List View and Split View.
    @track canDisplayTextSearch = false;//indicates whether text search can occur on this page.
    @track displayObjectNames = false;  //indicates whether the objects drop down can be displayed.
    @track displayListViewNames = false;//indicates whether the list view names drop down can be displayed.
    @track headerCanWrap = false;       //indicates whether the header row can wrap
    @track calloutCount = 1;            //indicates the number of callouts made for this component
    @track eventCount = 0;              //indicates the number of events requested by the enterprise user

    @track showQuickDataModal = false;  //indicates whether the quick data modal should be displayed
    @track quickDataHeading = 'Test Heading';
    @track quickDataFieldType = 'richtext';
    @track quickDataFieldLabel = 'Field Label';
    @track quickDataRowId;
    @track quickDataFieldValue;
    @track quickDataFieldName;
    @track quickDataObjectName;
    @track quickDataComponentId;      //the HTML field name that called the quick data modal. Used to set the focus back on the component
    @track quickDataOldFieldValue;

    @track offset = -1;
    @track rowLimit = -1;
    @track refreshRate = '';                    //the refresh rate in seconds if the list view is auto refreshing.

    //for handling hover changes
    @track hoverSFDCId;
    @track hoverAPIName;
    @track hoverLabelName;
    @track hoverIsDisplayed;
    @track hoverPositionLeft;
    @track hoverPositionTop;
    hoverErrorTypes = '';                    //holds those types for which an error is returned when attempting to create the popover

    //for handling column width changes
    @track mouseStart;
    @track oldWidth;
    @track parentObj;
    @track mouseDownColumn;

    //for handling sorting
    @track listViewSortData = new Map();
    @track columnSortData = new Map();
    @track columnSortDataStr = '';

    //for type-ahead functionality for searching list views
    @track whereClauseListView;
    @track whereClauseObject;

    //for handling edited records
    updatedRowData = new Map();
    rowDataStr = '';

    //for tracking list view init process
    @track isInitialized = true;        //indicates whether the list views have been initialized for the first time or not.
    @track isInitializedCheck = false;  //indicates whether the list views have been initialized BY THE ADMIN
    @track showProgress = false;        //indicates whether the progress bar should be displayed
    @track batchId = '';                //indicates the batch Id of the list view batch process.
    @track isInitializing = true;       //indicates whether we are initializing the page or not.
    @track inRenderedCallback = false;  //indicates whether the rendered callback method is processing

    @track refreshTitle = 'Click to perform full list view refresh';

    //for message channel handlers
    subscription = null;
    receivedMessage;

    label = {
        Rows, Selected, Select_Action, Export_All, Export_Selected, Loading, Select_Object, Object,
        Select_List_View, List_View, Go_To_Original, Unpin_List_View, Pin_List_View, Stop_Auto_Refresh,
        Refresh, List_View_Admin, Sort_By, Save_All_Data, Reset_All_Data, Save_Row_Data, Search_List_Dot,
        Reset_Row_Data
    };

    /*
     * Method which gets called after the class has been instantiated
     * but before it is rendered. We do have access to variables in this method.
     */
    async renderedCallback() {
        if (this.pageName === '') {
            this.dispatchEvent(SLVHelper.createToast('error', '', 'List View Configuration Error', 'A page/component name must be provided for all simpli list view components.', false));
            return;
        }
        console.log('Starting simpliUIListViews.renderedCallback for ' + this.pageName);
        console.log('Record id - ' + this.recordId);

        //this ensures we only call this once for each page load
        if (this.mode !== undefined && this.componentConfig === undefined && this.isInitialized === true && this.inRenderedCallback === false) {
            this.dispatchEvent(new CustomEvent('eventresponse', { detail: { type: 'rendering', status: 'started' } }));

            this.inRenderedCallback = true;

            loadScript(this, JSPDF)
                .then(() => {
                    console.log('then');
                    // load the autotable js file
                    loadScript(this, JSPDF_AUTO_TABLE);
                })
                .catch(error => {
                    console.log('error');
                    throw (error);
                });
            //turn spinner on
            this.spinnerOn('renderedCallback');

            //create unique component Id. Used for sending messages to other components.
            let num = Math.floor(Math.random() * 1000000);
            this.uniqueComponentId = this.pageName + ':' + num.toString();

            //subscribe to message channel
            this.subscribeMC();

            console.log('Component Id created - ' + this.uniqueComponentId);
            console.log('Ltn page name        - ' + this.pageName + ' for ' + this.pageName);
            console.log('Page Mode            - ' + this.mode + ' for ' + this.pageName);
            console.log('User config undefined for ' + this.pageName);

            //get component config
            console.log(this.pageName + ' CALLOUT - getComponentConfig - ' + this.calloutCount++);
            this.componentConfig = await getComponentConfig({ compName: this.pageName });
            this.hasEnterprise = await hasEnterprise({});
            this.hasModifyAll = await hasModifyAll({});

            this.handleComponentConfig();

            //get user sort config
            console.log(this.pageName + ' CALLOUT - getUserSortConfigs - ' + this.calloutCount++);
            this.userSortConfigs = await getUserSortConfigs({ compName: this.pageName });

            this.handleUserSortConfigs();

            this.handleTypeAheadWhereClauses();

            if (this.mode === 'Stand Alone') {
                this.isModeStandAlone = true;
                this.spinnerOff('renderedCallback');

            } else if (this.mode === 'App Page') {
                this.isModeApp = true;
                this.canPin = true;
                this.displayObjectNames = true;
                this.displayListViewNames = true;
                this.getObjectsList();

            } else if (this.mode === 'Single Object List View') {

                if (SLVHelper.isEmpty(this.singleListViewObject)) {
                    this.dispatchEvent(SLVHelper.createToast('error', '', 'Single Object List View Configuration Error', 'If using Single Object List View mode the list view object must be provided.', false));
                    this.spinnerOff('renderedCallback');
                    return;
                }

                this.canPin = true;
                this.isModeSingleObject = true;
                this.displayObjectNames = false;
                this.displayListViewNames = true;

                let event = { detail: { selectedValue: this.singleListViewObject }, target: { value: this.singleListViewObject } }; //faking an event
                this.handleObjectChange(event);
                this.getListViewsForObject();

            } else if (this.mode === 'Single List View') {

                if (this.singleListViewObject === '' || this.singleListViewApiName === '') {
                    this.dispatchEvent(SLVHelper.createToast('error', '', 'Single List View Configuration Error', 'If using Single List View mode the list view object and API name must be provided.', false));
                    this.spinnerOff('renderedCallback');
                    return;
                }

                this.isModeSingle = true;
                this.selectedObject = this.singleListViewObject;
                this.selectedListView = this.singleListViewApiName;

                this.refreshAllListViewData();


            } else if (this.mode === 'Related List View') {

                if (this.singleListViewObject === '' || this.singleListViewApiName === '' || this.joinFieldName === '') {
                    this.dispatchEvent(SLVHelper.createToast('error', '', 'Related List View Configuration Error', 'If using Related List View mode the list view object, list view API name and join field name must be provided.', false));
                    this.spinnerOff('renderedCallback');
                    return;
                }
                this.isModeRelated = true;
                if (this.displayAllRelatedRecords) {
                    this.listwrapperstyle = 'relatedlistdisplayallwrapper';
                } else {
                    this.listwrapperstyle = 'relatedlistscrollwrapper';
                }
                this.selectedObject = this.singleListViewObject;
                this.selectedListView = this.singleListViewApiName;

                if (this.joinData !== '') //only set list view data if there is join data.
                {
                    this.refreshAllListViewData();
                } else {
                    this.isInitializing = false;
                    this.spinnerOff('renderedCallback');
                }

            } else if (this.mode === 'Split View') {

                this.canPin = true;
                this.isModeSplitView = true;
                this.displayListViewNames = true;
                this.headerCanWrap = true;
                this.hasMainTitle = false;
                this.displayRowCount = false;
                this.noSorting = false;
                this.useSimpleSorting = false;
                this.displaySelectedCount = false;
                this.allowInlineEditing = false;
                this.displayTextSearch = false;
                this.canDisplayTextSearch = false;
                this.typeAheadListSearch = false;
                this.typeAheadObjectSearch = false;
                this.displayActions = false;
                this.displayRecordPopovers = false;
                this.allowRefresh = false;
                this.displayURL = false;
                this.displayReprocess = false;
                this.listviewdropdownstyle = 'splitviewlistviewdropdown';
                this.listwrapperstyle = 'splitviewscrollwrapper';
                //NO OBJECT
                if (this.singleListViewObject === '') {
                    this.displayObjectNames = true;
                    this.objectlistdropdownstyle = 'splitviewobjectlistdropdown';
                    await this.getObjectsList();

                    //if we have a pinned list then getting the object will get the list views
                    if (this.selectedListView !== undefined) {
                        this.refreshAllListViewData();
                    } else {
                        this.isInitializing = false;
                        this.spinnerOff('renderedCallback');
                    }

                    //OBJECT EXISTS
                } else {
                    this.selectedObject = this.singleListViewObject;

                    if (this.singleListViewApiName !== '')
                        this.selectedListView = this.singleListViewApiName;

                    //get the object list. Even if we are not displaying the list we get it in case
                    //we have a pinned list view which is handled in getObjectsList()
                    await this.getObjectsList();

                    //if we do not have a pinned list then the list views will not be populated
                    //so populate them.
                    if (this.pinnedObject === undefined)
                        this.getListViewsForObject();

                    //get data if we have object + list view
                    if (this.selectedListView !== undefined) {
                        this.refreshAllListViewData();
                    } else {
                        this.spinnerOff('renderedCallback');
                    }
                }
            }

            this.dispatchEvent(new CustomEvent('eventresponse', { detail: { type: 'rendering', status: 'finished' } }));

        } else {
            console.log('No page initialization needed for ' + this.pageName);
            if (this.virtual) {
                this.spinner = false;
            }
        }
        console.log('Finished renderedCallback for ' + this.pageName);
    }

    handleStandAloneRowData(rows) {
        console.log('Rows - ' + rows);
        if (rows === undefined || rows === '') {
            this.spinnerOff('handleStandAloneRowData(No Data)');
            return;
        }
        console.log('Rows - ' + JSON.stringify(rows));

        if (rows.columns === undefined || rows.data === undefined) {
            this.dispatchEvent(SLVHelper.createToast('error', '', 'StandAlone Component Config Error', 'The row-data property must be set when using standalone mode and must contain both columns and data', false));
        }

        this._columnData = JSON.parse(JSON.stringify(rows.columns)); //make the objects writable
        this._rowData = JSON.parse(JSON.stringify(rows.data));

        this.listViewData = {};
        this.listViewData.isCoreListView = false;
        this.listViewData.isDefaultSort = true;
        this.listViewData.objectName = 'Account';
        this.listViewData.userTimeZone = 'America/Chicago';
        this.listViewData.fieldMetaData = this._columnData;
        this.listViewData.uIColumnCount = this._columnData.length;

        let listview = {};
        listview.defaultSortOrder = '';
        listview.isNonEditable = true;
        listview.lastModifiedBy = '';
        listview.lastModifiedDate = '';
        listview.lastModifiedText = '';
        listview.listViewType = 'Custom';
        listview.offset = -1;
        listview.rowLimit = 10000;
        this.listViewData.listView = listview;

        this.listViewDataRows = this.rowData;
        let index = 1;
        this.listViewDataRows.forEach(row => {
            row.isEdited = false;
            row.isDeleted = false;
            if (SLVHelper.isEmpty(row.sfdcId)) {
                row.sfdcId = index;
            }
            if (row.isDisplayed === undefined) row.isDisplayed = true;
            if (row.isTotals === undefined) row.isTotals = false;
            if (row.highlightColor === undefined) row.highlightColor = '';
            row.salesforceId = row.sfdcId;
            row.rowId = row.sfdcId + ':' + index;
            row.checkBoxId = 'checkbox:' + row.rowId;
            //row.isEditable = true;

            let fieldIndex = 1;
            row.fields.forEach(field => {
                let column = this._columnData[fieldIndex - 1];
                field.label = '';
                field.key = row.rowId + ':' + fieldIndex;
                field.objValueId = row.salesforceId;
                //field.isEditable = true;
                if (field.uIValue === undefined) field.uIValue = field.value;
                field = SLVHelper.setFieldTypes(column.type, field);
                if (field.cssStyle === undefined) field.cssStyle = '';
                if (field.currencyCode === undefined) field.currencyCode = 'USD';
                fieldIndex++;
            });
            index++;
        });

        index = 0;
        this.listViewData.fieldMetaData.forEach(column => {
            if (column.columnWidth !== undefined) column.columnWidth = 'width: ' + column.columnWidth + ';'; //CSS
            if (column.sortDir === undefined) column.sortDir = false;
            if (column.sortIndex === undefined) column.sortIndex = index;
            if (column.sortIndexDisplay === undefined) column.sortIndexDisplay = index + 1;
            if (column.columnIndex === undefined) column.sortIndex = index + 1;
            if (column.sortable === undefined) column.sortable = false;
            if (column.sortingTooltip === undefined) column.sortingTooltip = '';
            index++;
        });


        this.listViewDataRowsSize = this.rowData.length;
        this.hasListViewDataRows = true;

        if (this.virtual) {
            this.listwrapperstyle = 'virtualapplistscrollwrapper';
        }

        this.dispatchEvent(new CustomEvent('eventresponse', { detail: { type: 'standAloneRendering', status: 'finished' } }));

        this.spinnerOff('handleStandAloneRowData');
    }

    handleComponentConfig() {
        try {
            console.log('Component configs retrieved successfully - ' + JSON.stringify(this.componentConfig) + ' size ' + this.componentConfig.length);

            let pinnedListView = this.componentConfig.pinnedListView;
            console.log('Pinned list view string - ' + pinnedListView);

            if (SLVHelper.toBool(this.componentConfig.AllowAdmin) === false) {
                if (this.hasModifyAll === true)
                    this.allowAdmin = true;
                else
                    this.allowAdmin = false;
            }
            if (SLVHelper.toBool(this.componentConfig.TypeAheadListSearch) === true) { this.typeAheadListSearch = true; }
            if (SLVHelper.toBool(this.componentConfig.TypeAheadObjectSearch) === true) { this.typeAheadObjectSearch = true; }
            if (SLVHelper.toBool(this.componentConfig.DisplayActionsButton) === false) { this.displayActions = false; }
            if (SLVHelper.toBool(this.componentConfig.DisplayListViewReprocessingButton) === false) { this.displayReprocess = false; }
            if (SLVHelper.toBool(this.componentConfig.DisplayOriginalListViewButton) === false) { this.displayURL = false; }
            if (SLVHelper.toBool(this.componentConfig.DisplayRowCount) === false) { this.displayRowCount = false; }
            if (SLVHelper.toBool(this.componentConfig.UseSimpleSorting) === true) { this.useSimpleSorting = true; }
            if (SLVHelper.toBool(this.componentConfig.NoSorting) === true) { this.noSorting = true; }
            if (SLVHelper.toBool(this.componentConfig.DisplaySelectedCount) === false) { this.displaySelectedCount = false; }
            if (SLVHelper.toBool(this.componentConfig.DisplayTextSearch) === false) { this.displayTextSearch = false; }
            if (this.displayTextSearch === true) { this.canDisplayTextSearch = true; }
            if (SLVHelper.toBool(this.componentConfig.AllowDataExport) === false) { this.displayExportButton = false; }
            if (SLVHelper.toBool(this.componentConfig.AllowAutomaticDataRefresh) === false) { this.allowRefresh = false; }
            if (SLVHelper.toBool(this.componentConfig.AllowInlineEditing) === false) { this.allowInlineEditing = false; }
            if (SLVHelper.toBool(this.componentConfig.AllowHorizontalScrolling) === false) { this.allowHorizontalScrolling = false; }
            if (SLVHelper.toBool(this.componentConfig.DisplayRecordPopovers) === false) { this.displayRecordPopovers = false; }

            this.excludedRecordPopoverTypes = this.excludedRecordPopoverTypes + this.componentConfig.ExcludedRecordPopoverTypes;

            if (this.allowHorizontalScrolling === true) {
                this.tablestyle = 'slds-table slds-table_bordered slds-table_fixed-layout slds-table_resizable-cols tablehorizontalscroll'; //the style applied to the list view table
            }
            //otherwise if they have a pinned list view then use it, if possible.
            if (pinnedListView !== undefined && pinnedListView !== '') {
                this.isPinned = true;
                this.pinnedObject = pinnedListView.substring(0, pinnedListView.lastIndexOf(':'));
                this.pinnedListView = pinnedListView.substring(pinnedListView.lastIndexOf(':') + 1);

            } else {
                this.isInitializing = false;
            }
        } catch (error) {
            this.dispatchEvent(SLVHelper.createToast('error', error, 'Error Retrieving User Config', 'Error retrieving the user config.', true));
        }
    }

    handleUserSortConfigs() {
        try {
            console.log('User sort configs retrieved successful - ' + this.userSortConfigs + ' for ' + this.pageName);

            const listViewSortFields = JSON.parse(this.userSortConfigs);
            console.log('List view sort fields size - ' + listViewSortFields.listviews.length);

            //EXAMPLE JSON - {"listviews": [{"name": "Account:Simpli_LV_Acct_1","fields": [{"sortIndex": "0", "fieldName": "Name", "sortDirection": "true"},{"sortIndex": "1", "fieldName": "BillingState", "sortDirection": "false"}]}, {"name": "Account:PlatinumandGoldSLACustomers","fields": [{"sortIndex": "0", "fieldName": "Name", "sortDirection": "true"},{"sortIndex": "1", "fieldName": "BillingState", "sortDirection": "false"},{"sortIndex": "2", "fieldName": "Id", "sortDirection": "false"}]}]}
            // eslint-disable-next-line guard-for-in
            for (let m in listViewSortFields.listviews) {

                let listviewSorting = listViewSortFields.listviews[m];
                //if we are working with the current list view
                if (listviewSorting.name === this.pinnedObject + ':' + this.pinnedListView
                    || listviewSorting.name === this.selectedObject + ':' + this.selectedListView
                    || listviewSorting.name === this.singleListViewObject + ':' + this.singleListViewApiName) {
                    console.log('Found sorting for current list view');
                    for (let i = 0; i < listviewSorting.fields.length; i++) {

                        let sortDirection = listviewSorting.fields[i].sortDirection;

                        if (sortDirection === undefined || sortDirection === '') {
                            sortDirection = true;
                        } else {
                            sortDirection = SLVHelper.toBool(sortDirection)
                        }

                        let columnData = [Number(listviewSorting.fields[i].sortIndex), listviewSorting.fields[i].fieldName, sortDirection];
                        this.columnSortData.set(Number(listviewSorting.fields[i].sortIndex), columnData);
                    }

                    this.columnSortDataStr = JSON.stringify(Array.from(this.columnSortData));
                    console.log('XXXX Column Sort Data Str - ' + this.columnSortDataStr);
                    this.listViewSortData.set(listviewSorting.name, this.columnSortData);

                    //for all other list views
                } else {
                    let columnSortData = new Map();

                    for (let index = 0; index < listviewSorting.fields.length; index++) {

                        let sortDirection = listviewSorting.fields[index].sortDirection;

                        if (sortDirection === undefined || sortDirection === '') {
                            sortDirection = true;
                        } else {
                            sortDirection = SLVHelper.toBool(sortDirection)
                        }

                        let columnData = [Number(listviewSorting.fields[index].sortIndex), listviewSorting.fields[index].fieldName, sortDirection];
                        columnSortData.set(Number(listviewSorting.fields[index].sortIndex), columnData);
                    }

                    this.listViewSortData.set(listviewSorting.name, columnSortData);

                }
            }
        } catch (error) {
            this.dispatchEvent(SLVHelper.createToast('error', error, 'Error Retrieving User Sorting', 'Error retrieving the user sorting config.', true));
        }
    }

    createWhereClause(field, operator, values) {
        let whereClause = { field: field, operator: operator, values: values };
        return whereClause;
    }

    handleTypeAheadWhereClauses() {
        if (!SLVHelper.isEmpty(this.includedObjects)) {
            this.whereClauseObject = this.createWhereClause('simpli_lv__Object_Name__c', 'IN', this.includedObjects);
            console.log('whereClauseObject - ' + JSON.stringify(this.whereClauseObject));
        } else if (!SLVHelper.isEmpty(this.excludedObjects)) {
            this.whereClauseObject = this.createWhereClause('simpli_lv__Object_Name__c', 'NOT IN', this.excludedObjects);
            console.log('whereClauseObject - ' + JSON.stringify(this.whereClauseObject));
        }

        if (this.mode === 'Single Object List View' && this.singleListViewObject !== '') {
            this.whereClauseListView = this.createWhereClause('simpli_lv__Object_Name__c', '=', this.selectedObject);
            console.log('whereClauseListView - ' + JSON.stringify(this.whereClauseListView));
        }
    }

    /*
     * Used for handling the message channel
     */
    @wire(MessageContext)
    messageContext;

    handleInitializedCheck(event) {
        try {
            const { detail } = event;
            this.isInitialized = detail;
            this.isInitializedCheck = true;
            if (this.isInitialized === false) {
                this.spinner = false; //a special case where we set it directly.
            }
        } catch (error) {
            SLVHelper.showErrorMessage(error);
        }
    }

    getListViewActions() {
        console.log('Starting getListViewActions');
        if (this.virtual) {
            this.dispatchEvent(new CustomEvent('getactions', { detail: { pageName: this.pageName, compType: this.mode, objectName: this.selectedObject, listViewName: this.selectedListView } }));
        } else {
            console.log(this.pageName + ' CALLOUT - getListViewActions - ' + this.calloutCount++);
            getListViewActions({ objectType: this.selectedObject, listViewName: this.selectedListView, componentName: this.pageName })
                .then(result => {
                    console.log(this.pageName + ' CALLOUT - getListViewActions - ' + this.calloutCount++);
                    this.objectActionList = result;
                    this.handleListViewActions(0);
                    this.dispatchEvent(new CustomEvent('eventresponse', { detail: { type: 'refreshActions', status: 'finished', listView: this.selectedListView, object: this.selectedObject, count: this.displayedActionList.length } }));
                })
                .catch(error => {
                    this.objectActionList = undefined;
                    this.spinnerOff('getObjectsList');
                    this.dispatchEvent(SLVHelper.createToast('error', error, 'Error Retrieving Actions', 'Error retrieving the list view actions.', true));
                });
        }
    }

    handleListViewActions(numSelectedRecords) {
        if (this.objectActionList.length === 0 || this.displayActions === false) {
            this.canDisplayActions = false;
        } else if (SLVHelper.toBool(this.displayActions) === true) {
            this.canDisplayActions = true;

            this.displayedActionList = [];

            this.objectActionList.forEach(action => {
                if (action.selectedRecVisibility === 'Always displayed')
                    this.displayedActionList[this.displayedActionList.length] = action;

                else if (numSelectedRecords === 0) {

                    if (action.selectedRecVisibility === 'Displayed if no records are selected'
                        || action.selectedRecVisibility === 'Displayed if zero or one record is selected')
                        this.displayedActionList[this.displayedActionList.length] = action;

                } else if (numSelectedRecords === 1) {

                    if (action.selectedRecVisibility === 'Displayed if one or more records are selected'
                        || action.selectedRecVisibility === 'Displayed if one record is selected')
                        this.displayedActionList[this.displayedActionList.length] = action;

                } else if (numSelectedRecords > 1) {

                    if (action.selectedRecVisibility === 'Displayed if multiple records are selected'
                        || action.selectedRecVisibility === 'Displayed if one or more records are selected')
                        this.displayedActionList[this.displayedActionList.length] = action;
                }
            });
        }
    }

    async refreshAllListViewData() {
        try {
            this.offset = -1;
            this.selectedRecordCount = 0;
            this.isEdited = false;
            this.hoverIsDisplayed = false;
            let selectedRows = this.template.querySelectorAll('lightning-input');
            if (selectedRows) {
                selectedRows.forEach((element) => { element.checked = false });
            }
            await this.getListViewDataPage();
            await this.getListViewActions();
        } catch (error) {
            SLVHelper.showErrorMessage(error);
        }
    }

    async getListViewDataPage() {
        try {
            console.log(this.pageName + ' CALLOUT - getListViewData(' + this.pageName + ', ' + this.mode + ', ' + this.selectedObject + ', ' + this.selectedListView + ', ' + this.columnSortDataStr + ', ' + this.joinFieldName + ', ' + this.joinData + ', ' + this.offset + ', ' + this.textSearchText + ')');
            if (this.virtual) {
                this.dispatchEvent(new CustomEvent('getdata', { detail: { pageName: this.pageName, compType: this.mode, objectName: this.selectedObject, listViewName: this.selectedListView, sortData: this.columnSortDataStr, joinFieldName: this.joinFieldName, joinData: this.joinData, offset: this.offset, textSearchStr: this.textSearchText } }));
            } else {
                this.spinnerOn('getListViewDataPage');
                this.dispatchEvent(new CustomEvent('eventresponse', { detail: { type: 'refreshData', status: 'started', object: this.selectedObject, listView: this.selectedListView } }));

                let listViewDataResult = await getListViewData({ pageName: this.pageName, compType: this.mode, objectName: this.selectedObject, listViewName: this.selectedListView, sortData: this.columnSortDataStr, joinFieldName: this.joinFieldName, joinData: this.joinData, offset: this.offset, textSearchStr: this.textSearchText });
                this.handleListViewDataPage(listViewDataResult);

                this.dispatchEvent(new CustomEvent('eventresponse', { detail: { type: 'refreshData', status: 'finished', count: this.listViewDataRowsSize, object: this.selectedObject, listView: this.selectedListView } }));
                this.spinnerOff('getListViewDataPage');
            }
        } catch (error) {
            this.dispatchEvent(SLVHelper.createToast('error', error, 'Error Retrieving List View Data', 'Error retrieving the list view data.', true));
            this.spinnerOff('getListViewDataPage');
        }

        this.refreshTime = Date.now();
    }

    handleListViewDataPage(listViewDataResult) {

        console.log('JSON Result - ' + JSON.stringify(listViewDataResult));
        console.log('List View Query - ' + listViewDataResult.queryString);
        console.log('Starting refreshListViewData - ' + this.pageName + ' - ' + this.selectedObject + ' - ' + this.selectedListView + ' - ' + this.joinFieldName + ' - ' + this.offset + ' for ' + this.pageName);

        //if this is the first time we are initializing the list view data OR we are refreshing the data.
        if (this.listViewData === undefined || this.listViewData.coreListId !== listViewDataResult.coreListId || this.offset === -1 || (this.offset === this.listViewData.listView.offset && this.offset === -1)) {
            //initialize list view info
            this.listViewData = listViewDataResult;

            //initialize list view row data
            this.listViewDataRows = listViewDataResult.rows;

            //else add the new data to the existing data
        } else {
            this.listViewDataRows = this.listViewDataRows.concat(listViewDataResult.rows);
        }

        let oldDataRowsSize = this.listViewDataRowsSize;
        //update the data rows size.
        this.listViewDataRowsSize = this.listViewDataRows.length;

        if (this.listViewData.hasTotalsRow) {
            this.listViewDataRowsSize--;
            if (this.isModeSplitView === true)
                this.listViewDataRows.pop();
        }

        if (this.listViewDataRowsSize === 0)
            this.hasListViewDataRows = false;
        else
            this.hasListViewDataRows = true;

        //this is to fix a weird issue where width of table gets reduced if there are no rows.
        if (this.allowHorizontalScrolling === true && this.hasListViewDataRows === true) {
            this.tablestyle = 'slds-table slds-table_bordered slds-table_fixed-layout slds-table_resizable-cols tablehorizontalscroll';
        } else {
            this.tablestyle = 'slds-table slds-table_bordered slds-table_fixed-layout slds-table_resizable-cols tablenohorizontalscroll';
        }


        console.log('this.listViewDataRows.length         - ' + this.listViewDataRows.length + ' for ' + this.pageName);
        console.log('listViewDataResult.listView.rowLimit - ' + listViewDataResult.listView.rowLimit + ' for ' + this.pageName);
        console.log('this.offset                          - ' + this.offset + ' for ' + this.pageName);
        console.log('listViewDataResult.listView.offset   - ' + listViewDataResult.listView.offset + ' for ' + this.pageName);

        //if we have not reached our max limit
        if (this.listViewDataRows.length < listViewDataResult.listView.rowLimit) {
            //if the offset has not changed or the row size has not changed then we are done.
            if (this.offset === listViewDataResult.listView.offset || oldDataRowsSize === this.listViewDataRowsSize) {
                this.dataSpinnerOff();

                //update offset (which will trigger another request for data)
            } else {
                this.dataSpinnerOn();
                this.offset = listViewDataResult.listView.offset;
                this.rowLimit = listViewDataResult.listView.rowLimit;
                this.getListViewDataPage();
            }

            //if we have reached our max limit
        } else {
            this.dataSpinnerOff();
        }

        console.log('List view data retrieval successful - ' + this.offset + ' of ' + this.rowLimit + ' records retrieved for ' + this.pageName);

        //sets the last modified text if the component has been configured to show the data.
        if (this.displayModified === true) {
            this.modifiedText = this.listViewData.listView.lastModifiedText;
        } else {
            this.modifiedText = '';
        }

        if (this.listViewData.listView.listViewType === 'Core') {
            this.isCoreListView = true;
            this.isCustomListView = false;
        } else {
            this.isCoreListView = false;
            this.isCustomListView = true;
        }

        this.displayTextSearch = false;
        if (this.canDisplayTextSearch === true && this.listViewData.canTextSearch === true) {
            this.displayTextSearch = true;
        }

        this.refreshTitle = 'Click to perform list view refresh on current list view';
        this.isInitializing = false;
    }

    async getObjectsList() {
        if (this.objectList === undefined) //only get the list views if we have not retrieved them before
        {
            console.log('Starting getObjectsList');
            console.log(this.pageName + ' CALLOUT - getListViewObjects - ' + this.calloutCount++);
            this.dispatchEvent(new CustomEvent('eventresponse', { detail: { type: 'refreshObjects', status: 'started' } }));
            await getListViewObjects({ includedObjects: this.includedObjects, excludedObjects: this.excludedObjects })
                .then(result => {
                    this.objectList = result;

                    if (this.objectList !== undefined && this.objectList.length > 0) {
                        console.log('Object list has been populated with size - ' + this.objectList.length + ' for ' + this.pageName);

                        if (this.pinnedObject !== undefined) {
                            //check if we have an object that matches the users pinned object. (could be stale)
                            const found = this.objectList.find(element => element.value === this.pinnedObject);

                            //if we do have an object then set it and get the pinned list view.
                            if (found !== undefined) {
                                console.log('Object IS in the object list for ' + this.pageName);
                                this.selectedObject = this.pinnedObject;
                                this.getListViewsForObject();
                            } else {
                                this.spinner = false; //cannot use spinnerOff() here as we might be initializing
                            }
                            this.pinnedObject = undefined;
                        } else if (this.isInitializing === false) {
                            this.spinnerOff('getObjectsList');
                        }

                        this.dispatchEvent(new CustomEvent('eventresponse', { detail: { type: 'refreshObjects', status: 'finished', count: this.objectList.length } }));
                    }
                })
                .catch(error => {
                    this.spinnerOff('getObjectsList');
                    this.dispatchEvent(SLVHelper.createToast('error', error, 'Error Retrieving List View Objects', 'Error retrieving the list view objects.', true));
                });
        }
    }

    async getListViewsForObject() {
        if (this.listViewListObject !== this.selectedObject && this.typeAheadListSearch === false) //only get the list views if its for a new object and we are not doing type ahead
        {
            this.listViewListObject = this.selectedObject;

            console.log(this.pageName + ' CALLOUT - getObjectListViews(' + this.selectedObject + ') - ' + this.calloutCount++);
            this.dispatchEvent(new CustomEvent('eventresponse', { detail: { type: 'refreshListViews', status: 'started', object: this.selectedObject } }));
            await getObjectListViews({ objectName: this.selectedObject })
                .then(result => {
                    console.log('Object list view retrieval successful for ' + this.pageName);
                    this.listViewList = result;
                    console.log('Object list view size - ' + this.listViewList.length + ' for ' + this.pageName);
                    console.log('Pinned list view      - ' + this.pinnedListView + ' for ' + this.pageName);
                    console.log('First List View Get   - ' + this.firstListViewGet + ' for ' + this.pageName);

                    //if we have no list views to display then either the object name is bad or the user does not have access to the object.
                    if (this.listViewList.length === 0) {
                        this.dispatchEvent(SLVHelper.createToast('error', '', 'Error Retrieving Object List Views', 'No list views available as the user does not have access to this object.', false));
                    } else if (this.urlListView !== undefined) {
                        this.selectedListView = this.urlListView;
                        this.selectedListViewExportName = this.selectedListView + '.csv';
                    } else if (this.pinnedListView !== undefined && this.firstListViewGet === true) {

                        console.log('We have a pinned list view for ' + this.pageName);
                        //check if we have the list view in the list. (it could be a stale pinning)
                        const found = this.listViewList.find(element => element.value === this.pinnedListView);

                        //if we have a valid list view name
                        if (found !== undefined) {
                            console.log('Found a list view with the pinned list view name for ' + this.pageName);
                            this.selectedListView = this.pinnedListView;
                            this.selectedListViewExportName = this.selectedListView + '.csv';
                            this.refreshAllListViewData();

                            //if we do not then bail.
                        } else {
                            console.log('Did NOT find a list view with the pinned list view name for ' + this.pageName);
                            this.isInitializing = false;
                        }

                        this.firstListViewGet = false;
                    }

                    this.refreshTitle = 'Click to perform a refresh on all ' + this.selectedObject + ' list views';

                    this.dispatchEvent(new CustomEvent('eventresponse', { detail: { type: 'refreshListViews', status: 'finished', count: this.listViewList.length, object: this.selectedObject } }));

                    this.spinnerOff('getListViewsForObject');
                })
                .catch(error => {
                    this.spinnerOff('getListViewsForObject');
                    this.dispatchEvent(SLVHelper.createToast('error', error, 'Error Retrieving Object List Views', 'Error retrieving ' + this.selectedObject + ' list views data. This usually indicates the user does not have read access to the object. if you believe this to be an error', true));
                });

            //if we
        } else if (this.typeAheadListSearch === true) {

            if (this.pinnedListView !== undefined && this.firstListViewGet === true) {

                console.log('We have a pinned list view for ' + this.pageName);

                //check for list view name validity (it could be a stale pinning)
                await getListViewId({ objectName: this.selectedObject, listViewName: this.pinnedListView })
                    .then(result => {
                        console.log('Is valid list view request successful for ' + this.pageName);

                        //if we have a valid list view name
                        if (result !== '') {
                            console.log('Found a list view with the pinned list view name for ' + this.pageName);
                            this.selectedListView = this.pinnedListView;
                            this.selectedListViewExportName = this.selectedListView + '.csv';
                            this.selectedListViewId = result;
                            this.whereClauseListView = this.createWhereClause('simpli_lv__Object_Name__c', '=', this.selectedObject);
                            this.refreshAllListViewData();

                            //if we do not then bail.
                        } else {
                            console.log('Did NOT find a list view with the pinned list view name for ' + this.pageName);
                            this.isInitializing = false;
                            this.spinner = false;
                        }

                        this.firstListViewGet = false;
                    }).catch(error => {
                        this.spinnerOff('isValidListView');
                        this.dispatchEvent(SLVHelper.createToast('error', error, 'Error Checking For Valid List View', 'Error checking for a valid list view with name ' + this.pinnedListView + ' for object ' + this.selectedObject + '.', true));
                    });

            } else {
                this.refreshTitle = 'Click to perform a refresh on all ' + this.selectedObject + ' list views';

                this.spinnerOff('getListViewsForObject');
            }
        } else {
            this.spinner = false; //cannot use spinnerOff() here as we might be initializing
        }
    }

    /*
     * Method which subscribes this component to a defined message channel. This subscription
     * allows the components to send messages to each other.
     */
    subscribeMC() {
        if (this.subscription) {
            return;
        }
        this.subscription = subscribe(
            this.messageContext,
            LISTVIEW_MC, (message) => {
                this.handleMessage(message);
            },
            { scope: APPLICATION_SCOPE }
        );
    }

    /*
     * Method which unsubscribes this component from any channels. 
     * This method will be called automatically by the SFDC framework.
     */
    unsubscribeMC() {
        unsubscribe(this.subscription);
        this.subscription = null;
    }

    /*
     * called when a component within the same APP as this component sends a message that records
     * have just been selected by that component.
     */
    handleMessage(message) {

        this.receivedMessage = message;
        console.log(this.uniqueComponentId + ' received a message from ' + this.receivedMessage.uniqueComponentId + ' for ' + this.pageName);

        console.log('message recordIds - ' + this.receivedMessage.recordIds);
        console.log('message objectType - ' + this.receivedMessage.objectType);
        console.log('message uniqueComponentId - ' + this.receivedMessage.uniqueComponentId);

        if (this.receivedMessage.uniqueComponentId === this.uniqueComponentId) {
            return;
        }


        if (this.receivedMessage.type === 'selectrecordupdate') {

            //if we have no record Id and its a NON-RECORD page RELATED LIST then set rows to 0
            if (this.receivedMessage.recordIds === ''
                && this.isModeRelated === true
                && this.isModeRelatedRecord === false) {
                this.hasListViewDataRows = false;
                return;
            } else if (this.receivedMessage.recordIds === ''
                && this.isModeSingle === true) {
                this.hasListViewDataRows = false;
                return;
            }

            console.log('selectedObject - ' + this.selectedObject);
            console.log('isModeRelatedRecord - ' + this.isModeRelatedRecord);
            console.log('joinFieldName - ' + this.joinFieldName);
            //if we have a list view selected AND if we have selected a specific list view to update
            if (this.selectedObject !== undefined
                && this.joinFieldName !== undefined
                && this.joinFieldName !== ''
                && this.isModeRelatedRecord === false) {
                console.log('We have a joined field name - ' + this.joinFieldName + ' for ' + this.pageName);
                console.log('Record ids from message - ' + this.receivedMessage.recordIds + ' for ' + this.pageName);
                this.joinData = JSON.stringify(message);
                console.log('Join Data JSON - ' + this.joinData + ' for ' + this.pageName);

                this.spinnerOn('handleMessage');

                if (!this.virtual) {
                    //we need to check and see if this message is valid for this component.
                    //I think we need to get rid of this.......causes data reload to take too long.
                    console.log(this.pageName + ' CALLOUT - isValidListViewDataRequest - ' + this.calloutCount++);
                    isValidListViewDataRequest({ objectName: this.selectedObject, joinFieldName: this.joinFieldName, joinData: this.joinData })
                        .then(result => {
                            console.log('isValidListViewDataRequest returned - ' + result + ' for ' + this.pageName);

                            if (result === 'success') {
                                this.refreshAllListViewData();
                            } else {
                                this.spinnerOff('handleMessage');
                            }

                        })
                        .catch(error => {
                            this.dispatchEvent(SLVHelper.createToast('error', error, 'Processing Error', 'Error processing the list view.', true));
                        });
                }
            } else {
                console.log('Page names are the same or we do not have a joined field name so ignoring message! for ' + this.uniqueComponentId);
            }
        }
    }

    handleAutoRefreshData() {

        console.log('Refreshing data for ' + this.pageName);

        if (this.isRefreshing) {

            let mills = (Date.now() - this.refreshTime);
            if (mills > 5000)
                this.refreshAllListViewData();

            //https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Function/bind
            //look at its use with setTimeout down the page!
            // eslint-disable-next-line @lwc/lwc/no-async-operation
            setTimeout(this.handleAutoRefreshData.bind(this), this.refreshRate * 1000); //change to milliseconds

        }
    }

    async handleAutoRefreshButtonClick() {
        console.log('Refresh button clicked for ' + this.pageName);
        console.log('Auto refresh was set to ' + this.isRefreshing + ' for ' + this.pageName);
        console.log('Refresh time was ' + this.refreshTime + ' for ' + this.pageName);

        //if we do not have the single/double click refresh setting then get it
        if (this.singleClickAutoRefresh === undefined) {
            console.log(this.pageName + ' CALLOUT - getListViewConfigParameter(SingleClickAutoDataRefresh) - ' + this.calloutCount++);
            this.singleClickAutoRefresh = await this.getConfigParameter('SingleClickAutoDataRefresh');
            if (this.singleClickAutoRefresh === undefined || this.singleClickAutoRefresh === null || this.singleClickAutoRefresh === '') {
                this.singleClickAutoRefresh = 'false';
            }
        }

        let mills = (Date.now() - this.refreshTime);

        //we are refreshing automatically and someone stops it.
        if (this.isRefreshing === true) {
            this.isRefreshing = false;
            this.dispatchEvent(SLVHelper.createToast('success', '', 'Auto Refresh Stopped', '', false));
            this.dispatchEvent(new CustomEvent('eventresponse', { detail: { type: 'autoRefreshOff', status: 'finished' } }));

            //if someone has clicked the refresh button again within 5 seconds
        } else if (this.singleClickAutoRefresh === 'true' || (mills < 5000 && this.isRefreshing === false)) {
            this.isRefreshing = true;

            //if we do not have the refresh rate then get it
            if (this.refreshRate === '') {
                console.log(this.pageName + ' CALLOUT - getListViewConfigParameter(RefreshRate) - ' + this.calloutCount++);
                this.refreshRate = await this.getConfigParameter('RefreshRate');
                if (this.refreshRate === undefined || this.refreshRate === null || this.refreshRate === '') {
                    this.refreshRate = '45'; //default to 45s if nothing returned
                }
            }

            this.dispatchEvent(SLVHelper.createToast('success', '', 'Auto Refresh Started', 'Refreshing every ' + this.refreshRate + 's', false));
            this.dispatchEvent(new CustomEvent('eventresponse', { detail: { type: 'autoRefreshOn', status: 'finished' } }));
            console.log('Refresh now set to ' + this.isRefreshing + ' @ ' + this.refreshRate + 's for ' + this.pageName);
            this.handleAutoRefreshData();

            //if someone clicked the refresh button for the first time
        } else {
            this.refreshAllListViewData();
            this.dispatchEvent(new CustomEvent('eventresponse', { detail: { type: 'autoRefreshOnce', status: 'finished' } }));
            this.dispatchEvent(SLVHelper.createToast('success', '', 'List View Refreshed', 'Click within 5 seconds of data loading to auto refresh.', false));
        }

    }

    async getConfigParameter(paramName) {
        return getListViewConfigParameter({ objectName: this.selectedObject, listViewName: this.selectedListView, paramName: paramName });
    }

    /*
     * Called when the user clicks the data download button.
     * This returns the data for the current list view in CSV format.
     */
    handleDownloadData() {
        console.log('Data export button clicked for ' + this.pageName);

        //get the header values
        let dataStr = this.listViewData.headersAsCSVString;

        this.listViewDataRows.forEach(element => {
            dataStr = dataStr + element.dataAsCSVString;
        });


        const data = new Blob([dataStr], { type: 'text/plain' });

        let downloadElement = document.createElement('a');
        downloadElement.href = URL.createObjectURL(data);
        downloadElement.setAttribute("download", "download");
        downloadElement.download = this.selectedListViewExportName;
        downloadElement.click();

        this.dispatchEvent(new CustomEvent('eventresponse', { detail: { type: 'downloadData', status: 'finished', data: dataStr, object: this.selectedObject, listView: this.selectedListView } }));

    }

    /*
     * Called when the user clicks the SELECTED data download button.
     * This returns the data for the current list view in CSV format.
     */
    handleSelectedDownloadData() {
        console.log('Selected data export button clicked for ' + this.pageName);

        //get the header values
        let dataStr = this.listViewData.headersAsCSVString;

        //get the selected record Ids
        const selectedRecords = new Set();
        let selectedRows = this.template.querySelectorAll('lightning-input');
        selectedRows.forEach(element => {
            if (element.checked === true && element.value !== 'all') {
                selectedRecords.add(element.value);
            }
        });

        this.listViewDataRows.forEach(element => {
            if (selectedRecords.has(element.rowId)) {
                dataStr = dataStr + element.dataAsCSVString;
            }
        });

        //turn string into blob
        const data = new Blob([dataStr], { type: 'text/plain' });

        let downloadElement = document.createElement('a');
        downloadElement.href = URL.createObjectURL(data);
        downloadElement.setAttribute("download", "download");
        downloadElement.download = this.selectedListViewExportName;
        downloadElement.click();

        this.dispatchEvent(new CustomEvent('eventresponse', { detail: { type: 'downloadSelectedData', status: 'finished', data: dataStr, object: this.selectedObject, listView: this.selectedListView } }));

    }

    /*
     * Called when a user checks a box next to a record for 
     * selection to be processed. This method is really for
     * handling the case when the ALL checkbox is checked. It 
     * also handles sending the record Ids checked to the message
     * channel.
     */
    handleRecordSelectChange(event) {
        this.spinnerOn('handleRecordSelectChange');
        try {
            const { target } = event;
            const { checked, value } = target;
            console.log('Record selected - ' + checked + ': ' + value + ' for ' + this.pageName);

            //get all checkbox components
            let selectedRows = this.template.querySelectorAll('lightning-input');

            //if we have selected "All" then run through all components setting them true or false.
            if (value === 'all') {
                selectedRows.forEach((element) => { element.checked = checked });

                if (checked === true) {
                    this.selectedRecordCount = this.listViewDataRowsSize;
                } else {
                    this.selectedRecordCount = 0;
                }

            } else {
                if (checked === true) {
                    this.selectedRecordCount++;
                } else {
                    this.selectedRecordCount--;
                }
            }

            this.handleListViewActions(this.selectedRecordCount);

            console.log('Sending to message channel for ' + this.uniqueComponentId);
            //run through all the checkbox components again now that they have been set
            let recordIds = '';

            selectedRows.forEach(element => {
                if (element.checked === true && element.value !== 'all') {
                    //the value includes the row number so remove that from the end as we only want the Ids
                    const indexOf = element.value.indexOf(':');
                    const recordId = element.value.substring(0, indexOf);
                    if (recordId !== '' && recordId !== undefined) //if we clicked "All" then the first one is blank.
                        recordIds = recordIds + recordId + ',';
                }
            });

            //remove the last comma if there is one.
            if (recordIds.length > 0) {
                recordIds = recordIds.substring(0, recordIds.lastIndexOf(','));
            }

            //if we are sending the selection to other components.
            if (SLVHelper.toBool(this.useMessageChannel) === true) {

                const message = {
                    type: 'selectrecordupdate',
                    recordIds: recordIds,
                    objectType: this.selectedObject,
                    uniqueComponentId: this.uniqueComponentId
                };
                publish(this.messageContext, LISTVIEW_MC, message);

            } else {
                console.log('NOT sending to message channel for ' + this.uniqueComponentId);
            }
            this.dispatchEvent(new CustomEvent('rowselectupdate', { detail: { recordIds: recordIds } }));
        } catch (error) {
            SLVHelper.showErrorMessage(error);
        } finally {
            this.spinnerOff('handleRecordSelectChange');
        }
    }

    /*
     * Called when a user is selecting a list view and 
     * they have changed the object of the list view.
     */
    handleObjectChange(event) {
        try {
            this.spinnerOn('handleObjectChange');
            const { detail, target } = event;
            if (this.typeAheadObjectSearch === true) {
                this.selectedObject = detail?.selectedValue ?? '';
            } else {
                this.selectedObject = target?.value ?? '';
            }
            this.selectedListView = undefined;
            this.selectedListViewId = undefined;
            this.selectedListViewExportName = undefined;
            this.whereClauseListView = this.createWhereClause('simpli_lv__Object_Name__c', '=', this.selectedObject);
            this.listViewList = undefined;
            this.listViewData = undefined;
            this.listViewDataRows = undefined;
            this.objectActionList = undefined;
            this.displayedActionList = [];
            this.columnSortDataStr = '';
            this.columnSortData = new Map();
            this.modifiedText = '';
            this.textSearchText = '';
            this.isCoreListView = true; //this is not necessarily true since we haven't chosen a list view but we set it to true because we want to display the resource refresh button for the object
            console.log('Object selected - ' + this.selectedObject + ' for ' + this.pageName);

            this.dispatchEvent(new CustomEvent('eventresponse', { detail: { type: 'objectSelected', status: 'finished', object: this.selectedObject } }));

            this.getListViewsForObject();
        } catch (error) {
            SLVHelper.showErrorMessage(error);
        }
    }

    /*
     * Called when a user changed a list view, used 
     * to retrieve record data.
     */
    handleListViewChanged(event) {
        try {

            const { detail, target } = event;
            const { value } = target;
            const { selectedValue } = detail;
            console.log('Old list view - ' + this.selectedListView + ' for ' + this.pageName);
            console.log('Sort data - ' + this.listViewSortData + ' for ' + this.pageName);
            this.spinnerOn('handleListViewChanged');
            this.textSearchText = '';

            //set the old column sort information into the list view sort data for caching otherwise it disappears.
            if (this.columnSortDataStr !== '') {
                this.listViewSortData.set(this.selectedObject + ':' + this.selectedListView, this.columnSortData);
            }

            //set the new selected list view (COMBO BOX)
            this.selectedListView = value;

            //set the new selected list view (TYPE AHEAD)
            if (selectedValue !== undefined)
                this.selectedListView = selectedValue;

            console.log('New list view - ' + this.selectedListView + ' for ' + this.pageName);
            this.selectedListViewExportName = this.selectedListView + '.csv';

            //set the column sort information for the NEW list view
            if (this.listViewSortData.get(this.selectedObject + ':' + this.selectedListView) !== undefined) {
                this.columnSortData = this.listViewSortData.get(this.selectedObject + ':' + this.selectedListView);
                this.columnSortDataStr = JSON.stringify(Array.from(this.columnSortData));

            } else {
                this.columnSortDataStr = '';
                this.columnSortData = new Map();
            }

            //if we are not in the construction of the page and we change the list view and its the pinned list view
            if (this.componentConfig !== undefined && this.pinnedObject === this.selectedObject && this.pinnedListView === this.selectedListView) {
                this.isPinned = true;
            } else {
                this.isPinned = false;
            }
            this.refreshTitle = 'Click to perform list view refresh on current list view';

            console.log('Starting ListView Data Refresh for ' + this.pageName);

            this.dispatchEvent(new CustomEvent('eventresponse', { detail: { type: 'listViewSelected', status: 'finished', object: this.selectedObject, listView: this.selectedListView } }));

            this.refreshAllListViewData();
        } catch (error) {
            SLVHelper.showErrorMessage(error);
        }
    }

    /*
     * Method for handling when a user pins a given list view.
     */
    handlePinningClick() {
        this.isPinned = true;

        console.log(this.pageName + ' CALLOUT - updateUserConfig(pinnedListView) - ' + this.calloutCount++);
        updateUserConfig({ compName: this.pageName, configName: 'pinnedListView', value: this.selectedObject + ':' + this.selectedListView })
            .then(() => {
                this.dispatchEvent(SLVHelper.createToast('success', '', 'List View Pinned', 'List view successfully pinned.', false));

                this.dispatchEvent(new CustomEvent('eventresponse', { detail: { type: 'pinListView', status: 'finished', object: this.selectedObject, listView: this.selectedListView } }));
            })
            .catch(error => {
                this.dispatchEvent(SLVHelper.createToast('error', error, 'Pinning Error', 'Error during user configuration update.', true));
            });

    }

    /*
     * Method for handling when a user UNPINS a given list view.
     */
    handleUnpinningClick() {

        console.log(this.pageName + ' CALLOUT - updateUserConfig(pinnedListView) - ' + this.calloutCount++);
        updateUserConfig({ compName: this.pageName, configName: 'pinnedListView', value: '' })
            .then(result => {
                console.log('RESULT - ' + result);
                if (result === 'success') {
                    this.dispatchEvent(SLVHelper.createToast('success', '', 'List View Unpinned', 'List view successfully unpinned.', false));
                    this.isPinned = false;
                    this.dispatchEvent(new CustomEvent('eventresponse', { detail: { type: 'unpinListView', status: 'finished', object: this.selectedObject, listView: this.selectedListView } }));

                } else {
                    console.log('List view unpinning NOT successful for ' + this.pageName);
                    this.dispatchEvent(SLVHelper.createToast('error', '', 'Unpinning Error', 'There was a problem unpinning the list view. This might be due to user permissions.', false));
                }
            })
            .catch(error => {
                this.dispatchEvent(SLVHelper.createToast('error', error, 'Unpinning Error', 'There was a problem unpinning the list view. This might be due to user permissions.', true));
            });
    }

    /*
     * Called when a URL on the pages table data is clicked
     */
    handleURLClick(event) {
        try {
            const target = event.target.target;
            //this is the URL
            console.log('URL clicked - ' + event.target.href + ' for ' + this.pageName);
            console.log('URL target  - ' + target + ' for ' + this.pageName);

            //hack to get the record Id from the URL
            const chars = event.target.href.split('/');
            console.log('Id - ' + chars[5] + ' for ' + this.pageName);

            //stop the link from doing its usual thing as we will be doing our thing.
            event.preventDefault();
            event.stopPropagation();

            SLVHelper.invokeWorkspaceAPI('isConsoleNavigation').then(isConsole => {
                if (isConsole) {
                    SLVHelper.invokeWorkspaceAPI('getFocusedTabInfo').then(focusedTab => {

                        if (focusedTab !== undefined && focusedTab.tabId !== undefined) {
                            SLVHelper.invokeWorkspaceAPI('openSubtab', {
                                parentTabId: focusedTab.tabId,
                                recordId: chars[5],
                                focus: true
                            }).then(tabId => {
                                console.log("Newly opened tab id - ", tabId);
                            });

                        } else {

                            // Navigate to record page
                            this[NavigationMixin.Navigate]({
                                type: 'standard__recordPage',
                                attributes: {
                                    recordId: chars[5],
                                    actionName: 'view',
                                },
                            });
                        }
                    });

                } else {

                    //if we are opening a up a new window then use the whole URL as is.
                    if (target === '_blank') {
                        // Navigate to a URL
                        this[NavigationMixin.Navigate]({
                            type: 'standard__webPage',
                            attributes: {
                                url: event.target.href
                            }
                        },
                            true);

                        //if we are using the same window then get the Id of the URL
                    } else {
                        // Navigate to record page
                        this[NavigationMixin.Navigate]({
                            type: 'standard__recordPage',
                            attributes: {
                                recordId: chars[5],
                                actionName: 'view',
                            },
                        });
                    }

                }
            });

            this.dispatchEvent(new CustomEvent('eventresponse', { detail: { type: 'urlClicked', status: 'finished', url: event.target.href } }));
        } catch (error) {
            SLVHelper.showErrorMessage(error);
        }
    }

    dataSpinnerOn() {
        this.dataSpinner = true;
        this.canDisplayActions = false;
        console.log('Data Spinner ON for ' + this.pageName);
    }

    dataSpinnerOff() {
        this.dataSpinner = false;
        if (this.objectActionList !== undefined && this.objectActionList.length > 0 && SLVHelper.toBool(this.displayActions) === true) {
            this.canDisplayActions = true;
        }
        console.log('Data Spinner OFF for ' + this.pageName);
    }

    spinnerOn(message) {
        this.spinner = true;
        console.log('Spinner ON - ' + message + ' - ' + this.pageName);
    }

    spinnerOff(message) {
        if (this.isInitializing === false) {
            this.spinner = false;
            console.log('Spinner OFF  - ' + message + ' - ' + this.pageName);
        }
    }

    handleProcessListViewsButtonClick(event) {

        this.spinnerOn('handleProcessListViewsButtonClick');
        console.log('Listview process button clicked for ' + this.pageName);
        console.log('selectedObject - ' + this.selectedObject + ' for ' + this.pageName);
        console.log('selectedListView - ' + this.selectedListView + ' for ' + this.pageName);
        console.log('DATA - ' + event.currentTarget.dataset.type);

        //if we need to initialize after install or upgrade
        if (event.currentTarget.dataset.type !== undefined && event.currentTarget.dataset.type === 'full' && this.isInitialized === false) {
            this.selectedObject = undefined;
            this.selectedListView = undefined;
        }

        //if we have selected a specific list view to update
        if (this.selectedObject !== undefined && this.selectedListView !== undefined && this.isInitialized === true) {
            console.log('Updating SINGLE list view for ' + this.pageName);

            console.log(this.pageName + ' CALLOUT - updateSingleListView - ' + this.calloutCount++);
            updateSingleListView({ objectType: this.selectedObject, listViewName: this.selectedListView })
                .then(result => {

                    if (result === 'success') {
                        this.dispatchEvent(SLVHelper.createToast('success', '', 'List View Updated Successfully', 'List view has been updated and refreshed successfully.', false));
                        this.dispatchEvent(new CustomEvent('processlistviewclick'));
                        this.refreshAllListViewData();

                    } else {
                        this.dispatchEvent(SLVHelper.createToast('error', '', 'Processing Error', 'Error processing the list view.', false));
                        this.spinnerOff('handleProcessListViewsButtonClick1');
                    }
                })
                .catch(error => {
                    this.dispatchEvent(SLVHelper.createToast('error', error, 'Processing Error', 'Error processing the list view.', true));
                    this.spinnerOff('handleProcessListViewsButtonClick2');
                });

            this.dispatchEvent(new CustomEvent('eventresponse', { detail: { type: 'processSingleListView', status: 'finished', object: this.selectedObject, listView: this.selectedListView } }));

        }

        //if we have selected an objects list views to update
        else if (this.selectedObject !== undefined && this.selectedListView === undefined && this.isInitialized === true) {
            console.log('Updating OBJECT list views for ' + this.pageName);

            console.log(this.pageName + ' CALLOUT - updateObjectListViews - ' + this.calloutCount++);
            updateObjectListViews({ objectType: this.selectedObject })
                .then(result => {

                    if (result === 'success') {
                        this.dispatchEvent(SLVHelper.createToast('success', '', this.selectedObject + ' List Views Updated', this.selectedObject + ' list views have been updated successfully.', false));
                        this.dispatchEvent(new CustomEvent('processlistviewclick'));
                        this.getListViewsForObject();
                        this.spinnerOff('handleProcessListViewsButtonClick3');

                    } else {
                        this.dispatchEvent(SLVHelper.createToast('error', '', 'Processing Error', 'Error processing the ' + this.selectedObject + ' list views.', false));
                        this.spinnerOff('handleProcessListViewsButtonClick4');
                    }
                })
                .catch(error => {
                    this.dispatchEvent(SLVHelper.createToast('error', error, 'Processing Error', 'Error processing the ' + this.selectedObject + ' list views.', true));
                    this.spinnerOff('handleProcessListViewsButtonClick5');
                });

            this.dispatchEvent(new CustomEvent('eventresponse', { detail: { type: 'processObjectListViews', status: 'finished', object: this.selectedObject } }));

        }

        //if we have selected ALL list views to update
        else if (this.selectedObject === undefined && this.selectedListView === undefined || this.isInitialized === false) {
            console.log('Updating ALL list views for ' + this.pageName);

            console.log(this.pageName + ' CALLOUT - updateAllListViews - ' + this.calloutCount++);
            updateAllListViews({})
                .then(result => {

                    if (result === 'failed') {
                        this.dispatchEvent(SLVHelper.createToast('error', '', 'Processing Error', 'Error processing the list views.', false));
                        this.spinnerOff('handleProcessListViewsButtonClick6');

                    } else {
                        this.batchId = result;
                        this.dispatchEvent(SLVHelper.createToast('success', '', 'List View Processing', 'List view processing has started for all list views. Refresh page after completion to see changes.', false));
                        this.dispatchEvent(new CustomEvent('processlistviewclick'));
                        this.spinnerOff('handleProcessListViewsButtonClick7');
                    }
                })
                .catch(error => {
                    this.dispatchEvent(SLVHelper.createToast('error', error, 'Processing Error', 'Error processing the list views.', true));
                    this.spinnerOff('handleProcessListViewsButtonClick8');
                });

            this.dispatchEvent(new CustomEvent('eventresponse', { detail: { type: 'processAllListViews', status: 'finished' } }));
        }

    }

    calculateWidth(event) {
        try {
            const { target, clientX } = event;
            const childObj = target;
            let parObj = childObj.parentNode;
            const mouseStart = clientX;
            this.mouseDownColumn = event.currentTarget.dataset.index;
            while (parObj.tagName !== 'TH') {
                parObj = parObj.parentNode;
            }
            this.mouseStart = mouseStart;
            this.oldWidth = parObj.offsetWidth;
            this.parentObj = parObj;

            console.log('Mouse start - ' + this.mouseStart);
            console.log('Old Width - ' + this.oldWidth);

            if (event.stopPropagation) event.stopPropagation();
            if (event.preventDefault) event.preventDefault();
            event.cancelBubble = true;
            event.returnValue = false;
        } catch (error) {
            SLVHelper.showErrorMessage(error);
        }
    }

    setNewWidth(event) {
        try {
            if (this.mouseStart === undefined) return;
            const { clientX } = event;

            console.log('event.clientX - ' + clientX);
            let newWidth = clientX - parseFloat(this.mouseStart) + parseFloat(this.oldWidth);

            console.log('New width - ' + newWidth);

            // const mainContainer = this.template.querySelector('.applistscrollwrapper');
            // if (!this.allowHorizontalScrolling && this.listViewData.fieldMetaData.length) {
            //     const mainContainerWidth = mainContainer.offsetWidth;
            //     const actionBtnsWidth = this.isEdited ? 60 : 0;
            //     const maxColumnWidth = ((mainContainerWidth - 32 - actionBtnsWidth) / this.listViewData.fieldMetaData.length).toFixed(0);
            //     if (newWidth >= maxColumnWidth) {
            //         newWidth = maxColumnWidth;
            //     }
            // }

            this.parentObj.style.width = newWidth + 'px';

            this.mouseStart = undefined;

            this.saveColumnWidth(newWidth, this.mouseDownColumn);
        } catch (error) {
            SLVHelper.showErrorMessage(error);
        }
    }

    saveColumnWidth(newWidth, columnIndex) {
        console.log(this.pageName + ' CALLOUT - updateUserConfigListViewWidth(columnWidth) - ' + this.calloutCount++);

        let configName = 'columnWidths:' + this.selectedObject + ':' + this.selectedListView;
        console.log('Config width string - ' + configName);
        updateUserConfigListViewWidth({ compName: this.pageName, configName: configName, columnIndex: columnIndex, width: newWidth })
            .then(() => {

            })
            .catch(error => {
                this.dispatchEvent(SLVHelper.createToast('error', error, 'Width Save Error', 'Error during user configuration update.', true));
            });

    }

    sortColumns(event) {
        this.spinnerOn('sortColumns');
        try {
            const { currentTarget } = event;
            const { dataset } = currentTarget;
            const { name, sortdir, sortindex } = dataset;
            //get all values from the event
            let fieldName = name;
            let sortDirection = sortdir;
            let sortIndex = sortindex;

            if (sortIndex === undefined || sortIndex === '') {
                sortIndex = this.columnSortData.size;
            }
            sortIndex = Number(sortIndex);

            if (sortDirection === undefined || sortDirection === '') {
                sortDirection = true;
            } else {
                sortDirection = SLVHelper.toBool(sortDirection)
            }

            let columnData;

            if (this.useSimpleSorting === true) {
                if (this.columnSortData.has(sortIndex)) {
                    columnData = this.columnSortData.get(sortIndex);

                    columnData[2] = !columnData[2];
                    columnData[0] = 0;

                    this.columnSortData = new Map();
                    this.columnSortData.set(0, columnData);
                    //first time clicking on column just add the column for sorting.
                } else {
                    columnData = [0, fieldName, sortDirection];
                    this.columnSortData = new Map();
                    this.columnSortData.set(0, columnData);
                }
            } else {
                //clicked on a column already being sorted then switch the direction
                if (this.columnSortData.has(sortIndex)) {
                    columnData = this.columnSortData.get(sortIndex);

                    //the second click on the column switch the column.
                    if (columnData[2] === true) {
                        columnData[2] = false;
                        this.columnSortData.set(sortIndex, columnData);

                        //third click on the column reset all sorting data.
                    } else {
                        this.columnSortData = new Map();
                    }

                    //first time clicking on a column then add the column for sorting.
                } else {
                    columnData = [sortIndex, fieldName, sortDirection];
                    this.columnSortData.set(sortIndex, columnData);
                }

            }
        } catch (error) {
            SLVHelper.showErrorMessage(error);
        } finally {
            this.columnSortDataStr = JSON.stringify(Array.from(this.columnSortData));
            this.listViewSortData.set(this.selectedObject + ':' + this.selectedListView, this.columnSortData);
            this.refreshAllListViewData();
        }
    }

    //ACTIONS

    //called when a user selects an action for processing.
    async handleActionSelect(event) {
        try {

            this.selectedRecordIds = new Set();
            let selectedRowId = '';

            const { target } = event;
            const { value } = target
            this.selectedActionKey = value;

            console.log('Chosen Action - ' + this.selectedActionKey + ' for ' + this.pageName);

            //get the ACTION
            if (this.displayedActionList?.length) {
                this.displayedActionList.forEach(action => {
                    if (action.value === this.selectedActionKey) {
                        this.selectedAction = action;
                    }
                });
            }


            //get the SELECTED RECORD IDs
            let selectedRows = this.template.querySelectorAll('lightning-input');
            if (selectedRows?.length) {
                selectedRows.forEach(element => {
                    if (element.checked === true && element.value !== 'all') {
                        selectedRowId = element.value.substring(0, element.value.indexOf(':'));
                        if (selectedRowId !== '')
                            this.selectedRecordIds.add(selectedRowId);
                    }
                });
            }


            this.selectedRecordIdsStr = JSON.stringify(Array.from(this.selectedRecordIds));

            //HYPERLINK
            if (this.selectedAction.isHyperlink === true) {
                let hyperlink = this.selectedAction.hyperlink;
                let recordIdStr = '';
                this.selectedRecordIds.forEach(recordId => {
                    recordIdStr = recordIdStr + recordId + '%2C'; //%2C = encoded comma
                });
                recordIdStr = recordIdStr.slice(0, -3); //remove last "%2C"

                if (this.selectedRecordIds.size > 1) {
                    this.dispatchEvent(SLVHelper.createToast('error', '', 'Error Processing Action', 'Multiple rows cannot be selected for this action', false));
                } else {

                    //go through the action parameters checking for field substitutions
                    this.selectedAction.allParameters.forEach(param => {
                        let key = '$' + param.aPIName + '$';
                        if (hyperlink.includes(key)) {
                            //get the ROW
                            let row;
                            this.listViewDataRows.forEach(element => {
                                if (element.isDeleted === false && element.salesforceId === recordIdStr) {
                                    row = element;
                                }
                            });

                            if (row === undefined) {
                                this.dispatchEvent(SLVHelper.createToast('error', '', 'Error Processing Action', 'A row must be selected for this action', false));
                                hyperlink = '';

                            } else if (param.value === 'Id') {
                                hyperlink = hyperlink.replace(key, row.salesforceId);
                            } else {

                                //get the FIELD value and substitute into hyperlink
                                row.fields.forEach(element => {
                                    if (element.name === param.value) {
                                        hyperlink = hyperlink.replace(key, element.value);
                                    }
                                });
                            }
                        }
                    });

                    console.log('Hyperlink - ' + hyperlink);

                    if (hyperlink !== '') {
                        this[NavigationMixin.Navigate]({
                            type: 'standard__webPage',
                            attributes: {
                                url: hyperlink,
                            },
                        });
                    }
                }

                //GENERATE PDF
            } else if (this.selectedAction.className === 'ListViewActionPDF') {
                this.spinnerOn('ListViewActionPDF');
                console.log('We are generating a PDF for ' + this.pageName);

                console.log(this.pageName + ' CALLOUT - getListViewConfigParameter(PDFTheme) - ' + this.calloutCount++);
                let theme = await this.getConfigParameter('PDFTheme');
                if (theme === undefined || theme === null || theme === '') {
                    theme = 'striped'; //default to striped if nothing returned
                }


                console.log(this.pageName + ' CALLOUT - updateAllListViews(PDFOrientationPortrait) - ' + this.calloutCount++);
                let orientation = await this.getConfigParameter('PDFOrientationPortrait');
                if (orientation === undefined || orientation === null || orientation === '') {
                    orientation = 'true'; //default to striped if nothing returned
                } else if (orientation === 'false') { //true = portrait, false = landscape
                    orientation = 'landscape';
                }

                const { jsPDF } = window.jspdf;
                let doc = new jsPDF(orientation);

                doc.autoTable({
                    head: SLVHelper.headRows(this.listViewData.fieldMetaData),
                    body: SLVHelper.bodyRows(this.selectedRecordIds, this.listViewDataRows),
                    theme: theme,
                    margin: { top: 5, right: 5, bottom: 5, left: 5 },
                });

                this.selectedListViewExportName = this.selectedListView + '.pdf';

                doc.save(this.selectedListViewExportName);
                this.spinnerOff('ListViewActionPDF');

                //SCREEN FLOW (AUTOMATED FLOWS HAPPEN IN CUSTOM)
            } else if (this.selectedAction.isFlow === true && this.selectedAction.flowType === 'Screen Flow' && !this.virtual) {
                this.selectedActionLabel = 'Label ' + this.selectedAction.label;

                this.showFlowModal = true;

                //CREATE/NEW
            } else if (this.selectedAction.className === 'ListViewActionCreate' && !this.virtual) {
                let navLocation = 'DETAIL';

                let defaultValues = {};
                if (this.isModeRelated) {
                    defaultValues[this.joinFieldName] = this.recordId;
                    navLocation = 'RELATED_LIST';
                }

                //go through the action parameters checking for field substitutions
                this.selectedAction.allParameters.forEach(param => {
                    if (param.aPIName === 'UserField')
                        defaultValues[param.value] = currentUserId;
                    if (param.aPIName === 'NoRedirect' && param.value === 'true')
                        navLocation = 'RELATED_LIST';
                });

                defaultValues = encodeDefaultFieldValues(defaultValues);

                try {
                    this[NavigationMixin.Navigate]({
                        type: 'standard__objectPage',
                        attributes: {
                            objectApiName: this.selectedObject,
                            actionName: 'new',
                        },
                        state: {
                            useRecordTypeCheck: 1,
                            defaultFieldValues: defaultValues,
                            navigationLocation: navLocation,
                        }
                    }).then(() => {
                        this.refreshAllListViewData();
                    });
                } catch (e) {
                    console.log('EXCEPTION THROWN - ' + JSON.stringify(e));
                }

                //CLONE
            } else if (this.selectedAction.className === 'ListViewActionClone' && !this.virtual) {

                if (this.selectedRecordIds.size !== 1) {
                    this.dispatchEvent(SLVHelper.createToast('error', '', 'Error Processing Action', 'A single row must be selected for cloning', false));
                } else {
                    console.log('We are cloning the following id - ' + selectedRowId + ' for ' + this.pageName);

                    this[NavigationMixin.Navigate]({
                        type: 'standard__recordPage',
                        attributes: {
                            objectApiName: this.selectedObject,
                            actionName: 'clone',
                            recordId: selectedRowId,
                        },
                    });
                    this.dispatchEvent(new CustomEvent('processclick'));
                }

                //EDIT
            } else if (this.selectedAction.className === 'ListViewActionEdit' && !this.virtual) {

                if (this.selectedRecordIds.size !== 1) {
                    this.dispatchEvent(SLVHelper.createToast('error', '', 'Error Processing Action', 'A single row must be selected for editing', false));
                } else {

                    console.log('We are editing the following id - ' + selectedRowId + ' for ' + this.pageName);

                    this[NavigationMixin.Navigate]({
                        type: 'standard__recordPage',
                        attributes: {
                            objectApiName: this.selectedObject,
                            actionName: 'edit',
                            recordId: selectedRowId,
                        },
                    });
                    this.dispatchEvent(new CustomEvent('processclick'));
                }

                //EDIT All
            } else if (this.selectedAction.className === 'ListViewActionEditAll' && !this.virtual) {

                console.log('We are editing all records for ' + this.pageName);

                if (this.listViewDataRows.length > 101) {
                    this.dispatchEvent(SLVHelper.createToast('error', '', 'Too Many Rows!', 'Inline editing only available for up to 100 rows', false));
                } else {
                    this.setAllRowsEdited();
                }

                //MASS CREATE
            } else if (this.selectedAction.className === 'ListViewActionMassCreate' && !this.virtual) {

                console.log('We are mass creating records for ' + this.pageName);
                if (this.selectedAction.massCreateListViewName !== undefined)
                    this.massCreateListView = this.selectedAction.massCreateListViewName
                else
                    this.massCreateListView = this.selectedListView;

                this.showMassCreateModal = true;

                //EMAIL USING TEMPLATE
            } else if (this.selectedAction.className === 'ListViewActionEmail' && this.selectedAction.emailTemplateFolder !== '' && this.selectedRecordIds.size > 0 && !this.virtual) {
                console.log('We are creating emails from a template for ' + this.pageName);
                this.showEmailTemplateModal = true;
                this.emailTemplateFolder = this.selectedAction.emailTemplateFolder;
                this.emailTemplateWhatIdField = this.selectedAction.emailTemplateWhatIdField;
                this.spinnerOff('ListViewActionEmailTemplate');

                //CUSTOM
            } else {

                if (this.selectedAction.hasDisplayParameters) {

                    this.selectedActionLabel = 'Label ' + this.selectedAction.label;               //   <-- This to be fixed.

                    console.log('Action Label selected - ' + this.selectedActionLabel + ' for ' + this.pageName);
                    console.log('Action name           - ' + this.selectedAction.value + ' for ' + this.pageName);
                    console.log('Action Record Ids     - ' + this.selectedRecordIdsStr + ' for ' + this.pageName);

                    this.showActionModal = true;

                } else if (this.virtual) {
                    this.dispatchEvent(new CustomEvent('runaction', { detail: { action: this.selectedAction } }));
                    this.resetActionComboBox();
                    return;

                } else {

                    this.selectedActionLabel = 'Label ' + this.selectedAction.label;               //   <-- This to be fixed.

                    console.log('Action Label selected - ' + this.selectedActionLabel + ' for ' + this.pageName);
                    console.log('Action name           - ' + this.selectedAction.value + ' for ' + this.pageName);
                    console.log('Action Record Ids     - ' + this.selectedRecordIdsStr + ' for ' + this.pageName);

                    this.showActionModal = true;
                }
            }

            this.resetActionComboBox();

            this.dispatchEvent(new CustomEvent('eventresponse', { detail: { type: 'runAction', status: 'finished', action: this.selectedActionKey, listView: this.selectedListView, object: this.selectedObject } }));

        } catch (error) {
            SLVHelper.showErrorMessage(error);
        }
    }

    resetActionComboBox() {
        this.template.querySelectorAll('lightning-combobox').forEach(combobox => {
            if (combobox.name === 'Action List')
                combobox.value = undefined;
        });
    }

    handleCancelButtonClick(event) {
        try {
            const { target } = event;
            const { label } = target;
            const action = label;
            if (action === 'Cancel') {
                this.outputStr = this.action;
            }
        } catch (error) {
            SLVHelper.showErrorMessage(error);
        }
    }

    handleMassCreateModalClose() {
        this.showMassCreateModal = false;
    }

    handleEmailTemplateModalClose() {
        this.showEmailTemplateModal = false;
    }

    cancelActionModal() {
        this.resetActionComboBox();
        this.showActionModal = false;
    }

    processActionModal() {

        this.showActionModal = false;
        this.selectedAction = '';

        this.refreshAllListViewData();
    }

    processActionModalRunAction(event) {
        try {
            const { detail } = event;
            const { action, valuesMap } = detail;
            this.showActionModal = false;
            this.dispatchEvent(new CustomEvent('runaction', { detail: { action: action, valuesMap: valuesMap } }));
        } catch (error) {
            SLVHelper.showErrorMessage(error);
        }
    }

    //ADMIN

    handleAdminButtonClick() {
        console.log('Admin button clicked for ' + this.pageName);

        this.showAdminModal = true;
    }

    async processAdminModal(event) {
        try {
            const { detail } = event;
            this.showAdminModal = false;

            if (detail === true) {
                this.refreshRate = await this.getConfigParameter('RefreshRate');
                this.singleClickAutoRefresh = await this.getConfigParameter('SingleClickAutoDataRefresh');

                this.handleComponentConfig();

                refreshApex(this.wiredListViewConfigResult);
                this.refreshAllListViewData();
            }
        } catch (error) {
            SLVHelper.showErrorMessage(error);
        }
    }

    //FLOW

    cancelFlowModal() {
        this.resetActionComboBox();
        this.showFlowModal = false;
    }

    finishFlowModal() {

        //reset the selected record Ids
        let selectedRows = this.template.querySelectorAll('lightning-input');
        selectedRows.forEach(element => { element.checked = false; });
        this.selectedRecordCount = 0;
        this.showFlowModal = false;

        this.refreshAllListViewData();
    }

    //INLINE EDITING

    setAllRowsEdited() {
        if (SLVHelper.toBool(this.allowInlineEditing) === true) {
            this.isEdited = true;
            this.listViewData.isEdited = true;
            if (this.listViewDataRows?.length) {
                this.listViewDataRows.forEach(element => {
                    if (element.isDeleted === false) {
                        element.isEdited = true;
                    }
                });
            }
        } else {
            this.dispatchEvent(SLVHelper.createToast('info', '', 'Editing Not Available', 'Inline editing is not available for this list view.', false));
        }
    }

    setRowEdited(event) {
        try {
            console.log('Row set to be edited - ' + event.target.id + ' for ' + this.pageName);
            const rowId = event.target.id.split('-')[0];

            if (SLVHelper.toBool(this.allowInlineEditing) === true) {
                this.isEdited = true;
                this.listViewData.isEdited = true;
                if (this.listViewDataRows?.length) {
                    this.listViewDataRows.forEach(element => {
                        if (element.rowId === rowId && element.isEditable) {
                            if (element.isDeleted === false) {
                                element.isEdited = true;
                            } else {
                                this.dispatchEvent(SLVHelper.createToast('warning', '', 'Warning', 'This row has already been deleted. No updates can be made.', false));
                            }
                        }
                    });
                }
            } else {
                this.dispatchEvent(SLVHelper.createToast('info', '', 'Editing Not Available', 'Inline editing is not available for this list view.', false));
            }
        } catch (error) {
            SLVHelper.showErrorMessage(error);
        }
    }

    handleRowDataSave(event) {
        try {
            const { target } = event;
            const { value } = target;
            console.log('Row data saved for ' + this.pageName);

            let rowId = value;

            let rowData = this.updatedRowData.get(rowId);

            if (rowData !== undefined) {
                this.spinnerOn('handleRowDataSave');
                let rowDataStr = JSON.stringify(Array.from(rowData)); //map objects cannot be stringified
                console.log('SAVE RESULT - ' + rowDataStr);

                if (this.virtual) {
                    this.dispatchEvent(new CustomEvent('savedatarow', { detail: { rowId: rowId, rowData: rowDataStr } }));
                    this.spinnerOff('handleRowDataSave');
                } else {

                    console.log(this.pageName + ' CALLOUT - updateRecord - ' + this.calloutCount++);
                    updateRecord({ rowId: rowId, rowData: rowDataStr })
                        .then(result => {
                            console.log('Record update response - ' + result);

                            if (result === '') {
                                this.dispatchEvent(SLVHelper.createToast('success', '', 'Success', 'Record saved successfully.', false));

                                this.listViewDataRows.forEach(element => {
                                    if (element.rowId === rowId) {
                                        element.isEdited = false;
                                    }
                                });

                                this.dispatchEvent(new CustomEvent('eventresponse', { detail: { type: 'dataSaved', status: 'finished', rowId: rowId, listView: this.selectedListView, object: this.selectedObject } }));

                                this.refreshAllListViewData();
                            } else {
                                this.dispatchEvent(SLVHelper.createToast('error', '', 'Error', 'There was a validation exception - ' + result, false));
                            }
                        })
                        .catch(error => {
                            this.dispatchEvent(SLVHelper.createToast('error', error, 'Error', 'Error saving the record.', true));
                            this.spinnerOff('handleRowDataSave');
                        });
                }
            } else {
                this.dispatchEvent(SLVHelper.createToast('warning', '', 'Warning', 'There was no updated data to save.', false));
                this.spinnerOff('handleAllRowDataSave');
            }
        } catch (error) {
            SLVHelper.showErrorMessage(error);
        }
    }

    handleAllRowDataSave() {
        this.spinnerOn('handleAllRowDataSave');
        let rowData = this.updatedRowData; //map of maps

        if (rowData !== undefined) {
            if (rowData.size > 0) {
                let rowDataStr = '{'
                rowData.forEach((element, key) => {
                    rowDataStr = rowDataStr + '"' + key + '":' + JSON.stringify(Array.from(element)) + ',';
                });

                rowDataStr = rowDataStr.slice(0, -1) + '}';

                console.log('SAVE RESULT - ' + rowDataStr + ' for ' + this.pageName);

                if (this.virtual) {
                    this.dispatchEvent(new CustomEvent('savedatarows', { detail: { rowData: rowDataStr } }));
                    this.spinnerOff('handleAllRowDataSave');
                } else {

                    console.log(this.pageName + ' CALLOUT - updateRecords - ' + this.calloutCount++);
                    updateRecords({ rowData: rowDataStr })
                        .then(() => {
                            console.log('Save successful for ' + this.pageName);
                            let rowCount = 0;
                            if (this.updatedRowData !== undefined) {
                                rowCount = this.updatedRowData.size;
                            }

                            if (rowCount > 0) {
                                this.dispatchEvent(SLVHelper.createToast('success', '', 'Success', rowCount + ' record(s) saved successfully.', false));
                                this.dispatchEvent(new CustomEvent('eventresponse', { detail: { type: 'dataSaved', status: 'finished', object: this.selectedObject, listView: this.selectedListView, rowCount: rowCount } }));
                            }

                            this.refreshAllListViewData();

                            this.listViewDataRows.forEach(element => {
                                element.isEdited = false;
                            });

                            this.updatedRowData = new Map();
                            this.isEdited = false;
                        })
                        .catch(error => {
                            this.dispatchEvent(SLVHelper.createToast('error', error, 'Error', 'Error saving the records.', true));
                            this.spinnerOff('handleAllRowDataSave');
                        });
                }
            } else {
                this.dispatchEvent(SLVHelper.createToast('warning', '', 'Warning', 'There was no updated data to save.', false));
                this.spinnerOff('handleAllRowDataSave');
            }
        }

    }

    handleRowDataReset(event) {
        try {
            console.log('Row data reset for ' + this.pageName);
            const { target } = event;
            const { value } = target;

            let rowId = value;

            this.updatedRowData.delete(rowId);

            let editedCount = 0;

            if (this.listViewDataRows?.length) {
                this.listViewDataRows.forEach(element => {
                    if (element.rowId === rowId) {
                        element.isEdited = false;
                    } else {
                        if (element.isEdited === true)
                            editedCount++;
                    }
                });
            }

            //set form to not editing if no rows are processing.
            if (editedCount === 0) {
                this.isEdited = false;
            }
        } catch (error) {
            SLVHelper.showErrorMessage(error);
        }
    }

    handleAllRowDataReset() {
        if (this.listViewDataRows?.length) {
            this.listViewDataRows.forEach(element => {
                element.isEdited = false;
            });
        }
        this.isEdited = false;
    }

    handleFieldDataChange(event) {
        try {
            console.log('Field changed for ' + this.pageName);
            const { detail, currentTarget, target } = event;
            const { value, checked } = target;
            const { selectedValue, field } = detail;
            const { dataset } = currentTarget;
            const { type } = dataset;


            //if data is coming in from a component
            let fieldValue = '';
            let rowId = '';
            let fieldName = '';

            //if data is coming in from a component
            if (type === undefined) {
                fieldValue = selectedValue;
                rowId = detail?.rowId ?? "";
                fieldName = field;

            } else {
                if (type === 'boolean') {
                    if (checked === true) {
                        fieldValue = 'true'; //have to turn boolean into string
                    } else {
                        fieldValue = 'false'
                    }
                    rowId = dataset?.rowId;
                    fieldName = dataset?.field;
                } else {
                    fieldValue = value;
                    rowId = dataset?.rowId;
                    fieldName = dataset?.field;
                }
            }

            console.log('fieldValue - ' + fieldValue + ' for ' + this.pageName);
            console.log('rowId - ' + rowId + ' for ' + this.pageName);
            console.log('fieldName - ' + fieldName + ' for ' + this.pageName);

            let rowData = this.updatedRowData.get(rowId);

            if (rowData === undefined) {
                rowData = new Map();
                this.updatedRowData.set(rowId, rowData);
            }

            rowData.set(fieldName, fieldValue);
        } catch (error) {
            SLVHelper.showErrorMessage(error);
        }
    }

    //QUICK DATA

    handleQuickDataClicked(event) {
        this.handleQuickDataDisplay(event);
    }

    handleQuickDataKeyDown(event) {
        try {
            const { keyCode } = event;
            if (keyCode === 32 || keyCode === 13) this.handleQuickDataDisplay(event); //if space or enter then quick display
        } catch (error) {
            SLVHelper.showErrorMessage(error);
        }
    }

    handleQuickDataDisplay(event) {
        try {
            const { currentTarget, target } = event;
            const { value, name } = target;
            const { dataset } = currentTarget;
            const { rowId, type, field, object } = dataset;
            this.quickDataHeading = 'Test Heading';
            this.quickDataFieldLabel = 'Field Label';
            this.quickDataRowId = rowId;
            this.quickDataFieldType = type
            this.quickDataFieldValue = value;
            this.quickDataFieldName = field;
            this.quickDataComponentId = name;
            this.quickDataOldFieldValue = value;
            this.quickDataObjectName = object;
            this.showQuickDataModal = true;
        } catch (error) {
            SLVHelper.showErrorMessage(error);
        }
    }

    handleQuickDataCancelled() {
        this.showQuickDataModal = false;
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        setTimeout(() => this.setQuickDataComponentFocus(this.quickDataOldFieldValue), 200);
    }

    setQuickDataComponentFocus(fieldValue) {
        this.template.querySelectorAll('lightning-input').forEach(element => {
            if (element.name === this.quickDataComponentId) {
                element.focus();
                if (fieldValue !== undefined) {
                    element.value = fieldValue;
                }
            }
        });
    }

    handleQuickDataChange(event) {
        try {
            const { detail } = event;
            const { fieldDataId, value, fieldName } = detail;
            this.showQuickDataModal = false;

            let rowId = fieldDataId;
            let fieldValue = value

            let rowData = this.updatedRowData.get(rowId);

            if (rowData === undefined) {
                rowData = new Map();
                this.updatedRowData.set(rowId, rowData);
            }

            rowData.set(fieldName, fieldValue);

            // eslint-disable-next-line @lwc/lwc/no-async-operation
            setTimeout(() => this.setQuickDataComponentFocus(fieldValue), 200);
        } catch (error) {
            SLVHelper.showErrorMessage(error);
        }
    }


    handleTextSearchChange(event) {
        try {
            const { target } = event;
            const { value } = target;
            this.textSearchText = value;
        } catch (error) {
            SLVHelper.showErrorMessage(error);
        }
    }

    handleTextSearch(event) {
        try {
            const { code, key, target } = event;
            const keyCode = code || key;
            const { value } = target;

            let searchStr = value;
            console.log('handleTextSearch called - ' + searchStr + ' for ' + this.pageName);

            if (keyCode === 'Enter' && (searchStr.length > 2 || searchStr.length === 0)) {
                //CUSTOM list views can only do CLIENT SIDE
                if (this.isCustomListView === true) {
                    this.listViewDataRows.forEach(element => {
                        if (searchStr === '') {
                            element.isDisplayed = true;
                        } else {
                            if (element.dataAsCSVString.toLowerCase().includes(searchStr.toLowerCase())) {
                                element.isDisplayed = true;
                            } else {
                                element.isDisplayed = undefined;
                            }
                        }
                    });

                    //CORE list views can do SERVER SIDE
                } else {
                    this.textSearchText = searchStr;
                    this.refreshAllListViewData();
                }
            }
        } catch (error) {
            SLVHelper.showErrorMessage(error);
        }
    }

    setJoinCriteria(value) {
        if (value !== '' && value !== undefined)
            this.joinData = '{"recordIds":"' + value + '"}';
        else
            this.joinData = '';

        if (!this.isInitializing && this.joinData !== '')
            this.refreshAllListViewData();
        else
            this.listViewData = undefined;
    }

    displayHoverDetails(event) {
        try {
            const { currentTarget, pageY, pageX } = event;
            const { dataset } = currentTarget;
            const { sfdcId, apiName, labelName } = dataset;
            if (this.displayRecordPopovers === true) {
                this.hoverSFDCId = sfdcId;
                this.hoverAPIName = apiName;
                this.hoverLabelName = labelName;
                this.hoverIsDisplayed = true;
                this.hoverPositionTop = pageY - 170;
                this.hoverPositionLeft = pageX + 10;
            }
        } catch (error) {
            SLVHelper.showErrorMessage(error);
        }
    }

    hideHoverDetails() {
        this.hoverIsDisplayed = false;
    }

    processHoverError(event) {
        try {
            const { detail } = event;
            this.hideHoverDetails(event);
            if (!this.hoverErrorTypes.includes(detail)) {
                this.hoverErrorTypes = this.hoverErrorTypes + ',' + detail;
            }
        } catch (error) {
            SLVHelper.showErrorMessage(error);
        }
    }

    handleSplitViewClick(event) {
        try {
            const { currentTarget } = event;
            const { dataset } = currentTarget;
            const { rowId } = dataset;
            let recordId = rowId;

            const message = {
                type: 'selectrecordupdate',
                recordIds: recordId,
                objectType: this.selectedObject,
                uniqueComponentId: this.uniqueComponentId
            };
            publish(this.messageContext, LISTVIEW_MC, message);
        } catch (error) {
            SLVHelper.showErrorMessage(error);
        }
    }

    handleEvent(type, requestData) {

        try {
            if (type === 'refreshActions')
                this.getListViewActions();
            else if (type === 'refreshData')
                this.refreshAllListViewData();
            else if (type === 'refreshObjects')
                this.getObjectsList();
            else if (type === 'refreshListViews')
                this.getListViewsForObject();
            else if (type === 'autoRefreshOnce')
                this.handleAutoRefreshButtonClick();
            else if (type === 'autoRefreshOn') {
                this.handleAutoRefreshButtonClick();
                this.handleAutoRefreshButtonClick();
            } else if (type === 'autoRefreshOff') {
                if (this.isRefreshing === true)
                    this.handleAutoRefreshButtonClick();
            } else if (type === 'downloadData')
                this.handleDownloadData();
            else if (type === 'downloadSelectedData')
                this.handleSelectedDownloadData();
            else if (type === 'pinListView')
                this.handlePinningClick();
            else if (type === 'unpinListView')
                this.handleUnpinningClick();
            else if (type === 'spinnerOn')
                this.spinnerOn('Requested Event');
            else if (type === 'spinnerOff')
                this.spinnerOff('Requested Event');
            else if (type === 'showAdmin')
                this.handleAdminButtonClick();
            else if (type === 'updateSetting')
                this.handleUpdateSettingEvent(requestData.name, requestData.value);
            else if (type === 'runAction') {
                let evt = { target: { value: requestData.name } };
                this.handleActionSelect(evt);
            }
            console.log('handleEvent(' + type + ') succeeded');
        } catch (error) {
            console.log('Error in handleEvent: ' + error.message);
            this.dispatchEvent(new CustomEvent('eventresponse', { detail: { type: type, response: 'failed', error: error.message } }));
        }

        console.log('Event response posted (' + this.eventCount + ')');
        this.eventCount++;
    }

    handleUpdateSettingEvent(name, value) {
        switch (name) {
            case 'hasMainTitle': this.hasMainTitle = SLVHelper.toBool(value); break;
            case 'mainTitle': this.mainTitle = value; break;
            case 'allowRefresh': this.allowRefresh = SLVHelper.toBool(value); break;
            case 'singleClickAutoRefresh': this.singleClickAutoRefresh = SLVHelper.toBool(value); break;
            case 'allowHorizontalScrolling': this.allowHorizontalScrolling = SLVHelper.toBool(value); break;
            case 'displayRecordPopovers': this.displayRecordPopovers = SLVHelper.toBool(value); break;
            case 'allowAdmin': this.allowAdmin = SLVHelper.toBool(value); break;
            case 'displayActions': this.displayActions = SLVHelper.toBool(value); break;
            case 'displayReprocess': this.displayReprocess = SLVHelper.toBool(value); break;
            case 'displayURL': this.displayURL = SLVHelper.toBool(value); break;
            case 'displayRowCount': this.displayRowCount = SLVHelper.toBool(value); break;
            case 'noSorting': this.noSorting = SLVHelper.toBool(value); break;
            case 'useSimpleSorting': this.useSimpleSorting = SLVHelper.toBool(value); break;
            case 'displaySelectedCount': this.displaySelectedCount = SLVHelper.toBool(value); break;
            case 'displayModified': this.displayModified = SLVHelper.toBool(value); break;
            case 'displayExportButton': this.displayExportButton = SLVHelper.toBool(value); break;
            case 'displayTextSearch': this.displayTextSearch = SLVHelper.toBool(value); break;
            default: break;
        }
    }

}
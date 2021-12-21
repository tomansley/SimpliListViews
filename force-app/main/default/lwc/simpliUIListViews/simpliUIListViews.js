/* eslint-disable vars-on-top */
/* eslint-disable no-console */
import { LightningElement, wire, track, api  } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import  LISTVIEW_MC  from '@salesforce/messageChannel/SimpliListViewMessageChannel__c';
import { refreshApex } from '@salesforce/apex';
import { subscribe, unsubscribe, publish, APPLICATION_SCOPE, MessageContext } from 'lightning/messageService';
import { encodeDefaultFieldValues } from 'lightning/pageReferenceUtils';
import currentUserId from '@salesforce/user/Id';

//------------------------ LABELS ------------------------
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
import Start_Auto_Refresh from '@salesforce/label/c.Start_Auto_Refresh';
import List_View_Admin from '@salesforce/label/c.List_View_Admin';
import Sort_By from '@salesforce/label/c.Sort_By';
import Save_All_Data from '@salesforce/label/c.Save_All_Data';
import Reset_All_Data from '@salesforce/label/c.Reset_All_Data';
import Save_Row_Data from '@salesforce/label/c.Save_Row_Data';
import Search_List_Dot from '@salesforce/label/c.Search_List_Dot';

//------------------------ METHODS ------------------------
import hasModifyAll from '@salesforce/apex/ListViewController.hasModifyAll';
import getListViewObjects from '@salesforce/apex/ListViewController.getListViewObjects';
import getObjectListViews from '@salesforce/apex/ListViewController.getObjectListViews';
import getListViewData from '@salesforce/apex/ListViewController.getListViewData';
import getListViewActions from '@salesforce/apex/ListViewController.getListViewActions';
import updateChangedListViews from '@salesforce/apex/ListViewController.updateChangedListViews';
import updateAllListViews from '@salesforce/apex/ListViewController.updateAllListViews';
import updateSingleListView from '@salesforce/apex/ListViewController.updateSingleListView';
import updateObjectListViews from '@salesforce/apex/ListViewController.updateObjectListViews';
import getComponentConfig from '@salesforce/apex/ListViewController.getComponentConfig';
import getUserSortConfigs from '@salesforce/apex/ListViewController.getUserSortConfigs';
import updateUserConfig from '@salesforce/apex/ListViewController.updateUserConfig';
import isValidListViewDataRequest from '@salesforce/apex/ListViewController.isValidListViewDataRequest';
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
    @api mode                       = undefined;    //indicates the mode the page is in for displaying the list view. i.e. app, single etc.
    @api pageName                   = '';           //this is NOT the page name but the COMPONENT name
    @api hasMainTitle               = undefined;    //indicates whether the component should display the main title
    @api mainTitle                  = 'List Views'; //the main title of the component.
    @api includedObjects            = '';           //indicates the objects that should be included in the list view
    @api excludedObjects            = '';           //indicates the objects that should be excluded in the list view.
    @api joinFieldName              = '';           //if the component uses data coming in from the message channel this field identifies the lookup field to use that data for.
    @api useMessageChannel          = false;        //identifies if the message channel should be used or not. This is used when components should be passing data between each other for updates.
    @api allowRefresh               = false;        //config indicating whether the auto refresh checkbox is made available.
    @api allowInlineEditing         = false;        //config indicating whether inline editing is available
    @api displayRecordPopovers      = false;        //config indicating whether record popovers should be displayed
    @api allowAdmin                 = false;        //indicates whether the admin button should display to the user
    @api displayActions             = false;
    @api displayReprocess           = false;
    @api displayURL                 = false;
    @api displayRowCount            = false;
    @api displaySelectedCount       = false;
    @api displayOrigButton;                         //this is not used....deprecated.
    @api displayModified            = false;
    @api displayExportButton        = false;
    @api displayTextSearch          = false;        //identifies whether the text search field should be displayed.
    @api singleListViewObject       = '';           //if in SINGLE mode holds the list view object to use.
    @api singleListViewApiName      = '';           //if in SINGLE mode holds the list view API name to use.
    @api excludedRecordPopoverTypes = '';           //Indicates those object types for which record detail popovers should not be displayed when the user moves the mouse over the record URL or name.
    @api set recordId(value)                        //used when component on standard record page. Record page injects record id into component.
         { 
             this.relatedRecordId = value; 
             this.setJoinCriteria(value);
             if (this.mode === 'Related List View') //we could have other moded components inside a record page
                 this.isModeRelatedRecord = true;
         };
         get recordId()
         { 
             return this.relatedRecordId; 
         };
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
 
    @api set joinCriteria(value) 
         {
             this.setJoinCriteria(value);
         }
         get joinCriteria() { 
             return this.joinData; 
         }
 
    //---------------
    //TRACKED FIELDS
    //---------------
    @track isCoreListView = false;
    @track isCustomListView = false;

    @track isModeRelatedRecord = false;  //indicates over and above being a related list view whether the page is a RECORD PAGE
    @track isModeRelated       = false;  //indicates whether the current mode is RELATED LIST VIEW
    @track isModeSingle        = false;  //indicates whether the current mode is SINGLE LIST VIEW
    @track isModeApp           = false;  //indicates whether the current mode is APP PAGE

    @track listwrapperstyle = 'applistscrollwrapper';
    @track relatedRecordId;             //holds the record Id if set by the API.
    @track uniqueComponentId  = '';
    @track hasModifyAll       = false;  //indicates whether the current user is allowed to modify all data.
    @track textSearchText = '';         //holds the current value for text searching.
    @track joinData           = '';     //holds the join data coming in from an external list view.....if it exists.
    @track modifiedText;                //holds the last modified text that should be displayed based on the component config
    @track userSortConfigs;             //holds all user sort configuration for this named component.
    @track componentConfig;                 //holds all user and org wide configuration for this named component.
    @track selectedListView;            //holds the selected list view name
    @track massCreateListView;          //holds the list view to display in the mass create if an alternate list view is provided than the currently displayed list view.
    @track selectedListViewExportName;  //holds the selected list view name + .csv
    @track selectedObject;              //holds the selected object name
    @track objectList;                  //holds the list of objects from which a user can choose one.
    @track listViewList;                //holds the set of list views for the chosen object
    @track listViewData;                //holds the set of data returned for a given object and list view.
    @track listViewDataRows;            //holds ALL PAGES of data that are returned.
    @track listViewDataRowsSize;        //holds total for ALL PAGES of data that are returned.
    @track hasListViewDataRows = false; //identifies if the list view has data rows or not.
    @track selectedAction;              //holds the selected action complex object if one is chosen.
    @track selectedActionKey;           //holds the selected action API name if one is chosen.
    @track selectedActionLabel;         //holds the selected action label if one is chosen.
    @track objectActionList;            //holds the (Complex Object) list of available actions for the selected object
    @track displayedActionList;         //holds the (Complex Object) list of available actions for the selected object based on the number of selected records
    @track showMassCreateModal;         //indicates whether the mass create action modal form should be displayed.
    @track showActionModal;             //indicates whether the action modal form should be displayed.
    @track showFlowModal;               //indicates whether the flow modal form should be displayed.
    @track showAdminModal;              //indicates whether the admin modal form should be displayed.
    @track selectedRecordIdsStr;        //holds the set of record ids that have been selected as a string
    @track selectedRecordIds;           //holds the set of record ids that have been selected
    @track selectedRecordCount = 0;     //the number of records selected. Passed into the modal dialog.  
    @track isPinned = false;            //identifies whether this list view and object have been pinned.
    @track pinnedListView = undefined;  //the list view that is pinned if there is a pinned list view.
    @track pinnedObject = undefined;    //the object that is pinned if there is a pinned list view.
    @track isRefreshed = false;         //identifies whether this list views data is being refreshed at intervals.
    @track spinner = false;             //identifies if the PAGE spinner should be displayed or not.
    @track dataSpinner = false;         //identifies if the DATA spinner should be displayed or not.
    @track firstListViewGet = true;     //indicates whether this is the first time the list views are being retrieved.
    @track canDisplayActions = false;    //indicates whether the page is in a position where the actions list is active
    @track offset = -1;
    @track rowLimit = -1;
    @track refreshRate = '';            //the refresh rate in seconds if the list view is auto refreshing.

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

    //for handling sorting
    @track listViewSortData = new Map();
    @track columnSortData = new Map();
    @track columnSortDataStr = '';

    //for handling edited records
    updatedRowData = new Map();
    rowDataStr = '';

    //for tracking list view init process
    @track isInitialized = true;        //indicates whether the list views have been initialized for the first time or not.
    @track isInitializedCheck = false;  //indicates whether the list views have been checked for initialization
    @track showProgress = false;        //indicates whether the progress bar should be displayed
    @track batchId = '';                //indicates the batch Id of the list view batch process.
    @track isInitializing = true;       //indicates whether we are initializing the page or not.

    @track refreshTitle = 'Click to perform full list view refresh';
  
    //for message channel handlers
    subscription = null;
    receivedMessage;

    label = { Rows, Selected, Select_Action, Export_All, Export_Selected, Loading, Select_Object, Object, 
              Select_List_View, List_View, Go_To_Original, Unpin_List_View, Pin_List_View, Stop_Auto_Refresh, 
              Start_Auto_Refresh, List_View_Admin, Sort_By, Save_All_Data, Reset_All_Data, Save_Row_Data, 
              Search_List_Dot };

    /*
     * Method which gets called when the class is being instantiated
     * Note that we do not have access to any local variables in the constructor
     */
    constructor() {
        super();

        //if the user recently changed a core list view this should do an immediate update. 
        //Only the last modified list view is processed.
        updateChangedListViews();
    }
    
    /*
     * Method which gets called after the class has been instantiated
     * but before it is rendered. We do have access to variables in this method.
     */
    async renderedCallback() {

        console.log('Starting simpliUIListViews.renderedCallback for ' + this.pageName);
        console.log('Record id - ' + this.recordId);

        //this ensures we only call this once for each page load
        if (this.mode !== undefined && this.componentConfig === undefined && this.isInitialized === true) {

            loadScript(this, JSPDF)
            .then(() => {
                console.log('then');
                // load the autotable js file
                loadScript(this, JSPDF_AUTO_TABLE);
            })
            .catch(error => {
                console.log('error');
                throw(error);
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
            this.componentConfig = await getComponentConfig({compName: this.pageName });

            this.handleComponentConfig();

            //get user sort config
            this.userSortConfigs = await getUserSortConfigs({compName: this.pageName });

            this.handleUserSortConfigs();

            if (this.mode === 'App Page') {
                this.isModeApp        = true;
                this.getObjectsList();             

            } else if (this.mode === 'Single List View') {

                if (this.singleListViewObject === '' || this.singleListViewApiName === '')
                {
                    this.dispatchEvent(new ShowToastEvent({
                        title: 'Single List View Configuration Error',
                        message: 'If using Single List View mode the list view object and API name must be provided.',
                        variant: 'error',
                        mode: 'sticky'
                    }));
                    this.spinnerOff('renderedCallback');
                    return;
                } else {

                    this.isModeSingle     = true;
                    this.selectedObject   = this.singleListViewObject;
                    this.selectedListView = this.singleListViewApiName;

                    this.refreshAllListViewData();
                }
            
            } else if (this.mode === 'Related List View') {

                if (this.singleListViewObject === '' || this.singleListViewApiName === '' || this.joinFieldName === '')
                {
                    this.dispatchEvent(new ShowToastEvent({
                        title: 'Related List View Configuration Error',
                        message: 'If using Related List View mode the list view object, list view API name and join field name must be provided.',
                        variant: 'error',
                        mode: 'sticky'
                    }));
                    this.spinnerOff('renderedCallback');
                    return;
                } else {
                    this.isModeRelated    = true;
                    this.listwrapperstyle = 'relatedlistscrollwrapper';
                    this.selectedObject   = this.singleListViewObject;
                    this.selectedListView = this.singleListViewApiName;

                    if (this.joinData !== '') //only set list view data if there is join data.
                    {
                        this.refreshAllListViewData();
                    } else {
                        this.isInitializing = false;
                        this.spinnerOff('renderedCallback');
                    }
                }
            }

        } else {
            console.log('No page initialization needed for ' + this.pageName);
        }
        console.log('Finished renderedCallback for ' + this.pageName);
    }
    
    handleComponentConfig() {

        try {
            console.log('Component configs retrieved successfully - ' + this.componentConfig + ' for ' + this.pageName);
            console.log('Component config size - ' + this.componentConfig.length + ' for ' + this.pageName);

            let pinnedListView = this.componentConfig.pinnedListView;
            console.log('Pinned list view string - ' + pinnedListView);

            if (this.toBool(this.componentConfig.AllowAdmin) === false) { 
                if (this.hasModifyAll === true)
                    this.allowAdmin = true;
                else
                    this.allowAdmin = false;
            }
            else if (this.toBool(this.componentConfig.AllowAdmin) === true) { this.allowAdmin = true; }
            if (this.toBool(this.componentConfig.DisplayActionsButton) === false) { this.displayActions = false; }
            if (this.toBool(this.componentConfig.DisplayListViewReprocessingButton) === false) { this.displayReprocess = false; }
            if (this.toBool(this.componentConfig.DisplayOriginalListViewButton) === false) { this.displayURL = false; }
            if (this.toBool(this.componentConfig.DisplayRowCount) === false) { this.displayRowCount = false; }
            if (this.toBool(this.componentConfig.DisplaySelectedCount) === false) { this.displaySelectedCount = false; }
            if (this.toBool(this.componentConfig.DisplayTextSearch) === false) { this.displayTextSearch = false; }
            if (this.toBool(this.componentConfig.AllowDataExport) === false) { this.displayExportButton = false; }
            if (this.toBool(this.componentConfig.AllowAutomaticDataRefresh) === false) { this.allowRefresh = false; }
            if (this.toBool(this.componentConfig.AllowInlineEditing) === false) { this.allowInlineEditing = false; }
            if (this.toBool(this.componentConfig.DisplayRecordPopovers) === false) { this.displayRecordPopovers = false; }

            this.excludedRecordPopoverTypes = this.excludedRecordPopoverTypes + this.componentConfig.ExcludedRecordPopoverTypes;

            //otherwise if they have a pinned list view then use it, if possible.
            if (pinnedListView != undefined && pinnedListView != '') {
                this.isPinned = true;
                this.pinnedObject = pinnedListView.substring(0, pinnedListView.lastIndexOf(':'));
                this.pinnedListView = pinnedListView.substring(pinnedListView.lastIndexOf(':')+1);

                console.log('Pinned object    - ' + this.pinnedObject);
                console.log('Pinned list view - ' + this.pinnedListView);

            } else {
                console.log('There is no pinned list view for ' + this.pageName);
                this.isInitializing = false;
            }
        } catch(error) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error Retrieving User Config',
                message: 'There was an error retrieving the user config. Please see an administrator - ' + error.body.message,
                variant: 'error',
                mode: 'sticky'
            }));
            console.log('Error Detected - ' + error.body.message + ' | ' + error.body.stackTrace + ' for ' + this.pageName);
        };

    }

    handleUserSortConfigs() {
        try {
            console.log('User sort configs retrieved successful - ' + this.userSortConfigs + ' for ' + this.pageName);

            var listViewSortFields = JSON.parse(this.userSortConfigs);
            console.log('List view sort fields size - ' + listViewSortFields.listviews.length); 

            //EXAMPLE JSON - {"listviews": [{"name": "Account:Simpli_LV_Acct_1","fields": [{"sortIndex": "0", "fieldName": "Name", "sortDirection": "true"},{"sortIndex": "1", "fieldName": "BillingState", "sortDirection": "false"}]}, {"name": "Account:PlatinumandGoldSLACustomers","fields": [{"sortIndex": "0", "fieldName": "Name", "sortDirection": "true"},{"sortIndex": "1", "fieldName": "BillingState", "sortDirection": "false"},{"sortIndex": "2", "fieldName": "Id", "sortDirection": "false"}]}]}
            for (var m in listViewSortFields.listviews) {

                let listviewSorting = listViewSortFields.listviews[m];
                //if we are working with the current list view
                if (listviewSorting.name === this.pinnedObject + ':' + this.pinnedListView
                    || listviewSorting.name === this.selectedObject + ':' + this.selectedListView
                    || listviewSorting.name === this.singleListViewObject + ':' + this.singleListViewApiName) {
                    console.log('Found sorting for current list view');
                    for (var i = 0; i < listviewSorting.fields.length; i++) {

                        let sortDirection = listviewSorting.fields[i].sortDirection;

                        if (sortDirection === undefined || sortDirection === '') {
                            sortDirection = true;
                        } else {
                            sortDirection = this.toBool(sortDirection)
                        }

                        let columnData = [Number(listviewSorting.fields[i].sortIndex), listviewSorting.fields[i].fieldName, sortDirection];
                        this.columnSortData.set(Number(listviewSorting.fields[i].sortIndex), columnData);
                    }

                    this.columnSortDataStr = JSON.stringify( Array.from(this.columnSortData));
                    console.log('XXXX Column Sort Data Str - ' + this.columnSortDataStr);
                    this.listViewSortData.set(listviewSorting.name, this.columnSortData);
                
                //for all other list views
                } else {
                    let columnSortData = new Map();
            
                    for (var i = 0; i < listviewSorting.fields.length; i++) {

                        let sortDirection = listviewSorting.fields[i].sortDirection;
                        
                        if (sortDirection === undefined || sortDirection === '') {
                            sortDirection = true;
                        } else {
                            sortDirection = this.toBool(sortDirection)
                        }

                        let columnData = [Number(listviewSorting.fields[i].sortIndex), listviewSorting.fields[i].fieldName, sortDirection];
                        columnSortData.set(Number(listviewSorting.fields[i].sortIndex), columnData);
                    }

                    this.listViewSortData.set(listviewSorting.name, columnSortData);

                }
            } 
        } catch(error) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error Handling User Config',
                message: 'There was an error handling the user sort config. Please see an administrator - ' + error.body.message,
                variant: 'error',
                mode: 'sticky'
            }));
            console.log('Error Detected - ' + error.body.message + ' | ' + error.body.stackTrace + ' for ' + this.pageName);
        };
    }
    /*
     * Used for handling the message channel
     */
    @wire(MessageContext)
    messageContext;
    
    
    @wire (hasModifyAll, { })
    wiredHasModifyAll({ error, data }) {
        if (data) { 
            console.log('Is sys admin called successfully - ' + data + ' for ' + this.pageName);
            this.hasModifyAll = data; 
        } else if (error) { 
            console.log('Error Detected - ' + error.body.message + ' | ' + error.body.stackTrace + ' for ' + this.pageName);
        }
    }

    handleInitializedCheck(event) {
        this.isInitialized = event.detail;
        this.isInitializedCheck = true;
        if (this.isInitialized === false)
        {
            this.spinner = false; //a special case where we set it directly.
        }
    }     

   /*
     * Wiring to get the (Complex Object) list of actions available for the provided object type
     */
    @wire (getListViewActions, { objectType: '$selectedObject', listViewName: '$selectedListView', componentName: '$pageName' })
    wiredListViewActions({ error, data }) {
        if (data) { 
            console.log('List view actions retrieval successful for ' + this.pageName);
            this.objectActionList = data; 
            
            console.log('Object action list size - ' + this.objectActionList.length); 
            if (this.objectActionList.length === 0 || this.displayActions === false) {
                this.canDisplayActions = false;
            } else if (this.toBool(this.displayActions) === true) {
                this.canDisplayActions = true;
                this.handleListViewActions(0);
            }

        } else if (error) { 
            console.log('Error Detected - ' + error.body.message + ' | ' + error.body.stackTrace);
            this.objectActionList = undefined; 
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error Retrieving Actions',
                message: 'There was an error retrieving the list view actions. Please see an administrator - ' + error.body.message,
                variant: 'error',
                mode: 'sticky'
            }));
        }
    }

    handleListViewActions(numSelectedRecords) {
        
        this.displayedActionList = new Array();

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

    refreshAllListViewData() {
        this.offset = -1;
        this.selectedRecordCount = 0;
        this.isEdited = false;
        this.textSearchText = '';
        this.hoverIsDisplayed = false;
        let selectedRows = this.template.querySelectorAll('lightning-input');
        selectedRows.forEach(element => element.checked = false);

        this.getListViewDataPage();
    }

    async getListViewDataPage() {

        this.spinnerOn('getListViewDataPage');

        try {
            let listViewDataResult = await getListViewData({pageName: this.pageName, objectName: this.selectedObject, listViewName: this.selectedListView, sortData: this.columnSortDataStr, joinFieldName: this.joinFieldName, joinData: this.joinData, offset: this.offset });
            this.handleListViewDataPage(listViewDataResult);
        } catch(error) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error Retrieving List View Data',
                message: 'There was an error retrieving the list view data. Please see an administrator - ' + error.message,
                variant: 'error',
                mode: 'sticky'
            }));
        }

        this.spinnerOff('getListViewDataPage');

    }

    handleListViewDataPage(listViewDataResult) {

        console.log('Starting refreshListViewData - ' + this.pageName + ' - ' + this.selectedObject + ' - ' + this.selectedListView + ' - ' + this.joinFieldName + ' - ' + this.offset + ' for ' + this.pageName);
        console.log('XXXXX columnSortDataStr - ' + this.columnSortDataStr + ' for ' + this.pageName);
        console.log('Selected list view - ' + this.selectedListView + ' for ' + this.pageName);

        if (this.listViewData === undefined) {
            console.log('this.listViewData            - undefined for ' + this.pageName);
            console.log('this.listViewData.coreListId - undefined for ' + this.pageName);
        } else {
            console.log('this.listViewData            - ' + this.listViewData + ' for ' + this.pageName);
            console.log('this.listViewData.coreListId - ' + this.listViewData.coreListId + ' for ' + this.pageName);
        }

        //if this is the first time we are initializing the list view data OR we are refreshing the data.
        if (this.listViewData === undefined || this.listViewData.coreListId !== listViewDataResult.coreListId || this.offset === -1 || (this.offset === this.listViewData.listView.offset && this.offset === -1))
        {
            //initialize list view info
            this.listViewData = listViewDataResult;

            //initialize list view row data
            this.listViewDataRows = listViewDataResult.rows;

        //else add the new data to the existing data
        } else {
            this.listViewDataRows = this.listViewDataRows.concat(listViewDataResult.rows);
        }

        //update the data rows size.
        this.listViewDataRowsSize = this.listViewDataRows.length;  

        if (this.listViewData.hasTotalsRow)
        {
            this.listViewDataRowsSize--;
        }

        if (this.listViewDataRowsSize === 0)
            this.hasListViewDataRows = false;
        else
            this.hasListViewDataRows = true;


        console.log('this.listViewDataRows.length         - ' + this.listViewDataRows.length + ' for ' + this.pageName);
        console.log('listViewDataResult.listView.rowLimit - ' + listViewDataResult.listView.rowLimit + ' for ' + this.pageName);
        console.log('this.offset                          - ' + this.offset + ' for ' + this.pageName);
        console.log('listViewDataResult.listView.offset   - ' + listViewDataResult.listView.offset + ' for ' + this.pageName);
    
        //if we have not reached our max limit
        if (this.listViewDataRows.length < listViewDataResult.listView.rowLimit)
        {
            //if the offset has not changed then we are done.
            if (this.offset === listViewDataResult.listView.offset)
            {
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
        if (this.displayModified === true)
        {
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

        this.refreshTitle = 'Click to perform list view refresh on current list view';
        this.textSearchText = '';
        this.isInitializing = false;

    }

    getObjectsList()
    {
        console.log('Starting getObjectsList');
        getListViewObjects({includedObjects: this.includedObjects, excludedObjects: this.excludedObjects })
        .then(result => {
            this.objectList = result; 

            if (this.objectList !== undefined && this.objectList.length > 0)
            {
                console.log('Object list has been populated with size - ' + this.objectList.length + ' for ' + this.pageName);
    
                if (this.pinnedObject !== undefined)
                {
                    //check if we have an object that matches the users pinned object. (could be stale)
                    var found = this.objectList.find(element => element.value === this.pinnedObject);
    
                    //if we do have an object then set it and get the pinned list view.
                    if (found !== undefined)
                    {
                        console.log('Object IS in the object list for ' + this.pageName);
                        this.selectedObject = this.pinnedObject;
                        this.getListViewsForObject();
                    }
                    this.pinnedObject = undefined;
                } else if (this.isInitializing === false) {
                    this.spinnerOff('getObjectsList');
                }
    
            }
        })
        .catch(error => {
            this.spinnerOff('getObjectsList');
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error Retrieving List View Objects',
                message: 'There was an error retrieving the list view objects. Please see an administrator - ' + error.body.message,
                variant: 'error',
                mode: 'sticky'
            }));
            console.log('Error Detected - ' + error.body.message + ' | ' + error.body.stackTrace);
        });
    }

    getListViewsForObject()
    {
        getObjectListViews({objectName: this.selectedObject })
        .then(result => {
            console.log('Object list view retrieval successful for ' + this.pageName);
            this.listViewList = result; 
            console.log('Object list view size - ' + this.listViewList.length + ' for ' + this.pageName);
            console.log('Pinned list view      - ' + this.pinnedListView + ' for ' + this.pageName);
            console.log('First List View Get   - ' + this.firstListViewGet + ' for ' + this.pageName);
            
            //if we have no list views to display then either the object name is bad or the user does not have access to the object.
            if (this.listViewList.length === 0)
            {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Error Retrieving Object List Views',
                    message: 'No list views available as the user does not have access to this object.',
                    variant: 'error',
                    mode: 'sticky'
                }));
            } else if (this.urlListView != undefined) {
                this.selectedListView = this.urlListView;
                this.selectedListViewExportName = this.selectedListView + '.csv';
            } else if (this.pinnedListView != undefined && this.firstListViewGet === true) {

                console.log('We have a pinned list view for ' + this.pageName);
                //check if we have the list view in the list. (it could be a stale pinning)
                const found = this.listViewList.find(element => element.value === this.pinnedListView);

                //if we have a valid list view name
                if (found !== undefined)
                {
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

            this.spinnerOff('getListViewsForObject'); 
        })
        .catch(error => {
            this.spinnerOff('getListViewsForObject');
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error Retrieving Object List Views',
                message: 'There was an error retrieving ' + this.selectedObject + ' list views data. This usually indicates the user does not have read access to the object. Please see an administrator if you believe this to be an error - ' + error.body.message,
                variant: 'error',
                mode: 'sticky'
            }));
            console.log('Error Detected - ' + error.body.message + ' | ' + error.body.stackTrace);
        });

    }

    /*
     * Method which subscribes this component to a defined message channel. This subscription
     * allows the components to send messages to each other.
     */
    subscribeMC() {
        //if (this.isModeRelatedRecord !== true) //only disregard if we are on a RECORD PAGE related list view
        //{
            if (this.subscription) {
                return;
            }
            this.subscription = subscribe(
                this.messageContext,
                LISTVIEW_MC, (message) => {
                                            this.handleMessage(message);
                                          },
                                          {scope: APPLICATION_SCOPE}
            );
        //}
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
        console.log(this.pageName + ' received a message from ' + this.receivedMessage.uniqueComponentId + ' for ' + this.pageName);

        if (this.receivedMessage.uniqueComponentId == this.uniqueComponentId)
        {
            return;
        }

        //if we have no record Id and its a NON-RECORD page RELATED LIST then set rows to 0
        if (this.receivedMessage.recordIds === '' 
            && this.isModeRelated === true 
            && this.isModeRelatedRecord === false)
        {
            this.hasListViewDataRows = false;
            return;
        } else if (this.receivedMessage.recordIds === '' 
            && this.isModeSingle === true)
        {
            this.hasListViewDataRows = false;
            return;
        }

        //if we have a list view selected AND if we have selected a specific list view to update
        if (this.selectedObject != undefined 
                && this.joinFieldName != undefined 
                && this.joinFieldName != ''
                && this.isModeRelatedRecord === false)
        {
            console.log('We have a joined field name - ' + this.joinFieldName + ' for ' + this.pageName);
            console.log('Record ids from message - ' + this.receivedMessage.recordIds + ' for ' + this.pageName);
            this.joinData = JSON.stringify(message);
            console.log('Join Data JSON - ' + this.joinData + ' for ' + this.pageName);

            this.spinnerOn('handleMessage');

            //we need to check and see if this message is valid for this component.
            //I think we need to get rid of this.......causes data reload to take too long.
            isValidListViewDataRequest({objectName: this.selectedObject, joinFieldName: this.joinFieldName, joinData: this.joinData })
            .then(result => {
                console.log('isValidListViewDataRequest returned - ' + result + ' for ' + this.pageName);

                if (result === 'success') {
                    this.refreshAllListViewData();    
                } else {
                    this.spinnerOff('handleMessage');
                }
    
            })
            .catch(error => {
                console.log('Error Detected - ' + error.body.message + ' | ' + error.body.stackTrace + ' for ' + this.pageName);
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Processing Error',
                    message: 'There was an error processing the list view. Please see an administrator - ' + error.body.message,
                    variant: 'error',
                    mode: 'sticky'
            }));
        });

        } else {
            console.log('Page names are the same or we do not have a joined field name so ignoring message! for ' + this.uniqueComponentId);
        }

    }

    handleAutoRefreshData() {

        console.log('Refreshing data for ' + this.pageName);

        if (this.isRefreshed) {

            this.refreshAllListViewData();            

            if (this.refreshRate === '')
            {
                getListViewConfigParameter({objectName: this.selectedObject, listViewName: this.selectedListView, paramName: 'RefreshRate'})
                .then(result => {
                    this.refreshRate = result * 1000;  //change to milliseconds                  
                })
                .catch(error => {
                    this.refreshRate = 25000 //if error then set to 25 secs.
                });
            }
            var utcDate = new Date().toUTCString(); 
            console.log('Refresh rate - ' + this.refreshRate + ' - ' + utcDate);

            //https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Function/bind
            //look at its use with setTimeout down the page!
            setTimeout(this.handleAutoRefreshData.bind(this), this.refreshRate);

        }
    }

    handleAutoRefreshButtonClick(event) {
        console.log('Auto refresh button clicked! for ' + this.pageName);
        console.log('Refresh was set to ' + this.isRefreshed + ' for ' + this.pageName);

        this.isRefreshed = !this.isRefreshed;

        if (this.isRefreshed === true)
        {
            this.dispatchEvent(new ShowToastEvent({
                title: 'List View Auto Refresh Started',
                message: 'List view refresh has been started. To stop refreshing click the refresh button again.',
                variant: 'success',
                mode: 'dismissable'
            }));

        } else {
            this.dispatchEvent(new ShowToastEvent({
                title: 'List View Auto Refresh Stopped',
                message: 'List view refresh has been stopped. To start refreshing click the refresh button again.',
                variant: 'success',
                mode: 'dismissable'
            }));
    
        }

        this.handleAutoRefreshData();
        console.log('Refresh now set to ' + this.isRefreshed + ' for ' + this.pageName);
    }

    /*
     * Called when the user clicks the data download button.
     * This returns the data for the current list view in CSV format.
     */
    handleDownloadData(event) {
        console.log('Data export button clicked for ' + this.pageName);
        
        //get the header values
        var dataStr = this.listViewData.headersAsCSVString;

        this.listViewDataRows.forEach(element => { 
            dataStr = dataStr + element.dataAsCSVString;      
        });


        var data = new Blob([dataStr]);
        event.target.href = URL.createObjectURL(data);

    }

    /*
     * Called when the user clicks the SELECTED data download button.
     * This returns the data for the current list view in CSV format.
     */
    handleSelectedDownloadData(event) {
        console.log('Selected data export button clicked for ' + this.pageName);
        
        //get the header values
        var dataStr = this.listViewData.headersAsCSVString;

        //get the selected record Ids
        var selectedRecords = new Set();
        let selectedRows = this.template.querySelectorAll('lightning-input');
        selectedRows.forEach(element => { 
                                            if (element.checked === true && element.value != 'all')
                                            {
                                                selectedRecords.add(element.value);
                                            }            
                                        });

        this.listViewDataRows.forEach(element => { 
                                                    if (selectedRecords.has(element.rowId)) {
                                                        dataStr = dataStr + element.dataAsCSVString;
                                                    }            
                                                });

        //turn string into blob
        var data = new Blob([dataStr]);

        //send blob to user.
        event.target.href = URL.createObjectURL(data);

    }

    /*
     * Called when a user checks a box next to a record for 
     * selection to be processed. This method is really for
     * handling the case when the ALL checkbox is checked. It 
     * also handles sending the record Ids checked to the message
     * channel.
     */
    handleRecordSelectChange(event) {
        console.log('handleRecordSelectChange Started for ' + this.pageName);
        this.spinnerOn('handleRecordSelectChange');
        console.log('Record selected - ' + event.target.checked + ': ' + event.target.value + ' for ' + this.pageName);

        //get all checkbox components
        let selectedRows = this.template.querySelectorAll('lightning-input');

        //if we have selected "All" then run through all components setting them true or false.
        if (event.target.value === 'all')
        {
            const checked = event.target.checked
            selectedRows.forEach(element => element.checked = checked);

            if (event.target.checked === true) {
                this.selectedRecordCount = this.listViewDataRowsSize;
            } else {
                this.selectedRecordCount = 0;
            }

        } else {
            if (event.target.checked === true) {
                this.selectedRecordCount++;
            } else {
                this.selectedRecordCount--;
            }
        }

        this.handleListViewActions(this.selectedRecordCount);

        //if we are sending the selection to other components.
        if (this.useMessageChannel === true) {
            console.time('handleRecordSelectChange3');

            console.log('Sending to message channel for ' + this.uniqueComponentId);
            //run through all the checkbox components again now that they have been set
            var recordIds = '';        

            selectedRows.forEach(element => { 
                if (element.checked === true && element.value != 'all')
                {
                    //the value includes the row number so remove that from the end as we only want the Ids
                    const indexOf = element.value.indexOf(':');
                    var recordId = element.value.substring(0, indexOf);
                    if (recordId !== '' && recordId !== undefined) //if we clicked "All" then the first one is blank.
                        recordIds = recordIds + recordId + ',';
                }            
            });

            //remove the last comma if there is one.
            if (recordIds.length > 0) {
                recordIds = recordIds.substring(0, recordIds.lastIndexOf(','));
            }

            /*
             * Publish the selected rows so that other components can use them if desired.
             * we do this regardless of whether there are records Ids or not as the user
             * may have clicked a single row and then unclicked. We need to send a message
             * about that deselected row.
             *
             * Also, we send the page name sending the message otherwise this same component
             * will potentially get the message!
             */
            const message = {
                recordIds: recordIds,
                objectType: this.selectedObject,
                uniqueComponentId: this.uniqueComponentId
            };
            publish(this.messageContext, LISTVIEW_MC, message);        
            console.timeEnd('handleRecordSelectChange3');
        
        } else {
            console.log('NOT sending to message channel for ' + this.uniqueComponentId);
        }

        this.spinnerOff('handleRecordSelectChange');
    }

    /*
     * Called when a user is selecting a list view and 
     * they have changed the object of the list view.
     */
    handleObjectChange(event) {
        this.spinnerOn('handleObjectChange');
        this.selectedListView = undefined;
        this.selectedListViewExportName = undefined;
        this.selectedObject = event.target.value;
        this.listViewList = undefined;
        this.listViewData = undefined;
        this.listViewDataRows = undefined;
        this.objectActionList = undefined;
        this.displayedActionList = undefined;
        this.columnSortDataStr = '';
        this.columnSortData = new Map(); 
        this.modifiedText = '';
        this.isRefreshed = false;
        console.log('Object selected - ' + this.selectedObject + ' for ' + this.pageName);
        this.getListViewsForObject();
    }

    /*
     * Called when a user changed a list view, used 
     * to retrieve record data.
     */
    handleListViewSelected(event) {

        console.log('Old list view - ' + this.selectedListView + ' for ' + this.pageName);
        console.log('Sort data - ' + this.listViewSortData + ' for ' + this.pageName);
        this.spinnerOn('handleListViewSelected');
        this.isRefreshed = false;
       
        //set the old column sort information into the list view sort data for caching otherwise it disappears.
        if (this.columnSortDataStr !== '')
        {
            this.listViewSortData.set(this.selectedObject + ':' + this.selectedListView, this.columnSortData);
        }

        //set the new selected list view
        this.selectedListView = event.target.value;
        console.log('New list view - ' + this.selectedListView + ' for ' + this.pageName);
        this.selectedListViewExportName = this.selectedListView + '.csv';

        //set the column sort information for the NEW list view
        if (this.listViewSortData.get(this.selectedObject + ':' + this.selectedListView) !== undefined)
        {
            this.columnSortData = this.listViewSortData.get(this.selectedObject + ':' + this.selectedListView);
            this.columnSortDataStr = JSON.stringify( Array.from(this.columnSortData));
        
        } else {
            this.columnSortDataStr = '';
            this.columnSortData = new Map();  
        }

        //if we are not in the construction of the page and we change the list view and its the pinned list view
        if (this.componentConfig != undefined && this.pinnedObject === this.selectedObject && this.pinnedListView === this.selectedListView) {
            this.isPinned = true;
        } else {
            this.isPinned = false;
        }
        this.refreshTitle = 'Click to perform list view refresh on current list view';

        console.log('Starting ListView Data Refresh for ' + this.pageName);

        this.refreshAllListViewData();
    }

    /*
     * Method for handling when a user pins a given list view.
     */
    handlePinningClick(event) {
        this.isPinned = true;

        updateUserConfig({compName: this.pageName, configName: 'pinnedListView', value: this.selectedObject + ':' + this.selectedListView })
        .then(result => {
            console.log('List view pinning successful for ' + this.pageName);
            this.dispatchEvent(new ShowToastEvent({
                title: 'List View Pinned',
                message: 'List view successfully pinned.',
                variant: 'success',
                mode: 'dismissable'
            }));
        })
        .catch(error => {
            console.log('Error Detected - ' + error.body.message + ' | ' + error.body.stackTrace + ' for ' + this.pageName);
            this.dispatchEvent(new ShowToastEvent({
                title: 'Processing Error',
                message: 'There was an error during user configuration update. Please see an administrator - ' + error.body.message,
                variant: 'error',
                mode: 'sticky'
            }));
        });

    }

    /*
     * Method for handling when a user UNPINS a given list view.
     */
    handleUnpinningClick(event) {

        updateUserConfig({compName: this.pageName, configName: 'pinnedListView', value: '' })
        .then(result => {
            console.log('RESULT - ' + result);
            if (result === 'success')
            {
                console.log('List view unpinning successful for ' + this.pageName);
                this.dispatchEvent(new ShowToastEvent({
                    title: 'List View Unpinned',
                    message: 'List view successfully unpinned.',
                    variant: 'success',
                    mode: 'dismissable'
                }));
                this.isPinned = false;
            } else {
                console.log('List view unpinning NOT successful for ' + this.pageName);
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Error Unpinning List View',
                    message: 'There was a problem unpinning the list view. This might be due to user permissions. Please see an administrator.',
                    variant: 'error',
                    mode: 'sticky'
                }));
            }
        })
        .catch(error => {
            console.log('Error Detected - ' + error.body.message + ' | ' + error.body.stackTrace + ' for ' + this.pageName);
            this.dispatchEvent(new ShowToastEvent({
                title: 'Processing Error',
                message: 'There was an error unpinning the list view due to user configuration. Please see an administrator - ' + error.body.message,
                variant: 'error',
                mode: 'sticky'
            }));
        });
    }
    
    /*
     * Called when a URL on the pages table data is clicked
     */
    handleURLClick(event) {

        var target = event.target.target;
        //this is the URL
        console.log('URL clicked - ' + event.target.href + ' for ' + this.pageName);
        console.log('URL target  - ' + target + ' for ' + this.pageName);

        //hack to get the record Id from the URL
        const chars = event.target.href.split('/');
        console.log('Id - ' + chars[5] + ' for ' + this.pageName);

        //stop the link from doing its usual thing as we will be doing our thing.
        event.preventDefault();
        event.stopPropagation();
        
        //if we are opening a up a new window then use the whole URL as is.
        if (target === '_blank')
        {
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

    dataSpinnerOn() {
        this.dataSpinner = true;
        this.canDisplayActions = false;
        console.log('Data Spinner ON for ' + this.pageName);
    }

    dataSpinnerOff() {
        this.dataSpinner = false;
        if (this.objectActionList !== undefined && this.objectActionList.length > 0 && this.toBool(this.displayActions) === true) {
            this.canDisplayActions = true;
        }
        console.log('Data Spinner OFF for ' + this.pageName);
    }

    spinnerOn(message) {
        this.spinner = true;
        console.log('Spinner ON - ' + message + ' - ' + this.pageName);
    }

    spinnerOff(message) {
        if (this.isInitializing === false)
        {
            this.spinner = false;
            console.log('Spinner OFF  - ' + message + ' - ' + this.pageName);
        }
        //var stack = new Error().stack
        //console.log( stack )
    }

    //called when a user clicks the button to refresh the list views.
    handleProcessListViewsButtonClick(event) {

        this.spinnerOn('handleProcessListViewsButtonClick');
        console.log('Listview process button clicked for ' + this.pageName);
        console.log('selectedObject - ' + this.selectedObject + ' for ' + this.pageName);
        console.log('selectedListView - ' + this.selectedListView + ' for ' + this.pageName);
        console.log('DATA - ' + event.currentTarget.dataset.type);

        //if we need to initialize after install or upgrade
        if (event.currentTarget.dataset.type !== undefined && event.currentTarget.dataset.type === 'full' && this.isInitialized === false)
        {
            this.selectedObject = undefined;
            this.selectedListView = undefined;
        }

        //if we have selected a specific list view to update
        if (this.selectedObject != undefined && this.selectedListView != undefined && this.isInitialized === true)
        {
            console.log('Updating SINGLE list view for ' + this.pageName);

            updateSingleListView({objectType: this.selectedObject, listViewName: this.selectedListView })
                .then(result => {

                    //if we have an error then send an ERROR toast.
                    if (result === 'success')
                    {
                        this.dispatchEvent(new ShowToastEvent({
                            title: 'List View Updated Successfully',
                            message: 'List view has been updated and refreshed successfully.',
                            variant: 'success',
                            mode: 'dismissable'
                        }));
                        this.dispatchEvent(new CustomEvent('processlistviewclick'));
                        this.refreshAllListViewData();

                    //else send an ERROR toast.
                    } else {
                        this.dispatchEvent(new ShowToastEvent({
                            title: 'Processing Error',
                            message: 'There was an error processing the list view. Please see an administrator - ' + error.body.message,
                            variant: 'error',
                            mode: 'sticky'
                        }));

                        this.spinnerOff('handleProcessListViewsButtonClick1');
                    }
                })
                .catch(error => {
                    console.log('Error Detected - ' + error.body.message + ' | ' + error.body.stackTrace);
                    this.dispatchEvent(new ShowToastEvent({
                        title: 'Processing Error',
                        message: 'There was an error processing the list view. Please see an administrator - ' + error.body.message,
                        variant: 'error',
                        mode: 'sticky'
                    }));
                    this.spinnerOff('handleProcessListViewsButtonClick2');
                });


        }
        
        //if we have selected an objects list views to update
        else if (this.selectedObject != undefined && this.selectedListView === undefined && this.isInitialized === true)
        {
            console.log('Updating OBJECT list views for ' + this.pageName);

            updateObjectListViews({objectType: this.selectedObject })
                .then(result => {

                    //if we have an error then send an ERROR toast.
                    if (result === 'success')
                    {
                        this.dispatchEvent(new ShowToastEvent({
                            title: 'List Views Updated Successfully',
                            message: 'List views have been updated successfully.',
                            variant: 'success',
                            mode: 'dismissable'
                        }));
                        this.dispatchEvent(new CustomEvent('processlistviewclick'));
                        this.getListViewsForObject();
                        this.spinnerOff('handleProcessListViewsButtonClick3');

                    //else send an ERROR toast.
                    } else {
                        this.dispatchEvent(new ShowToastEvent({
                            title: 'Processing Error',
                            message: 'There was an error processing the list views. Please see an administrator - ' + result,
                            variant: 'error',
                            mode: 'sticky'
                        }));
                        this.spinnerOff('handleProcessListViewsButtonClick4');
                    }
                })
                .catch(error => {
                    console.log('Error Detected - ' + error.body.message + ' | ' + error.body.stackTrace + ' for ' + this.pageName);
                    this.dispatchEvent(new ShowToastEvent({
                        title: 'Processing Error',
                        message: 'There was an error processing the list views. Please see an administrator - ' + error.body.message,
                        variant: 'error',
                        mode: 'sticky'
                    }));
                    this.spinnerOff('handleProcessListViewsButtonClick5');
                });

        }

        //if we have selected ALL list views to update
        else if (this.selectedObject === undefined && this.selectedListView === undefined ||  this.isInitialized === false)
        {
            console.log('Updating ALL list views for ' + this.pageName);

            updateAllListViews({ })
                .then(result => {

                    //if we have an error then send an ERROR toast.
                    if (result === 'failed')
                    {
                        this.dispatchEvent(new ShowToastEvent({
                            title: 'Processing Error',
                            message: 'There was an error processing the list views. Please see an administrator.',
                            variant: 'error',
                            mode: 'sticky'
                        }));
                        this.spinnerOff('handleProcessListViewsButtonClick6');

                    //else send a SUCCESS toast.
                    } else {

                        this.batchId = result;

                        //this.isInitialized = false;
                        //this.showProgress = true;

                        this.dispatchEvent(new ShowToastEvent({
                            title: 'List View Processing',
                            message: 'List view processing has started for ALL list views. You MUST do a full page refresh after completion to see changes.',
                            variant: 'success',
                            mode: 'dismissable'
                        }));
                        this.dispatchEvent(new CustomEvent('processlistviewclick'));
                        this.spinnerOff('handleProcessListViewsButtonClick7');
                    }
                })
                .catch(error => {
                    console.log('Error Detected - ' + error.body.message + ' | ' + error.body.stackTrace + ' for ' + this.pageName);
                    this.dispatchEvent(new ShowToastEvent({
                        title: 'Processing Error',
                        message: 'There was an error processing the list views. Please see an administrator - ' + error.body.message,
                        variant: 'error',
                        mode: 'sticky'
                    }));
                    this.spinnerOff('handleProcessListViewsButtonClick8');
                });

        }

    }

    /*
     * Called when a user tries to change the width of a column.
     */
    calculateWidth(event) {
        var childObj = event.target
        var parObj = childObj.parentNode;
        while(parObj.tagName != 'TH') {
            parObj = parObj.parentNode;
        }
        console.log('Final tag name ' + parObj.tagName + ' for ' + this.pageName);
        var mouseStart=event.clientX;
        this.mouseStart = mouseStart;
        this.oldWidth = parObj.offsetWidth;
        this.parentObj = parObj;
        // Stop text selection event
        if(event.stopPropagation) event.stopPropagation();
        if(event.preventDefault) event.preventDefault();
        event.cancelBubble=true;
        event.returnValue=false;
    };

    /*
     * Called when a user tries to change the width of a column.
     */
    setNewWidth(event) {

        if (this.mouseStart === undefined) return;

        var childObj = event.target
        var parObj = childObj.parentNode;
        while(parObj.tagName != 'TH') {
            parObj = parObj.parentNode;
        }
        var newWidth = event.clientX- parseFloat(this.mouseStart)+parseFloat(this.oldWidth);
        this.parentObj.style.width = newWidth+'px';

        this.mouseStart = undefined;
    };

    /*
     * Method that gets fired when a user clicks on one of the column headings to have that column
     * be a part of the data sorting. The page can have multiple columns be a part of the sort.
     */
    sortColumns(event) {
        this.spinnerOn('sortColumns');

        //get all values from the event
        let fieldName = event.currentTarget.dataset.name;
        let sortDirection = event.currentTarget.dataset.sortdir;
        let sortIndex = event.currentTarget.dataset.sortindex;
        
        //turn all the values into their respective data types
        if (sortIndex === undefined || sortIndex === '') {
            sortIndex = this.columnSortData.size;
        }
        sortIndex = Number(sortIndex);
        
        if (sortDirection === undefined || sortDirection === '') {
            sortDirection = true;
        }  else {
            sortDirection = this.toBool(sortDirection)
        }

        let columnData = undefined;

        //if a user has clicked on a column that is already being sorted then switch the direction
        if (this.columnSortData.has(sortIndex)) {
            columnData = this.columnSortData.get(sortIndex);

            //if this is the second click on the column then switch the column.
            if (columnData[2] === true) {
                columnData[2] = false; 
                this.columnSortData.set(sortIndex, columnData);

            //if this is the third click on the column then reset all sorting data.
            } else {
                this.columnSortData = new Map(); 
            }

        //if this is the first time clicking on a column then just add the column for sorting.
        } else {
            columnData = [sortIndex, fieldName, sortDirection];
            this.columnSortData.set(sortIndex, columnData);
        }

        this.columnSortDataStr = JSON.stringify( Array.from(this.columnSortData));
        this.listViewSortData.set(this.selectedObject + ':' + this.selectedListView, this.columnSortData);
        this.refreshAllListViewData();
    }

    //-------------------------------------------------------------------------------------------
    //ACTIONS
    //-------------------------------------------------------------------------------------------

    //called when a user selects an action for processing.
    async handleActionSelect(event) {
        this.selectedRecordIds = new Set();
        var selectedRowId = '';
        
        this.selectedActionKey = event.target.value;

        console.log('Chosen Action - ' + this.selectedActionKey + ' for ' + this.pageName);

        //get the ACTION
        this.displayedActionList.forEach(action => {
                                                    if (action.value === this.selectedActionKey) {
                                                        this.selectedAction = action;
                                                    }
                                                });

        //get the SELECTED RECORD IDs
        let selectedRows = this.template.querySelectorAll('lightning-input');
        selectedRows.forEach(element => { 
                                            if (element.checked === true && element.value != 'all')
                                            {
                                                selectedRowId = element.value.substring(0, element.value.indexOf(':'));
                                                if (selectedRowId !== '')
                                                    this.selectedRecordIds.add(selectedRowId);
                                            }            
                                        });

                                            
        //------------------------------------------------------
        //HYPERLINK
        //------------------------------------------------------
        if (this.selectedAction.isHyperlink === true)
        {
            let hyperlink = this.selectedAction.hyperlink;
            let recordIdStr = '';
            this.selectedRecordIds.forEach(recordId => {
                                                      recordIdStr = recordIdStr + recordId + '%2C'; //%2C = encoded comma
                                                  });
            recordIdStr = recordIdStr.slice(0,-3); //remove last "%2C"

            if (this.selectedRecordIds.size > 1)
            {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Error Processing Action',
                    message: 'Multiple rows cannot be selected for this action',
                    variant: 'error',
                    mode: 'dismissable'
                }));

            } else {

                //go through the action parameters checking for field substitutions
                this.selectedAction.allParameters.forEach(param => {
                                                                        let key = '$' + param.aPIName + '$';
                                                                        if (hyperlink.includes(key))
                                                                        {
                                                                            //get the ROW
                                                                            let row = undefined;
                                                                            this.listViewDataRows.forEach(element => { 
                                                                                if (element.isDeleted === false && element.salesforceId === recordIdStr)
                                                                                {
                                                                                    row = element;      
                                                                                }
                                                                            });        

                                                                            if (row === undefined)
                                                                            {
                                                                                this.dispatchEvent(new ShowToastEvent({
                                                                                  title: 'Error Processing Action',
                                                                                  message: 'A row must be selected for this action',
                                                                                  variant: 'error',
                                                                                  mode: 'dismissable'
                                                                                }));

                                                                                hyperlink = '';

                                                                            } else if (param.value === 'Id')
                                                                            {
                                                                                hyperlink = hyperlink.replace(key, row.salesforceId);
                                                                            } else {

                                                                                //get the FIELD value and substitute into hyperlink
                                                                                row.fields.forEach(element => { 
                                                                                    if (element.name === param.value)
                                                                                    {
                                                                                        hyperlink = hyperlink.replace(key, element.value);      
                                                                                    }
                                                                                });        
                                                                            }
                                                                        }
                                                                    });

                console.log('Hyperlink - ' + hyperlink);

                if (hyperlink !== '')
                {
                    this[NavigationMixin.Navigate]({
                        type: 'standard__webPage',
                        attributes: {
                            url: hyperlink,
                        },
                    });
                }
            }

        //------------------------------------------------------
        //SCREEN FLOW (AUTOMATED FLOWS HAPPEN IN CUSTOM)
        //------------------------------------------------------
        } else if (this.selectedAction.isFlow === true && this.selectedAction.flowType === 'Screen Flow')
        {
            this.selectedRecordIdsStr = JSON.stringify( Array.from(this.selectedRecordIds));

            this.selectedActionLabel = 'Label ' + this.selectedAction.label;
            
            console.log('Action Label selected - ' + this.selectedActionLabel + ' for ' + this.pageName);
            console.log('Action name           - ' + this.selectedAction.value + ' for ' + this.pageName);
            console.log('Action Record Ids     - ' + this.selectedRecordIdsStr + ' for ' + this.pageName);
    
            this.showFlowModal = true;

        //------------------------------------------------------
        //NEW
        //------------------------------------------------------
        } else if (this.selectedAction.label === 'New')
        {
            var defaultValues = {};
            if (this.isModeRelated)
            {
                defaultValues[this.joinFieldName] = this.recordId;
            }

            //go through the action parameters checking for field substitutions
            this.selectedAction.allParameters.forEach(param => {
                if (param.aPIName === 'UserField')
                    defaultValues[param.value] = currentUserId;
            });

            defaultValues = encodeDefaultFieldValues(defaultValues);

            this[NavigationMixin.Navigate]({
                type: 'standard__objectPage',
                attributes: {
                    objectApiName: this.selectedObject,
                    actionName: 'new',
                },
                state: {
                    useRecordTypeCheck: 1,
                    defaultFieldValues: defaultValues,
                }
            });
            

        //------------------------------------------------------
        //CLONE
        //------------------------------------------------------
        } else if (this.selectedAction.label === 'Clone')
        {

            if (this.selectedRecordIds.size !== 1) {    
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Error Processing Action',
                    message: 'A single row must be selected for cloning.',
                    variant: 'error',
                    mode: 'dismissable'
                }));
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

        //------------------------------------------------------
        //EDIT
        //------------------------------------------------------
        } else if (this.selectedAction.label === 'Edit')
        {

            if (this.selectedRecordIds.size !== 1) {      
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Error Processing Action',
                    message: 'A single row must be selected for editing.',
                    variant: 'error',
                    mode: 'dismissable'
                }));
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

        //------------------------------------------------------
        //EDIT All
        //------------------------------------------------------
        } else if (this.selectedAction.label === 'Edit All')
        {

            console.log('We are editing all records for ' + this.pageName);

            if (this.listViewDataRows.length > 101) {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Too Many Rows!',
                    message: 'Inline editing only available for up to 100 rows.',
                    variant: 'error',
                    mode: 'dismissable'
                }));

            } else {
                this.setAllRowsEdited();
            }

        //------------------------------------------------------
        //MASS CREATE
        //------------------------------------------------------
        } else if (this.selectedAction.className === 'ListViewActionMassCreate')
        {

            console.log('We are mass creating records for ' + this.pageName);
            if (this.selectedAction.massCreateListViewName !== undefined)
                this.massCreateListView = this.selectedAction.massCreateListViewName
            else
                this.massCreateListView = this.selectedListView;

            this.showMassCreateModal = true;

        //------------------------------------------------------
        //GENERATE PDF
        //------------------------------------------------------
        } else if (this.selectedAction.className === 'ListViewActionPDF')
        {
            this.spinnerOn('ListViewActionPDF');
            console.log('We are generating a PDF for ' + this.pageName);

            var theme = await getListViewConfigParameter({objectName: this.selectedObject, listViewName: this.selectedListView, paramName: 'PDFTheme'});

            var orientation = await getListViewConfigParameter({objectName: this.selectedObject, listViewName: this.selectedListView, paramName: 'PDFOrientationPortrait'});

            if (orientation == 'false') //true = portrait, false = landscape
                orientation = 'landscape';

            const { jsPDF } = window.jspdf;
            var doc = new jsPDF(orientation); 
    
            doc.autoTable({
                head: this.headRows(),
                body: this.bodyRows(),
                theme: theme,
                margin: {top: 5, right: 5, bottom: 5, left: 5},
            });
              
            this.selectedListViewExportName = this.selectedListView + '.csv';

            doc.save(this.selectedListViewExportName);
            this.spinnerOff('ListViewActionPDF');
            
        //------------------------------------------------------
        //CUSTOM
        //------------------------------------------------------
        } else {

            if (this.selectedRecordIds.size === 0) {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Error Processing Action',
                    message: 'No rows selected for processing.',
                    variant: 'error',
                    mode: 'dismissable'
                }));
                this.dispatchEvent(new CustomEvent('processclick'));
            
            } else {
                this.selectedRecordIdsStr = JSON.stringify( Array.from(this.selectedRecordIds));

                this.selectedActionLabel = 'Label ' + this.selectedAction.label;               //   <-- This to be fixed.
                
                console.log('Action Label selected - ' + this.selectedActionLabel + ' for ' + this.pageName);
                console.log('Action name           - ' + this.selectedAction.value + ' for ' + this.pageName);
                console.log('Action Record Ids     - ' + this.selectedRecordIdsStr + ' for ' + this.pageName);
        
                this.showActionModal = true;
            }

        }

        this.resetActionComboBox();

    }

    resetActionComboBox() {
        this.template.querySelectorAll('lightning-combobox').forEach(combobox => {
            if (combobox.name === 'Action List')
                combobox.value = undefined;
        });
    }

    //called if the user selects the cancel button.
    handleCancelButtonClick(event) {
        var action = event.target.label;
        if (action === 'Cancel')
        {
            this.outputStr = this.action;
        }
    }

    handleMassCreateModalClose() {
        this.showMassCreateModal = false;
    }
 
    cancelActionModal() {    
        this.resetActionComboBox();
        this.showActionModal = false;
    }

    processActionModal() {   

        //reset the selected record Ids
        //let selectedRows = this.template.querySelectorAll('lightning-input');
        //selectedRows.forEach(element => element.checked = false);
        //this.selectedRecordCount  = 0;
        this.showActionModal      = false;
        this.selectedAction       = '';
        //this.selectedRecordIdsStr = '';
        //this.selectedRecordIds    = new Set();

        this.refreshAllListViewData();
    }

    //-------------------------------------------------------------------------------------------
    //ADMIN
    //-------------------------------------------------------------------------------------------

    handleAdminButtonClick(event) {
        console.log('Admin button clicked for ' + this.pageName);

        this.showAdminModal = true;
    }

    /*
     * Method called after the admin modal dialog is closed.
     */
    processAdminModal(event) {   
        this.showAdminModal = false;

        if (event.detail === true) {
            refreshApex(this.wiredListViewConfigResult);
            this.refreshAllListViewData();
        }
    }

    //-------------------------------------------------------------------------------------------
    //FLOW
    //-------------------------------------------------------------------------------------------

    cancelFlowModal() {    
        this.resetActionComboBox();
        this.showFlowModal = false;
    }

    finishFlowModal() {   

        //reset the selected record Ids
        let selectedRows = this.template.querySelectorAll('lightning-input');
        selectedRows.forEach(element => element.checked = false);
        this.selectedRecordCount  = 0;
        this.showFlowModal      = false;

        this.refreshAllListViewData();
    }

    //-------------------------------------------------------------------------------------------
    //INLINE EDITING
    //-------------------------------------------------------------------------------------------

    /*
     * Method which sets all rows in the current data set to be editable
     */
    setAllRowsEdited() {
        if (this.toBool(this.allowInlineEditing) === true)
        {
            this.isEdited = true;
            this.listViewData.isEdited = true;
            this.listViewDataRows.forEach(element => { 
                if (element.isDeleted === false)
                {
                    element.isEdited = true;      
                }
            });        
        }
    }

    /*
     * Method which sets a single row in the current data set to be editable based on the provided row Id
     */
    setRowEdited(event) {
        console.log('Row set to be edited - ' + event.target.id + ' for ' + this.pageName);
        const rowId = event.target.id.split('-')[0];

        if (this.toBool(this.allowInlineEditing) === true)
        {
            this.isEdited = true;
            this.listViewData.isEdited = true;
            this.listViewDataRows.forEach(element => { 
                if (element.isDeleted === false && element.rowId === rowId && element.isEditable)
                {
                    element.isEdited = true;      
                }
            });        
        } else {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Editing Not Available',
                message: 'Inline editing is not available for this list view.',
                variant: 'info',
                mode: 'dismissable'
            }));
        }
    }

    /*
     * Method called when a row is edited and the SAVE button on the row is clicked.
     */
    handleRowDataSave(event) {
        console.log('Row data saved for ' + this.pageName);

        let rowId = event.target.value;

        let rowData = this.updatedRowData.get(rowId);

        if (rowData !== undefined)
        {
            let rowDataStr = JSON.stringify( Array.from(rowData)); //map objects cannot be stringified
            console.log('SAVE RESULT - ' + rowDataStr);

            updateRecord({rowId: rowId, rowData: rowDataStr})
            .then(result => {
                console.log('Save successful for ' + this.pageName);
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Success',
                    message: 'Record saved successfully.',
                    variant: 'success',
                    mode: 'dismissable'
                }));
                this.refreshAllListViewData();
            })
            .catch(error => {
                console.log('Error Detected - ' + error.body.message + ' | ' + error.body.stackTrace);
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Error',
                    message: 'There was an error saving the record. Please see an administrator - ' + error.body.message,
                    variant: 'error',
                    mode: 'sticky'
                }));
            });
        }
    }     

     /*
     * Method called when a row is edited and the SAVE ALL button on the column header is clicked.
     */
     handleAllRowDataSave(event)
    {

        let rowData = this.updatedRowData; //map of maps

        if (rowData !== undefined)
        {
            let rowDataStr = '{'
              rowData.forEach((element, key) => { 
                rowDataStr = rowDataStr + '"' + key + '":' + JSON.stringify( Array.from(element)) + ',';
            });        

            rowDataStr = rowDataStr.slice(0, -1) + '}';
              
            console.log('SAVE RESULT - ' + rowDataStr + ' for ' + this.pageName);

            updateRecords({rowData: rowDataStr})
            .then(result => {
                console.log('Save successful for ' + this.pageName);
                let rowCount = 0;
                if (this.updatedRowData !== undefined) {
                    rowCount = this.updatedRowData.size;
                }
        
                if (rowCount > 0) {
                    this.dispatchEvent(new ShowToastEvent({
                        title: 'Success',
                        message: rowCount + ' record(s) saved successfully.',
                        variant: 'success',
                        mode: 'dismissable'
                    }));
                }
                
                this.refreshAllListViewData();
                
                this.listViewDataRows.forEach(element => { 
                    element.isEdited = false;      
                });
        
                this.updatedRowData = new Map();
                this.isEdited = false;

            })
            .catch(error => {
                console.log('Error Detected - ' + error.body.message + ' | ' + error.body.stackTrace + ' for ' + this.pageName);
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Error',
                    message: 'There was an error saving the record. Please try again or see an administrator - ' + error.body.message,
                    variant: 'error',
                    mode: 'sticky'
                }));
            });
        }

    }

    /*
     * Method called when a row is edited and the RESET button on the row is clicked forcing a full data reset of the row.
     */
    handleRowDataReset(event) {
        console.log('Row data reset for ' + this.pageName);

        let rowId = event.target.value;

        this.updatedRowData.delete(rowId);

        let editedCount = 0;
        this.listViewDataRows.forEach(element => { 
            if (element.rowId === rowId)
            {
                element.isEdited = false;      
            } else {
                if (element.isEdited === true)
                    editedCount++;
            }
        });

        //set form to not editing if no rows are processing.
        if (editedCount === 0) {
            this.isEdited = false;
        }

    }

    /*
     * Method called when a row is edited and the ALL RESET button on the column is clicked forcing a full data reset of the entire dataset.
     */
    handleAllRowDataReset(event) {

        this.listViewDataRows.forEach(element => { 
            element.isEdited = false;      
        });

        this.isEdited = false;
    }

    /*
     * Method called when a row is edited and a field within that row is changed.
     */
    handleFieldDataChange(event) {
        console.log('Field changed for ' + this.pageName);

        //if data is coming in from a component
        let fieldValue = '';
        let rowId = '';
        let fieldName = '';

        //if data is coming in from a component
        if (event.currentTarget.dataset.type === undefined)
        {
            fieldValue = event.detail.selectedValue;
            rowId = event.detail.rowId;
            fieldName  = event.detail.field;
        
        } else {
            if (event.currentTarget.dataset.type === 'boolean') {
                if (event.target.checked === true) {
                    fieldValue = 'true'; //have to turn boolean into string
                } else { 
                    fieldValue = 'false'
                }
                rowId  = event.currentTarget.dataset.rowId;
                fieldName  = event.currentTarget.dataset.field;    
            } else {
                fieldValue = event.target.value;
                rowId  = event.currentTarget.dataset.rowId;
                fieldName  = event.currentTarget.dataset.field;
            }
        }

        console.log('fieldValue - ' + fieldValue + ' for ' + this.pageName);
        console.log('rowId - ' + rowId + ' for ' + this.pageName);
        console.log('fieldName - ' + fieldName + ' for ' + this.pageName);

        let rowData = this.updatedRowData.get(rowId);

        if (rowData === undefined)
        {
            rowData = new Map();
            this.updatedRowData.set(rowId, rowData);
        }

        rowData.set(fieldName, fieldValue);

    }

    /*
     * Method that handles text changes to the text search field.
     */
    handleTextSearchChange(event) {
        
        console.log('handleTextSearchChange called - ' + event.target.value + ' for ' + this.pageName);

        this.listViewDataRows.forEach(element => { 
            if (event.target.value === '')
            {
                element.isDisplayed = true;
            } else {
                console.log('CSV String - ' + element.dataAsCSVString + ' for ' + this.pageName);
                if (element.dataAsCSVString.toLowerCase().includes(event.target.value.toLowerCase())) {
                    console.log('Element will be displayed for ' + this.pageName);
                    element.isDisplayed = true;
                } else {
                    console.log('Element will NOT be displayed for ' + this.pageName);
                    element.isDisplayed = undefined;
                }
            }
        });

    }

    /*
     * Method to set the join criteria whenever its changed. This should only happen on SINGLE and RELATED list views.
     * The method will refresh the list view data if there is criteria or clear the list view data if there is no criteria.
     */
    setJoinCriteria(value) {
        console.log('Inside setJoinCriteria - ' + value);
        if (value !== '' && value !== undefined)
            this.joinData = '{"recordIds":"' + value + '"}';
        else
            this.joinData = '';
        
        if (!this.isInitializing && this.joinData !== '') 
            this.refreshAllListViewData(); 
        else 
            this.listViewData = undefined;
    }

    toBool(value) {
        var strValue = String(value).toLowerCase();
        strValue = ((!isNaN(strValue) && strValue !== '0') &&
            strValue !== '' &&
            strValue !== 'null' &&
            strValue !== 'undefined') ? '1' : strValue;
        return strValue === 'true' || strValue === '1' ? true : false
    };

    //-------------------------------------------------------------------------------------------
    // POPOVER
    //-------------------------------------------------------------------------------------------
    displayHoverDetails(event) {
        console.log('Field set for hover - ' + event.currentTarget.dataset.sfdcId + ', ' + event.currentTarget.dataset.apiName + ', ' + event.currentTarget.dataset.labelName + ' for ' + this.pageName);

        if (this.excludedRecordPopoverTypes.includes(event.currentTarget.dataset.apiName))
        {
            console.log('Hover not displayed. Object type in excluded popover types');
        
        //if there was an error retrieving the popover details then don't try display again
        } else if (this.hoverErrorTypes.includes(event.currentTarget.dataset.apiName))
        {
            console.log('Hover not displayed. Object type in hover error list');

        //if we are allowed to display popovers then update
        } else if (this.displayRecordPopovers === true)
        {            
            console.log('Popover to be displayed');
            console.log('Page coords        - ' + event.pageX + ', ' + event.pageY + ' for ' + this.pageName);

            this.hoverSFDCId = event.currentTarget.dataset.sfdcId;
            this.hoverAPIName = event.currentTarget.dataset.apiName;
            this.hoverLabelName = event.currentTarget.dataset.labelName;
            this.hoverIsDisplayed = true;
            this.hoverPositionTop = event.pageY - 240; //have to move up as this is the number of pixels used for the header
            this.hoverPositionLeft = event.pageX + 10; //have to move left as this is the number of pixels used for the sidebar    
        } else {
            console.log('Record popovers disabled');
        }
    }

    /*
     * Method called when a row is edited and the RESET button on the row is clicked forcing a full data reset of the row.
     */
    hideHoverDetails(event) {
        console.log('Popover set for hiding - ' + this.pageName);
        this.hoverIsDisplayed = false;
    }

    processHoverError(event) {
        this.hideHoverDetails(event);
        if (!this.hoverErrorTypes.includes(event.detail))
        {
            this.hoverErrorTypes = this.hoverErrorTypes + ',' + event.detail;
        }
    }

    //-------------------------------------------------------------------------------------------
    //PDF TABLES
    //-------------------------------------------------------------------------------------------

    //head: [['Name', 'Email', 'Country']],
    //body: [
    //  ['David', 'david@example.com', 'Sweden'],
    //  ['Castille', 'castille@example.com', 'Spain'],
    //  // ...
    ///]

    headRows() {
        let headers = [];
        let headerRow = [];
        headers.push(headerRow);
        this.listViewData.fieldMetaData.forEach(column => { headerRow.push(column.label); });
        return headers;
      }
            
    bodyRows() {
        var body = []
        this.listViewDataRows.forEach(row => { 

            //if no rows are selected or the Id has been selected.
            if (this.selectedRecordIds.size === 0 || this.selectedRecordIds.has(row.salesforceId))
            {
                var bodyRow = [];

                for (var i = 0; i < row.fields.length; i++) {
                    var field = row.fields[i];
                    bodyRow.push(field.value);
                }
                body.push(bodyRow)
            }
        });
        return body;
      }
}
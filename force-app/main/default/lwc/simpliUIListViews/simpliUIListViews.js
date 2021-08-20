/* eslint-disable vars-on-top */
/* eslint-disable no-console */
import { LightningElement, wire, track, api  } from 'lwc';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import  LISTVIEW_MC  from '@salesforce/messageChannel/SimpliListViewMessageChannel__c';
import { refreshApex } from '@salesforce/apex';
import { subscribe, unsubscribe, publish, APPLICATION_SCOPE, MessageContext } from 'lightning/messageService';

//------------------------ LABELS ------------------------
import Rows from '@salesforce/label/c.Rows';
import Selected from '@salesforce/label/c.Selected';
import Select_Action from '@salesforce/label/c.Select_Action';
import Export_All from '@salesforce/label/c.Export_All';
import Export_Selected from '@salesforce/label/c.Export_Selected';
import Loading from '@salesforce/label/c.Loading';
import Not_Initialized from '@salesforce/label/c.Not_Initialized';
import Process_List_Views from '@salesforce/label/c.Process_List_Views';
import List_View_Processing_Complete from '@salesforce/label/c.List_View_Processing_Complete';
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
import List_Views_Need_Initialized from '@salesforce/label/c.List_Views_Need_Initialized';
import Refresh from '@salesforce/label/c.Refresh';
import Refresh_List_Views from '@salesforce/label/c.Refresh_List_Views';
import Search_List_Dot from '@salesforce/label/c.Search_List_Dot';
import Processing_Status from '@salesforce/label/c.Processing_Status';

import isSysAdmin from '@salesforce/apex/ListViewController.isSysAdmin';
import getIsInitialized from '@salesforce/apex/ListViewController.getIsInitialized';
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

export default class simpliUIListViews extends NavigationMixin(LightningElement) {

    wiredListViewDataResult;
    wiredObjectListViewsResult;
    wiredListViewObjectsResult;

    @api mode                  = 'App Page'; //indicates the mode the page is in for displaying the list view. i.e. app, single etc.
    @api pageName              = '';                 //this is NOT the page name but the COMPONENT name
    @api hasMainTitle          = undefined;
    @api mainTitle             = 'List Views';
    @api includedObjects       = '';
    @api excludedObjects       = '';
    @api joinFieldName         = '';
    @api useMessageChannel     = false;
    @api allowRefresh          = false; //config indicating whether the auto refresh checkbox is made available.
    @api allowInlineEditing    = false; //config indicating whether inline editing is available
    @api allowAdmin            = false;  //indicates whether the admin button should display to the user
    @api displayActions        = false;
    @api displayReprocess      = false;
    @api displayURL            = false;
    @api displayRowCount       = false;
    @api displaySelectedCount  = false;
    @api displayOrigButton;             //this is not used....deprecated.
    @api displayModified       = false;
    @api displayExportButton   = false;
    @api displayTextSearch     = false;  //identifies whether the text search field should be displayed.
    @api singleListViewObject  = '';     //if in SINGLE mode holds the list view object to use.
    @api singleListViewApiName = '';     //if in SINGLE mode holds the list view API name to use.

    @api set joinCriteria(value) {
        this.setJoinCriteria(value);
    }
    get joinCriteria() { 
        return this.joinData; 
    }

    @track isModeRelated      = false;  //indicates whether the current mode is RELATED LIST VIEW
    @track isModeSingle       = false;  //indicates whether the current mode is SINGLE LIST VIEW
    @track isModeApp          = true;   //indicates whether the current mode is APP PAGE

    @track isSysAdmin         = false;  //indicates whether the current user is a sys admin.
    @track textSearchText = '';         //holds the current value for text searching.
    @track joinData           = '';     //holds the join data coming in from an external list view.....if it exists.
    @track modifiedText;                //holds the last modified text that should be displayed based on the component config
    @track userSortConfigs;             //holds all user sort configuration for this named component.
    @track componentConfig;                 //holds all user and org wide configuration for this named component.
    @track selectedListView;            //holds the selected list view name
    @track selectedListViewExportName;  //holds the selected list view name + .csv
    @track selectedObject;              //holds the selected object name
    @track objectList;                  //holds the list of objects from which a user can choose one.
    @track listViewList;                //holds the set of list views for the chosen object
    @track listViewData;                //holds the set of data returned for a given object and list view.
    @track listViewDataRows;            //holds ALL PAGES of data that are returned.
    @track listViewDataRowsSize;        //holds total for ALL PAGES of data that are returned.
    @track listViewDataColumns;         //holds the data tables column information
    @track selectedAction;              //holds the selected action complex object if one is chosen.
    @track selectedActionKey;           //holds the selected action API name if one is chosen.
    @track selectedActionLabel;         //holds the selected action label if one is chosen.
    @track objectActionList;            //holds the (Complex Object) list of available actions for the selected object
    //@track listViewConfigParams;       //holds the config parameters for the chosen list view (if one exists)
    @track showActionModal;             //indicates whether the action modal form should be displayed.
    @track showAdminModal;              //indicates whether the admin modal form should be displayed.
    @track selectedRecordIdsStr;        //holds the set of record ids that have been selected as a string
    @track selectedRecordCount = 0;     //the number of records selected. Passed into the modal dialog.  
    @track isPinned = false;            //identifies whether this list view and object have been pinned.
    @track pinnedListView = undefined;  //the list view that is pinned if there is a pinned list view.
    @track pinnedObject = undefined;    //the object that is pinned if there is a pinned list view.
    @track urlListView = undefined;     //the list view that is supplied on the URL if it exists.
    @track urlObject = undefined;       //the object that is supplied on the URL if it exists.
    @track isRefreshed = false;         //identifies whether this list views data is being refreshed at intervals.
    @track spinner = false;             //identifies if the PAGE spinner should be displayed or not.
    @track dataSpinner = false;         //identifies if the DATA spinner should be displayed or not.
    @track firstListViewGet = true;     //indicates whether this is the first time the list views are being retrieved.
    @track canDisplayActions = false;    //indicates whether the page is in a position where the actions list is active
    @track offset = -1;
    @track rowLimit = -1;

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
    @track showProgress = false;        //indicates whether the progress bar should be displayed
    @track batchId = '';                //indicates the batch Id of the list view batch process.
    @track isInitializing = true;       //indicates whether we are initializing the page or not.

    @track refreshTitle = 'Click to perform full list view refresh';
  
    //for message channel handlers
    subscription = null;
    receivedMessage;
    isValid;

    currentPageReference;

    label = { Rows, Selected, Select_Action, Export_All, Export_Selected, Loading, Not_Initialized, Process_List_Views, List_View_Processing_Complete,
              Select_Object, Object, Select_List_View, List_View, Go_To_Original, Unpin_List_View, Pin_List_View, Stop_Auto_Refresh, Start_Auto_Refresh,
              List_View_Admin, Sort_By, Save_All_Data, Reset_All_Data, Save_Row_Data, List_Views_Need_Initialized, Refresh_List_Views, Refresh, Search_List_Dot,
              Processing_Status  };

    /*
     * Method which gets called when the class is being instantiated
     * Note that we do not have access to any local variables in the constructor
     */
    constructor() {
        super();

        //if the user recently changed a core list view this should do an immediate update. 
        //Only the last modified list view is processed.
        updateChangedListViews()
            .then(result => {
            })
            .catch(error => {
            });
    }
    

    @wire(CurrentPageReference)
    setCurrentPageReference(currentPageReference) {
        this.currentPageReference = currentPageReference;
        if(this.currentPageReference) {
            window.console.log('Current Page Reference...'+JSON.stringify(this.currentPageReference));
        }
    }

    /*
     * Method which gets called after the class has been instantiated
     * but before it is rendered. We do have access to variables in this method.
     */
    async renderedCallback() {

        console.log('Starting simpliUIListViews.renderedCallback for ' + this.pageName);
        //this ensures we only call this once for each page load
        if (this.componentConfig === undefined) {
            this.spinnerOn();

            console.log('User config is undefined for ' + this.pageName);

            //always subscribe to the message channel
            this.subscribeMC();

            if (this.mode === 'Single List View') {

                if (this.singleListViewObject === '' || this.singleListViewApiName === '')
                {
                    this.dispatchEvent(new ShowToastEvent({
                        title: 'Single List View Configuration Error',
                        message: 'If using Single List View mode the list view object and API name must be provided.',
                        variant: 'error',
                        mode: 'sticky'
                    }));
                    return;
                } else {

                    this.isModeSingle     = true;
                    this.isModeApp        = false;
                    this.selectedObject   = this.singleListViewObject;
                    this.selectedListView = this.singleListViewApiName;

                    this.refreshAllListViewData();
                }
            }

            if (this.mode === 'Related List View') {

                if (this.singleListViewObject === '' || this.singleListViewApiName === '' || this.joinFieldName === '')
                {
                    this.dispatchEvent(new ShowToastEvent({
                        title: 'Related List View Configuration Error',
                        message: 'If using Related List View mode the list view object, list view API name and join field name must be provided.',
                        variant: 'error',
                        mode: 'sticky'
                    }));
                    return;
                } else {

                    this.isModeRelated    = true;
                    this.isModeApp        = false;
                    this.selectedObject   = this.singleListViewObject;
                    this.selectedListView = this.singleListViewApiName;

                    if (this.joinData !== '') //only set list view data if there is join data.
                    {
                        this.refreshAllListViewData();
                    }
                }
            }

            this.urlObject = this.currentPageReference.state.ObjectName;
            this.urlListView = this.currentPageReference.state.ListViewName;
            
            console.log('URL object    - ' + this.urlObject + ' for ' + this.pageName);
            console.log('URL list view - ' + this.urlListView + ' for ' + this.pageName);
            console.log('Ltn page name - ' + this.pageName + ' for ' + this.pageName);
            console.log('Page Mode     - ' + this.mode + ' for ' + this.pageName);

            getComponentConfig({compName: this.pageName })
            .then(result => {
                console.log('Component configs retrieved successfully - ' + result + ' for ' + this.pageName);
                this.componentConfig = result;
                console.log('Component config size - ' + this.componentConfig.length + ' for ' + this.pageName);

                let pinnedListView = this.componentConfig.pinnedListView;
                console.log('Pinned list view string - ' + pinnedListView);

                if (this.toBool(this.componentConfig.AllowAdmin) === false) { 
                    if (this.isSysAdmin === true)
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

                //if we have a URL object then use it
                if (this.urlObject != undefined) {
                    this.selectedObject = this.urlObject

                //otherwise if they have a pinned list view then use it, if possible.
                } else if (pinnedListView != undefined && pinnedListView != '') {
                    this.isPinned = true;
                    this.pinnedObject = pinnedListView.substring(0, pinnedListView.lastIndexOf(':'));
                    this.pinnedListView = pinnedListView.substring(pinnedListView.lastIndexOf(':')+1);

                    console.log('Pinned object    - ' + this.pinnedObject);
                    console.log('Pinned list view - ' + this.pinnedListView);

                    //force a refresh of the list view objects. This will then force a refresh of the list view names and then the list view data.
                    getListViewObjects({includedObjects: this.includedObjects, excludedObjects: this.excludedObjects })
                    .then(result => {
                        this.handleListViewObjects(result);
                    })
                    .catch(error => {
                        this.dispatchEvent(new ShowToastEvent({
                            title: 'Error Retrieving List View Objects',
                            message: 'There was an error retrieving the list view objects. Please see an administrator - ' + error.body.message,
                            variant: 'error',
                            mode: 'sticky'
                        }));
                        console.log('Error Detected - ' + error.body.message + ' | ' + error.body.stackTrace);
                    });
        
                } else {
                    console.log('There is no URL object and no pinned list view for ' + this.pageName);
                    this.isInitializing = false;
                    this.spinnerOff();
                }
            })
            .catch(error => {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Error Retrieving User Config',
                    message: 'There was an error retrieving the user config. Please see an administrator - ' + error.body.message,
                    variant: 'error',
                    mode: 'sticky'
                }));
                console.log('Error Detected - ' + error.body.message + ' | ' + error.body.stackTrace + ' for ' + this.pageName);
            });

            getUserSortConfigs({compName: this.pageName })
            .then(result => {
                console.log('User sort configs retrieved successful - ' + result + ' for ' + this.pageName);
                this.userSortConfigs = result;

                var listViewSortFields = JSON.parse(result);
                console.log('List view sort fields size - ' + listViewSortFields.listviews.length); 

                //EXAMPLE JSON - {"listviews": [{"name": "Account:Simpli_LV_Acct_1","fields": [{"sortIndex": "0", "fieldName": "Name", "sortDirection": "true"},{"sortIndex": "1", "fieldName": "BillingState", "sortDirection": "false"}]}, {"name": "Account:PlatinumandGoldSLACustomers","fields": [{"sortIndex": "0", "fieldName": "Name", "sortDirection": "true"},{"sortIndex": "1", "fieldName": "BillingState", "sortDirection": "false"},{"sortIndex": "2", "fieldName": "Id", "sortDirection": "false"}]}]}
                for (var m in listViewSortFields.listviews) {

                    let listviewSorting = listViewSortFields.listviews[m];
                    //if we are working with the current list view
                    if (listviewSorting.name === this.pinnedObject + ':' + this.pinnedListView) {
                        
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
            })
            .catch(error => {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Error Handling User Config',
                    message: 'There was an error handling the user sort config. Please see an administrator - ' + error.body.message,
                    variant: 'error',
                    mode: 'sticky'
                }));
                console.log('Error Detected - ' + error.body.message + ' | ' + error.body.stackTrace + ' for ' + this.pageName);
            });

        } else {
            console.log('No page initialization needed for ' + this.pageName);
        }
        console.log('Finished renderedCallback for ' + this.pageName);
    }
    
    /*
     * Used for handling the message channel
     */
    @wire(MessageContext)
    messageContext;
    
    
    @wire (isSysAdmin, { })
    wiredIsSysAdmin({ error, data }) {
        if (data) { 
            console.log('Is sys admin called successfully - ' + data + ' for ' + this.pageName);
            this.isSysAdmin = data; 
        } else if (error) { 
            console.log('Error Detected - ' + error.body.message + ' | ' + error.body.stackTrace + ' for ' + this.pageName);
        }
    }



    @wire (getIsInitialized, { })
    wiredIsInitialized({ error, data }) {
        if (data) { 
            console.log('Is Initialized called successfully - ' + data + ' for ' + this.pageName);
            this.isInitialized = data; 
        } else if (error) { 
            console.log('Error Detected - ' + error.body.message + ' | ' + error.body.stackTrace + ' for ' + this.pageName);
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error Checking Initialization',
                message: 'There was an error checking for Simpli List Views initialization. Please see an administrator - ' + error.body.message,
                variant: 'error',
                mode: 'sticky'
            }));
        }
    }

    /*
     * Wiring to get the (Complex Object) list of actions available for the provided object type
     */
    @wire (getListViewActions, { objectType: '$selectedObject', listViewName: '$selectedListView' })
    wiredListViewActions({ error, data }) {
        if (data) { 
            console.log('List view actions retrieval successful for ' + this.pageName);
            this.objectActionList = data; 
            
            console.log('Object action list size - ' + this.objectActionList.length); 
            if (this.objectActionList.length === 0 || this.displayActions === false) {
                this.canDisplayActions = false;
            } else if (this.toBool(this.displayActions) === true) {
                this.canDisplayActions = true;
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

    refreshAllListViewData() {
        this.offset = -1;
        this.selectedRecordCount = 0;
        this.isEdited = false;
        this.textSearchText = '';
        let selectedRows = this.template.querySelectorAll('lightning-input');
        selectedRows.forEach(element => element.checked = false);

        this.getListViewDataPage();
    }

    getListViewDataPage() {

        console.log('Starting refreshListViewData - ' + this.pageName + ' - ' + this.selectedObject + ' - ' + this.selectedListView + ' - ' + this.joinFieldName + ' - ' + this.offset + ' for ' + this.pageName);
        console.log('columnSortDataStr - ' + this.columnSortDataStr + ' for ' + this.pageName);
        this.spinnerOn();
        console.log('Selected list view - ' + this.selectedListView + ' for ' + this.pageName);

        getListViewData({pageName: this.pageName, objectName: this.selectedObject, listViewName: this.selectedListView, sortData: this.columnSortDataStr, joinFieldName: this.joinFieldName, joinData: this.joinData, offset: this.offset })
        .then(result => {

            if (this.listViewData === undefined) {
                console.log('this.listViewData            - undefined for ' + this.pageName);
                console.log('this.listViewData.coreListId - undefined for ' + this.pageName);
            } else {
                console.log('this.listViewData            - ' + this.listViewData + ' for ' + this.pageName);
                console.log('this.listViewData.coreListId - ' + this.listViewData.coreListId + ' for ' + this.pageName);
            }
            console.log('result.coreListId - ' + result.coreListId + ' for ' + this.pageName);
            
            //if this is the first time we are initializing the list view data OR we are refreshing the data.
            if (this.listViewData === undefined || this.listViewData.coreListId !== result.coreListId || this.offset === -1 || (this.offset === this.listViewData.listView.offset && this.offset === -1))
            {
                //initialize list view info
                this.listViewData = result;

                //initialize list view row data
                this.listViewDataRows = result.rows;

            //else add the new data to the existing data
            } else {
                this.listViewDataRows = this.listViewDataRows.concat(result.rows);
            }

            //update the data rows size.
            this.listViewDataRowsSize = this.listViewDataRows.length;  

            if (this.listViewData.hasTotalsRow)
            {
                this.listViewDataRowsSize--;
            }

            console.log('this.listViewDataRows.length - ' + this.listViewDataRows.length + ' for ' + this.pageName);
            console.log('result.listView.rowLimit       - ' + result.listView.rowLimit + ' for ' + this.pageName);
            console.log('this.offset                  - ' + this.offset + ' for ' + this.pageName);
            console.log('result.listView.offset         - ' + result.listView.offset + ' for ' + this.pageName);
        
            //if we have not reached our max limit
            if (this.listViewDataRows.length < result.listView.rowLimit)
            {
                //if the offset has not changed then we are done.
                if (this.offset === result.listView.offset)
                {
                    this.dataSpinnerOff();

                //update offset (which will trigger another request for data)
                } else {
                    this.dataSpinnerOn();
                    this.offset = result.listView.offset;
                    this.rowLimit = result.listView.rowLimit;
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

            if (this.listViewData.listView.listViewType !== 'Core') {
                this.displayReprocess = false;
            }

            this.textSearchText = '';
            this.isInitializing = false;
            this.spinnerOff();
            
        })
        .catch(error => {
            console.log('Error Detected - ' + error.body.message + ' | ' + error.body.stackTrace + ' for ' + this.pageName);
            this.listViewData = undefined; 
            this.spinnerOff();
            this.dataSpinnerOff();
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error Retrieving Data',
                message: 'There was an error retrieving the data - ' + error.body.message,
                variant: 'error',
                mode: 'sticky'
            }));
        });

    }

    handleListViewObjects(data)
    {
        this.objectList = data; 

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
                    refreshApex(this.wiredObjectListViewsResult);
                }
                this.pinnedObject = undefined;
            } else if (this.isInitializing === false) {
                this.spinnerOff();
            }

        }

    }

    /*
     * Wiring to get the list of objects in the system
     */
    @wire (getListViewObjects, { includedObjects: '$includedObjects', excludedObjects: '$excludedObjects'  })
    wiredListViewObjects(wiredListViewObjectsResult) {
        console.log('Starting getListViewObjects for ' + this.pageName);
        this.wiredListViewObjectsResult = wiredListViewObjectsResult;
        const { data, error } = wiredListViewObjectsResult;
        if (data) {
            this.handleListViewObjects(data); 
        } else if (error) { 
            console.log('Error Detected - ' + error.body.message + ' | ' + error.body.stackTrace);
            this.objectList = undefined; 
            this.spinnerOff();
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error Retrieving List View Objects',
                message: 'There was an error retrieving the list view objects. Please see an administrator - ' + error.body.message,
                variant: 'error',
                mode: 'sticky'
            }));
        }
        console.log('Finished getListViewObjects for ' + this.pageName);
    }

    /*
     * Wiring to get the list of configuration options from the server controller (ListViewController).
     * We pass the selected object which identifies which list views to retrieve.
     */
    @wire (getObjectListViews, { objectName: '$selectedObject' })
    wiredObjectListViews(wiredObjectListViewsResult) {
        console.log('Starting getObjectListViews for ' + this.pageName);
        this.wiredObjectListViewsResult = wiredObjectListViewsResult;
        const { data, error } = wiredObjectListViewsResult;
        if (data) { 
            console.log('Object list view retrieval successful for ' + this.pageName);
            this.listViewList = data; 
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

            this.spinnerOff(); 
        } else if (error) { 
            console.log('Error Detected - ' + error.body.message + ' | ' + error.body.stackTrace + ' for ' + this.pageName);
            this.listViewList = undefined; 
            this.spinnerOff(); 
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error Retrieving Object List Views',
                message: 'There was an error retrieving ' + this.selectedObject + ' list views data. This usually indicates the user does not have read access to the object. Please see an administrator if you believe this to be an error - ' + error.body.message,
                variant: 'error',
                mode: 'sticky'
            }));
        }
        console.log('Finished getObjectListViews for ' + this.pageName);
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
            {scope: APPLICATION_SCOPE});
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
        console.log(this.pageName + ' received a message from ' + this.receivedMessage.pageName + ' for ' + this.pageName);

        //if we have a list view selected AND if we have selected a specific list view to update
        if (this.selectedObject != undefined && this.receivedMessage.pageName != this.pageName && this.joinFieldName != undefined && this.joinFieldName != '')
        {
            console.log('We have a joined field name - ' + this.joinFieldName + ' for ' + this.pageName);
            console.log('Record ids from message - ' + this.receivedMessage.recordIds + ' for ' + this.pageName);
            this.joinData = JSON.stringify(message);
            console.log('Join Data JSON - ' + this.joinData + ' for ' + this.pageName);
            this.spinnerOn();

            //we need to check and see if this message is valid for this component.
            //I think we need to get rid of this.......causes data reload to take too long.
            isValidListViewDataRequest({objectName: this.selectedObject, joinFieldName: this.joinFieldName, joinData: this.joinData })
            .then(result => {
                console.log('isValidListViewDataRequest returned - ' + result + ' for ' + this.pageName);

                if (result === 'success') {
                    this.refreshAllListViewData();    
                } else {
                    this.spinnerOff();
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
            console.log('Page names are the same or we do not have a joined field name so ignoring message! for ' + this.pageName);
        }

    }

    handleAutoRefreshData() {

        console.log('Refreshing data for ' + this.pageName);

        if (this.isRefreshed) {

            this.refreshAllListViewData();            

            //https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Function/bind
            //look at its use with setTimeout down the page!
            setTimeout(this.handleAutoRefreshData.bind(this), 5000);

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
        this.spinnerOn();
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

        //if we are sending the selection to other components.
        if (this.useMessageChannel === true) {
            console.time('handleRecordSelectChange3');

            console.log('Sending to message channel for ' + this.pageName);
            //run through all the checkbox components again now that they have been set
            var recordIds = '';        

            for(let i = 0; i < selectedRows.length; i++) {
                if(selectedRows[i].checked === true && selectedRows[i].value != 'all') {

                    //the value includes the row number so remove that from the end as we only want the Ids
                    const indexOf = selectedRows[i].value.indexOf(':');
                    var recordId = selectedRows[i].value.substring(0, indexOf);
                    recordIds = recordIds + recordId + ',';
                }
            }

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
                pageName: this.pageName
            };
            publish(this.messageContext, LISTVIEW_MC, message);        
            console.timeEnd('handleRecordSelectChange3');
        
        } else {
            console.log('NOT sending to message channel for ' + this.pageName);
        }

        this.spinnerOff();
    }

    /*
     * Called when a user is selecting a list view and 
     * they have changed the object of the list view.
     */
    handleObjectChange(event) {
        this.spinnerOn();
        this.selectedListView = undefined;
        this.selectedListViewExportName = undefined;
        this.selectedObject = event.target.value;
        this.listViewList = undefined;
        this.listViewData = undefined;
        this.listViewDataRows = undefined;
        this.objectActionList = undefined;
        this.columnSortDataStr = '';
        this.columnSortData = new Map(); 
        this.modifiedText = '';

        console.log('Object selected - ' + this.selectedObject + ' for ' + this.pageName);
    }

    /*
     * Called when a user changed a list view, used 
     * to retrieve record data.
     */
    handleListViewSelected(event) {

        console.log('Old list view - ' + this.selectedListView + ' for ' + this.pageName);
        console.log('Sort data - ' + this.listViewSortData + ' for ' + this.pageName);
        this.spinnerOn();
        
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
        this.isPinned = false;

        updateUserConfig({compName: this.pageName, configName: 'pinnedListView', value: '' })
        .then(result => {
            console.log('List view unpinning successful for ' + this.pageName);
            this.dispatchEvent(new ShowToastEvent({
                title: 'List View Unpinned',
                message: 'List view successfully unpinned.',
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

    spinnerOn() {
        this.spinner = true;
        console.log('Spinner ON for ' + this.pageName);
    }

    spinnerOff() {
        if (this.isInitializing === false)
        {
            this.spinner = false;
            console.log('Spinner OFF for ' + this.pageName);
        }
        //var stack = new Error().stack
        //console.log( stack )
    }

    //called when a user clicks the button to refresh the list views.
    handleProcessListViewsButtonClick() {

        this.spinnerOn();
        console.log('Listview process button clicked for ' + this.pageName);
        console.log('selectedObject - ' + this.selectedObject + ' for ' + this.pageName);
        console.log('selectedListView - ' + this.selectedListView + ' for ' + this.pageName);

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

                        this.spinnerOff();
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
                    this.spinnerOff();
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
                        refreshApex(this.wiredObjectListViewsResult);
                        this.spinnerOff();

                    //else send an ERROR toast.
                    } else {
                        this.dispatchEvent(new ShowToastEvent({
                            title: 'Processing Error',
                            message: 'There was an error processing the list views. Please see an administrator - ' + result,
                            variant: 'error',
                            mode: 'sticky'
                        }));
                        this.spinnerOff();
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
                    this.spinnerOff();
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
                        this.spinnerOff();

                    //else send a SUCCESS toast.
                    } else {

                        this.batchId = result;

                        this.isInitialized = false;
                        this.showProgress = true;

                        this.dispatchEvent(new ShowToastEvent({
                            title: 'List View Processing',
                            message: 'List view processing has started for ALL list views. You MUST do a full page refresh after completion to see changes.',
                            variant: 'success',
                            mode: 'dismissable'
                        }));
                        this.dispatchEvent(new CustomEvent('processlistviewclick'));
                        this.spinnerOff();
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
                    this.spinnerOff();
                });

        }

    }

    //called when a user selects an action for processing.
    handleActionSelect(event) {
        var selectedRecords = new Set();
        var selectedRowId = '';
        
        this.selectedActionKey = event.target.value;

        console.log('Chosen Action - ' + this.selectedActionKey + ' for ' + this.pageName);

        this.objectActionList.forEach(action => {
                                                    if (action.value === this.selectedActionKey) {
                                                        this.selectedAction = action;
                                                    }
                                                });

        //------------------------------------------------------
        //HYPERLINK
        //------------------------------------------------------
        if (this.selectedAction.isHyperlink === true)
        {
            this[NavigationMixin.Navigate]({
                type: 'standard__webPage',
                attributes: {
                    url: this.selectedAction.hyperlink,
                },
            });
            

        //------------------------------------------------------
        //NEW
        //------------------------------------------------------
        } else if (this.selectedAction.label === 'New')
        {
            this[NavigationMixin.Navigate]({
                type: 'standard__objectPage',
                attributes: {
                    objectApiName: this.selectedObject,
                    actionName: 'new',
                },
            });
            

        //------------------------------------------------------
        //CLONE
        //------------------------------------------------------
        } else if (this.selectedAction.label === 'Clone')
        {

            //get the selected record Id
            let selectedRows = this.template.querySelectorAll('lightning-input');
            selectedRows.forEach(element => { 
                                                if (element.checked === true && element.value != 'all')
                                                {
                                                    selectedRecords.add(element.value);
                                                    selectedRowId = element.value.substring(0, element.value.indexOf(':'));
                                                }            
                                            });

            if (selectedRecords.size !== 1) {    
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

            //get the selected record Id
            let selectedRows = this.template.querySelectorAll('lightning-input');

            selectedRows.forEach(element => { 
                                                if (element.checked === true && element.value != 'all')
                                                {
                                                    selectedRecords.add(element.value);
                                                    selectedRowId = element.value.substring(0, element.value.indexOf(':'));
                                                }            
                                            });

            if (selectedRecords.size !== 1) {      
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
        //CUSTOM
        //------------------------------------------------------
        } else {

            //get the selected record Ids
            let selectedRows = this.template.querySelectorAll('lightning-input');

            selectedRows.forEach(element => { 
                                                if (element.checked === true && element.value != 'all')
                                                {
                                                    selectedRecords.add(element.value.substring(0, element.value.indexOf(':')));
                                                }
                                            });

            if (selectedRecords.size === 0) {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Error Processing Action',
                    message: 'No rows selected for processing.',
                    variant: 'error',
                    mode: 'dismissable'
                }));
                this.dispatchEvent(new CustomEvent('processclick'));
            
            } else {
                this.selectedRecordIdsStr = JSON.stringify( Array.from(selectedRecords));

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

    handleAdminButtonClick(event) {
        console.log('Admin button clicked for ' + this.pageName);

        this.showAdminModal = true;
    }

    //called if the user selects the cancel button.
    handleCancelButtonClick(event) {
        var action = event.target.label;
        if (action === 'Cancel')
        {
            this.outputStr = this.action;
        }
    }
 
    cancelActionModal() {    
        this.resetActionComboBox();
        this.showActionModal = false;
    }

    processActionModal() {   

        //reset the selected record Ids
        let selectedRows = this.template.querySelectorAll('lightning-input');
        selectedRows.forEach(element => element.checked = false);
        this.selectedRecordCount  = 0;
        this.showActionModal      = false;
        this.selectedAction       = '';

        this.refreshAllListViewData();
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
        this.spinnerOn();

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

    /*
     * Method which sets all rows in the current data set to be editable
     */
    setAllRowsEdited() {
        if (this.toBool(this.allowInlineEditing) === true && this.listViewData.isCoreListView === true)
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

        if (this.toBool(this.allowInlineEditing) === true && this.listViewData.isCoreListView === true)
        {
            this.isEdited = true;
            this.listViewData.isEdited = true;
            this.listViewDataRows.forEach(element => { 
                if (element.isDeleted === false && element.rowId === rowId)
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
}
/* eslint-disable vars-on-top */
/* eslint-disable no-console */
import { LightningElement, wire, track, api  } from 'lwc';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import  LISTVIEW_MC  from '@salesforce/messageChannel/SimpliListViewMessageChannel__c';
import { refreshApex } from '@salesforce/apex';
import { subscribe, unsubscribe, publish, APPLICATION_SCOPE, MessageContext } from 'lightning/messageService';

import getListViewObjects from '@salesforce/apex/ListViewController.getListViewObjects';
import getObjectListViews from '@salesforce/apex/ListViewController.getObjectListViews';
import getListViewData from '@salesforce/apex/ListViewController.getListViewData';
import getListViewsActions from '@salesforce/apex/ListViewController.getListViewsActions';
import updateChangedListViews from '@salesforce/apex/ListViewController.updateChangedListViews';
import updateAllListViews from '@salesforce/apex/ListViewController.updateAllListViews';
import updateSingleListView from '@salesforce/apex/ListViewController.updateSingleListView';
import updateObjectListViews from '@salesforce/apex/ListViewController.updateObjectListViews';
import getUserConfigs from '@salesforce/apex/ListViewController.getUserConfigs';
import getUserSortConfigs from '@salesforce/apex/ListViewController.getUserSortConfigs';
import updateUserConfig from '@salesforce/apex/ListViewController.updateUserConfig';
import isValidListViewDataRequest from '@salesforce/apex/ListViewController.isValidListViewDataRequest';

export default class simpliUIListViews extends NavigationMixin(LightningElement) {

    wiredListViewDataResult;
    wiredObjectListViewsResult;
    wiredListViewObjectsResult;

    @api pageName             = '';                 //this is NOT the page name but the COMPONENT name
    @api hasMainTitle         = false;
    @api mainTitle            = 'List Views';
    @api includedObjects      = '';
    @api excludedObjects      = '';
    @api joinFieldName        = '';
    @api useMessageChannel    = false;
    @api allowRefresh         = false; //config indicating whether the auto refresh checkbox is made available.
    @api displayActions       = false;
    @api displayReprocess     = false;
    @api displayURL           = false;
    @api displayRowCount      = false;
    @api displaySelectedCount = false;
    @api displayOrigButton;             //this is not used....deprecated.
    @api displayModified      = false;
    @api displayExportButton  = false;

    @track joinData           = '';     //holds the join data coming in from an external list view.....if it exists.
    @track modifiedText;                //holds the last modified text that should be displayed based on the component config
    @track userSortConfigs;             //holds all user sort configuration for this named component.
    @track userConfigs;                 //holds all user and org wide configuration for this named component.
    @track selectedListView;            //holds the selected list view name
    @track selectedListViewExportName;  //holds the selected list view name + .csv
    @track selectedObject;              //holds the selected object name
    @track objectList;                  //holds the list of objects from which a user can choose one.
    @track listViewList;                //holds the set of list views for the chosen object
    @track listViewData;                //holds the set of data returned for a given object and list view.
    @track listViewDataRows;            //holds ALL PAGES of data that are returned.
    @track listViewDataRowsSize;        //holds total for ALL PAGES of data that are returned.
    @track listViewDataColumns;         //holds the data tables column information
    @track selectedAction;              //holds the selected action API name if one is chosen.
    @track selectedActionLabel;         //holds the selected action label if one is chosen.
    @track objectActionList;            //holds the list of available actions for the selected object
    //@track listViewConfigParams;        //holds the config parameters for the chosen list view (if one exists)
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
    @track allowAdmin = true;           //indicates whether the admin button should display to the user
    @track firstListViewGet = true;     //indicates whether this is the first time the list views are being retrieved.
    @track canDisplayActions = true;    //indicates whether the page is in a position where the actions list is active
    
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

    //for tracking list view init process
    @track isInit = true;               //indicates whether the list views have been initialized for the first time or not.
    @track showProgress = false;        //indicates whether the progress bar should be displayed
    @track batchId = '';                //indicates the batch Id of the list view batch process.
    @track isInitializing = true;       //indicates whether we are initializing the page or not.

  
    //for message channel handlers
    subscription = null;
    receivedMessage;
    isValid;

    currentPageReference;


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

        console.log('Starting renderedCallback');
        //this ensures we only call this once for each page load
        if (this.userConfigs === undefined) {

            console.log('User config is undefined');

            this.spinnerOn();
            //always subscribe to the message channel
            this.subscribeMC();

            this.urlObject = this.currentPageReference.state.ObjectName;
            this.urlListView = this.currentPageReference.state.ListViewName;
            
            console.log('URL object - ' + this.urlObject);
            console.log('URL list view - ' + this.urlListView);
            console.log('Ltn page name - ' + this.pageName);

            getUserConfigs({compName: this.pageName })
            .then(result => {
                console.log('User configs retrieved successful - ' + result);
                this.userConfigs = result;
                console.log('User config size - ' + this.userConfigs.length); 

                let pinnedListView = this.userConfigs.pinnedListView;
                console.log('Pinned list view string - ' + pinnedListView);

                if (this.userConfigs.DisplayActionsButton === 'false') { this.displayActions = false; }
                if (this.userConfigs.DisplayListViewReprocessingButton === 'false') { this.displayReprocess = false; }
                if (this.userConfigs.DisplayOriginalListViewButton === 'false') { this.displayURL = false; }
                if (this.userConfigs.DisplayRowCount === 'false') { this.displayRowCount = false; }
                if (this.userConfigs.DisplaySelectedCount === 'false') { this.displaySelectedCount = false; }
                if (this.userConfigs.AllowDataExport === 'false') { this.displayExportButton = false; }
                if (this.userConfigs.AllowAutomaticDataRefresh === 'false') { this.allowRefresh = false; }

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
                            title: 'Error Handling User Config',
                            message: 'There was an error handling the list view objects. Please see an administrator\n\n' + error.message,
                            variant: 'error',
                            mode: 'sticky'
                        }));
                        console.log(error.stack)
        
                    });
        
                } else {
                    console.log('There is no URL object and no pinned list view');
                    this.isInitializing = false;
                    this.spinnerOff();
                }
            })
            .catch(error => {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Error Handling User Config',
                    message: 'There was an error handling the user config. Please see an administrator\n\n' + error.message + '\n\n' + error.stackTrace,
                    variant: 'error',
                    mode: 'sticky'
                }));
            });

            getUserSortConfigs({compName: this.pageName })
            .then(result => {
                console.log('User sort configs retrieved successful - ' + result);
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
                            } else if (sortDirection === 'true') {
                                sortDirection = true; //turning the STRING 'true' into the BOOLEAN true
                            } else if (sortDirection === 'false') {
                                sortDirection = false; //turning the STRING 'false' into the BOOLEAN false
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
                            } else if (sortDirection === 'true') {
                                sortDirection = true; //turning the STRING 'true' into the BOOLEAN true
                            } else if (sortDirection === 'false') {
                                sortDirection = false; //turning the STRING 'false' into the BOOLEAN false
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
                    message: 'There was an error handling the user sort config. Please see an administrator\n\n' + error.message,
                    variant: 'error',
                    mode: 'sticky'
                }));
                console.log(error.stack)

            });

        } else {
            console.log('No page initialization needed');
        }
        console.log('Finished renderedCallback');
    }
    
    /*
     * Used for handling the message channel
     */
    @wire(MessageContext)
    messageContext;
    
    /*
     * Wiring to get the list of actions available for the provided object type
     */
    @wire (getListViewsActions, { objectType: '$selectedObject', listViewName: '$selectedListView' })
    wiredListViewsActions({ error, data }) {
        if (data) { 
            console.log('List view actions retrieval successful'); 
            this.objectActionList = data; 
            console.log('Object action list size - ' + this.objectActionList.length); 
            this.error = undefined; 
        } else if (error) { 
            this.error = error; 
            console.log('Error Detected ' + error.message + ' - ' + error.stackTrace); 
            this.objectActionList = undefined; 
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error Retrieving Actions',
                message: 'There was an error retrieving the list view actions. Please see an administrator\n\n' + error.message,
                variant: 'error',
                mode: 'sticky'
            }));
        }
    }

    refreshAllListViewData() {
        this.offset = -1;
        this.getListViewDataPage();
    }

    getListViewDataPage() {

        console.log('Starting refreshListViewData - ' + this.pageName + ' - ' + this.selectedObject + ' - ' + this.selectedListView + ' - ' + this.joinFieldName + ' - ' + this.offset);
        console.log('columnSortDataStr - ' + this.columnSortDataStr);
        this.spinnerOn();
        console.log('Selected list view - ' + this.selectedListView);

        getListViewData({pageName: this.pageName, objectName: this.selectedObject, listViewName: this.selectedListView, sortData: this.columnSortDataStr, joinFieldName: this.joinFieldName, joinData: this.joinData, offset: this.offset })
        .then(result => {

            if (this.listViewData === undefined) {
                console.log('this.listViewData            - undefined');
                console.log('this.listViewData.coreListId - undefined');
            } else {
                console.log('this.listViewData            - ' + this.listViewData);
                console.log('this.listViewData.coreListId - ' + this.listViewData.coreListId);
            }
            console.log('result.coreListId - ' + result.coreListId);
            
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

            console.log('this.listViewDataRows.length - ' + this.listViewDataRows.length);
            console.log('result.listView.rowLimit       - ' + result.listView.rowLimit);
            console.log('this.offset                  - ' + this.offset);
            console.log('result.listView.offset         - ' + result.listView.offset);
        
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

            console.log('List view data retrieval successful - ' + this.offset + ' of ' + this.rowLimit + ' records retrieved'); 

            //sets the last modified text if the component has been configured to show the data.
            if (this.displayModified === true)
            {
                this.modifiedText = this.listViewData.listView.lastModifiedText;
            } else {
                this.modifiedText = '';
            }

            this.error = undefined;  
            this.isInitializing = false;
            this.spinnerOff();
            
        })
        .catch(error => {
            this.error = error; 
            console.log('Error Detected ' + error.message + ' - ' + error.stackTrace); 
            this.listViewData = undefined; 
            this.spinnerOff();
            this.dataSpinnerOff();
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error Retrieving Data',
                message: 'There was an error retrieving the data. Please see an administrator\n\n' + error.message,
                variant: 'error',
                mode: 'sticky'
            }));
        });

    }

    handleListViewObjects(data)
    {
        console.log('List view objects retrieval successful'); 
        console.log('Included objects - ' + this.includedObjects); 
        console.log('Excluded objects - ' + this.excludedObjects); 
        console.log('List view objects retrieval successful'); 
        this.objectList = data; 
        this.error = undefined;
        

        if (this.objectList === undefined || this.objectList.length === 0)
        {
            console.log('Object list is null'); 
            this.isInit = false;
        } else {
            console.log('Object list has been populated with size - ' + this.objectList.length); 

            if (this.pinnedObject !== undefined)
            {
                //check if we have an object that matches the users pinned object. (could be stale)
                var found = this.objectList.find(element => element.value === this.pinnedObject);

                //if we do have an object then set it and get the pinned list view.
                if (found !== undefined)
                {
                    console.log('Object IS in the object list');
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
        console.log('Starting getListViewObjects'); 
        this.wiredListViewObjectsResult = wiredListViewObjectsResult;
        const { data, error } = wiredListViewObjectsResult;
        if (data) {
            this.handleListViewObjects(data); 
        } else if (error) { 
            this.error = error; 
            console.log('Error Detected ' + error.message + ' - ' + error.stackTrace); 
            this.objectList = undefined; 
            this.spinnerOff();
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error Retrieving List View Objects',
                message: 'There was an error retrieving the list view objects. Please see an administrator\n\n' + error.message,
                variant: 'error',
                mode: 'sticky'
            }));
        }
        console.log('Finished getListViewObjects'); 
    }

    /*
     * Wiring to get the list of configuration options from the server controller (ListViewController).
     * We pass the selected object which identifies which list views to retrieve.
     */
    @wire (getObjectListViews, { objectName: '$selectedObject' })
    wiredObjectListViews(wiredObjectListViewsResult) {
        console.log('Starting getObjectListViews'); 
        this.wiredObjectListViewsResult = wiredObjectListViewsResult;
        const { data, error } = wiredObjectListViewsResult;
        if (data) { 
            console.log('Object list view retrieval successful'); 
            this.listViewList = data; 
            this.error = undefined; 
            console.log('Object list view size - ' + this.listViewList.length); 
            console.log('Pinned list view      - ' + this.pinnedListView); 
            console.log('First List View Get   - ' + this.firstListViewGet); 
            
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

                console.log('We have a pinned list view'); 
                //check if we have the list view in the list. (it could be a stale pinning)
                const found = this.listViewList.find(element => element.value === this.pinnedListView);

                //if we have a valid list view name
                if (found !== undefined)
                {
                    console.log('Found a list view with the pinned list view name'); 
                    this.selectedListView = this.pinnedListView;
                    this.selectedListViewExportName = this.selectedListView + '.csv';
                    this.refreshAllListViewData();

                //if we do not then bail.
                } else {
                    console.log('Did NOT find a list view with the pinned list view name'); 
                    this.isInitializing = false;      
                }

                this.firstListViewGet = false;
            }
            this.spinnerOff(); 
        } else if (error) { 
            this.error = error; 
            console.log('Error Detected ' + error.body.message + ' - ' + error.body.stackTrace); 
            this.listViewList = undefined; 
            this.spinnerOff(); 
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error Retrieving Object List Views',
                message: 'There was an error retrieving ' + this.selectedObject + ' list views data. This usually indicates the user does not have read access to the object. Please see an administrator if you believe this to be an error.',
                variant: 'error',
                mode: 'sticky'
            }));
        }
        console.log('Finished getObjectListViews'); 
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
        console.log(this.pageName + ' received a message from ' + this.receivedMessage.pageName);

        //if we have a list view selected AND if we have selected a specific list view to update
        if (this.selectedObject != undefined && this.receivedMessage.pageName != this.pageName && this.joinFieldName != undefined && this.joinFieldName != '')
        {
            console.log('We have a joined field name - ' + this.joinFieldName);
            console.log('Record ids from message - ' + this.receivedMessage.recordIds);
            this.joinData = JSON.stringify(message);
            this.spinnerOn();

            //we need to check and see if this message is valid for this component.
            //I think we need to get rid of this.......causes data reload to take too long.
            isValidListViewDataRequest({objectName: this.selectedObject, joinFieldName: this.joinFieldName, joinData: this.joinData })
            .then(result => {
                console.log('isValidListViewDataRequest returned - ' + result);

                if (result === 'success') {
                    this.refreshAllListViewData();    
                } else {
                    this.spinnerOff();
                }
    
            })
            .catch(error => {
                console.log('Error - ' + error);
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Processing Error',
                    message: 'There was an error processing the list view. Please see an administrator\n\n' + error,
                    variant: 'error',
                    mode: 'sticky'
                }));
        });

        } else {
            console.log('Page names are the same or we do not have a joined field name so ignoring message!');
        }

    }

    handleAutoRefreshData() {

        console.log('Refreshing data');

        if (this.isRefreshed) {

            this.refreshAllListViewData();            

            //https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Function/bind
            //look at its use with setTimeout down the page!
            setTimeout(this.handleAutoRefreshData.bind(this), 5000);

        }
    }

    handleAutoRefreshButtonClick(event) {
        console.log('Auto refresh button clicked!');
        console.log('Refresh was set to ' + this.isRefreshed);

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
        console.log('Refresh now set to ' + this.isRefreshed);
    }

    /*
     * Called when the user clicks the data download button.
     * This returns the data for the current list view in CSV format.
     */
    handleDownloadData(event) {
        console.log('Data export button clicked');    
        
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
        console.log('Selected data export button clicked');   
        
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
        console.log('handleRecordSelectChange Started');
        this.spinnerOn();
        console.log('Record selected - ' + event.target.checked + ': ' + event.target.value);

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

            console.log('Sending to message channel');
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
            console.log('NOT sending to message channel');
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

        console.log('Object selected - ' + this.selectedObject);
    }

    /*
     * Called when a user changed a list view, used 
     * to retrieve record data.
     */
    handleListViewSelected(event) {

        console.log('Old list view - ' + this.selectedListView);
        console.log('Sort data - ' + this.listViewSortData);
        this.spinnerOn();
        
        //set the old column sort information into the list view sort data for caching otherwise it disappears.
        if (this.columnSortDataStr !== '')
        {
            this.listViewSortData.set(this.selectedObject + ':' + this.selectedListView, this.columnSortData);
        }

        //set the new selected list view
        this.selectedListView = event.target.value;
        console.log('New list view - ' + this.selectedListView);
        this.selectedListViewExportName = this.selectedListView + '.csv';

        //set the column sort information for the NEW list view
        console.log('Test1');
        if (this.listViewSortData.get(this.selectedObject + ':' + this.selectedListView) !== undefined)
        {
            console.log('Test2');
            this.columnSortData = this.listViewSortData.get(this.selectedObject + ':' + this.selectedListView);
            this.columnSortDataStr = JSON.stringify( Array.from(this.columnSortData));
            console.log('Test3');
        
        } else {
            console.log('Test4');
            this.columnSortDataStr = '';
            this.columnSortData = new Map();  
            console.log('Test5');
        }
        console.log('Test6');

        //if we are not in the construction of the page and we change the list view and its the pinned list view
        if (this.userConfigs != undefined && this.pinnedObject === this.selectedObject && this.pinnedListView === this.selectedListView) {
            this.isPinned = true;
        } else {
            this.isPinned = false;
        }
        console.log('Starting ListView Data Refresh');

        this.refreshAllListViewData();
    }

    /*
     * Method for handling when a user pins a given list view.
     */
    handlePinningClick(event) {
        this.isPinned = true;

        updateUserConfig({compName: this.pageName, configName: 'pinnedListView', value: this.selectedObject + ':' + this.selectedListView })
        .then(result => {
            console.log('List view pinning successful'); 
            this.dispatchEvent(new ShowToastEvent({
                title: 'List View Pinned',
                message: 'List view successfully pinned.',
                variant: 'success',
                mode: 'dismissable'
            }));
        })
        .catch(error => {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Processing Error',
                message: 'There was an error during user configuration update. Please see an administrator\n\n' + error.message,
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
            console.log('List view unpinning successful'); 
            this.dispatchEvent(new ShowToastEvent({
                title: 'List View Unpinned',
                message: 'List view successfully unpinned.',
                variant: 'success',
                mode: 'dismissable'
            }));
        })
        .catch(error => {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Processing Error',
                message: 'There was an error during user configuration update. Please see an administrator\n\n' + error.message,
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
        console.log('URL clicked - ' + event.target.href);
        console.log('URL target  - ' + target);

        //hack to get the record Id from the URL
        const chars = event.target.href.split('/');
        console.log('Id - ' + chars[5]);

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
        console.log('Data Spinner ON');
    }

    dataSpinnerOff() {
        this.dataSpinner = false;
        this.canDisplayActions = true;
        console.log('Data Spinner OFF');
    }

    spinnerOn() {
        this.spinner = true;
        console.log('Spinner ON');
    }

    spinnerOff() {
        if (this.isInitializing === false)
        {
            this.spinner = false;
            console.log('Spinner OFF');
        }
        //var stack = new Error().stack
        //console.log( stack )
    }

    //called when a user clicks the button to refresh the list views.
    handleProcessListViewsButtonClick() {

        this.spinnerOn();
        console.log('Listview process button clicked!');
        console.log('selectedObject - ' + this.selectedObject);
        console.log('selectedListView - ' + this.selectedListView);

        //if we have selected a specific list view to update
        if (this.selectedObject != undefined && this.selectedListView != undefined && this.isInit === true)
        {
            console.log('Updating SINGLE list view');

            updateSingleListView({objectType: this.selectedObject, listViewName: this.selectedListView })
                .then(result => {

                    //if we have an error then send an ERROR toast.
                    if (result === 'success')
                    {
                        this.dispatchEvent(new ShowToastEvent({
                            title: 'List View Updated Successfully',
                            message: 'List view has been updated successfully. Refresh entire page to see the changes.',
                            variant: 'success',
                            mode: 'dismissable'
                        }));
                        this.dispatchEvent(new CustomEvent('processlistviewclick'));
                        this.refreshAllListViewData();
                        this.spinnerOff();

                    //else send an ERROR toast.
                    } else {
                        this.dispatchEvent(new ShowToastEvent({
                            title: 'Processing Error',
                            message: 'There was an error processing the list view. Please see an administrator',
                            variant: 'error',
                            mode: 'sticky'
                        }));

                        this.spinnerOff();
                    }
                })
                .catch(error => {
                    this.dispatchEvent(new ShowToastEvent({
                        title: 'Processing Error',
                        message: 'There was an error processing the list view. Please see an administrator\n\n' + error.message,
                        variant: 'error',
                        mode: 'sticky'
                    }));
                    this.spinnerOff();
                });


        }
        
        //if we have selected an objects list views to update
        else if (this.selectedObject != undefined && this.selectedListView === undefined && this.isInit === true)
        {
            console.log('Updating OBJECT list views');

            updateObjectListViews({objectType: this.selectedObject })
                .then(result => {

                    //if we have an error then send an ERROR toast.
                    if (result === 'success')
                    {
                        this.dispatchEvent(new ShowToastEvent({
                            title: 'List Views Updated Successfully',
                            message: 'List views have been updated successfully. Refresh entire page to see the changes.',
                            variant: 'success',
                            mode: 'dismissable'
                        }));
                        this.dispatchEvent(new CustomEvent('processlistviewclick'));
                        refreshApex(this.wiredObjectListViewsResult);
                        this.refreshAllListViewData();
                        this.spinnerOff();

                    //else send an ERROR toast.
                    } else {
                        this.dispatchEvent(new ShowToastEvent({
                            title: 'Processing Error',
                            message: 'There was an error processing the list views. Please see an administrator',
                            variant: 'error',
                            mode: 'sticky'
                        }));
                        this.spinnerOff();
                
                    }
                })
                .catch(error => {
                    this.dispatchEvent(new ShowToastEvent({
                        title: 'Processing Error',
                        message: 'There was an error processing the list views. Please see an administrator\n\n' + error.message,
                        variant: 'error',
                        mode: 'sticky'
                    }));
                    this.spinnerOff();
                });

        }

        //if we have selected ALL list views to update
        else if (this.selectedObject === undefined && this.selectedListView === undefined ||  this.isInit === false)
        {
            console.log('Updating ALL list views');

            updateAllListViews({ })
                .then(result => {

                    //if we have an error then send an ERROR toast.
                    if (result === 'failed')
                    {
                        this.dispatchEvent(new ShowToastEvent({
                            title: 'Processing Error',
                            message: 'There was an error processing the list views. Please see an administrator',
                            variant: 'error',
                            mode: 'sticky'
                        }));
                        this.spinnerOff();

                    //else send a SUCCESS toast.
                    } else {

                        this.batchId = result;

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
                    this.dispatchEvent(new ShowToastEvent({
                        title: 'Processing Error',
                        message: 'There was an error processing the list views. Please see an administrator\n\n' + error.message,
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
        
        this.selectedAction = event.target.value;

        console.log('Chosen Action - ' + this.selectedAction);

        //------------------------------------------------------
        //NEW
        //------------------------------------------------------
        if (this.selectedAction.startsWith('New:'))
        {
            this[NavigationMixin.Navigate]({
                type: 'standard__objectPage',
                attributes: {
                    objectApiName: this.selectedObject,
                    actionName: 'new',
                },
            });
            
            this.selectedAction = '';

        //------------------------------------------------------
        //CLONE
        //------------------------------------------------------
        } else if (this.selectedAction.startsWith('Clone:'))
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
                this.selectedAction = '';            
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Error Processing Action',
                    message: 'A single row must be selected for cloning.',
                    variant: 'error',
                    mode: 'dismissable'
                }));
            } else {
                console.log('We are cloning the following id - ' + selectedRowId);
                this.selectedAction = '';

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
        } else if (this.selectedAction.startsWith('Edit:'))
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
                this.selectedAction = '';            
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Error Processing Action',
                    message: 'A single row must be selected for editing.',
                    variant: 'error',
                    mode: 'dismissable'
                }));
            } else {

                console.log('We are editing the following id - ' + selectedRowId);
                this.selectedAction = '';

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
        //CUSTOM
        //------------------------------------------------------
        } else {

            //get the selected record Ids
            let selectedRows = this.template.querySelectorAll('lightning-input');

            selectedRows.forEach(element => { 
                                                if (element.checked === true && element.value != 'all')
                                                {
                                                    selectedRecords.add(element.value);
                                                }
                                            });

            if (selectedRecords.size === 0) {
                this.selectedAction = '';
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Error Processing Action',
                    message: 'No rows selected for processing.',
                    variant: 'error',
                    mode: 'dismissable'
                }));
                this.dispatchEvent(new CustomEvent('processclick'));

                return;
            
            } else {
                this.selectedRecordIdsStr = JSON.stringify( Array.from(selectedRecords));

                this.selectedActionLabel = 'Label ' + this.selectedAction;               //   <-- This to be fixed.
                
                console.log('Action Label selected - ' + this.selectedActionLabel);
                console.log('Action name           - ' + this.selectedAction);
                console.log('Action Record Ids     - ' + this.selectedRecordIdsStr);
        
                this.showActionModal = true;
            }

        }

    }

    handleAdminButtonClick(event) {
        console.log('Admin button clicked');

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
        this.selectedAction = '';
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
        console.log('final tag Name'+parObj.tagName);
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
        } else if (sortDirection === 'true') {
            sortDirection = true; //turning the STRING 'true' into the BOOLEAN true
        } else if (sortDirection === 'false') {
            sortDirection = false; //turning the STRING 'false' into the BOOLEAN false
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

}
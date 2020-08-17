/* eslint-disable vars-on-top */
/* eslint-disable no-console */
import { LightningElement, wire, track, api  } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import  LISTVIEW_MC  from '@salesforce/messageChannel/SimpliListViewMessageChannel__c';
import { refreshApex } from '@salesforce/apex';
import { subscribe, unsubscribe, publish, APPLICATION_SCOPE, MessageContext } from 'lightning/messageService';

import getListViewObjects from '@salesforce/apex/ListViewController.getListViewObjects';
import getObjectListViews from '@salesforce/apex/ListViewController.getObjectListViews';
import getListViewData from '@salesforce/apex/ListViewController.getListViewData';
import getListViewsActions from '@salesforce/apex/ListViewController.getListViewsActions';
import getListViewConfigParams from '@salesforce/apex/ListViewController.getListViewConfigParams';
import updateChangedListViews from '@salesforce/apex/ListViewController.updateChangedListViews';
import updateAllListViews from '@salesforce/apex/ListViewController.updateAllListViews';
import updateSingleListView from '@salesforce/apex/ListViewController.updateSingleListView';
import updateObjectListViews from '@salesforce/apex/ListViewController.updateObjectListViews';
import getUserConfigs from '@salesforce/apex/ListViewController.getUserConfigs';
import updateUserConfig from '@salesforce/apex/ListViewController.updateUserConfig';
import isValidListViewDataRequest from '@salesforce/apex/ListViewController.isValidListViewDataRequest';

export default class simpliUIListViews extends NavigationMixin(LightningElement) {

    wiredListViewDataResult;
    wiredObjectListViewsResult;

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

    @track modifiedText;                //holds the last modified text that should be displayed based on the component config
    @track userConfigs;                 //holds all user configuration for this named component.
    @track selectedListView;            //holds the selected list view name
    @track selectedObject;              //holds the selected object name
    @track objectList;                  //holds the list of objects from which a user can choose one.
    @track listViewList;                //holds the set of list views for the chosen object
    @track listViewData;                //holds the set of data returned for a given object and list view.
    @track listViewDataColumns;         //holds the data tables column information
    @track selectedAction;              //holds the selected action API name if one is chosen.
    @track selectedActionLabel;         //holds the selected action label if one is chosen.
    @track objectActionList;            //holds the list of available actions for the selected object
    @track listViewConfigParams;        //holds the config parameters for the chosen list view (if one exists)
    @track showActionModal;             //indicates whether the action modal form should be displayed.
    @track showAdminModal;              //indicates whether the admin modal form should be displayed.
    @track selectedRecordIdsStr;        //holds the set of record ids that have been selected as a string
    @track selectedRecordCount = 0;     //the number of records selected. Passed into the modal dialog.  
    @track isPinned = false;            //identifies whether this list view and object have been pinned.
    @track pinnedListView = undefined;  //the list view that is pinned if there is a pinned list view.
    @track pinnedObject = undefined;    //the object that is pinned if there is a pinned list view.
    @track isRefreshed = false;         //identifies whether this list views data is being refreshed at intervals.
    @track spinner = false;             //identifies if the PAGE spinner should be displayed or not.
    @track allowAdmin = true;           //indicates whether the admin button should display to the user
    //for handling column width changes
    @track mouseStart;
    @track oldWidth;
    @track parentObj;

    //for handling sorting
    @track columnSortData = new Map();
    @track columnSortDataStr = '';

    //for tracking list view init process
    @track isInit = true;               //indicates whether the list views have been initialized for the first time or not.
    @track showProgress = false;        //indicates whether the progress bar should be displayed
    @track batchId = '';                //indicates the batch Id of the list view batch process.
  
    //for message channel handlers
    subscription = null;
    receivedMessage;
    isValid;

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
    
    /*
     * Method which gets called after the class has been instantiated
     * but before it is rendered. We do have access to variables in this method.
     */
    renderedCallback() {

        //this ensures we only call this once for each page load
        if (this.userConfigs === undefined) {

            //always subscribe to the message channel
            this.subscribeMC();

            getUserConfigs({compName: this.pageName })
            .then(result => {
                console.log('User configs retrieved successful - ' + result);
                this.userConfigs = result;

                let pinnedListView = this.userConfigs.pinnedListView;

                if (pinnedListView != undefined && pinnedListView != '') {
                    this.isPinned = true;
                    this.pinnedObject = pinnedListView.substring(0, pinnedListView.lastIndexOf(':'));
                    this.selectedObject = this.pinnedObject;
                    this.pinnedListView = pinnedListView.substring(pinnedListView.lastIndexOf(':')+1);
                }
            })
            .catch(error => {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Error Handling User Config',
                    message: 'There was an error handling the user config. Please see an administrator\n\n' + error.body.message + '\n\n' + error.body.stackTrace,
                    variant: 'error',
                    mode: 'sticky'
                }));
            });
        }
    }
    
    /*
     * Used for handling the message channel
     */
    @wire(MessageContext)
    messageContext;
    
    /*
     * Wiring to get the list of config parameters for the chosen object and list view
     */
    @wire (getListViewConfigParams, { objectType: '$selectedObject', listViewName: '$selectedListView' })
    wiredListViewsConfigs({ error, data }) {
        if (data) { 
            console.log('List view config retrieval successful'); 
            this.listViewConfigParams = data; 
            this.error = undefined; 
        } else if (error) { 
            this.error = error; 
            console.log('Error Detected ' + error.body.message + ' - ' + error.body.stackTrace); 
            this.listViewConfigParams = undefined; 
            this.spinner = false;
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error Retrieving List View Configs',
                message: 'There was an error retrieving the list view configs. Please see an administrator\n\n' + error.body.message + '\n\n' + error.body.stackTrace,
                variant: 'error',
                mode: 'sticky'
            }));
        }
    }

    /*
     * Wiring to get the list of actions available for the provided object type
     */
    @wire (getListViewsActions, { objectType: '$selectedObject' })
    wiredListViewsActions({ error, data }) {
        if (data) { 
            console.log('List view actions retrieval successful'); 
            this.objectActionList = data; 
            this.error = undefined; 
            this.spinner = false; 
        } else if (error) { 
            this.error = error; 
            console.log('Error Detected ' + error.body.message + ' - ' + error.body.stackTrace); 
            this.objectActionList = undefined; 
            this.spinner = false; 
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error Retrieving Actions',
                message: 'There was an error retrieving the list view actions. Please see an administrator\n\n' + error.body.message + '\n\n' + error.body.stackTrace,
                variant: 'error',
                mode: 'sticky'
            }));
        }
    }

    /*
     * Wiring to get the list of objects in the system using a LISTVIEW NAME
     */
    @wire (getListViewData, { objectName: '$selectedObject', listViewName: '$selectedListView', sortData: '$columnSortDataStr', joinFieldName: '$joinFieldName', joinData: '' })
    wiredListViewData(wiredListViewDataResult) {
        this.wiredListViewDataResult = wiredListViewDataResult;
        const { data, error } = wiredListViewDataResult;

        if (data) { 
            console.log('List view data retrieval successful'); 
            this.listViewData = data;

            //sets the last modified text if the component has been configured to show the data.
            if (this.displayModified === true)
            {
                this.modifiedText = this.listViewData.listView.lastModifiedText;
            } else {
                this.modifiedText = '';
            }

            this.error = undefined;  
            this.spinner = false;
        } else if (error) { 
            this.error = error; 
            console.log('Error Detected ' + error.body.message + ' - ' + error.body.stackTrace); 
            this.listViewData = undefined; 
            this.spinner = false;
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error Retrieving Data',
                message: 'There was an error retrieving the data. Please see an administrator\n\n' + error.body.message + '\n\n' + error.body.stackTrace,
                variant: 'error',
                mode: 'sticky'
            }));
        }
    }

    /*
     * Wiring to get the list of objects in the system
     */
    @wire (getListViewObjects, { includedObjects: '$includedObjects', excludedObjects: '$excludedObjects'  })
    wiredListViewObjects({ error, data }) {
        if (data) { 
            console.log('List view objects retrieval successful'); 
            console.log('Included objects - ' + this.includedObjects); 
            console.log('Excluded objects - ' + this.excludedObjects); 
            console.log('List view objects retrieval successful'); 
            this.objectList = data; 
            this.error = undefined;
            
            if (this.objectList === undefined || this.objectList.length === 0)
            {
                this.isInit = false;
            }

            this.spinner = false;
        } else if (error) { 
            this.error = error; 
            console.log('Error Detected ' + error.body.message + ' - ' + error.body.stackTrace); 
            this.objectList = undefined; 
            this.spinner = false;
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error Retrieving List View Objects',
                message: 'There was an error retrieving the list view objects. Please see an administrator\n\n' + error.body.message + '\n\n' + error.body.stackTrace,
                variant: 'error',
                mode: 'sticky'
            }));
        }
    }

    /*
     * Wiring to get the list of configuration options from the server controller (ListViewController).
     * We pass the selected object which identifies which list views to retrieve.
     */
    @wire (getObjectListViews, { objectName: '$selectedObject' })
    wiredObjectListViews(wiredObjectListViewsResult) {
        this.wiredObjectListViewsResult = wiredObjectListViewsResult;
        const { data, error } = wiredObjectListViewsResult;
        if (data) { 
            console.log('Object list view retrieval successful'); 
            this.listViewList = data; 
            this.error = undefined; 
            if (this.pinnedListView != undefined) {
                this.selectedListView = this.pinnedListView;
            }
            this.spinner = false; 
        } else if (error) { 
            this.error = error; 
            console.log('Error Detected ' + error.body.message + ' - ' + error.body.stackTrace); 
            this.listViewList = undefined; 
            this.spinner = false; 
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error Retrieving Object List Views',
                message: 'There was an error retrieving the ' + objectName + ' list views data. Please see an administrator\n\n' + error.body.message + '\n\n' + error.body.stackTrace,
                variant: 'error',
                mode: 'sticky'
            }));
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
            let joinData = JSON.stringify(message);

            //we need to check and see if this message is valid for this component.
            //I think we need to get rid of this.......causes data reload to take too long.
            isValidListViewDataRequest({objectName: this.selectedObject, joinFieldName: this.joinFieldName, joinData: joinData })
            .then(result => {
                console.log('isValidListViewDataRequest returned - ' + result);

                if (result === 'success') {

                    getListViewData({objectName: this.selectedObject, listViewName: this.selectedListView, sortData: this.columnSortDataStr, joinFieldName: this.joinFieldName, joinData: joinData })
                        .then(result => {
                            console.log('List view data retrieval successful'); 
                            this.listViewData = result;
                        })
                        .catch(error => {
                            this.dispatchEvent(new ShowToastEvent({
                                title: 'Processing Error',
                                message: 'There was an error processing the list view. Please see an administrator\n\n' + error.body.message + '\n\n' + error.body.stackTrace,
                                variant: 'error',
                                mode: 'sticky'
                            }));
                    });
    
                }    
    
            })
            .catch(error => {
                console.log('Error');
            });

        } else {
            console.log('Page names are the same or we do not have a joined field name so ignoring message!');
        }

    }

    handleAutoRefreshData() {

        console.log('Refreshing data');

        if (this.isRefreshed) {

            refreshApex(this.wiredListViewDataResult);

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
        var csvData = this.listViewData.dataAsString;

        var data = new Blob([csvData]);
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
        for(let i = 0; i < selectedRows.length; i++) {
            if (selectedRows[i].checked === true && selectedRows[i].value != 'all')
            {
                selectedRecords.add(selectedRows[i].value);
            }
        }

        //go through rows looking for selected record Ids
        for(let i = 0; i < this.listViewData.rows.length; i++) {
            console.log('Inside data loop ');
            
            if (selectedRecords.has(this.listViewData.rows[i].rowId)) {
                dataStr = dataStr + this.listViewData.rows[i].dataAsCSVString;
            }
        }

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
        this.spinner = true;
        console.log('Record selected - ' + event.target.checked + ': ' + event.target.value);

        //get all checkbox components
        let selectedRows = this.template.querySelectorAll('lightning-input');

        //if we have selected "All" then run through all components setting them true or false.
        if (event.target.value === 'all')
        {

            for(let i = 0; i < selectedRows.length; i++) {
                selectedRows[i].checked = event.target.checked;
            }

            if (event.target.checked === true) {
                this.selectedRecordCount = this.listViewData.rowCount;
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

            console.log('Sending to message channel');
            //run through all the checkbox components again now that they have been set
            var recordIds = '';        

            for(let i = 0; i < selectedRows.length; i++) {
                if(selectedRows[i].checked === true && selectedRows[i].value != 'all') {
                            recordIds = recordIds + selectedRows[i].value + ',';
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
        
        } else {
            console.log('NOT sending to message channel');
        }

        this.spinner = false;
    }

    /*
     * Called when a user is selecting a list view and 
     * they have changed the object of the list view.
     */
    handleObjectChange(event) {
        this.spinner = true;
        this.selectedObject = event.target.value;
        this.listViewList = undefined;
        this.selectedListView = undefined;
        this.listViewData = undefined;
        this.objectActionList = undefined;
        
        console.log('Object selected - ' + this.selectedObject);
    }

    /*
     * Called when a user changed a list view, used 
     * to retrieve record data.
     */
    handleListViewSelected(event) {
        this.spinner = true;
        this.selectedListView = event.target.value;
        console.log('List view selected - ' + this.selectedListView);
        this.listViewData = undefined;

        //if we are not in the construction of the page and we change the list view and its the pinned list view
        if (this.userConfigs != undefined && this.pinnedObject === this.selectedObject && this.pinnedListView === this.selectedListView) {
            this.isPinned = true;
        } else {
            this.isPinned = false;
        }
    }

    /*
     * Method for handling when a user pins a given list view.
     */
    handlePinningClick(event) {
        this.isPinned = true;

        updateUserConfig({compName: this.pageName, configName: 'pinnedListView', value: this.selectedObject + ':' + this.selectedListView })
        .then(result => {
            console.log('User config update successful'); 
        })
        .catch(error => {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Processing Error',
                message: 'There was an error during user configuration update. Please see an administrator\n\n' + error.body.message + '\n\n' + error.body.stackTrace,
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
            console.log('User config update successful'); 
        })
        .catch(error => {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Processing Error',
                message: 'There was an error during user configuration update. Please see an administrator\n\n' + error.body.message + '\n\n' + error.body.stackTrace,
                variant: 'error',
                mode: 'sticky'
            }));
        });
    }
    
    /*
     * Called when a URL on the pages table data is clicked
     */
    handleURLClick(event) {

        //this is the URL
        console.log('URL clicked! - ' + event.target.href);

        //hack to get the record Id from the URL
        const chars = event.target.href.split('/');
        console.log('ID - ' + chars[5]);

        //stop the link from doing its usual thing as we will be doing our thing.
        event.preventDefault();
        event.stopPropagation();
        
        // Navigate to record page
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: chars[5],
                actionName: 'view',
            },
        });
    }

    //called when a user clicks the button to refresh the list views.
    handleProcessListViewsButtonClick() {

        this.spinner = true;
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

                    //else send an ERROR toast.
                    } else {
                        this.dispatchEvent(new ShowToastEvent({
                            title: 'Processing Error',
                            message: 'There was an error processing the list view. Please see an administrator',
                            variant: 'error',
                            mode: 'sticky'
                        }));
                
                    }
                })
                .catch(error => {
                    this.dispatchEvent(new ShowToastEvent({
                        title: 'Processing Error',
                        message: 'There was an error processing the list view. Please see an administrator\n\n' + error.body.message + '\n\n' + error.body.stackTrace,
                        variant: 'error',
                        mode: 'sticky'
                    }));
            });

            this.spinner = false;
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

                    //else send an ERROR toast.
                    } else {
                        this.dispatchEvent(new ShowToastEvent({
                            title: 'Processing Error',
                            message: 'There was an error processing the list views. Please see an administrator',
                            variant: 'error',
                            mode: 'sticky'
                        }));
                
                    }
                })
                .catch(error => {
                    this.dispatchEvent(new ShowToastEvent({
                        title: 'Processing Error',
                        message: 'There was an error processing the list views. Please see an administrator\n\n' + error.body.message + '\n\n' + error.body.stackTrace,
                        variant: 'error',
                        mode: 'sticky'
                    }));
            });

            this.spinner = false;
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

                    //else send a SUCCESS toast.
                    } else {

                        this.batchId = result;

                        this.showProgress = true;

                        this.dispatchEvent(new ShowToastEvent({
                            title: 'List View Processing',
                            message: 'List view processing has started and should be complete in a few minutes. Refresh to see the changes.',
                            variant: 'success',
                            mode: 'dismissable'
                        }));
                        this.dispatchEvent(new CustomEvent('processlistviewclick'));
                    }
                })
                .catch(error => {
                    this.dispatchEvent(new ShowToastEvent({
                        title: 'Processing Error',
                        message: 'There was an error processing the list views. Please see an administrator\n\n' + error.body.message + '\n\n' + error.body.stackTrace,
                        variant: 'error',
                        mode: 'sticky'
                    }));
            });

            this.spinner = false;
        }

    }

    //called when a user selects an action for processing.
    handleActionSelect(event) {

        var selectedRecords = new Set();
        
        this.selectedAction = event.target.value;

        //get the selected record Ids
        let selectedRows = this.template.querySelectorAll('lightning-input');
        for(let i = 0; i < selectedRows.length; i++) {
            if (selectedRows[i].checked === true && selectedRows[i].value != 'all')
            {
                selectedRecords.add(selectedRows[i].value);
            }
        }

        if (selectedRecords.size === 0) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error Processing Action',
                message: 'No rows selected for processing.',
                variant: 'error',
                mode: 'dismissable'
            }));
            this.dispatchEvent(new CustomEvent('processclick'));

            this.selectedAction = '';
            return;
        
        } else {
            this.showActionModal = true;
            this.selectedRecordIdsStr = JSON.stringify( Array.from(selectedRecords));

            this.selectedActionLabel = 'Label ' + this.selectedAction;               //   <-- This to be fixed.
            
            console.log('Action Label selected - ' + this.selectedActionLabel);
            console.log('Action name           - ' + this.selectedAction);
            console.log('Action Record Ids     - ' + this.selectedRecordIdsStr);
    
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
 
    cancelModal() {    
        this.selectedAction = '';
        this.showActionModal = false;
    }

    processModal() {   

        //reset the selected record Ids
        let selectedRows = this.template.querySelectorAll('lightning-input');
        for(let i = 0; i < selectedRows.length; i++) {
            if (selectedRows[i].checked === true)
            {
                selectedRows[i].checked = false;
            }
        }

        this.showActionModal      = false;
        this.selectedAction       = '';

        refreshApex(this.wiredListViewDataResult);
        console.log('APEX REFRESHED');
    }

    /*
     * Method called after the admin modal dialog is closed.
     */
    processAdminModal() {   

        this.showAdminModal = false;

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
        this.spinner = true;

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
        
      }

}
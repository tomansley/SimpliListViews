/* eslint-disable vars-on-top */
/* eslint-disable no-console */
import { LightningElement, wire, track, api  } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import getListViewObjects from '@salesforce/apex/ListViewController.getListViewObjects';
import getObjectListViews from '@salesforce/apex/ListViewController.getObjectListViews';
import getListViewData from '@salesforce/apex/ListViewController.getListViewData';
import getListViewsActions from '@salesforce/apex/ListViewController.getListViewsActions';
import getListViewConfig from '@salesforce/apex/ListViewController.getListViewConfig';
import updateChangedListViews from '@salesforce/apex/ListViewController.updateChangedListViews';
import updateAllListViews from '@salesforce/apex/ListViewController.updateAllListViews';
import updateSingleListView from '@salesforce/apex/ListViewController.updateSingleListView';
import updateObjectListViews from '@salesforce/apex/ListViewController.updateObjectListViews';
import { refreshApex } from '@salesforce/apex';

export default class SimpliUIBatch extends NavigationMixin(LightningElement) {

    @api hasMainTitle = false;
    @api mainTitle = 'List Views';
    @api displayActions = false;
    @api displayReprocess = false;
    @api displayURL = false;
    @api includedObjects = '';
    @api excludedObjects = '';
    @api displayOrigButton;

    @track selectedListView;            //holds the selected list view name
    @track selectedObject;              //holds the selected object name
    @track objectList;                  //holds the list of objects from which a user can choose one.
    @track listViewList;                //holds the set of list views for the chosen object
    @track listViewData;                //holds the set of data returned for a given object and list view.
    @track listViewDataColumns;         //holds the data tables column information
    @track spinner = false;             //identifies if the spinner should be displayed or not.
    @track selectedAction;              //holds the selected action API name if one is chosen.
    @track selectedActionLabel;         //holds the selected action label if one is chosen.
    @track objectActionList;            //holds the list of available actions for the selected object
    @track listViewConfig;              //holds the config parameters for the chosen list view (if one exists)
    @track showActionModal;             //indicates whether the action modal form should be displayed.
    @track selectedRecordIdsStr;        //holds the set of record ids that have been selected as a string
    @track selectedRecordCount = 0;     //the number of records selected. Passed into the modal dialog.  

    //for handling column width changes
    @track mouseStart;
    @track oldWidth;
    @track parentObj;

    //for handling sorting
    @track columnSortData = new Map();
    @track columnSortDataStr = '';
  
    constructor() {
        super();

        //if the user recently changed a core list view this should do an immediate update. 
        //Only 5 list views are updated at most.
        updateChangedListViews()
            .then(result => {
            })
            .catch(error => {
            });
    }
    
    /*
     * Wiring to get the list of config parameters for the chosen object and list view
     */
    @wire (getListViewConfig, { objectType: '$selectedObject', listViewName: '$selectedListView' })
    wiredListViewsConfigs({ error, data }) {
        if (data) { 
            console.log('SUCCESS DATA GET ' + data); 
            this.listViewConfig = data; this.error = undefined; this.spinner = false; }
        else if (error) { 
            console.log('error DETECTED ' + error.message); 
            this.error = error; this.listViewConfig = undefined; this.spinner = false; }
    }

    /*
     * Wiring to get the list of actions available for the provided object type
     */
    @wire (getListViewsActions, { objectType: '$selectedObject' })
    wiredListViewsActions({ error, data }) {
        if (data) { 
            console.log('SUCCESS DATA GET ' + data); 
            this.objectActionList = data; this.error = undefined; this.spinner = false; }
        else if (error) { 
            console.log('error DETECTED ' + error.message); 
            this.error = error; this.objectActionList = undefined; this.spinner = false; }
    }

    /*
     * Wiring to get the list of objects in the system using a LISTVIEW NAME
     */
    @wire (getListViewData, { objectName: '$selectedObject', listViewName: '$selectedListView', sortData: '$columnSortDataStr' })
    wiredListViewData({ error, data }) {
        if (data) { 
            console.log('SUCCESS DATA GET ' + data); 
            this.listViewData = data; this.error = undefined; this.spinner = false; }
        else if (error) { 
            console.log('error DETECTED ' + error.message); 
            this.error = error; this.listViewData = undefined; this.spinner = false; }
    }

    /*
     * Wiring to get the list of objects in the system
     */
    @wire (getListViewObjects, { includedObjects: '$includedObjects', excludedObjects: '$excludedObjects'  })
    wiredListViewObjects({ error, data }) {
        if (data) { this.objectList = data; this.error = undefined; this.spinner = false; }
        else if (error) { this.error = error; this.objectList = undefined; this.spinner = false; }
    }

    /*
     * Wiring to get the list of configuration options from the server controller (ListViewController).
     * We pass the selected object which identifies which list views to retrieve.
     */
    @wire (getObjectListViews, { objectName: '$selectedObject' })
    wiredObjectListViews({ error, data }) {
        if (data) { this.listViewList = data; this.error = undefined; this.spinner = false; }
        else if (error) { this.error = error; this.listViewList = undefined; this.spinner = false; }
    }

    //called when a user checks a box next to a record for selection to be processed.
    handleRecordSelectChange(event) {
        console.log('Record selected - ' + event.target.checked + ': ' + event.target.value);
        if (event.target.value === 'all')
        {
            let selectedRows = this.template.querySelectorAll('lightning-input');
        
            for(let i = 0; i < selectedRows.length; i++) {
                if(selectedRows[i].type === 'checkbox') {
                    selectedRows[i].checked = event.target.checked;
                }
            }
        }
    }

    //called when a user is selecting a list view and they have changed the object of the list view.
    handleObjectChange(event) {
        this.spinner = true;
        this.selectedObject = event.target.value;
        this.listViewList = undefined;
        this.selectedListView = undefined;
        this.listViewData = undefined;
        this.objectActionList = undefined;
        console.log('Object selected - ' + this.selectedObject);
    }

    //called when a user changed a list view, used to retrieve record data.
    handleListViewSelected(event) {
        this.spinner = true;
        this.selectedListView = event.target.value;
        this.listViewData = undefined;
        console.log('List view selected - ' + this.selectedListView);
    }
    
    //called when a URL on the pages table data is clicked
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
        var selectObject;
        var selectListView;

        this.spinner = true;
        console.log('Listview process button clicked!');
        console.log('selectedObject - ' + this.selectedObject);
        console.log('selectedListView - ' + this.selectedListView);

        selectObject = this.selectedObject;
        selectListView = this.selectedListView;

        //if we have selected a specific list view to update
        if (this.selectedObject != undefined && this.selectedListView != undefined)
        {
            console.log('Updating SINGLE list view');

            updateSingleListView({objectType: this.selectedObject, listViewName: this.selectedListView })
                .then(result => {

                    //if we have an error then send an ERROR toast.
                    if (result === 'success')
                    {
                        this.dispatchEvent(new ShowToastEvent({
                            title: 'List View Updated Successfully',
                            message: 'List view has been updated successfully. Refresh to see the changes.',
                            variant: 'success',
                            mode: 'sticky'
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
                        message: 'There was an error processing the list view. Please see an administrator',
                        variant: 'error',
                        mode: 'sticky'
                    }));
            });

            this.spinner = false;

        }
        
        //if we have selected an objects list views to update
        if (this.selectedObject != undefined && this.selectedListView === undefined)
        {
            console.log('Updating OBJECT list views');

            updateObjectListViews({objectType: this.selectedObject })
                .then(result => {

                    //if we have an error then send an ERROR toast.
                    if (result === 'success')
                    {
                        this.dispatchEvent(new ShowToastEvent({
                            title: 'List Views Updated Successfully',
                            message: 'List views have been updated successfully. Refresh to see the changes.',
                            variant: 'success',
                            mode: 'sticky'
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
                        message: 'There was an error processing the list views. Please see an administrator',
                        variant: 'error',
                        mode: 'sticky'
                    }));
            });

            this.spinner = false;
        }

        //if we have selected ALL list views to update
        if (this.selectedObject === undefined && this.selectedListView === undefined)
        {
            console.log('Updating ALL list views');

            updateAllListViews({ })
                .then(result => {

                    //if we have an error then send an ERROR toast.
                    if (result === 'success')
                    {
                        this.dispatchEvent(new ShowToastEvent({
                            title: 'List View Processing',
                            message: 'List view processing has started and should be complete in a few minutes. Refresh to see the changes.',
                            variant: 'success',
                            mode: 'sticky'
                        }));
                        this.dispatchEvent(new CustomEvent('processlistviewclick'));

                    //else send a SUCCESS toast.
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
                        message: 'There was an error processing the list views. Please see an administrator',
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
        
        this.selectedRecordCount = 0;
        this.selectedAction = event.target.value;

        //get the selected record Ids
        let selectedRows = this.template.querySelectorAll('lightning-input');
        for(let i = 0; i < selectedRows.length; i++) {
            if(selectedRows[i].type === 'checkbox') {
                if (selectedRows[i].checked === true && selectedRows[i].value != 'all')
                {
                    selectedRecords.add(selectedRows[i].value);
                    this.selectedRecordCount++;
                }
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
            if(selectedRows[i].type === 'checkbox') {
                if (selectedRows[i].checked === true)
                {
                    selectedRows[i].checked = false;
                }
            }
        }

        this.showActionModal      = false;
        //this.selectedListView     = undefined;
        //this.listViewData         = undefined;
        //this.listViewDataColumns  = undefined;
        this.selectedAction       = '';

        refreshApex(this.listViewData);
        console.log('APEX REFRESHED');
    }

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
        // Stop text selection event so mouse move event works perfectlly.
        if(event.stopPropagation) event.stopPropagation();
        if(event.preventDefault) event.preventDefault();
        event.cancelBubble=true;
        event.returnValue=false;          
        //component.set("v.mouseStart",mouseStart);
        //component.set("v.oldWidth",parObj.offsetWidth);
    };

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
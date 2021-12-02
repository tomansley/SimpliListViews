import { LightningElement, wire, track, api  } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import createRecords from '@salesforce/apex/ListViewController.createRecords';
import getListViewDataShell from '@salesforce/apex/ListViewController.getListViewDataShell';

import Create from '@salesforce/label/c.Create';
import Cancel from '@salesforce/label/c.Cancel';
import Save_All_Data from '@salesforce/label/c.Save_All_Data';
import Reset_All_Data from '@salesforce/label/c.Reset_All_Data';

export default class SimpliUIListViewsMassCreateModal extends LightningElement {

    @api showModal;
    @api objectName;
    @api listViewName;
    @api masterObjId;
    @api masterObjField;

    @track spinner = false;
    @track listViewData;
    @track listViewDataRows;
    @track isInitialized = false;

    updatedRowData = new Map();

    //for handling column width changes
    @track mouseStart;
    @track oldWidth;
    @track parentObj;

    label = { Create, Cancel, Save_All_Data, Reset_All_Data };

    /*
     * Method which gets called after the class has been instantiated
     * but before it is rendered. We do have access to variables in this method.
     */
    async renderedCallback() {

        console.log('Starting simpliUIListViewsMassCreateModal.renderedCallback for MassCreateModal');

        this.getListViewShell();
    }

    handleClose() {
        this.listViewData = undefined;
        this.dispatchEvent(new CustomEvent('close'));
    }

    handleCancelClick(event) {
        this.listViewData = undefined;
        this.dispatchEvent(new CustomEvent('close'));
    }

    getListViewShell() {

        console.log('Starting getListViewShell - ' + this.objectName + ' - ' + this.listViewName + ' - ' + this.masterObjField + ' - ' + this.joinData + ' for MassCreateModal');
        console.log('Selected list view - ' + this.listViewName + ' for MassCreateModal');

        if (this.objectName !== undefined && this.listViewName !== undefined && this.listViewData === undefined && this.showModal)
        {
            this.spinnerOn();
            console.log('Calling getListViewDataShell!');
            getListViewDataShell({objectName: this.objectName, listViewName: this.listViewName, joinFieldName: this.masterObjField, joinData: this.joinData })
            .then(result => {

                console.log('result.coreListId - ' + result.coreListId + ' for MassCreateModal');
                
                //initialize list view info
                this.listViewData = result;

                //initialize list view row data
                this.listViewDataRows = result.rows;

                this.isInitialized = true;

                this.spinnerOff();
                
                console.log('this.listViewData            - ' + this.listViewData + ' for MassCreateModal');

            })
            .catch(error => {
                console.log('Error Detected - ' + error.message + ' | ' + error.stackTrace + ' for MassCreateModal');
                this.listViewData = undefined; 
                this.spinnerOff();
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Error Retrieving Data',
                    message: 'There was an error setting up the mass create page - ' + error.message,
                    variant: 'error',
                    mode: 'sticky'
                }));
            });
        }

    }
    
     /*
      * Method called when the CREATE button is clicked.
      */
     handleCreateClick(event) {

        let rowData = this.updatedRowData; //map of maps

        this.spinnerOn();

        if (rowData !== undefined)
        {
            let rowDataStr = '{'
              rowData.forEach((element, key) => { 
                rowDataStr = rowDataStr + '"' + key + '":' + JSON.stringify( Array.from(element)) + ',';
            });        

            rowDataStr = rowDataStr.slice(0, -1) + '}';
              
            console.log('SAVE RESULT - ' + rowDataStr + ' for MassCreateModal');

            createRecords({objType: this.objectName, rowData: rowDataStr})
            .then(result => {

                if (result.endsWith(':success'))
                {
                    console.log('Create successful for MassCreateModal');
            
                    const rowCount = result.split(':')[0];

                    this.dispatchEvent(new ShowToastEvent({
                        title: 'Success',
                        message: rowCount + ' record(s) created successfully.',
                        variant: 'success',
                        mode: 'dismissable'
                    }));

                    this.handleClose();
                    this.spinnerOff();
                } else {
                    this.dispatchEvent(new ShowToastEvent({
                        title: 'Error',
                        message: result,
                        variant: 'error',
                        mode: 'sticky'
                    }));
                    this.spinnerOff();
                    }
            })
            .catch(error => {
                console.log('Error Detected - ' + error.message + ' | ' + error.stackTrace + ' for MassCreateModal');
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Error',
                    message: 'There was an error creating the records. Please try again or see an administrator - ' + error.message,
                    variant: 'error',
                    mode: 'sticky'
                }));
                this.spinnerOff();
            });
        }

    }

    /*
     * Method called when a row is edited and a field within that row is changed.
     */
    handleFieldDataChange(event) {
        console.log('Field changed for MassCreateModal');

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

        console.log('fieldValue - ' + fieldValue + ' for MassCreateModal');
        console.log('rowId - ' + rowId + ' for MassCreateModal');
        console.log('fieldName - ' + fieldName + ' for MassCreateModal');

        let rowData = this.updatedRowData.get(rowId);

        if (rowData === undefined)
        {
            rowData = new Map();
            this.updatedRowData.set(rowId, rowData);

            if (this.masterObjField !== '')
                rowData.set(this.masterObjField, this.masterObjId);
        }

        rowData.set(fieldName, fieldValue);

    }

    spinnerOn() {
        this.spinner = true;
        console.log('Spinner ON for ' + this.pageName);
    }

    spinnerOff() {
        this.spinner = false;
        console.log('Spinner OFF for ' + this.pageName);
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
        console.log('Final tag name ' + parObj.tagName + ' for MassCreateModal');
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

}
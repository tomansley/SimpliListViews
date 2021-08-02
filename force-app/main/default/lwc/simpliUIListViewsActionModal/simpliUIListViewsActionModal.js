import { LightningElement, wire, track, api  } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

//------------------------ LABELS ------------------------
import Close from '@salesforce/label/c.Close';
import Value from '@salesforce/label/c.Value';
import Field_Name from '@salesforce/label/c.Field_Name';
import Process from '@salesforce/label/c.Process';
import Cancel from '@salesforce/label/c.Cancel';
import Continue_Processing from '@salesforce/label/c.Continue_Processing';
import Selected_Records_With from '@salesforce/label/c.Selected_Records_With';
import Action from '@salesforce/label/c.Action';

import processAction from '@salesforce/apex/ListViewController.processAction';
import getListViewAction from '@salesforce/apex/ListViewController.getListViewAction';

export default class simpliUIListViewsActionModal extends LightningElement {

    @api showModal;                     //indicates whether this modal dialog should be displayed or not.
    @api actionApiName;                 //the action that was clicked on.
    @api recordIds;                     //a concatenated string of record Ids
    @track listViewAction;              //holds the action data for the provided action API name.
    @track hasParameters = true;        //indicates whether the action has parameters
    @track requestDataMap = new Map();  //holds the map of field/value request data
    @track spinner = false;             //identifies if the spinner should be displayed or not.
    @api recordCount;                   //the number of record Ids passed in.

    label = { Close, Value, Field_Name, Process, Cancel, Continue_Processing, Selected_Records_With, Action };

    constructor() {
        super();
        this.showModal = false;
    }

    /*
     * Wiring to get the list of objects in the system using a LISTVIEW NAME
     */
    @wire (getListViewAction, { actionName: '$actionApiName'})
    wiredListViewAction({ error, data }) {
        if (data) { 
            console.log('SUCCESS DATA GET ' + data); 
            this.listViewAction = data; this.error = undefined;
            if (this.listViewAction.parameters.length === 0) {
                this.hasParameters = false;
            } else {
                this.hasParameters = true;
            }
        } else if (error) {
            console.log('error DETECTED ' + error.message); 
            this.error = error; this.listViewAction = undefined;}
    }

    handleProcessClick() {
        this.spinner = true;

        var resultStr;
        var valuesMap = new Map();
        var strValuesMap;

        //get all the externally named values into a JSON string
        for (let [k, v] of this.requestDataMap) {
            console.log('Adding key/value pair - (' + k + ',' + v + ')');
            valuesMap.set(k, v);
        }

        strValuesMap = JSON.stringify( Array.from(valuesMap) );

        console.log('Action name  - ' + this.actionApiName);
        console.log('Data         - ' + this.recordIds);
        console.log('Field/Value  - ' + strValuesMap);

        processAction({ actionKey: this.actionApiName, dataIds: this.recordIds, valuesMap: strValuesMap})
            .then(result => {
                resultStr = result;
                this.error = undefined;

                //get the status
                let status = resultStr.substring(0, resultStr.indexOf(':'));
                
                //get any associated message
                let message = resultStr.substring(resultStr.indexOf(':')+1);
                if (message === '' && status === 'Ok') {
                    message = 'All records have been processed successfully.';
                } else if (message === '' && status != 'Ok') {
                    message = 'There was an error processing the records.';
                }

                if (status === 'Ok') {
                    this.dispatchEvent(new ShowToastEvent({
                        title: this.listViewAction.label + ' Completed!',
                        message: message,
                        variant: 'success',
                        mode: 'dismissable'
                    }));
                    this.dispatchEvent(new CustomEvent('processed'));
                
                } else {
                    this.dispatchEvent(new ShowToastEvent({
                        title: 'Processing Error!',
                        message: message,
                        variant: 'error',
                        mode: 'sticky'
                    }));
                    this.spinner = false;
                    return;
                }
            })
            .catch(error => {
                resultStr = undefined;
                this.error = error;

                this.dispatchEvent(new ShowToastEvent({
                    title: 'Processing Error',
                    message: 'There was an error whilst processing\n\n' + error.body.message + '\n\n' + error.body.stackTrace,
                    variant: 'error',
                    mode: 'sticky'
                }));
                this.spinner = false;
                return;
        });

        this.spinner = false;
    }
  
    //called when a value is changed.
    handleValueUpdate(event) {
        var name = event.target.name;
        var value = event.target.value;
        this.requestDataMap.set(name, value);
        console.log('Value updated - ' + event.target.name + ' - ' + event.target.value);
    }

    handleCancelClick() {
        this.dispatchEvent(new CustomEvent('cancelled'));
    }

    handleClose() {
        this.dispatchEvent(new CustomEvent('cancelled'));
    }

}
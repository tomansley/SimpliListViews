import { LightningElement, wire, track, api  } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import processAction from '@salesforce/apex/ListViewController.processAction';
import getListViewAction from '@salesforce/apex/ListViewController.getListViewAction';

export default class simpliUIListViewsModal extends LightningElement {

    @api showModal;                     //indicates whether this modal dialog should be displayed or not.
    @api actionApiName;                 //the action that was clicked on.
    @api recordIds;                     //a concatenated string of record Ids
    @track listViewAction;              //holds the action data for the provided action API name.
    @track hasParameters = true;        //indicates whether the action has parameters
    @track requestDataMap = new Map();  //holds the map of field/value request data
    @track spinner = false;             //identifies if the spinner should be displayed or not.
    @api recordCount;                   //the number of record Ids passed in.

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
                if (resultStr === 'Ok') {
                    this.dispatchEvent(new ShowToastEvent({
                        title: this.listViewAction.label + ' Completed!',
                        message: 'All records have been processed successfully.',
                        variant: 'success',
                        mode: 'dismissable'
                    }));
                    this.dispatchEvent(new CustomEvent('processed'));
                
                } else {
                    this.dispatchEvent(new ShowToastEvent({
                        title: 'Processing Error!',
                        message: resultStr,
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
                    message: 'There was an error whilst processing - ' + error.message,
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
import {LightningElement, api, wire, track} from 'lwc';

import getListViewAction from '@salesforce/apex/ListViewController.getListViewAction';
import Close from '@salesforce/label/c.Close';

export default class SimpliUIListViewsFlowFrame extends LightningElement {

    @api showModal;                 //indicates whether this modal dialog should be displayed or not.
    @api recordIds;                 //a concatenated string of record Ids
    @api actionApiName;             //the flow that was selected.
    @track listViewAction;          //holds the action data for the provided action API name.
    @track isInitialized = false;;  //identifies if the frame has been initialized

    label = { Close };

    renderedCallback() {
        if (!this.isInitialized && this.actionApiName !== undefined)
        {
            this.isInitialized = true;
            getListViewAction({ actionName: this.actionApiName})
            .then(result => {
                console.log('getListViewAction successfully called'); 
                this.listViewAction = result;
                this.hasParameters = this.listViewAction.hasDisplayParameters;
                this.spinner = false;
            })
            .catch(error => {
                console.log('Error Detected - ' + error.message + ' | ' + error.stackTrace);
                this.spinner = false;
                return;
            });
        }
    }

    finishFlow() {
        this.dispatchEvent(new CustomEvent('finished'));
    }

    handleCancelClick() {
        this.dispatchEvent(new CustomEvent('cancelled'));
    }

    handleClose() {
        this.dispatchEvent(new CustomEvent('cancelled'));
    }
}
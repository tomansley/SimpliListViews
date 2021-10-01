import {LightningElement, api, wire, track} from 'lwc';

import getListViewAction from '@salesforce/apex/ListViewController.getListViewAction';
import Close from '@salesforce/label/c.Close';

export default class SimpliUIListViewsFlowFrame extends LightningElement {

    @api showModal;        //indicates whether this modal dialog should be displayed or not.
    @api recordIds;        //a concatenated string of record Ids
    @api actionApiName;    //the flow that was selected.
    @track listViewAction; //holds the action data for the provided action API name.

    label = { Close };

    /*
     * Wiring to get the list of objects in the system using a LISTVIEW NAME
     */
    @wire (getListViewAction, { actionName: '$actionApiName'})
    wiredListViewAction({ error, data }) {
        if (data) { 
            console.log('List view successfully retrieved - ' + data); 
            this.listViewAction = data;
        } else if (error) {
            console.log('Error Detected - ' + error.body.message + ' | ' + error.body.stackTrace);
            this.listViewAction = undefined;}
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
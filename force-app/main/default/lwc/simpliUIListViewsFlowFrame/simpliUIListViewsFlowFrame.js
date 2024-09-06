/* eslint-disable no-console */
import {LightningElement, api, track} from 'lwc';

import * as SLVHelper from 'c/simpliUIListViewsHelper';

import getListViewAction from '@salesforce/apex/ListViewController.getListViewAction';
import Close from '@salesforce/label/c.Close';

export default class SimpliUIListViewsFlowFrame extends LightningElement {

    @api showModal;                 //indicates whether this modal dialog should be displayed or not.
    @api actionApiName;             //the flow that was selected.
    @track listViewAction;          //holds the action data for the provided action API name.
    @track isInitialized = false;  //identifies if the frame has been initialized

    _recordIds;
    @api set recordIds(value) 
    { 
        //the record ids come through as a set. So we need to change it to an array
        this._recordIds = [];
        if (!SLVHelper.isEmpty(value)) {        
            value.forEach(recordId => {
                this._recordIds.push(recordId);
            });
        }

        if (this._recordIds.length > 0)
        {
            //the LWC object that is required for the lightning-flow component
            this._recordIds = [{
                name: 'recordIds',
                type: 'String',
                value: this._recordIds
            }];
        
        }
    }
    
    get recordIds() 
    { 
        return this._recordIds; 
    }


    label = { Close };

    renderedCallback() {
        if (!this.isInitialized && this.actionApiName !== undefined)
        {
            this.isInitialized = true;
            getListViewAction({ actionName: this.actionApiName})
            .then(result => {
                console.log('getListViewAction successfully called'); 
                this.listViewAction = result;
            })
            .catch(error => {
                console.log('Error Detected - ' + error.message + ' | ' + error.stackTrace);
            });
        }

    }

    handleFlowStatusChange(event) {
        if (event.detail.status === 'FINISHED') {
            this.dispatchEvent(new CustomEvent('finished'));
        }
    }

    handleCancelClick() {
        this.dispatchEvent(new CustomEvent('cancelled'));
        this.isInitialized = false;
    }

    handleClose() {
        this.dispatchEvent(new CustomEvent('cancelled'));
        this.isInitialized = false;
    }
}
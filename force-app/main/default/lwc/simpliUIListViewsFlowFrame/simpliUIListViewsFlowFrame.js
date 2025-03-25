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
    flowInputVariables = [];            //holds the input variables for the flow

    _listViewObjectAPIName;            //action parameters that have been configured and have a value.
    @api set listViewObjectAPIName(value)
    {
        this._listViewObjectAPIName = value;

        if (!SLVHelper.isEmpty(value)) {
            this.flowInputVariables.push({
                name: 'listViewObjectAPIName',
                type: 'String',
                value: this._listViewObjectAPIName
            })
        }
    }
    get listViewObjectAPIName() 
    { 
        return this._listViewObjectAPIName; 
    }

    _actionParameters;            //action parameters that have been configured and have a value.
    @api set actionParameters(value)
    {
        this._actionParameters = JSON.parse(JSON.stringify(value));

        if (!SLVHelper.isEmpty(value)) {
            this.flowInputVariables.push({
                name: 'actionParameters',
                type: 'String',
                value: this._actionParameters
            })
        }
    }
    get actionParameters() 
    { 
        return this._actionParameters; 
    }

    _listViewAPIName;             //the list view API name that is being used.
    @api set listViewAPIName(value)
    {
        this._listViewAPIName = value;

        if (!SLVHelper.isEmpty(value)) {
            this.flowInputVariables.push({
                name: 'listViewAPIName',
                type: 'String',
                value: this._listViewAPIName
            })
        }
    }
    get listViewAPIName() 
    { 
        return this._listViewAPIName; 
    }

    _recordIds;             //the record ids that are being used.
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
            this.flowInputVariables.push({
                name: 'recordIds',
                type: 'String',
                value: this._recordIds
            });
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
import { LightningElement, wire, track, api  } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import * as SLVHelper from 'c/simpliUIListViewsHelper';

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
import getListViewActionAndData from '@salesforce/apex/ListViewController.getListViewActionAndData';

export default class simpliUIListViewsActionModal extends LightningElement {

    @api showModal;                     //indicates whether this modal dialog should be displayed or not.
    @api actionApiName;                 //the action that was clicked on.
    @api recordIds;                     //the record ids of the records to be updated

    @track recordCount;                 //the number of record Ids passed in. Only used in the UI.
    @track listViewAction;              //holds the action data for the provided action API name.
    @track hasParameters = true;        //indicates whether the action has parameters
    @track requestDataMap = new Map();  //holds the map of field/value request data
    @track spinner = false;             //identifies if the spinner should be displayed or not.
    @track isInitialized = false;
    @track calloutCount = 1;            //indicates the number of callouts made for this component

    label = { Close, Value, Field_Name, Process, Cancel, Continue_Processing, Selected_Records_With, Action };

    constructor() {
        super();
        this.showModal = false;
    }

    renderedCallback() {

        if (this.showModal === true && !this.isInitialized && this.recordIds !== undefined)
        {
            var parsedIds = JSON.parse(this.recordIds);
            this.recordCount = parsedIds.length; 

            if (this.recordCount === 1)
            {
                this.spinner = true;
                console.log('simpliUIListViewsActionModal CALLOUT - getActionAndData - ' + this.calloutCount++);
                getListViewActionAndData({ actionName: this.actionApiName, dataIds: this.recordIds})
                .then(result => {
                    console.log('getListViewActionAndData successfully called'); 
                    this.listViewAction = result;
                    this.hasParameters = this.listViewAction.hasDisplayParameters;
                    this.spinner = false;
    
                    this.listViewAction.displayParameters.forEach(element => { 
                                                                                 
                                                                                 if (element.value !== null)
                                                                                 {
                                                                                     if (element.type === 'datetime' || element.type === 'date' || element.type === 'time')
                                                                                     {
                                                                                        this.requestDataMap.set(element.aPIName, element.uIValue);
                                                                                        console.log('Setting UI key/value - ' + element.aPIName + '/' + element.uIValue);
                                                                                     } else {
                                                                                        this.requestDataMap.set(element.aPIName, element.value);
                                                                                        console.log('Setting key/value - ' + element.aPIName + '/' + element.value);
                                                                                     }
                                                                                 }
                                                                             });
                })
                .catch(error => {
                    console.log('Error Detected - ' + error.message + ' | ' + error.stackTrace);
                    this.spinner = false;
                    return;
                });
                
            } else {
                this.spinner = true;
                console.log('simpliUIListViewsActionModal CALLOUT - getListViewAction - ' + this.calloutCount++);
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

            this.isInitialized = true;
    
        }

    }

    handleProcessClick() {
        this.spinner = true;

        var resultStr;
        var valuesMap = new Map();
        var strValuesMap;

        //get all the non-displayed parameters into the request data map
        this.listViewAction.nonDisplayParameters.forEach(element => { 
            this.requestDataMap.set(element.aPIName, element.value);
        });        

        //get all the externally named values into a JSON string
        for (let [k, v] of this.requestDataMap) {
            console.log('Adding key/value pair - (' + k + ',' + v + ')');
            valuesMap.set(k, v);
        }

        strValuesMap = JSON.stringify( Array.from(valuesMap) );

        console.log('Action name  - ' + this.actionApiName);
        console.log('Data         - ' + this.recordIds);
        console.log('Field/Value  - ' + strValuesMap);

        console.log('simpliUIListViewsActionModal CALLOUT - processAction - ' + this.calloutCount++);
        processAction({ actionKey: this.actionApiName, dataIds: this.recordIds, valuesMap: strValuesMap})
            .then(result => {
                resultStr = result;

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
                    this.dispatchEvent(SLVHelper.createToast('success', '', this.listViewAction.label + ' Completed!', message, false)); 
                    this.spinner = false;
                    this.recordCount = undefined;
                    this.isInitialized = false;
                    this.listViewAction = undefined;
                    this.dispatchEvent(new CustomEvent('processed'));
                
                } else {
                    this.dispatchEvent(SLVHelper.createToast('error', '', 'Processing Error', message, false)); 
                    this.spinner = false;
                    return;
                }
            })
            .catch(error => {
                resultStr = undefined;
                this.dispatchEvent(SLVHelper.createToast('error', error, 'Processing Error', 'There was an error processing the records - ', true)); 
                this.spinner = false;
                return;
        });
    }
  
    //called when a value is changed.
    handleValueUpdate(event) {

        //if data is coming in from a component
        let fieldValue = '';
        let fieldName = '';

        //if data is coming in from a component
        if (event.currentTarget.dataset.type === undefined)
        {
            fieldValue = event.detail.selectedValue;
            fieldName  = event.detail.field;
        
        } else {
            if (event.currentTarget.dataset.type === 'boolean') {
                if (event.target.checked === true) {
                    fieldValue = 'true'; //have to turn boolean into string
                } else { 
                    fieldValue = 'false'
                }
                fieldName  = event.currentTarget.dataset.field;    
            } else {
                fieldValue = event.target.value;
                fieldName  = event.currentTarget.dataset.field;
            }
        }

        this.requestDataMap.set(fieldName, fieldValue);
        console.log('Value updated - ' + fieldName + ' - ' + fieldValue);
    }

    handleCancelClick() {
        this.isInitialized = false;
        this.listViewAction = undefined;
        this.dispatchEvent(new CustomEvent('cancelled'));
    }

    handleClose() {
        this.isInitialized = false;
        this.listViewAction = undefined;
        this.dispatchEvent(new CustomEvent('cancelled'));
    }

}
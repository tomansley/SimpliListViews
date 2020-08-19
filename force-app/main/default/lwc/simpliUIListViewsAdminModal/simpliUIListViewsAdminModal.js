import { LightningElement, wire, track, api  } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';

import getListViewConfig from '@salesforce/apex/ListViewController.getListViewConfig';
import getListViewColumnLabels from '@salesforce/apex/ListViewController.getListViewColumnLabels';
import processParamChange from '@salesforce/apex/ListViewController.processParamChange';
import processConditionChange from '@salesforce/apex/ListViewController.processConditionChange';

export default class simpliUIListViewsAdminModal extends LightningElement {

    wiredListViewConfigResult;

    @api showModal;                     //indicates whether this modal dialog should be displayed or not.
    @api listViewObject;                //the object of the list view.
    @api listViewName;                  //the name of the list view.
    @api recordCount;                   //the number of record Ids passed in.
    @track listViewConfig               //holds all configuration for the list view
    @track listViewColumnLabels         //holds all column label information
    @track error                        //holds any error details.
    @track paramNameLoad;               //on entry into a param value the name is set here.
    @track paramValueLoad;              //on entry into a param value the value is set here.
    @track newConditionField;
    @track newConditionOperator;
    @track newConditionValue;
    @track newConditionOrder;
    @track newConditionColor;
    @track configChanged;

    get booleanList() {
        return [
            { label: 'Yes', value: 'true'},
            { label: 'No', value: 'false'},
        ];
    }

    get operatorList() {
        return [
            { label: 'Equals', value: 'Equals' },
            { label: 'Not Equal', value: 'Not Equal' },
            { label: 'Greater Than', value: 'Greater Than' },
            { label: 'Less Than', value: 'Less Than' },
            { label: 'Contains', value: 'Contains' },
        ];
    }

    get orderList() {
        return [
            { label: '1', value: '1' },
            { label: '2', value: '2' },
            { label: '3', value: '3' },
            { label: '4', value: '4' },
            { label: '5', value: '5' },
        ];
    }

    constructor() {
        super();
        this.showModal = false;
    }

    /*
     * Method which gets called after the class has been instantiated
     * but before it is rendered. We do have access to variables in this method.
     */
    renderedCallback() {

        this.newConditionField;
        this.newConditionOperator = 'Equals';
        this.newConditionValue;
        this.newConditionOrder = '1';
        this.newConditionColor = '#000000';

        if (this.listViewConfig === undefined) {
            this.configChanged = false;
        }
    }

    /*
     * Wiring to get the list of config parameters for the chosen object and list view
     */
    @wire (getListViewConfig, { objectType: '$listViewObject', listViewName: '$listViewName' })
    wiredListViewConfig(wiredListViewConfigResult) {
        this.wiredListViewConfigResult = wiredListViewConfigResult;
        const { data, error } = wiredListViewConfigResult;

        if (data) { 
            console.log('List view config retrieval successful'); 
            this.listViewConfig = data; 
            this.error = undefined; 
        } else if (error) { 
            this.error = error; 
            console.log('Error Detected ' + error.message); 
            this.listViewConfig = undefined;
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error Retrieving List View Config',
                message: 'There was an error retrieving the list view configuration. Please see an administrator - ' + error.message,
                variant: 'error',
                mode: 'sticky'
            }));
        }
    }

    /*
     * Wiring to get the list of objects in the system
     */
    @wire (getListViewColumnLabels, { objectName: '$listViewObject', listViewName: '$listViewName' })
    wiredListViewColumnLabels({ error, data }) {
        if (data) { 
            console.log('List view column label retrieval successful'); 
            this.listViewColumnLabels = data; 
            this.error = undefined;
        } else if (error) { 
            this.error = error; 
            console.log('Error Detected ' + error.body.message + ' - ' + error.body.stackTrace); 
            this.listViewColumnLabels = undefined; 
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error Retrieving List View Column Labels',
                message: 'There was an error retrieving the list view column labels. Please see an administrator\n\n' + error.message + '\n\n' + error.stackTrace,
                variant: 'error',
                mode: 'sticky'
            }));
        }
    }

    handleParamLoad(event)
    {
        this.paramNameLoad = event.target.name;

        this.paramValueLoad = event.target.value;

        console.log('Param loaded - ' + this.paramNameLoad + ' - ' + this.paramValueLoad);

    }

    //called when a value is changed.
    handleParamUpdate(event) {

        var name = event.target.name;
        var value = event.target.value;

        console.log('Inside handleParamChange - ' + name + '/' + value);

        //if we are leaving the param with no value change then do nothing.
        if (value === this.paramValueLoad) {
            this.paramValueLoad = undefined;
            this.paramNameLoad = undefined;
            return;
        }

        this.configChanged = true;
        console.log('Param being processed');

        processParamChange({ objectName: this.listViewObject, listViewName: this.listViewName, paramName: name, paramValue: value})
            .then(result => {
                var resultStr = result;
                this.error = undefined;

                //get the status
                let status = resultStr.substring(0, resultStr.indexOf(':'));
                
                //get any associated message
                let message = resultStr.substring(resultStr.indexOf(':')+1);
                if (message === '' && status != 'Ok') {
                    message = 'There was an error processing the records.';
                }

                if (status === 'Ok') {
                    this.dispatchEvent(new ShowToastEvent({
                        title: 'Parameter Updated Successfully!',
                        message: message,
                        variant: 'success',
                        mode: 'dismissable'
                    }));
                
                } else {
                    this.dispatchEvent(new ShowToastEvent({
                        title: 'Processing Error!',
                        message: message,
                        variant: 'error',
                        mode: 'sticky'
                    }));
                    return;
                }
            })
            .catch(error => {
                var resultStr = undefined;
                this.error = error;

                if (error.message != undefined) {
                    this.dispatchEvent(new ShowToastEvent({
                        title: 'Processing Error',
                        message: 'There was an error whilst processing - ' + error.message,
                        variant: 'error',
                        mode: 'sticky'
                    }));
                }
                return;
            });

        this.paramValueLoad = undefined;
        this.paramNameLoad = undefined;
    }

    handleConditionChange(event) {
        var id = event.target.name;
        var action = event.target.value;
        console.log('Id - ' + id);
        console.log('Action - ' + action);

        var resultStr;
        var valuesMap = new Map();
        var strParamsMap;

        //if we are REMOVING we just need to pass the id of the condition
        if (action === 'remove') {

            strParamsMap = id;

        //if we are ADDING we need to pass all condition information
        } else if (action === 'add') {

            var errorMsg = '';

            if (this.newConditionField === undefined || this.newConditionField === '') { errorMsg = 'The condition field must be provided.'}
            else if (this.newConditionValue === undefined || this.newConditionValue === '') { errorMsg = 'The condition value must be provided.'}
            
            //if we have an error
            if (errorMsg != '')
            {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Condition Error',
                    message: errorMsg,
                    variant: 'error',
                    mode: 'sticky'
                }));
                return;
            } 

            valuesMap.set('field', this.newConditionField);
            valuesMap.set('operator', this.newConditionOperator);
            valuesMap.set('value', this.newConditionValue);
            valuesMap.set('order', this.newConditionOrder);
            valuesMap.set('color', this.newConditionColor);

            strParamsMap = JSON.stringify( Array.from(valuesMap) );
            console.log('Params Field/Value  - ' + strParamsMap);

        }

        processConditionChange({ objectName: this.listViewObject, listViewName: this.listViewName, action: action, conditionData: strParamsMap})
            .then(result => {
                resultStr = result;
                this.error = undefined;

                //get the status
                let status = resultStr.substring(0, resultStr.indexOf(':'));
                
                //get any associated message
                let message = resultStr.substring(resultStr.indexOf(':')+1);
                if (message === '' && status === 'Ok') {
                    message = 'All conditions processed.';
                } else if (message === '' && status != 'Ok') {
                    message = 'There was an error processing the condition.';
                }

                if (status === 'Ok') {
                    this.dispatchEvent(new ShowToastEvent({
                        title: 'Condition Updated Successfully!',
                        message: message,
                        variant: 'success',
                        mode: 'dismissable'
                    }));
                
                    refreshApex(this.wiredListViewConfigResult);

                } else {
                    this.dispatchEvent(new ShowToastEvent({
                        title: 'Processing Error!',
                        message: message,
                        variant: 'error',
                        mode: 'sticky'
                    }));
                    return;
                }
            })
            .catch(error => {
                resultStr = undefined;
                this.error = error;

                this.dispatchEvent(new ShowToastEvent({
                    title: 'Processing Error',
                    message: 'There was an error whilst processing\n\n' + error.message + '\n\n' + error.stackTrace,
                    variant: 'error',
                    mode: 'sticky'
                }));
                return;
        });

        this.configChanged = true;

    }

    handleClose() {
        //refresh the entire page
        if (this.configChanged)
            window.location.replace(window.location.href);
        else
            this.dispatchEvent(new CustomEvent('close'));
    }

    handleCloseClick(event) {

        //refresh the entire page
        if (this.configChanged)
            window.location.replace(window.location.href);
        else
            this.dispatchEvent(new CustomEvent('close'));
    }

    handleConditionFieldChange(event) {
        this.newConditionField = event.target.value;
        console.log('New Condition Field Change - ' + this.newConditionField);
    }

    handleConditionOperatorChange(event) {
        this.newConditionOperator = event.target.value;
        console.log('New Condition Operator Change - ' + this.newConditionOperator);
    }

    handleConditionValueChange(event) {
        this.newConditionValue = event.target.value;
        console.log('New Condition Value Change - ' + this.newConditionValue);
    }

    handleConditionOrderChange(event) {
        this.newConditionOrder = event.target.value;
        console.log('New Condition Order Change - ' + this.newConditionOrder);
    }

    handleConditionColorChange(event) {
        this.newConditionColor = event.target.value;
        console.log('New Condition Color Change - ' + this.newConditionColor);
    }


}
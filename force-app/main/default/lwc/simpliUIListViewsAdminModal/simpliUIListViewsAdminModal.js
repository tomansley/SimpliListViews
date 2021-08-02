import { LightningElement, wire, track, api  } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';

//------------------------ LABELS ------------------------
import Close from '@salesforce/label/c.Close';
import List_View_Config from '@salesforce/label/c.List_View_Config';
import Settings from '@salesforce/label/c.Settings';
import Parameter_Name from '@salesforce/label/c.Parameter_Name';
import Value from '@salesforce/label/c.Value';
import Select_A_Value from '@salesforce/label/c.Select_A_Value';
import Highlighting from '@salesforce/label/c.Highlighting';
import Add_Remove from '@salesforce/label/c.Add_Remove';
import Field from '@salesforce/label/c.Field';
import Operator from '@salesforce/label/c.Operator';
import Precedence from '@salesforce/label/c.Precedence';
import Color from '@salesforce/label/c.Color';
import Field_Name from '@salesforce/label/c.Field_Name';
import Remove_Condition from '@salesforce/label/c.Remove_Condition';
import Select_A_Column from '@salesforce/label/c.Select_A_Column';
import Enter_A_Value from '@salesforce/label/c.Enter_A_Value';
import Add_Condition from '@salesforce/label/c.Add_Condition';

import getListViewConfig from '@salesforce/apex/ListViewController.getListViewConfig';
import getCachedListViewConfig from '@salesforce/apex/ListViewController.getCachedListViewConfig';
import getListViewColumnLabels from '@salesforce/apex/ListViewController.getListViewColumnLabels';
import processParamChange from '@salesforce/apex/ListViewController.processParamChange';
import processConditionChange from '@salesforce/apex/ListViewController.processConditionChange';

export default class simpliUIListViewsAdminModal extends NavigationMixin(LightningElement) {

    currentPageReference;

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
    @track configChanged;               //identifies if a change has been made which needs to force a data refresh

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

    label = { Close, List_View_Config, Settings, Parameter_Name, Value, Select_A_Value, Highlighting, Add_Remove, Field,
              Operator, Precedence, Color, Field_Name, Remove_Condition, Select_A_Column, Enter_A_Value, Add_Condition }

    constructor() {
        super();
        this.showModal = false;
    }

    /*
     * Method which gets called after the class has been instantiated
     * but before it is rendered. We do have access to variables in this method.
     */
    renderedCallback() {

        console.log('Starting simpliUIListViewsAdminModal.renderedCallback');
    
        this.newConditionField;
        this.newConditionOperator = 'Equals';
        this.newConditionValue;
        this.newConditionOrder = '1';
        this.newConditionColor = '#000000';

        if (this.listViewConfig === undefined) {
            this.configChanged = false;
        }
    }

    @wire(CurrentPageReference)
    setCurrentPageReference(currentPageReference) {
        this.currentPageReference = currentPageReference;
        if(this.currentPageReference) {
            window.console.log('Current Page Reference...'+JSON.stringify(this.currentPageReference));
        }

        let testparam=this.currentPageReference.attributes.apiName;
        console.log('OBJ Name - ' + testparam);
    }

    getListViewConfig() {
        console.log('Starting getListViewConfig - ' + this.listViewObject + ' - ' + this.listViewName);

        getListViewConfig({objectName: this.listViewObject, listViewName: this.listViewName})
        .then(result => {
            console.log('List view config retrieval successful'); 
            this.listViewConfig = result; 
            this.error = undefined;             
        })
        .catch(error => {
            this.error = error; 
            console.log('Error Detected ' + error.body.message); 
            this.listViewConfig = undefined;
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error Retrieving List View Config',
                message: 'There was an error retrieving the list view configuration. Please see an administrator - ' + error.body.message,
                variant: 'error',
                mode: 'sticky'
            }));
        });


    }
    /*
     * Wiring to get the list of config parameters for the chosen object and list view. Note that this wired
     * method only gets called on INITIALIZATION of the modal dialog. After that the data is updated by calling
     * the getListViewConfig() method. This is because we do not want the cached results but the updated results.
     */
    @wire (getCachedListViewConfig, { objectName: '$listViewObject', listViewName: '$listViewName' })
    wiredListViewConfig(wiredListViewConfigResult) {
        this.wiredListViewConfigResult = wiredListViewConfigResult;
        const { data, error } = wiredListViewConfigResult;

        if (data) { 
            console.log('Cached list view config retrieval successful'); 
            this.listViewConfig = data; 
            this.error = undefined; 
        } else if (error) { 
            this.error = error; 
            console.log('Error Detected ' + error.body.message); 
            this.listViewConfig = undefined;
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error Retrieving List View Config',
                message: 'There was an error retrieving the list view configuration. Please see an administrator - ' + error.body.message,
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
                message: 'There was an error retrieving the list view column labels. Please see an administrator\n\n' + error.body.message + '\n\n' + error.body.stackTrace,
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

        this.handleParamIsUpdated(event);
    }

    handleParamIsUpdated(event) {
        this.configChanged = true;
    }

    //called when a value is changed.
    handleParamUpdate(event) {

        var name = event.target.name;
        var value = event.target.value;
        var type = event.target.type;
        var label = event.target.label;

        if (type === undefined) {
            type = 'Boolean';
        }
        
        console.log('Inside handleParamChange - ' + name + '/' + value);

        //if we are leaving the param with no value change then do nothing.
        if (value === this.paramValueLoad) {
            this.paramValueLoad = undefined;
            this.paramNameLoad = undefined;
            return;
        }

        console.log('Param being processed');

        processParamChange({ objectName: this.listViewObject, listViewName: this.listViewName, paramName: name, paramValue: value, paramLabel: label, paramType: type})
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
                    this.configChanged = true;
                    this.getListViewConfig(); //reget the config
                
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
                    this.getListViewConfig();
                    this.configChanged = true;
                
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
        setTimeout(function(){
            console.log('after');
        },500); //give the parameter time to be saved before sending message to parent
        this.dispatchEvent(new CustomEvent('close', { detail: this.configChanged }));
        this.configChanged = false;
    }

    handleCloseClick(event) {
        setTimeout(function(){
            console.log('after');
        },500); //give the parameter time to be saved before sending message to parent
        this.dispatchEvent(new CustomEvent('close', { detail: this.configChanged }));
        this.configChanged = false;
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
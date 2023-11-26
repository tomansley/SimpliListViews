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
import Update from '@salesforce/label/c.Update';

import getListViewConfig from '@salesforce/apex/ListViewController.getListViewConfig';
import getListViewColumns from '@salesforce/apex/ListViewController.getListViewColumns';
import processParamChange from '@salesforce/apex/ListViewController.processParamChange';
import processConditionChange from '@salesforce/apex/ListViewController.processConditionChange';

export default class simpliUIListViewsAdminModal extends NavigationMixin(LightningElement) {

    currentPageReference;

    @api showModal;                     //indicates whether this modal dialog should be displayed or not.
    @api listViewObject;                //the object of the list view.
    //have to use get/set methods as we are not using the wired approach
    @api get listViewName() { return this.lvName; }                  
         set listViewName(value) { this.lvName = value; this.getListViewConfig(); }
    @api listViewMode;                  //indicates the mode of the list view calling the admin page.

    @track spinner = false;             //identifies if the spinner should be displayed or not.
    @track listViewConfig               //holds all configuration for the list view
    @track listViewColumns              //holds all column label information
    @track error                        //holds any error details.
    @track paramNameLoad;               //on entry into a param value the name is set here.
    @track paramValueLoad;              //on entry into a param value the value is set here.
    @track firstConditionField;         //the first condition in the fields list
    @track newConditionField;
    @track newConditionColumn;          //the complex column object set when field is selected
    @track newConditionOperator;
    @track newConditionValue;
    @track newConditionOrder = '1';
    @track newConditionColor;
    @track configChanged;               //identifies if a change has been made which needs to force a data refresh
    @track lvName;                      //the name of the list view.
    @track closeDisabled = undefined;

    get booleanList() {
        return [
            { label: 'Yes', value: 'true'},
            { label: 'No', value: 'false'},
        ];
    }

    get dateList() {
        return [
            { label: 'Today', value: 'Today' },
            { label: 'Tomorrow', value: 'Tomorrow' },
            { label: 'Yesterday', value: 'Yesterday' }
        ];
    }

    get operatorList() {
        if (this.newConditionColumn === undefined) {
            return [ ];
        } else if (this.newConditionColumn.type === 'boolean') {
            return [
                { label: 'Equals', value: 'Equals' },
                { label: 'Not Equal', value: 'Not Equal' },
            ];
        } else if (this.newConditionColumn.type === 'date' 
                    || this.newConditionColumn.type === 'datetime') {
            return [
                { label: 'Equals', value: 'Equals' },
                { label: 'Not Equal', value: 'Not Equal' },
                { label: 'Greater Than', value: 'Greater Than' },
                { label: 'Less Than', value: 'Less Than' },
            ];
        } else {
            return [
                { label: 'Equals', value: 'Equals' },
                { label: 'Not Equal', value: 'Not Equal' },
                { label: 'Greater Than', value: 'Greater Than' },
                { label: 'Less Than', value: 'Less Than' },
                { label: 'Contains', value: 'Contains' },
            ];
        }
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
              Operator, Precedence, Color, Field_Name, Remove_Condition, Select_A_Column, Enter_A_Value, Add_Condition,
              Update
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

        console.log('Starting simpliUIListViewsAdminModal.renderedCallback');
    
        if (this.listViewConfig === undefined) {
            this.configChanged = false;
            getListViewConfig();
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
        console.log('Starting getListViewConfig - ' + this.listViewObject + ' - ' + this.listViewName + ' - ' + this.listViewMode);

        if (this.listViewObject !== undefined && this.listViewObject !== null 
                && this.listViewName !== undefined && this.listViewName !== null 
                && this.listViewMode !== undefined && this.listViewMode !== null)
        {
            console.log('Getting ListViewConfigs - ' + this.listViewObject + ' - ' + this.listViewName + ' - ' + this.listViewMode);
            getListViewConfig({objectName: this.listViewObject, listViewName: this.listViewName, listViewMode: this.listViewMode })
            .then(result => {
                console.log('List view config retrieval successful'); 
                console.log('List View Config - ' + JSON.stringify(result));
                this.listViewConfig = result;    
            })
            .catch(error => {
                console.log('Error Detected - ' + error.body.message + ' | ' + error.body.stackTrace);
                this.listViewConfig = undefined;
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Error Retrieving List View Config',
                    message: 'There was an error retrieving the list view configuration - ' + error.body.message,
                    variant: 'error',
                    mode: 'sticky'
                }));
            });
        }

    }

    /*
     * Wiring to get the list of objects in the system
     */
    @wire (getListViewColumns, { objectName: '$listViewObject', listViewName: '$listViewName' })
    wiredListViewColumns({ error, data }) {
        if (data) { 
            console.log('List view column label retrieval successful'); 
            this.listViewColumns = data;
            this.resetNewCondition();
        } else if (error) { 
            console.log('Error Detected - ' + error.body.message + ' | ' + error.body.stackTrace);
            this.listViewColumns = undefined; 
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error Retrieving List View Column Labels',
                message: 'There was an error retrieving the list view column labels - ' + error.body.message + '\n\n' + error.body.stackTrace,
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

        this.closeDisabled = true;
        this.configChanged = true;
    }

    //called when a value is changed.
    handleParamUpdate(event) {

        this.closeDisabled = true;
        
        var name = event.target.name;
        var value = event.target.value;
        var type = event.target.dataset.type;
        var label = event.target.label;

        if (type === undefined) {
            type = 'Boolean';
        }
        
        console.log('Inside handleParamChange - ' + name + '/' + value);

        console.log('Starting value - ' + this.paramValueLoad);

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
                console.log('Error Detected - ' + error.body.message + ' | ' + error.body.stackTrace);
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Processing Error',
                    message: 'There was an error processing the param changes - ' + error.body.message,
                    variant: 'error',
                    mode: 'sticky'
                }));
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
        this.spinner = true;

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
                this.spinner = false;
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
                    this.resetNewCondition();
                    this.spinner = false;

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
                console.log('Error Detected - ' + error.body.message + ' | ' + error.body.stackTrace);

                this.dispatchEvent(new ShowToastEvent({
                    title: 'Processing Error',
                    message: 'There was an error processing the condition changes - ' + error.body.message,
                    variant: 'error',
                    mode: 'sticky'
                }));
                this.spinner = false;
                return;
        });

        this.configChanged = true;

    }

    resetNewCondition() {
        if (this.listViewColumns !== undefined && this.listViewColumns.length > 0)
        {
            this.firstConditionField = this.listViewColumns[0].value;
            this.newConditionColumn = this.listViewColumns[0];
            this.newConditionField = this.listViewColumns[0].value;
        }
        this.newConditionValue = undefined;
        this.newConditionColor = '#DBFFB4';
        this.newConditionOperator = 'Equals';
        this.newConditionOrder = '1';
    }

    handleClose() {
        setTimeout(function(){
            console.log('after');
        },500); //give the parameter time to be saved before sending message to parent
        this.dispatchEvent(new CustomEvent('close', { detail: this.configChanged }));
        this.configChanged = false;
        this.resetNewCondition();
    }

    handleUpdateClick(event) {
       setTimeout(function(){
            console.log('after');
        },500); //give the parameter time to be saved before sending message to parent
        this.closeDisabled = undefined;
        this.dispatchEvent(new ShowToastEvent({
            title: 'Config Updated',
            message: 'Config updated successfully!',
            variant: 'success',
            mode: 'dismissable'
        }));
}

    handleCloseClick(event) {
        setTimeout(function(){
            console.log('after');
        },500); //give the parameter time to be saved before sending message to parent
        this.dispatchEvent(new CustomEvent('close', { detail: this.configChanged }));
        this.configChanged = false;
        this.resetNewCondition();
    }

    handleConditionFieldChange(event) {
        this.newConditionField = event.target.value;
        console.log('New Condition Field Change - ' + this.newConditionField);

        //go find type for new field and set
        this.listViewColumns.forEach(element => {
                                                    if (element.value === this.newConditionField)
                                                    {
                                                        this.newConditionColumn = element;
                                                    }
                                                });
        this.newConditionValue = undefined;
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
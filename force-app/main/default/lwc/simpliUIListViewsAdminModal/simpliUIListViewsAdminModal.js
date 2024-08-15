/* eslint-disable @lwc/lwc/no-async-operation */
/* eslint-disable no-useless-return */
/* eslint-disable no-console */
/* eslint-disable no-else-return */
import { LightningElement, wire, track, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import * as SLVHelper from 'c/simpliUIListViewsHelper';

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
import Column_Styles from '@salesforce/label/c.Column_Styles';
import Font from '@salesforce/label/c.Font';
import Decoration from '@salesforce/label/c.Decoration';
import Style from '@salesforce/label/c.Style';
import constiant from '@salesforce/label/c.constiant';
import Transform from '@salesforce/label/c.Transform';
import Weight from '@salesforce/label/c.Weight';
import Alignment from '@salesforce/label/c.Alignment';

import getListViewConfig from '@salesforce/apex/ListViewController.getListViewConfig';
import getListViewColumns from '@salesforce/apex/ListViewController.getListViewColumns';
import processParamChange from '@salesforce/apex/ListViewController.processParamChange';
import processConditionChange from '@salesforce/apex/ListViewController.processConditionChange';
import processColumnStyleChange from '@salesforce/apex/ListViewController.processColumnStyleChange';

export default class simpliUIListViewsAdminModal extends NavigationMixin(LightningElement) {

    currentPageReference;

    @api showModal;                     //indicates whether this modal dialog should be displayed or not.
    @api listViewObject;                //the object of the list view.
    //have to use get/set methods as we are not using the wired approach
    @api get listViewName() { return this.lvName; }
    set listViewName(value) { this.lvName = value; this.getListViewConfig(); }
    @api listViewMode;                  //indicates the mode of the list view calling the admin page.

    @track spinner = false;             //identifies if the spinner should be displayed or not.
    @track listViewConfig;               //holds all configuration for the list view
    @track listViewColumns;              //holds all column label information
    @track styleListViewColumns;         //holds all column label information
    @track error;                        //holds any error details.
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

    @track firstColumnStyleField;         //the first condition in the fields list
    @track newColumnStyleField;
    @track newColumnStyleColumn;          //the complex column object set when field is selected
    @track newColumnStyleFont;
    @track newColumnStyleDecoration;
    @track newColumnStyleStyle;
    @track newColumnStyleTransform;
    @track newColumnStyleconstiant;
    @track newColumnStyleWeight;
    @track newColumnStyleAlignment;

    get fontStyleList() {
        return [
            { label: 'Arial', value: 'Arial' },
            { label: 'Arial Black', value: 'Arial Black' },
            { label: 'Comic Sans', value: 'Comic Sans' },
            { label: 'Courier', value: 'Courier' },
            { label: 'Georgia', value: 'Georgia' },
            { label: 'Impact', value: 'Impact' },
            { label: 'Lucida Console', value: 'Lucida Console' },
            { label: 'Lucida Sans', value: 'Lucida Sans' },
            { label: 'Palatino', value: 'Palatino' },
            { label: 'Tahoma', value: 'Tahoma' },
            { label: 'Trebuchet', value: 'Trebuchet' },
            { label: 'Times New Roman', value: 'Times New Roman' },
            { label: 'Verdana', value: 'Verdana' },
        ];
    }

    get decorationStyleList() {
        return [
            { label: 'None', value: 'none' },
            { label: 'Underline', value: 'underline' },
            { label: 'Overline', value: 'overline' },
            { label: 'Line Thru', value: 'line-through' },
        ];
    }

    get styleStyleList() {
        return [
            { label: 'Normal', value: 'normal' },
            { label: 'Unset', value: 'unset' },
            { label: 'Italic', value: 'italic' },
            { label: 'Oblique', value: 'oblique' },
        ];
    }

    get transformStyleList() {
        return [
            { label: 'None', value: 'none' },
            { label: 'Uppercase', value: 'uppercase' },
            { label: 'Lowercase', value: 'lowercase' },
            { label: 'Capitalize', value: 'capitalize' },
        ];
    }

    get constiantStyleList() {
        return [
            { label: 'Normal', value: 'normal' },
            { label: 'Small Caps', value: 'small-caps' },
        ];
    }

    get weightStyleList() {
        return [
            { label: 'Normal', value: 'normal' },
            { label: 'Bold', value: 'bold' },
        ];
    }

    get alignmentList() {
        return [
            { label: 'Left', value: 'left' },
            { label: 'Right', value: 'right' },
            { label: 'Center', value: 'center' },
            { label: 'Justify', value: 'justify' },
        ];
    }

    get booleanList() {
        return [
            { label: 'Yes', value: 'true' },
            { label: 'No', value: 'false' },
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
            return [];
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

    label = {
        Close, List_View_Config, Settings, Parameter_Name, Value, Select_A_Value, Highlighting, Add_Remove, Field,
        Operator, Precedence, Color, Field_Name, Remove_Condition, Select_A_Column, Enter_A_Value, Add_Condition,
        Update, Column_Styles, Font, Decoration, Style, constiant, Transform, Weight, Alignment
    }

    constructor() {
        super();
        this.showModal = false;
    }

    /*
     * Method which gets called after the class has been instantiated
     * but before it is rendered. We do have access to constiables in this method.
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
        if (this.currentPageReference) {
            window.console.log('Current Page Reference...' + JSON.stringify(this.currentPageReference));
        }

        let testparam = this.currentPageReference.attributes.apiName;
        console.log('OBJ Name - ' + testparam);
    }

    getListViewConfig() {
        console.log('Starting getListViewConfig - ' + this.listViewObject + ' - ' + this.listViewName + ' - ' + this.listViewMode);

        if (this.listViewObject !== undefined && this.listViewObject !== null
            && this.listViewName !== undefined && this.listViewName !== null
            && this.listViewMode !== undefined && this.listViewMode !== null) {
            console.log('Getting ListViewConfigs - ' + this.listViewObject + ' - ' + this.listViewName + ' - ' + this.listViewMode);
            getListViewConfig({ objectName: this.listViewObject, listViewName: this.listViewName, listViewMode: this.listViewMode })
                .then(result => {
                    console.log('List view config retrieval successful');
                    console.log('List View Config - ' + JSON.stringify(result));
                    this.listViewConfig = result;
                    this.setStyleColumns();
                })
                .catch(error => {
                    console.log('Error Detected - ' + JSON.stringify(error));
                    this.listViewConfig = undefined;
                    this.dispatchEvent(new ShowToastEvent({
                        title: 'Error Retrieving List View Config',
                        message: 'There was an error retrieving the list view configuration - ' + error.body.message,
                        constiant: 'error',
                        mode: 'sticky'
                    }));
                });
        }

    }

    setStyleColumns() {
        this.styleListViewColumns = [];
        if (this.listViewColumns !== undefined && this.listViewConfig !== undefined) {
            this.listViewColumns.forEach(column => {
                let exists = false;
                this.listViewConfig.columnStyles.forEach(style => {

                    console.log('Column - ' + column.value + ' | Style - ' + style.fieldName);
                    if (column.value === style.fieldName) {
                        exists = true;
                    }
                });
                if (exists === false) {
                    this.styleListViewColumns.push(column);
                }
            });
        }

    }
    /*
     * Wiring to get the list of objects in the system
     */
    @wire(getListViewColumns, { objectName: '$listViewObject', listViewName: '$listViewName' })
    wiredListViewColumns({ error, data }) {
        if (data) {
            console.log('List view column label retrieval successful');
            this.listViewColumns = data;
            this.setStyleColumns();
            this.resetNewCondition();
            this.resetNewColumnStyle();
        } else if (error) {
            console.log('Error Detected - ' + error.body.message + ' | ' + error.body.stackTrace);
            this.listViewColumns = undefined;
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error Retrieving List View Column Labels',
                message: 'There was an error retrieving the list view column labels - ' + error.body.message + '\n\n' + error.body.stackTrace,
                constiant: 'error',
                mode: 'sticky'
            }));
        }
    }

    handleParamLoad(event) {
        try {
            const { target } = event;
            this.paramNameLoad = target?.name ?? '';

            this.paramValueLoad = target?.value ?? '';

            console.log('Param loaded - ' + this.paramNameLoad + ' - ' + this.paramValueLoad);

            this.closeDisabled = true;
            this.configChanged = true;
        } catch (error) {
            SLVHelper.showErrorMessage(error);
        }
    }

    //called when a value is changed.
    handleParamUpdate(event) {
        try {
            const { target } = event;
            const name = target?.name ?? '';
            const value = target?.value ?? '';
            let type = target?.dataset?.type ?? '';
            const label = target?.label ?? '';

            this.closeDisabled = true;

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

            processParamChange({ objectName: this.listViewObject, listViewName: this.listViewName, paramName: name, paramValue: value, paramLabel: label, paramType: type })
                .then(result => {
                    const resultStr = result;

                    //get the status
                    let status = resultStr.substring(0, resultStr.indexOf(':'));

                    //get any associated message
                    let message = resultStr.substring(resultStr.indexOf(':') + 1);
                    if (message === '' && status !== 'Ok') {
                        message = 'There was an error processing the records.';
                    }

                    if (status === 'Ok') {
                        this.dispatchEvent(new ShowToastEvent({
                            title: 'Parameter Updated Successfully!',
                            message: message,
                            constiant: 'success',
                            mode: 'dismissable'
                        }));
                        this.configChanged = true;
                        this.getListViewConfig(); //reget the config

                    } else {
                        this.dispatchEvent(new ShowToastEvent({
                            title: 'Processing Error!',
                            message: message,
                            constiant: 'error',
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
                        constiant: 'error',
                        mode: 'sticky'
                    }));
                    return;
                });

            this.paramValueLoad = undefined;
            this.paramNameLoad = undefined;
        } catch (error) {
            SLVHelper.showErrorMessage(error);
        }
    }

    //---------------------------------------------------------------------------------------------------------
    // CONDITION METHODS
    //---------------------------------------------------------------------------------------------------------
    handleConditionChange(event) {
        this.spinner = true;
        try {
            const { target } = event;
            const id = target?.name ?? '';
            const action = target?.value ?? '';
            let resultStr;
            const valuesMap = new Map();
            let strParamsMap;
            let errorMsg = '';

            console.log('Id - ' + id);
            console.log('Action - ' + action);


            //if we are REMOVING we just need to pass the id of the condition
            if (action === 'remove') {

                strParamsMap = id;

                //if we are ADDING we need to pass all condition information
            } else if (action === 'add') {

                if (this.newConditionField === undefined || this.newConditionField === '') { errorMsg = 'The condition field must be provided.' }
                else if (this.newConditionValue === undefined || this.newConditionValue === '') { errorMsg = 'The condition value must be provided.' }

                //if we have an error
                if (errorMsg !== '') {
                    this.dispatchEvent(new ShowToastEvent({
                        title: 'Condition Error',
                        message: errorMsg,
                        constiant: 'error',
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

                strParamsMap = JSON.stringify(Array.from(valuesMap));
                console.log('Params Field/Value  - ' + strParamsMap);

            }

            processConditionChange({ objectName: this.listViewObject, listViewName: this.listViewName, action: action, conditionData: strParamsMap })
                .then(result => {
                    resultStr = result;

                    //get the status
                    let status = resultStr.substring(0, resultStr.indexOf(':'));

                    //get any associated message
                    let message = resultStr.substring(resultStr.indexOf(':') + 1);
                    if (message === '' && status === 'Ok') {
                        message = 'All conditions processed.';
                    } else if (message === '' && status !== 'Ok') {
                        message = 'There was an error processing the condition.';
                    }

                    if (status === 'Ok') {
                        this.dispatchEvent(new ShowToastEvent({
                            title: 'Condition Updated Successfully!',
                            message: message,
                            constiant: 'success',
                            mode: 'dismissable'
                        }));
                        this.getListViewConfig();
                        this.configChanged = true;
                        this.resetNewCondition();

                    } else {
                        this.dispatchEvent(new ShowToastEvent({
                            title: 'Processing Error!',
                            message: message,
                            constiant: 'error',
                            mode: 'sticky'
                        }));
                        return;
                    }
                })
                .catch(error => {
                    resultStr = undefined;
                    console.log('Error Detected - ' + error.body.message + ' | ' + error.body.stackTrace);

                    this.dispatchEvent(new ShowToastEvent({
                        title: 'Processing Error',
                        message: 'There was an error processing the condition changes - ' + error.body.message,
                        constiant: 'error',
                        mode: 'sticky'
                    }));
                    return;
                });

            this.configChanged = true;
        } catch (error) {
            SLVHelper.showErrorMessage(error);
        } finally {
            this.spinner = false;
        }
    }

    resetNewCondition() {
        if (this.listViewColumns !== undefined && this.listViewColumns.length > 0) {
            this.firstConditionField = this.listViewColumns[0].value;
            this.newConditionColumn = this.listViewColumns[0];
            this.newConditionField = this.listViewColumns[0].value;
        }
        this.newConditionValue = undefined;
        this.newConditionColor = '#DBFFB4';
        this.newConditionOperator = 'Equals';
        this.newConditionOrder = '1';
    }

    handleConditionFieldChange(event) {
        try {
            const { target } = event;
            this.newConditionField = target?.value ?? '';
            console.log('New Condition Field Change - ' + this.newConditionField);

            //go find type for new field and set
            if (this.listViewColumns?.length) {
                this.listViewColumns.forEach(element => {
                    if (element.value === this.newConditionField) {
                        this.newConditionColumn = element;
                    }
                });
            }

            this.newConditionValue = undefined;
        } catch (error) {
            SLVHelper.showErrorMessage(error);
        }
    }

    handleConditionOperatorChange(event) {
        try {
            const { target } = event;
            this.newConditionOperator = target?.value ?? '';
            console.log('New Condition Operator Change - ' + this.newConditionOperator);
        } catch (error) {
            SLVHelper.showErrorMessage(error);
        }
    }

    handleConditionValueChange(event) {
        try {
            const { target } = event;
            this.newConditionValue = target?.value ?? '';
            console.log('New Condition Value Change - ' + this.newConditionValue);
        } catch (error) {
            SLVHelper.showErrorMessage(error);
        }
    }

    handleConditionOrderChange(event) {
        try {
            const { target } = event;
            this.newConditionOrder = target.value ?? '';
            console.log('New Condition Order Change - ' + this.newConditionOrder);
        } catch (error) {
            SLVHelper.showErrorMessage(error);
        }
    }

    handleConditionColorChange(event) {
        try {
            const { target } = event;
            this.newConditionColor = target?.value ?? '';
            console.log('New Condition Color Change - ' + this.newConditionColor);
        } catch (error) {
            SLVHelper.showErrorMessage(error);
        }
    }

    //---------------------------------------------------------------------------------------------------------
    // STYLE METHODS
    //---------------------------------------------------------------------------------------------------------
    handleColumnStyleChange(event) {
        this.spinner = true;
        try {
            const { target } = event;
            const id = target?.name ?? '';
            const action = target?.value ?? '';
            let resultStr;
            const valuesMap = new Map();
            let strParamsMap;
            let errorMsg = '';

            console.log('Id - ' + id);
            console.log('Action - ' + action);

            //if we are REMOVING we just need to pass the id of the column style
            if (action === 'remove') {

                strParamsMap = id;

                //if we are ADDING we need to pass all style information
            } else if (action === 'add') {

                if (SLVHelper.isEmpty(this.newColumnStyleField)) { errorMsg = 'The style field must be provided.' }

                //if we have an error
                if (errorMsg !== '') {
                    this.dispatchEvent(new ShowToastEvent({
                        title: 'Style Error',
                        message: errorMsg,
                        constiant: 'error',
                        mode: 'sticky'
                    }));
                    this.spinner = false;
                    return;
                }

                valuesMap.set('field', this.newColumnStyleField);
                valuesMap.set('font', this.newColumnStyleFont);
                valuesMap.set('decoration', this.newColumnStyleDecoration);
                valuesMap.set('style', this.newColumnStyleStyle);
                valuesMap.set('transform', this.newColumnStyleTransform);
                valuesMap.set('constiant', this.newColumnStyleconstiant);
                valuesMap.set('weight', this.newColumnStyleWeight);
                valuesMap.set('alignment', this.newColumnStyleAlignment);

                strParamsMap = JSON.stringify(Array.from(valuesMap));
                console.log('Params Field/Value  - ' + strParamsMap);

            }

            processColumnStyleChange({ objectName: this.listViewObject, listViewName: this.listViewName, action: action, columnStyleData: strParamsMap })
                .then(result => {
                    resultStr = result;

                    //get the status
                    let status = resultStr.substring(0, resultStr.indexOf(':'));

                    //get any associated message
                    let message = resultStr.substring(resultStr.indexOf(':') + 1);

                    if (status === 'Ok') {
                        message = 'All column styles processed.';

                        this.dispatchEvent(new ShowToastEvent({
                            title: 'Style Updated Successfully!',
                            message: message,
                            constiant: 'success',
                            mode: 'dismissable'
                        }));
                        this.getListViewConfig();
                        this.configChanged = true;
                        this.resetNewColumnStyle();
                    } else {
                        message = 'There was an error processing the column style.';
                        this.dispatchEvent(new ShowToastEvent({
                            title: 'Processing Error!',
                            message: message,
                            constiant: 'error',
                            mode: 'sticky'
                        }));
                    }
                })
                .catch(error => {
                    resultStr = undefined;
                    console.log('Error Detected - ' + error.body.message + ' | ' + error.body.stackTrace);

                    this.dispatchEvent(new ShowToastEvent({
                        title: 'Processing Error',
                        message: 'There was an error processing the column style changes - ' + error.body.message,
                        constiant: 'error',
                        mode: 'sticky'
                    }));
                });

            this.configChanged = true;
        } catch (error) {
            SLVHelper.showErrorMessage(error);
        } finally {
            this.spinner = false;
        }
    }

    resetNewColumnStyle() {
        if (this.styleListViewColumns !== undefined && this.styleListViewColumns.length > 0) {
            this.firstColumnStyleField = this.styleListViewColumns[0].value;
            this.newColumnStyleColumn = this.styleListViewColumns[0];
            this.newColumnStyleField = this.styleListViewColumns[0].value;
        }
        this.newColumnStyleFont = 'Arial';
        this.newColumnStyleDecoration = 'none';
        this.newColumnStyleStyle = 'normal';
        this.newColumnStyleTransform = 'none';
        this.newColumnStyleconstiant = 'normal';
        this.newColumnStyleWeight = 'normal';
        this.newColumnStyleAlignment = 'left';
    }

    handleColumnStyleFieldChange(event) {
        try {
            const { target } = event;
            let name = target.name ?? '';
            let value = target.value ?? '';
            console.log('New Columns Style Field Name - ' + name);
            console.log('New Column Style Field Value - ' + value);

            if (name === 'style') this.newColumnStyleStyle = value;
            else if (name === 'transform') this.newColumnStyleTransform = value;
            else if (name === 'constiant') this.newColumnStyleconstiant = value;
            else if (name === 'fieldName') this.newColumnStyleField = value;
            else if (name === 'decoration') this.newColumnStyleDecoration = value;
            else if (name === 'font') this.newColumnStyleFont = value;
            else if (name === 'weight') this.newColumnStyleWeight = value;
            else if (name === 'alignment') this.newColumnStyleAlignment = value;
        } catch (error) {
            SLVHelper.showErrorMessage(error);
        }
    }

    handleClose() {
        setTimeout(function () {
            console.log('after');
        }, 500); //give the parameter time to be saved before sending message to parent
        this.dispatchEvent(new CustomEvent('close', { detail: this.configChanged }));
        this.configChanged = false;
        this.resetNewCondition();
    }

    handleUpdateClick() {
        setTimeout(function () {
            console.log('after');
        }, 500); //give the parameter time to be saved before sending message to parent
        this.closeDisabled = undefined;
        this.dispatchEvent(new ShowToastEvent({
            title: 'Config Updated',
            message: 'Config updated successfully!',
            constiant: 'success',
            mode: 'dismissable'
        }));
    }

}
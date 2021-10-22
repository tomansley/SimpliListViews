/* eslint-disable no-console */
import { LightningElement, track, wire, api } from 'lwc';
import { getPicklistValuesByRecordType } from 'lightning/uiObjectInfoApi';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { CurrentPageReference } from 'lightning/navigation';
import { getRecord } from 'lightning/uiRecordApi';

//------------------------ LABELS ------------------------
import None_Dash from '@salesforce/label/c.None_Dash';

export default class SimpliUIListViewsPicklist extends LightningElement {
    
    @wire(CurrentPageReference) pageRef;

    @api type;                        //indicates the type of component to be created. (picklist or multipicklist)
    @api objectApiName;               //object API name of the object that the field is on.
    @api pickListFieldApiName;        //field API name of the field being displayed.
    @api label;                       //label if any to be displayed. For Simpli this is hidden
    @api variant;                     //the variant to use for the component. Usually = label-hidden
    @api rowId;                       //the row Id of the record in question.
    @api sfdcId;                      //holds the SFDC Id of the record in question. Used to identify the record type for picklist option values.
    @api sourceLabel = 'Available';   //label displayed above the AVAILABLE options.
    @api selectedLabel = 'Selected';  //label displayed above the SELECTED options.
    @api size = 5;                    //the number of options to display if we are displaying the multi-picklist
                 
    @track compName;
    @track value;
    recordTypeIdValue;

    hasError = false;                //identifies if there is an error retrieving the picklist values
    isPicklist = false;              //set internally. Identifies that the component being displayed is a PICKLIST
    isMultiPicklist = false;         //set internally. Identifies that the component being displayed is a MULTI-PICKLIST

    label = { None_Dash }

    @track options = [
        { label: 'Default 1', value: 'Default1' },
        { label: 'Default 2', value: 'Default2' },
        { label: '--None--', value: "" }
    ];   
    
    get recordTypeId() {
        return this.recordTypeIdValue;
    }
    set recordTypeId(value) {
        this.recordTypeIdValue = value;
    }

    @api 
    get selectedValue() {
        return this.value;
    }
    set selectedValue(val) {
        if (val === '' || val === undefined || val === null)
            this.value = { label: '--None--', value: "" }.value;
        else
            this.value = val;
    }
         
    renderedCallback() {

        if (this.type === 'picklist') {
            this.isPicklist = true;
        } else if (this.type === 'multipicklist') {
            this.isMultiPicklist = true;
        }

        this.compName = this.rowId + ':' + this.pickListFieldApiName;

        console.log('In simpliUIListViewsPicklist.renderedCallback');
        console.log('type     - ' + this.type);
        console.log('label  - ' + this.label);
        console.log('variant    - ' + this.variant);
        console.log('rowId - ' + this.rowId);
        console.log('sfdcId - ' + this.sfdcId);
        console.log('objectApiName    - ' + this.objectApiName);
        console.log('pickListFieldApiName - ' + this.pickListFieldApiName);

    }

    /*
     * Method to retrieve the row data for the provided row Id. This method is not currently used as we have not implemented dependent picklists.
     */
    @wire(getRecord, { recordId: '$sfdcId', fields: ['$pickListFieldApiName'], optionalFields: [] })
    getRecord({ error, data }) {
        if (data) {
            this.recordTypeId = data.recordTypeId;
            console.log('Record type retrieved - ' + this.recordTypeId);
        } else if (error) {
            console.log('Error Detected - ' + error.body.message + ' | ' + error.body.stackTrace);
            this.hasError = true;
        }
    }

    /*
     * Method to retrieve object information, specifically record types so that picklist values can then be retrieved.
     */
    @wire(getObjectInfo, { objectApiName: '$objectApiName' })
    getRecordTypeId({ error, data }) {
        if (data) {
            let response = data;
            if(this.recordTypeId === undefined){
                this.recordTypeId = response.defaultRecordTypeId;
            }
            console.log("Default Record Type Id", JSON.stringify(response.defaultRecordTypeId));
        } else if (error) {
            console.log('Error Detected - ' + error.body.message + ' | ' + error.body.stackTrace);
            this.hasError = true;
        }
    }
                     
    /*
     * Method to retrieve all object picklist values given its API name and record type.
     */
    @wire(getPicklistValuesByRecordType, { recordTypeId: '$recordTypeId', objectApiName: '$objectApiName' })
    wiredOptions({ error, data }) {
        if (data) {
            let response = data;

            //if we have a valid picklist field then get the options.
            if(response.picklistFieldValues[this.pickListFieldApiName] !== undefined) {
                let tempOptions = [];
                if (this.type === 'picklist') {
                    tempOptions = [{ label: '--None--', value: "" }];
                }
                let temp2Options = response.picklistFieldValues[this.pickListFieldApiName].values;
                temp2Options.forEach(opt => tempOptions.push(opt));

                this.options = tempOptions;
            }
            console.log('Options - ', JSON.stringify(this.options));

            //if the selected value has NOT been provided then default it.
            if(this.selectedValue === '' || this.selectedValue === undefined || this.selectedValue === null) {
                if (this.type === 'picklist') {
                    this.value = { label: '--None--', value: "" }.value;
                } else if (this.type === 'multipicklist') {
                    this.value = this.selectedValue;
                }

            //otherwise set it based on provided value/s
            } else {
                if (this.type === 'picklist') {
                    let pickVal = this.options.find(listItem => listItem.value === this.value);
                    if (pickVal !== undefined && pickVal !== null)
                    {
                        this.value = pickVal.value;
                    }
                } else if (this.type === 'multipicklist') {
                    this.value = this.value;
                }
            }
        } else if (error) {
            console.log('Error Detected - ' + error.body.message + ' | ' + error.body.stackTrace);
        }
    }

    /*
     * Method which gets called when a value on the component is changed. This method
     * sends a change event message to its parent component notifying of the change.
     */
    handleChange(event) {
        let tempValue = event.target.value;
        console.log("event.target.value",event.target.value);
        console.log("this.value",tempValue);
        let selectedValue = undefined;
        if (Array.isArray(tempValue)) {
            selectedValue = tempValue.join(';');
        } else {
            selectedValue = tempValue;
        }
        let rowId = this.rowId;
        let field = this.pickListFieldApiName;

        //Firing change event for aura container to handle
        //For Self
        const pickValueChangeEvent = new CustomEvent('picklistchange', {
            detail: { selectedValue, rowId, field },
        });
        this.dispatchEvent(pickValueChangeEvent);
    }

}
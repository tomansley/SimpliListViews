/* eslint-disable no-console */
import { LightningElement, track, wire, api } from 'lwc';
import { getPicklistValuesByRecordType } from 'lightning/uiObjectInfoApi';
import { CurrentPageReference } from 'lightning/navigation';
import * as SLVHelper from 'c/simpliUIListViewsHelper';
import getRecordTypeId from '@salesforce/apex/ListViewsPicklistController.getRecordTypeId';

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
    @api required = undefined;        //whether the picklist is required or not.
    @api fieldLevelHelp = '';         //field level help.
    @api fieldStyle = '';
    @api recordTypeId;                //if a record type exists then it should be provided.
    @api defaultValue;                //the default value to be displayed.
    @api picklistValues;              //the picklist values to be displayed if not using an object.field set of values

    @track compName;
    @track value;
    recordTypeIdValue;

    hasError = false;                //identifies if there is an error retrieving the picklist values
    isPicklist = false;              //set internally. Identifies that the component being displayed is a PICKLIST
    isMultiPicklist = false;         //set internally. Identifies that the component being displayed is a MULTI-PICKLIST

    label = { None_Dash }

    @track isOptionsSet = false;
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
        if (SLVHelper.isEmpty(val)) {
            if (this.type === 'picklist')
                this.value = '';
            else
                this.value = [];
        } else {
            if (this.type === 'picklist')
                this.value = val;
            else
                this.value = val.split(';');
        }
    }

    async renderedCallback() {

        if (this.type === 'picklist') {
            this.isPicklist = true;
        } else if (this.type === 'multipicklist') {
            this.isMultiPicklist = true;
        }

        //if we have options provided to us
        if (this.picklistValues !== undefined) {
            this.options = this.picklistValues;
            this.isOptionsSet = true;
            this.compName = this.rowId + ':';
            this.selectedValue(this.defaultValue);
        
        //if we are getting the options from an object field.
        } else {
            this.compName = this.rowId + ':' + this.pickListFieldApiName;

            if (SLVHelper.isEmpty(this.recordTypeId)) {
                console.log('Getting record type for id - ' + this.sfdcId);
                this.recordTypeId = await getRecordTypeId({ recordId: this.sfdcId });
            }
        
        }

        console.log('In simpliUIListViewsPicklist.renderedCallback');
        console.log('type     - ' + this.type);
        console.log('label  - ' + this.label);
        console.log('variant    - ' + this.variant);
        console.log('rowId - ' + this.rowId);
        console.log('sfdcId - ' + this.sfdcId);
        console.log('objectApiName    - ' + this.objectApiName);
        console.log('recordTypeId    - ' + this.recordTypeId);
        console.log('pickListFieldApiName - ' + this.pickListFieldApiName);

    }

    @wire(getPicklistValuesByRecordType, { objectApiName: '$objectApiName', recordTypeId: '$recordTypeId' })
    wiredOptions({ error, data }) {
        console.log('getPicklistValuesByRecordType Record type - ' + this.recordTypeId);
        console.log('getPicklistValuesByRecordType objectApiName - ' + this.objectApiName);
        if (data) {
            let response = data;

            //if we have a valid picklist field then get the options.
            if (response.picklistFieldValues[this.pickListFieldApiName] !== undefined) {
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
            if (SLVHelper.isEmpty(this.selectedValue)) {
                if (this.type === 'picklist') {
                    this.value = { label: '--None--', value: "" }.value;
                } else if (this.type === 'multipicklist') {
                    this.value = this.selectedValue;
                }

                //otherwise set it based on provided value/s
            } else {
                if (this.type === 'picklist') {
                    let pickVal = this.options.find(listItem => listItem.value === this.value);
                    if (!SLVHelper.isEmpty(pickVal)) {
                        this.value = pickVal.value;
                    }
                }
            }

            this.isOptionsSet = true;
        } else if (error) {
            console.log('Error Detected - ' + error.body.message + ' | ' + error.body.stackTrace);
        }
    }

    /*
     * Method which gets called when a value on the component is changed. This method
     * sends a change event message to its parent component notifying of the change.
     */
    handleChange(event) {
        try {
            const { target } = event
            let tempValue = target?.value ?? '';
            console.log("event.target.value", target.value);
            console.log("this.value", tempValue);
            let selectedValue;
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
        } catch (error) {
            SLVHelper.showErrorMessage(error);
        }
    }
}
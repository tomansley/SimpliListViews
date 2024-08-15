/* eslint-disable no-console */
/* eslint-disable @lwc/lwc/no-async-operation */

import { api, LightningElement, track, wire } from 'lwc';

import * as SLVHelper from 'c/simpliUIListViewsHelper';

import getRecordName from '@salesforce/apex/ListViewLookupController.getRecordName';
import search from '@salesforce/apex/ListViewLookupController.search';

//------------------------ LABELS ------------------------
import Search_Dot from '@salesforce/label/c.Search_Dot';

export default class SimpliUIListViewsLookup extends LightningElement {

    @api rowId;           //the record Id of the record being updated.
    @api initialName = '';   //the initial STRING value of the field for display purposes only
    @api initialId = '';     //the initial ID value of the field.
    @api fieldObjName;       //the API name of the object that the field is on that is being populated
    @api fieldName;          //the API name of the field the lookup is populating. Used to create the unique key only

    href;
    searchTerm;
    isInitialized = false; //identifies if the component has been initialized.
    iconName = 'standard:account'; //the icon name used when displaying the options. This will changed based on the provided object type

    uniqueKey;           //a key which is unique to this lookup component and passed back with the value once a selection has been made 
    @track selectedName; //the string name of the selected record (used for display purposes only)
    @track selectedId;   //the id of the selected record
    @track options;      //the lookup values that are returned from the search
    @track hasValue;
    @track blurTimeout;  //used for indicating when the results should be displayed and when they shouldn't

    //css
    @track boxClass = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-has-focus';
    @track inputClass = '';

    label = { Search_Dot }

    renderedCallback() {
        if (this.isInitialized === false) {
            this.isInitialized = true;
            console.log('In simpliUIListViewsLookup.renderedCallback');
            console.log('rowId     - ' + this.rowId);
            console.log('initialName  - ' + this.initialName);
            console.log('initialId    - ' + this.initialId);
            console.log('fieldObjName - ' + this.fieldObjName);
            console.log('fieldName    - ' + this.fieldName);
            this.uniqueKey = this.rowId + ':' + this.fieldName;
            console.log('uniqueKey - ' + this.uniqueKey);

            this.iconName = 'standard:' + this.fieldObjName.toLowerCase();

            //if we have an initial value then set that as the chosen option.
            if (this.initialId !== '' && this.initialName !== '') {
                this.boxClass = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-has-focus';
                this.hasValue = true;
                this.selectedId = this.initialId;
                this.selectedName = this.initialName;

                //if we do not have the name of the record to display then get it.
            } else if (this.initialId !== '' && this.initialName === '') {
                getRecordName({ selectedId: this.initialId, fieldObjName: this.fieldObjName })
                    .then(result => {
                        console.log('Get record name successful for ' + this.pageName);
                        console.log('Record name - ' + result);

                        this.selectedName = result;

                    })
                    .catch(error => {
                        console.log('Error Detected - ' + error.body.message + ' | ' + error.body.stackTrace + ' for ' + this.pageName);
                    });

                this.boxClass = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-has-focus';
                this.hasValue = true;
                this.selectedId = this.initialId;

            }

            console.log('selectedName  - ' + this.selectedName);
            console.log('selectedId    - ' + this.selectedId);
        }
    }

    /*
     * Method called when the search term has been updated and the data is searched for.
     */
    @wire(search, { searchTerm: '$searchTerm', obj: '$fieldObjName' })
    wiredRecords({ error, data }) {
        if (data) {
            this.options = data;
            console.log("common this.options", JSON.stringify(this.options));
        } else if (error) {
            console.log('Error Detected - ' + error.body.message + ' | ' + error.body.stackTrace);
        }
    }

    /*
     * Method that gets called when the user clicks on the lookup widget. In this case the search term gets set back to null
     * and the available f
     */
    handleClick() {
        console.log("In handleClick");

        this.searchTerm = '';
        this.inputClass = 'slds-has-focus';
        this.boxClass = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-has-focus slds-is-open';
        //let combobox = this.template.querySelector('#box');
        //combobox.classList.add("slds-is-open"); 
    }

    /*
     * Method that gets called when the cursor moves AWAY from the lookup widget
     */
    handleBlur() {
        console.log("In handleBlur");
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        this.blurTimeout = setTimeout(() => { this.boxClass = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-has-focus' }, 300);
    }

    /*
     * Method called when a selection is made from the drop down list
     */
    onSelect(event) {
        try {
            console.log("In onSelect");
            const { currentTarget } = event;
            this.selectedId = currentTarget?.dataset?.id ?? '';
            this.selectedName = currentTarget?.dataset?.value ?? '';
            console.log('selectedId - ', this.selectedId);
            console.log('selectedName - ', this.selectedName);

            //send selected value to parent and in return parent sends the value to @api rowId
            let rowId = this.rowId;
            let selectedValue = this.selectedId;
            let field = this.fieldName;
            this.dispatchEvent(new CustomEvent('lookupchange', { detail: { selectedValue, rowId, field }, }));

            if (this.blurTimeout) {
                clearTimeout(this.blurTimeout);
            }
            this.boxClass = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-has-focus';
            this.hasValue = true;
        } catch (error) {
            SLVHelper.showErrorMessage(error);
        }
    }

    /*
     * Method called when the search term is updated.
     */
    onChange(event) {
        try {
            console.log("In onChange");
            const { target } = event;
            this.searchTerm = target.value ?? '';
            console.log("searchTerm", this.searchTerm);
        } catch (error) {
            SLVHelper.showErrorMessage(error);
        }
    }

    /*
     * Called when the user removes the currently selected value.
     */
    handleRemovePill() {
        console.log("Removing pill");
        this.hasValue = false;
        let selectedValue = '';
        let rowId = this.rowId;
        let field = this.fieldName;
        const valueSelectedEvent = new CustomEvent('lookupchange', {
            detail: { selectedValue, rowId, field },
        });
        this.dispatchEvent(valueSelectedEvent);
    }
}
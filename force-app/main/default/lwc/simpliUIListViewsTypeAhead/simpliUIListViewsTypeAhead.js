/* eslint-disable no-console */
/* eslint-disable @lwc/lwc/no-async-operation */

import { api, LightningElement, track } from 'lwc';
import getRecordName from '@salesforce/apex/ListViewTypeAheadController.getRecordName';
import search from '@salesforce/apex/ListViewTypeAheadController.search';

import * as SLVHelper from 'c/simpliUIListViewsHelper';

//------------------------ LABELS ------------------------
import Search_Dot from '@salesforce/label/c.Search_Dot';

export default class SimpliUIListViewsTypeAhead extends LightningElement {

    //THESE TWO TO BE REMOVED IF POSSIBLE
    @api initialName = '';  //the initial string value of the field for display purposes only
    @api variant = 'label-hidden';  //the variant of the component. Helps to indicate label position
    @api label = '';                //the label of the component if there is one.
    @api fieldLevelHelp = '';       //any field level help that should be provided

    _initialId;          //the initial value of the field.
    @api set initialId(value) {
        if (this.searchType === 'schema') {
            this.searchTerm = value;
        }
        this._initialId = value;
        this.search();
    }
    get initialId() {
        return this._initialId;
    }


    _searchType;          //indicates the type of data being searched for. i.e. sobject, metadata, schema
    @api set searchType(value) {
        if (value !== this._searchType) {
            this.searchTerm = '';
            this.oldSearchTerm = '';
        }
        this._searchType = value;
    }
    get searchType() {
        return this._searchType;
    }

    _fieldObjName;          //the API name of the object that the field is on that is being populated
    @api set fieldObjName(value) {
        if (value !== this._fieldObjName) {
            this.searchTerm = '';
            this.oldSearchTerm = '';
        }
        this._fieldObjName = value;
    }
    get fieldObjName() {
        return this._fieldObjName;
    }

    _whereClause = [];           //any additional criteria (in SOQL format without WHERE keyword) to be applied when displaying values
    @api set whereClause(value) 
         {
            this.searchTerm = '';
            this.oldSearchTerm = '';
            this._whereClause = [];
            if (!SLVHelper.isEmpty(value)) {
                this._whereClause.push(value);
            }
            this.search();
         }
    get whereClause() {
        return this._whereClause;
    }

    _labelFieldName;           //the API name of the label field the lookup is populating. Used to create the unique key only
    @api set labelFieldName(value) {
        if (value !== this._labelFieldName) {
            this.searchTerm = '';
            this.oldSearchTerm = '';
        }
        this._labelFieldName = value;
    }
    get labelFieldName() {
        return this._labelFieldName;
    }

    _keyFieldName;           //the API name of the labels associated key field.
    @api set keyFieldName(value) {
        if (value !== this._keyFieldName) {
            this.searchTerm = '';
            this.oldSearchTerm = '';
        }
        this._keyFieldName = value;
    }
    get keyFieldName() {
        return this._keyFieldName;
    }

    _searchTerm;           //the API name of the labels associated key field.
    set searchTerm(value) {
        this._searchTerm = value;
    }
    get searchTerm() {
        return this._searchTerm;
    }

    @api iconName;          //the icon name used when displaying the options.

    href;
    oldSearchTerm;
    isInitialized = false; //identifies if the component has been initialized.

    uniqueKey;           //a key which is unique to this search component and passed back with the value once a selection has been made 
    @track selectedName; //the string name of the selected record (used for display purposes only)
    @track selectedId;   //the id of the selected record
    @track options;      //the search values that are returned from the search
    @track hasValue;
    @track blurTimeout;  //used for indicating when the results should be displayed and when they shouldn't

    //css
    @track boxClass = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-has-focus';
    @track inputClass = '';

    label = { Search_Dot }

    renderedCallback() {
        if (this.isInitialized === false) {
            if (this.searchType !== '' && this.searchType !== undefined) {
                console.log('In SimpliUIListViewsTypeAhead.renderedCallback');
                console.log('searchType     - ' + this.searchType);
                console.log('initialName    - ' + this.initialName);
                console.log('initialId      - ' + this.initialId);
                console.log('fieldObjName   - ' + this.fieldObjName);
                console.log('labelFieldName - ' + this.labelFieldName);
                console.log('whereClause    - ' + JSON.stringify(this.whereClause));
                this.uniqueKey = this.labelFieldName;
                console.log('uniqueKey - ' + this.uniqueKey);

                //if we have an initial value then set that as the chosen option.
                if (this.initialId !== '' && this.initialName !== '') {
                    this.boxClass = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-has-focus';
                    this.hasValue = true;
                    this.selectedId = this.initialId;
                    this.selectedName = this.initialName;
                    this.isInitialized = true;

                    //if we do not have the name of the record to display then get it.
                } else if (this.searchType === 'sobject' && this.initialId !== undefined && this.initialId !== '' && this.initialName === '') {
                    getRecordName({ selectedId: this.initialId, objName: this.fieldObjName, labelFieldName: this.labelFieldName })
                        .then(result => {
                            console.log('Get record name successful');
                            console.log('Record name - ' + result);

                            this.selectedName = result;
                            this.searchTerm = this.selectedName;
                            this.boxClass = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-has-focus';
                            this.hasValue = true;
                            this.selectedId = this.initialId;
                            this.isInitialized = true;
                        })
                        .catch(error => {
                            SLVHelper.showErrorMessage(error);
                        });
                    this.isInitialized = true;
                }

                console.log('selectedName  - ' + this.selectedName);
                console.log('selectedId    - ' + this.selectedId);
            }
        } else {
            console.log('Inside typeahead renderedCallback');
        }
    }

    search() {
        console.log("searchTerm1", this.searchTerm);
        if ((this.searchType === 'sobject' && this.whereClause !== undefined && this.labelFieldName !== undefined && this.keyFieldName !== undefined && this.fieldObjName !== undefined)
            ||
            (this.searchType === 'schema' && this.fieldObjName !== undefined)
            &&
            this.searchTerm.length > 1) {
            let whereClauseStr = JSON.stringify(this.whereClause);

            console.log('Performing search - ' + this.searchType + ', ' + this.searchTerm + ', ' + this.fieldObjName + ', ' + this.labelFieldName + ', ' + this.keyFieldName + ', ' + this.whereClauseStr)

            search({ searchType: this.searchType, searchTerm: this.searchTerm, objName: this.fieldObjName, labelFieldName: this.labelFieldName, keyFieldName: this.keyFieldName, whereClauseJSON: whereClauseStr })
                .then(result => {
                    console.log('searchType - ' + this.searchType);
                    console.log('fieldObjName - ' + this.fieldObjName);
                    console.log('result - ' + result);
                    this.options = result;
                    // console.log("Options - ", JSON.stringify(this.options));
                    if (this.options.length === 0)
                        this.options = undefined;
                })
                .catch(error => {
                    SLVHelper.showErrorMessage(error);
                });

        } else if (this.searchType === 'schema' && this.fieldObjName !== undefined) {
            console.log('searchType = schema, fieldObjName != undefined');
        }

    }

    /*
     * Method that gets called when the user clicks on the search widget. In this case the search term gets set back to null
     * and the available f
     */
    handleClick() {
        console.log("In handleClick");
        console.log('fieldObjName   - ' + this.fieldObjName);
        console.log('labelFieldName - ' + this.labelFieldName);
        console.log('whereClause    - ' + JSON.stringify(this.whereClause));

        this.oldSearchTerm = this.searchTerm;
        this.searchTerm = '';
        this.inputClass = 'slds-has-focus';
        this.boxClass = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-has-focus slds-is-open';
        this.search();
    }

    /*
     * Method that gets called when the cursor moves AWAY from the search widget
     */
    handleBlur() {
        console.log("In handleBlur");

        if (this.searchTerm === '')
            this.searchTerm = this.oldSearchTerm;
        
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        this.blurTimeout = setTimeout(() => { this.boxClass = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-has-focus' }, 300);
    }

    /*
     * Method called when a selection is made from the drop down list
     */
    onSelect(event) {
        console.log("In onSelect");
        try {
            const { currentTarget } = event;
            this.selectedId = currentTarget?.dataset?.id ?? '';
            this.selectedName = currentTarget?.dataset?.value ?? '';
            console.log('selectedId - ', this.selectedId);
            console.log('selectedName - ', this.selectedName);

            //send selected value to parent and in return parent sends the value to @api rowId
            let selectedValue = this.selectedId;
            let field = this.labelFieldName;
            this.searchTerm = this.selectedName;
            this.dispatchEvent(new CustomEvent('valuechange', { detail: { selectedValue, field }, }));

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
            this.searchTerm = target?.value ?? '';
            this.search();
            console.log("searchTerm", this.searchTerm);
        } catch (error) {
            SLVHelper.showErrorMessage(error);
        }
    }

}
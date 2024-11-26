/* eslint-disable no-console */
import { LightningElement, api, track } from 'lwc';

import getObjectFieldData from '@salesforce/apex/ListViewFieldSelectorController.getObjectFieldData';
import * as SLVHelper from 'c/simpliUIListViewsHelper';

export default class SimpliUIListViewsFieldSelector extends LightningElement {

    @api objectStartList;
    @api heading;
    @api okLabel;
    @api cancelLabel;
    @api showModal;

    @track selectedField = undefined;
    @track isInitialized = false;
    @track listData;
    @track spinner = false;
    @track spinnerText = 'Loading...';
    @track showSelect = false;

    renderedCallback() {
        if (this.showModal && this.isInitialized === false)
        {
            if (this.cancelLabel === undefined)
                this.cancelLabel = 'Cancel';

            if (this.okLabel === undefined)
                this.okLabel = 'Ok';

            this.listData = [{
                list : this.objectStartList,
                selected : "",
                index : 0
            }];
            this.isInitialized = true;
        }
    }

    getFieldData(objName) {
        this.spinnerOn('Getting Field Data...');
        getObjectFieldData({objName: objName})
        .then(result => {
            console.log('Field data retrieval successful');
            console.log('Field data - ' + JSON.stringify(result)); 

            let newList = {
                list : result,
                selected : "",
                index : this.listData.length
            }

            this.listData.push(newList);
            this.spinnerOff('getFieldData');
            console.log('List data - ' + JSON.stringify(this.listData));

        })
        .catch(error => {
            this.dispatchEvent(SLVHelper.createToast('error', error, 'Error Retrieving Field Data', 'There was an error retrieving the field data.', true)); 
            this.spinnerOff('getFieldData');
        });
    }

    handleItemSelected(event) {
        let index = Number(event.currentTarget.dataset.index);
        let value = event.currentTarget.dataset.value;
        let type;
        let relObj;

        console.log('Item Selected - ' + value + ' @ index ' + index);

        this.listData = this.listData.slice(0, index+1);

        let data = this.listData.at(index);

        data.selected = value;

        data.list.forEach(option => {
            if (option.value === value) {
                type = option.type;
                relObj = option.relationshipObj;
            }
        });

        if (type === 'Object') {
            this.selectedField = undefined;
            if (this.listData.length < 6) {
                this.getFieldData(relObj); //go get fields and relationship data
                this.showSelect = false;
            } else {
                this.dispatchEvent(SLVHelper.createToast('error', '', 'Too Many Levels', 'A field can only be up to 6 levels deep in the hierarchy.', false)); 
            }
        } else {
            this.selectedField = '';
            this.listData.forEach(option => {
                this.selectedField = this.selectedField + option.selected + '.';
            });
    
            this.selectedField = this.selectedField.substring(0, this.selectedField.length-1);
    
            this.showSelect = true;
            console.log('List data - ' + JSON.stringify(this.listData));
        }


    }

    handleCancelClick() {
        this.dispatchEvent(new CustomEvent('cancel', { detail: {value: false}}));

        //reset values
        this.listData = [{
            list : this.objectStartList,
            selected : "",
            index : 0
        }];
    }

    handleSelectClick() {
        console.log('Field Selected - ' + this.selectedField);
        this.dispatchEvent(new CustomEvent('select', { detail: this.selectedField}));
        
        //reset values
        this.listData = [{
            list : this.objectStartList,
            selected : "",
            index : 0
        }];
    }

    spinnerOn(message) {
        this.spinnerText = message;
        this.spinner = true;
        console.log('Spinner ON - ' + message);
    }

    spinnerOff(message) {
        this.spinner = false;
        console.log('Spinner OFF  - ' + message);
    }
}
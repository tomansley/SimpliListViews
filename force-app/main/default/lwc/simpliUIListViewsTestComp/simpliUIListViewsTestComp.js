import { LightningElement, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import getStandAloneColumns from '@salesforce/apex/ListViewTestCompController.getStandAloneColumns';
import getStandAloneRowData from '@salesforce/apex/ListViewTestCompController.getStandAloneRowData';

export default class SimpliUIListViewsTestComp extends LightningElement {

    @track selectedAccountId = '';
    @track standAloneColumnData;
    @track standAloneRowData;

    @wire (getStandAloneColumns, {})
    wiredGetStandAloneColumns({ error, data }) {
       if (data) { 
           this.standAloneColumnData = JSON.stringify(data); 
       } else if (error) { 
           this.standAloneColumnData = undefined; 
           this.dispatchEvent(new ShowToastEvent({
            title: 'Error',
            message: 'There was an error retrieving the stand alone columns - ' + error.message,
            variant: 'error',
            mode: 'sticky'
        })); 
       }
    }

    @wire (getStandAloneRowData, {})
    wiredgetStandAloneRowData({ error, data }) {
       if (data) { 
           this.standAloneRowData = JSON.stringify(data); 
       } else if (error) { 
           this.standAloneRowData = undefined; 
           this.dispatchEvent(new ShowToastEvent({
            title: 'Error',
            message: 'There was an error retrieving the stand alone row data - ' + error.message,
            variant: 'error',
            mode: 'sticky'
        })); 
       }
    }

    handleExample4DataChange(event) {
        console.log('Handling Example 4 Data Change - ' + event.detail.selectedValue);
        this.selectedAccountId = event.detail.selectedValue;
    }
}
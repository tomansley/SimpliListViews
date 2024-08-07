import { LightningElement, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import getData from '@salesforce/apex/ListViewTestCompController.getData';

export default class SimpliUIListViewsTestComp extends LightningElement {

    @track selectedAccountId = '';
    @track standAloneData = '';

    get standAloneJSONData() {
        if (this.standAloneData !== '') {
            return JSON.stringify(this.standAloneData);
        }
        return '';
    }

    @wire (getData, {})
    wiredGetStandAloneData({ error, data }) {
       if (data) { 
           this.standAloneData = data;
       } else if (error) { 
           this.standAloneData = undefined; 
           this.dispatchEvent(new ShowToastEvent({
            title: 'Error',
            message: 'There was an error retrieving the stand alone data - ' + error.message,
            variant: 'error',
            mode: 'sticky'
        })); 
       }
    }

    //for event testing
    handleEventRequest(event) {
        let eventRequest = { type: 'refreshData'};

        const slvs = this.template.querySelectorAll('c-simpli-u-i-list-views');
        let slv = null;
        
        slvs.forEach(tmpslv => {
            if (tmpslv.uniqueComponentId.includes("My Button Event Test")) {
                slv = tmpslv;
            }
        });

        slv.eventRequest(eventRequest);

        eventRequest = { type: 'updateSetting', name: "hasMainTitle", value: false};
        slv.eventRequest(eventRequest);

    }

    //for event testing
    handleEventResponse(event) {
        console.log('EVENT RESPONSE - ' + JSON.stringify(event.detail));
    }

    handleExample4DataChange(event) {
        console.log('Handling Example 4 Data Change - ' + event.detail.selectedValue);
        this.selectedAccountId = event.detail.selectedValue;
    }

}
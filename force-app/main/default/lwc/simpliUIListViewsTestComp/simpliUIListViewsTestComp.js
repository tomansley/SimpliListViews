/* eslint-disable no-console */
import { LightningElement, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import * as SLVHelper from 'c/simpliUIListViewsHelper';

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

    @wire(getData, {})
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
    handleEventRequest() {
        let eventRequest = { type: 'refreshData' };

        const slvs = this.template.querySelectorAll('c-simpli-u-i-list-views');
        let slv = null;

        if (slvs?.length) {
            slvs.forEach(tmpslv => {
                if (tmpslv.uniqueComponentId.includes("My Button Event Test")) {
                    slv = tmpslv;
                }
            });
        }

        slv.eventRequest(eventRequest);

        eventRequest = { type: 'updateSetting', name: "hasMainTitle", value: false };
        slv.eventRequest(eventRequest);

    }

    //for event testing
    handleEventResponse(event) {
        try {
            const { detail } = event;
            console.log('EVENT RESPONSE - ' + JSON.stringify(detail));
        } catch (error) {
            SLVHelper.showErrorMessage(error);
        }
    }

    handleExample4DataChange(event) {
        try {
            const { detail } = event;
            console.log('Handling Example 4 Data Change - ' + detail.selectedValue);
            this.selectedAccountId = detail.selectedValue ?? '';
        } catch (error) {
            SLVHelper.showErrorMessage(error);
        }
    }

}
import { LightningElement, wire, track, api  } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import updateAllListViews from '@salesforce/apex/ListViewController.updateAllListViews';
import getListViewObjects from '@salesforce/apex/ListViewController.getListViewObjects';

export default class SimpliUIListViewsStart extends LightningElement {

    @track spinner = false;             //identifies if the spinner should be displayed or not.

    //for tracking list view init process
    @track isInit = true;               //indicates whether the list views have been initialized for the first time or not.
    @track showProgress = false;        //indicates whether the progress bar should be displayed
    @track batchId = '';                //indicates the batch Id of the list view batch process.

    /*
     * Wiring to get the list of objects in the system
     */
    @wire (getListViewObjects, { includedObjects: '', excludedObjects: ''  })
    wiredListViewObjects({ error, data }) {
        if (data) { 
            
            if (data === undefined || data.length === 0)
            {
                this.isInit = false;
            }

            this.spinner = false;
        }
    }
    
    //called when a user clicks the button to refresh the list views.
    handleProcessListViewsButtonClick() {

        this.spinner = true;
        console.log('Listview process button clicked!');

        updateAllListViews({ })
        .then(result => {

            //if we have an error then send an ERROR toast.
            if (result === 'failed')
            {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Processing Error',
                    message: 'There was an error processing the list views. Please see an administrator',
                    variant: 'error',
                    mode: 'sticky'
                }));

            //else send a SUCCESS toast.
            } else {

                this.batchId = result;

                this.showProgress = true;

                this.dispatchEvent(new ShowToastEvent({
                    title: 'List View Processing',
                    message: 'List view processing has started. See progress bar below. You MUST do a full page refresh after completion to see changes.',
                    variant: 'success',
                    mode: 'dismissable'
                }));
                this.dispatchEvent(new CustomEvent('processlistviewclick'));
            }
        })
        .catch(error => {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Processing Error',
                message: 'There was an error processing the list views. Please see an administrator',
                variant: 'error',
                mode: 'sticky'
            }));
        });
    
        this.spinner = false;

    }


}
import { LightningElement, wire, track, api  } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import updateAllListViews from '@salesforce/apex/ListViewController.updateAllListViews';

export default class SimpliUIListViewsStart extends LightningElement {

    @track spinner = false;             //identifies if the spinner should be displayed or not.

    //called when a user clicks the button to refresh the list views.
    handleProcessListViewsButtonClick() {

        this.spinner = true;
        console.log('Listview process button clicked!');

        updateAllListViews({ })
            .then(result => {

                //if we have an error then send an ERROR toast.
                if (result === 'success')
                {
                    this.dispatchEvent(new ShowToastEvent({
                        title: 'List View Processing',
                        message: 'List view processing has started and will be complete in a few minutes.',
                        variant: 'success',
                        mode: 'sticky'
                    }));
                    this.dispatchEvent(new CustomEvent('processlistviewclick'));

                //else send a SUCCESS toast.
                } else {
                    this.dispatchEvent(new ShowToastEvent({
                        title: 'Processing Error',
                        message: 'There was an error processing the list views. Please see an administrator',
                        variant: 'error',
                        mode: 'sticky'
                    }));
            
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
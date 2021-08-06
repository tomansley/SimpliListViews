import { LightningElement, wire, track, api  } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

//------------------------ LABELS ------------------------
import List_Views_Initialized from '@salesforce/label/c.List_Views_Initialized';
import List_Views_Need_Initialized from '@salesforce/label/c.List_Views_Need_Initialized';
import Refresh from '@salesforce/label/c.Refresh';
import Refresh_List_Views from '@salesforce/label/c.Refresh_List_Views';
import Feature_Overview from '@salesforce/label/c.Feature_Overview';
import Quick_Start from '@salesforce/label/c.Quick_Start';
import Issues_And_Questions from '@salesforce/label/c.Issues_And_Questions';
import Configuration from '@salesforce/label/c.Configuration';
import Processing_Status from '@salesforce/label/c.Processing_Status';
import List_View_Processing_Complete from '@salesforce/label/c.List_View_Processing_Complete';

import updateAllListViews from '@salesforce/apex/ListViewController.updateAllListViews';
import getIsInitialized from '@salesforce/apex/ListViewController.getIsInitialized';

export default class SimpliUIListViewsStart extends LightningElement {

    @track spinner = false;             //identifies if the spinner should be displayed or not.

    //for tracking list view init process
    @track isInitialized = false;               //indicates whether the list views have been initialized for the first time or not.
    @track showProgress = false;        //indicates whether the progress bar should be displayed
    @track batchId = '';                //indicates the batch Id of the list view batch process.
    
    label = { List_Views_Initialized, List_Views_Need_Initialized, Refresh, Refresh_List_Views, Feature_Overview, Quick_Start,
              Issues_And_Questions, Configuration, Processing_Status, List_View_Processing_Complete }

    @wire (getIsInitialized, { })
    wiredIsInitialized({ error, data }) {
        if (data) { 
            console.log('Is Initialized called successfully - ' + data); 
            this.isInitialized = data; 
        } else if (error) { 
            console.log('Error Detected - ' + error.body.message + ' | ' + error.body.stackTrace);
            this.objectActionList = undefined; 
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error Checking Initialization',
                message: 'There was an error checking for Simpli List Views initialization. Please see an administrator - ' + error.body.message,
                variant: 'error',
                mode: 'sticky'
            }));
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
                    message: 'There was an error processing the list views. Please see an administrator.' + error.body.message,
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
            console.log('Error Detected - ' + error.body.message + ' | ' + error.body.stackTrace);
            this.dispatchEvent(new ShowToastEvent({
                title: 'Processing Error',
                message: 'There was an error processing the list views. Please see an administrator - ' + error.body.message,
                variant: 'error',
                mode: 'sticky'
            }));
        });
    
        this.spinner = false;

    }


}
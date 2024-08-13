/* eslint-disable no-console */
import { LightningElement, track, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import Not_Initialized from '@salesforce/label/c.Not_Initialized';
import Process_List_Views from '@salesforce/label/c.Process_List_Views';
import List_Views_Initialized from '@salesforce/label/c.List_Views_Initialized';
import List_Views_Initialized_Verbage from '@salesforce/label/c.List_Views_Initialized_Verbage';
import List_View_Processing_Complete from '@salesforce/label/c.List_View_Processing_Complete';
import List_Views_Need_Initialized from '@salesforce/label/c.List_Views_Need_Initialized';
import List_Views_Need_Initialized_Verbage from '@salesforce/label/c.List_Views_Need_Initialized_Verbage';
import Refresh from '@salesforce/label/c.Refresh';
import Refresh_List_Views from '@salesforce/label/c.Refresh_List_Views';
import Processing_Status from '@salesforce/label/c.Processing_Status';

import getIsInitialized from '@salesforce/apex/ListViewController.getIsInitialized';
import updateAllListViews from '@salesforce/apex/ListViewController.updateAllListViews';

export default class SimpliUIListViewsInitCard extends LightningElement {

    @api set batchId(value)                  //indicates the batch Id of the list view batch process.
    {
        this.apexBatchId = value;
        if (value !== '') {
            this.isInitialized = false;
            this.showProgress = true;
        }
    }
    get batchId() {
        return this.apexBatchId;
    }
    @api alwaysDisplayed = undefined;

    @track apexBatchId = '';            //holds the batch Id to be monitored
    @track spinner = false;             //identifies if the spinner should be displayed or not.
    @track isInitialized = true;        //indicates whether the list views have been initialized for the first time or not.
    @track isInitializedCheck = false;  //indicates whether the list views have been checked for initialization
    @track showProgress = false;        //indicates whether the progress bar should be displayed

    label = {
        Not_Initialized, Process_List_Views, List_View_Processing_Complete, List_Views_Need_Initialized_Verbage,
        List_Views_Need_Initialized, Refresh_List_Views, Refresh, List_Views_Initialized, List_Views_Initialized_Verbage,
        Processing_Status
    };

    async renderedCallback() {

        console.log('Starting simpliUIListViewsInitCard.renderedCallback');
        console.log('Record id - ' + this.recordId);

        if (this.isInitializedCheck === false) {
            this.isInitialized = await getIsInitialized({});
            this.handleIsInitialized();
        }
    }

    handleIsInitialized() {
        this.isInitializedCheck = true;
        if (this.isInitialized === false) {
            this.spinner = false; //a special case where we set it directly.
        }
        this.dispatchEvent(new CustomEvent('initializedcheck', { detail: this.isInitialized }));
    }

    spinnerOn(message) {
        this.spinner = true;
        console.log('Spinner ON - ' + message);
    }

    spinnerOff(message) {
        this.spinner = false;
        console.log('Spinner OFF  - ' + message);
    }

    //called when a user clicks the button to refresh the list views.
    handleProcessListViewsButtonClick() {

        this.spinnerOn('handleProcessListViewsButtonClick');
        console.log('Listview process button clicked');

        updateAllListViews({})
            .then(result => {

                //if we have an error then send an ERROR toast.
                if (result === 'failed') {
                    this.dispatchEvent(new ShowToastEvent({
                        title: 'Processing Error',
                        message: 'There was an error processing the list views.',
                        variant: 'error',
                        mode: 'sticky'
                    }));
                    this.spinnerOff('handleProcessListViewsButtonClick1');

                    //else send a SUCCESS toast.
                } else {

                    this.batchId = result;

                    this.isInitialized = false;
                    this.showProgress = true;

                    this.dispatchEvent(new ShowToastEvent({
                        title: 'List View Processing',
                        message: 'List view processing has started for all list views. Refresh page after completion to see changes.',
                        variant: 'success',
                        mode: 'dismissable'
                    }));
                    this.dispatchEvent(new CustomEvent('processlistviewclick'));
                    this.spinnerOff('handleProcessListViewsButtonClick2');
                }
            })
            .catch(error => {
                console.log('Error Detected - ' + error.body.message + ' | ' + error.body.stackTrace + ' for ' + this.pageName);
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Processing Error',
                    message: 'There was an error processing the list views - ' + error.body.message,
                    variant: 'error',
                    mode: 'sticky'
                }));
                this.spinnerOff('handleProcessListViewsButtonClick3');
            });

    }

}
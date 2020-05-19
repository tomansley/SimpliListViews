import { LightningElement, track, api } from 'lwc';

import getListViewInitProgress from '@salesforce/apex/ListViewController.getListViewInitProgress';

export default class SimpliUIListViewsInitProgressBar extends LightningElement {
    @track progress = 0;
    @track hasCompleted = false;

    @api batchId = '';
    @api workingText = 'Working...';
    @api completeText = 'Complete!';

    connectedCallback() {
        
        this._interval = setInterval(() => {

            getListViewInitProgress({batchId: this.batchId})
            .then(result => {
                this.progress = Number(result);
                this.error = undefined;

                if (this.progress === 100) {
                    this.hasCompleted = true;
                    clearInterval(this._interval);
                }
            })
            .catch(error => {
                this.error = error;
                this.progress = 0;
            });

        }, 2000);

    }

}
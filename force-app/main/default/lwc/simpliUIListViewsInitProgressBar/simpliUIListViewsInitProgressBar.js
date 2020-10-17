import { LightningElement, track, api } from 'lwc';

import getListViewInitProgress from '@salesforce/apex/ListViewController.getListViewInitProgress';

export default class SimpliUIListViewsInitProgressBar extends LightningElement {
    @track progress = 0;
    @track hasCompleted = false;

    @api batchId = '';
    @api workingText = 'Working...';
    @api completeText = 'Complete!';

    batchStatus = 'Initializing';

    connectedCallback() {
        
        this._interval = setInterval(() => {

            getListViewInitProgress({batchId: this.batchId})
            .then(result => {

                const progressResult = result.split(':'); //response = progress:status               

                this.progress = Number(progressResult[0]);
                this.batchStatus = progressResult[1] + ' (' + Number(progressResult[0]).toFixed(0) + '%)';
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
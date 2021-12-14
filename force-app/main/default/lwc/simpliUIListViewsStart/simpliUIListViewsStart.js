import { LightningElement, wire, track, api  } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

//------------------------ LABELS ------------------------
import Feature_Overview from '@salesforce/label/c.Feature_Overview';
import Quick_Start from '@salesforce/label/c.Quick_Start';
import Issues_And_Questions from '@salesforce/label/c.Issues_And_Questions';
import Configuration from '@salesforce/label/c.Configuration';

import getOrgWideDescriptions from '@salesforce/apex/ListViewConfigController.getOrgWideDescriptions';
import getComponentDescriptions from '@salesforce/apex/ListViewConfigController.getComponentDescriptions';
import getListViewDescriptions from '@salesforce/apex/ListViewConfigController.getListViewDescriptions';

export default class SimpliUIListViewsStart extends LightningElement {

    @track spinner = false;             //identifies if the spinner should be displayed or not.

    @track orgWideDescs;                //holds ORG WIDE description details
    @track compDescs;                   //holds COMPONENT description details
    @track listViewDescs;               //holds LIST VIEW description details

    //for tracking list view init process
    @track isInitialized = false;       //indicates whether the list views have been initialized for the first time or not.
    @track showProgress = false;        //indicates whether the progress bar should be displayed
    @track batchId = '';                //indicates the batch Id of the list view batch process.
    
    label = { Feature_Overview, Quick_Start, Issues_And_Questions, Configuration }

    /*
     * Method which gets called after the class has been instantiated
     * but before it is rendered. We do have access to variables in this method.
     */
    async renderedCallback() {

        console.log('Starting simpliUIListViewsStart.renderedCallback for ' + this.pageName);

    }

    @wire (getOrgWideDescriptions, { })
    wiredOrgWideDescriptions({ error, data }) {
        if (data) { 
            console.log('Get Org Wide Descriptions called successfully - ' + data); 
            this.orgWideDescs = data; 
        } else if (error) { 
            console.log('Error Detected - ' + error.body.message + ' | ' + error.body.stackTrace);
            this.objectActionList = undefined; 
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error Retrieving Org Wide Descriptions',
                message: 'There was an error retrieving the org wide descriptions. Please see an administrator - ' + error.body.message,
                variant: 'error',
                mode: 'sticky'
            }));
        }
    }
    
    @wire (getComponentDescriptions, { })
    wiredComponentDescriptions({ error, data }) {
        if (data) { 
            console.log('Get Component Descriptions called successfully - ' + data); 
            this.compDescs = data; 
        } else if (error) { 
            console.log('Error Detected - ' + error.body.message + ' | ' + error.body.stackTrace);
            this.objectActionList = undefined; 
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error Retrieving Component Descriptions',
                message: 'There was an error retrieving the component descriptions. Please see an administrator - ' + error.body.message,
                variant: 'error',
                mode: 'sticky'
            }));
        }
    }
    
    @wire (getListViewDescriptions, { })
    wiredListViewsDescriptions({ error, data }) {
        if (data) { 
            console.log('Get List View Descriptions called successfully - ' + data); 
            this.listViewDescs = data; 
        } else if (error) { 
            console.log('Error Detected - ' + error.body.message + ' | ' + error.body.stackTrace);
            this.objectActionList = undefined; 
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error Retrieving List View Descriptions',
                message: 'There was an error retrieving the list view descriptions. Please see an administrator - ' + error.body.message,
                variant: 'error',
                mode: 'sticky'
            }));
        }
    }

}
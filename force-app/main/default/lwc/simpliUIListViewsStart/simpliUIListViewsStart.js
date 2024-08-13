/* eslint-disable no-console */
import { LightningElement, wire, track } from 'lwc';
import * as SLVHelper from 'c/simpliUIListViewsHelper';

//------------------------ LABELS ------------------------
import Feature_Overview from '@salesforce/label/c.Feature_Overview';
import Quick_Start from '@salesforce/label/c.Quick_Start';
import Issues_And_Questions from '@salesforce/label/c.Issues_And_Questions';
import Configuration from '@salesforce/label/c.Configuration';
import Example_App_Descriptions from '@salesforce/label/c.Example_App_Descriptions';

import getOrgWideConfig from '@salesforce/apex/ListViewAdminController.getOrgWideConfig';
import getOrgWideDescriptions from '@salesforce/apex/ListViewConfigController.getOrgWideDescriptions';
import getComponentDescriptions from '@salesforce/apex/ListViewConfigController.getComponentDescriptions';
import getListViewDescriptions from '@salesforce/apex/ListViewConfigController.getListViewDescriptions';

export default class SimpliUIListViewsStart extends LightningElement {

    @track spinner = false;             //identifies if the spinner should be displayed or not.

    @track hasConfig = true;            //indicates whether the global config exists in the org
    @track config;                      //holds the org wide config
    @track orgWideDescs;                //holds ORG WIDE description details
    @track compDescs;                   //holds COMPONENT description details
    @track listViewDescs;               //holds LIST VIEW description details

    //for tracking list view init process
    @track isInitialized = false;       //indicates whether the list views have been initialized for the first time or not.
    @track showProgress = false;        //indicates whether the progress bar should be displayed
    @track batchId = '';                //indicates the batch Id of the list view batch process.
    @track inRenderedCallback = false;  //indicates whether the rendered callback method is processing
    @track calloutCount = 1;            //indicates the number of callouts made for this component

    label = { Feature_Overview, Quick_Start, Issues_And_Questions, Configuration, Example_App_Descriptions }

    /*
     * Method which gets called after the class has been instantiated
     * but before it is rendered. We do have access to variables in this method.
     */
    async renderedCallback() {

        console.log('Starting simpliUIListViewsStart.renderedCallback');
        if (this.config === undefined && this.hasConfig === true && this.inRenderedCallback === false) {
            this.inRenderedCallback = true;
            console.log('Starting getConfig()');
            this.getConfig();
        }
    }

    @wire(getOrgWideDescriptions, {})
    wiredOrgWideDescriptions({ error, data }) {
        if (data) {
            console.log('simpliUIListViewsStart CALLOUT - getOrgWideDescriptions - ' + this.calloutCount++);
            console.log('Get Org Wide Descriptions called successfully - ' + data);
            this.orgWideDescs = data;
        } else if (error) {
            this.objectActionList = undefined;
            this.dispatchEvent(SLVHelper.createToast('error', error, 'Error Retrieving Org Wide Descriptions', 'There was an error retrieving the org wide descriptions ', true));
        }
    }

    @wire(getComponentDescriptions, {})
    wiredComponentDescriptions({ error, data }) {
        if (data) {
            console.log('simpliUIListViewsStart CALLOUT - getComponentDescriptions - ' + this.calloutCount++);
            console.log('Get Component Descriptions called successfully - ' + data);
            this.compDescs = data;
        } else if (error) {
            this.objectActionList = undefined;
            this.dispatchEvent(SLVHelper.createToast('error', error, 'Error Retrieving Component Descriptions', 'There was an error retrieving the component descriptions ', true));
        }
    }

    @wire(getListViewDescriptions, {})
    wiredListViewsDescriptions({ error, data }) {
        if (data) {
            console.log('simpliUIListViewsStart CALLOUT - getListViewDescriptions - ' + this.calloutCount++);
            console.log('Get List View Descriptions called successfully - ' + data);
            this.listViewDescs = data;
        } else if (error) {
            this.objectActionList = undefined;
            this.dispatchEvent(SLVHelper.createToast('error', error, 'Error Retrieving List View Descriptions', 'There was an error retrieving the list view descriptions ', true));
        }
    }

    getConfig() {
        this.spinner = true;
        console.log('simpliUIListViewsStart CALLOUT - getOrgWideConfig - ' + this.calloutCount++);
        getOrgWideConfig()
            .then(result => {
                console.log('Org wide config retrieved successfully - ' + result);
                this.hasConfig = true;
                this.config = result;
                this.spinner = false;
            })
            .catch(error => {
                this.dispatchEvent(SLVHelper.createToast('error', error, 'Processing Error', 'There was an error handling the config - ', true));
                this.hasConfig = false;
                this.isInitialized = false;
                this.spinner = false;
            });
    }
}
/* eslint-disable no-console */
import { LightningElement, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import * as SLVHelper from 'c/simpliUIListViewsHelper';

//------------------------ LABELS ------------------------
import Parameter_Name from '@salesforce/label/c.Parameter_Name';
import Value from '@salesforce/label/c.Value';
import Select_A_Value from '@salesforce/label/c.Select_A_Value';
import Available from '@salesforce/label/c.Available';
import Selected from '@salesforce/label/c.Selected';
import Save from '@salesforce/label/c.Save';
import List_Views_Cleaned from '@salesforce/label/c.List_Views_Cleaned';
import List_Views_Click_For_Cleaning from '@salesforce/label/c.List_Views_Click_For_Cleaning';
import Clean from '@salesforce/label/c.Clean';
import Clean_List_Views from '@salesforce/label/c.Clean_List_Views';
import Cleaning_Status from '@salesforce/label/c.Cleaning_Status';
import List_View_Cleaning_Complete from '@salesforce/label/c.List_View_Cleaning_Complete';
import List_Views_Click_For_Cleaning_Verbage from '@salesforce/label/c.List_Views_Click_For_Cleaning_Verbage';

import getOrgWideConfig from '@salesforce/apex/ListViewAdminController.getOrgWideConfig';
import saveOrgWideConfig from '@salesforce/apex/ListViewAdminController.saveOrgWideConfig';
import getObjectNames from '@salesforce/apex/ListViewAdminController.getObjectNames';
import cleanListViews from '@salesforce/apex/ListViewAdminController.cleanListViews';
import clearCache from '@salesforce/apex/ListViewAdminController.clearCache';

export default class SimpliUIListViewsAdmin extends NavigationMixin(LightningElement) {

    @track hasConfig = true;            //indicates whether the global config exists in the org
    @track config = undefined;
    @track parameters = new Map();      //holds the map of field/value parameter data
    @track spinner = false;             //identifies if the PAGE spinner should be displayed or not.
    @track objNamesList = undefined;
    @track isInitialized = false;               //indicates whether the list views have been initialized for the first time or not.
    @track showProgress = false;                //indicates whether the progress bar should be displayed
    @track showCleanProgress = false;           //indicates whether the cleaning job progress bar should be displayed
    @track showCreateActionWizardModal = false; //indicates whether the create action wizard modal should be displayed
    @track batchId = '';                        //indicates the batch Id of the list view batch process.
    @track excListViewsStrChanged = false;      //indicates that the excluded list views str has changed.

    get booleanList() {
        return [
            { label: 'Yes', value: 'true' },
            { label: 'No', value: 'false' },
        ];
    }

    label = {
        Parameter_Name, Value, Select_A_Value, Available, Selected, Save, List_Views_Cleaned, List_Views_Click_For_Cleaning,
        Clean, Clean_List_Views, Cleaning_Status, List_View_Cleaning_Complete, List_Views_Click_For_Cleaning_Verbage
    }

    renderedCallback() {
        console.log('SimpliUIListViewsAdmin.renderedCallback started');

        if (this.config === undefined && this.hasConfig === true) {
            console.log('Starting getConfig()');
            this.getConfig();
        }

    }

    handleInitializedCheck(event) {
        try {
            const { detail } = event;
            this.isInitialized = detail;
        } catch (error) {
            SLVHelper.showErrorMessage(error);
        }
    }

    @wire(getObjectNames, {})
    wiredObjectListViews(wiredObjectListViewsResult) {
        this.spinnerOn();
        console.log('Starting getObjectNames');
        const { data, error } = wiredObjectListViewsResult;
        if (data) {
            console.log('Object names retrieval successful');
            this.objNamesList = data;
            console.log('Object names size - ' + this.objNamesList.length);
            this.spinnerOff();
        } else if (error) {
            this.listViewList = undefined;
            this.spinnerOff();
            this.dispatchEvent(SLVHelper.createToast('error', error, 'Error Retrieving Object Names', 'There was an error retrieving all object names - ', true));
        }
        console.log('Finished getObjectNames');
    }

    getConfig() {
        this.spinnerOn();
        this.hasConfig = true;
        console.log('simpliUIListViewsAdmin CALLOUT - getOrgWideConfig - ' + this.calloutCount++);
        getOrgWideConfig()
            .then(result => {
                console.log('Org wide config retrieved successfully - ' + result);
                this.config = result;
            })
            .catch(error => {
                this.dispatchEvent(SLVHelper.createToast('error', error, 'Processing Error', 'There was an error handling the config - ', true));
                this.hasConfig = false;
                this.isInitialized = false;

            }).finally(() => {
                this.spinnerOff();
            });
    }

    handleSaveClick() {
        if (this.parameters.size === 0) return;

        this.spinnerOn();

        let isConfirmed = true;
        if (this.excListViewsStrChanged === true) {
            // eslint-disable-next-line no-restricted-globals, no-alert
            isConfirmed = confirm("The Excluded List Views parameter was updated. This will force deletion of those core ListViewAnything list views that match the provided value.\n\n Click to confirm or cancel to go back!");
        }

        if (isConfirmed === true) {

            let resultStr;
            let valuesMap = new Map();
            let strValuesMap;


            //get all the externally named values into a JSON string
            for (let [k, v] of this.parameters) {
                console.log('Adding key/value pair - (' + k + ',' + v + ')');
                valuesMap.set(k, v);
            }

            strValuesMap = JSON.stringify(Array.from(valuesMap));
            console.log('Field/Value  - ' + strValuesMap);

            console.log('simpliUIListViewsAdmin CALLOUT - saveOrgWideConfig - ' + this.calloutCount++);
            saveOrgWideConfig({ paramStr: strValuesMap })
                .then(result => {
                    resultStr = result;

                    //get the status
                    let status = resultStr.substring(0, resultStr.indexOf(':'));

                    //get any associated message
                    let message = resultStr.substring(resultStr.indexOf(':') + 1);
                    if (message === '' && status === 'Ok') {
                        message = 'All configuration has been saved successfully.';
                    } else if (message === '' && status !== 'Ok') {
                        message = 'There was an error saving the configuration.';
                    }

                    if (status === 'Ok') {
                        this.dispatchEvent(SLVHelper.createToast('success', '', 'Save Successful!', message, false));
                        this.getConfig();

                    } else {
                        this.dispatchEvent(SLVHelper.createToast('error', '', 'Processing Error', message, false));
                        this.spinnerOff();
                    }
                })
                .catch(error => {
                    resultStr = undefined;
                    this.dispatchEvent(SLVHelper.createToast('error', error, 'Processing Error', 'There was an error saving the admin config - ', true));
                    this.spinnerOff();

                });
        } else {
            this.spinnerOff();
        }

    }

    //called when a user clicks the button to refresh the list views.
    handleCleanListViewsButtonClick() {

        this.spinnerOn();
        console.log('Listview cleaning button clicked and updating all list views');

        console.log('simpliUIListViewsAdmin CALLOUT - cleanListViews - ' + this.calloutCount++);
        cleanListViews({})
            .then(result => {
                //if we have an error then send an ERROR toast.
                if (result === 'failed') {
                    this.dispatchEvent(SLVHelper.createToast('success', '', 'Processing Error', 'There was an error cleaning the list views - ', true));
                    //else send a SUCCESS toast.
                } else {
                    this.batchId = result;
                    this.showCleanProgress = true;
                    this.dispatchEvent(SLVHelper.createToast('success', '', 'List View Cleaning', 'List view cleaning has started.', false));
                    this.dispatchEvent(new CustomEvent('cleanlistviewclick'));
                }
            })
            .catch(error => {
                this.dispatchEvent(SLVHelper.createToast('error', error, 'Processing Error', 'There was an error cleaning the list views - ', true));

            }).finally(() => {
                this.spinnerOff();
            });
    }

    handleParamUpdate(event) {
        try {
            const { target } = event;
            const { name, value } = target;

            console.log('Handling Param Update (Name/Value) - ' + name + '/' + value);

            this.parameters.set(name, value);

            if (name === 'ExcludedListViews') {
                if (value === '')
                    this.excListViewsStrChanged = false;
                else
                    this.excListViewsStrChanged = true;
            }
        } catch (error) {
            SLVHelper.showErrorMessage(error);
        }
    }

    handleScheduleJobRefreshed() {
        this.getConfig();
    }

    handleConfigCreated(event) {
        try {
            const { detail } = event;
            const { name, status } = detail;
            console.log('NAME - ' + name);
            console.log('STATUS - ' + status);

            if (name === 'createStart')
                this.spinnerOn();
            else if (name === 'createEnd')
                this.getConfig();
            else if (name === 'importStart')
                this.spinnerOn();
            else if (name === 'importEnd') {
                this.spinnerOff();
            }
        } catch (error) {
            SLVHelper.showErrorMessage(error);
        }
    }

    handleClearCacheClick() {
        this.spinnerOn();
        console.log('Listview clear cache button clicked');

        console.log('simpliUIListViewsAdmin CALLOUT - clearCache - ' + this.calloutCount++);
        clearCache({})
            .then(() => {
                this.dispatchEvent(SLVHelper.createToast('success', '', 'ListViewAnything Cache Cleared', '', false));
            })
            .catch(error => {
                this.dispatchEvent(SLVHelper.createToast('error', error, 'Processing Error', 'There was an error clearing the cache - ', true));
            }).finally(() => {
                this.spinnerOff();
            });

    }

    handleImportExportEvent(event) {
        console.log('IMPORT/EXPORT EVENT - ' + event);
        //this.getConfig();
    }

    handleConfigImported() {
        this.getConfig();
    }

    handleCreateActionClicked() {
        this.showCreateActionWizardModal = true;
    }

    handleCreateActionClose() {
        this.showCreateActionWizardModal = false;
    }

    handleCreateActionFinished() {
        this.showCreateActionWizardModal = false;
    }

    spinnerOn() {
        this.spinner = true;
        console.log('Spinner ON');
    }

    spinnerOff() {
        this.spinner = false;
        console.log('Spinner OFF');
    }

}
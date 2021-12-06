import { LightningElement, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

//------------------------ LABELS ------------------------
import List_Views_Initialized from '@salesforce/label/c.List_Views_Initialized';
import List_Views_Need_Initialized from '@salesforce/label/c.List_Views_Need_Initialized';
import Refresh from '@salesforce/label/c.Refresh';
import Refresh_List_Views from '@salesforce/label/c.Refresh_List_Views';
import Parameter_Name from '@salesforce/label/c.Parameter_Name';
import Value from '@salesforce/label/c.Value';
import Select_A_Value from '@salesforce/label/c.Select_A_Value';
import Available from '@salesforce/label/c.Available';
import Selected from '@salesforce/label/c.Selected';
import Save from '@salesforce/label/c.Save';
import Processing_Status from '@salesforce/label/c.Processing_Status';
import List_View_Processing_Complete from '@salesforce/label/c.List_View_Processing_Complete';

import getOrgWideConfig from '@salesforce/apex/ListViewAdminController.getOrgWideConfig';
import saveOrgWideConfig from '@salesforce/apex/ListViewAdminController.saveOrgWideConfig';
import getObjectNames from '@salesforce/apex/ListViewAdminController.getObjectNames';
import updateAllListViews from '@salesforce/apex/ListViewController.updateAllListViews';
import getIsInitialized from '@salesforce/apex/ListViewController.getIsInitialized';

export default class SimpliUIListViewsAdmin extends NavigationMixin(LightningElement) {

    @track config = undefined;
    @track parameters = new Map();       //holds the map of field/value parameter data
    @track spinner = false;             //identifies if the PAGE spinner should be displayed or not.
    @track objNamesList = undefined;
    @track isInitialized = false;               //indicates whether the list views have been initialized for the first time or not.
    @track showProgress = false;        //indicates whether the progress bar should be displayed
    @track batchId = '';                //indicates the batch Id of the list view batch process.

    get booleanList() {
        return [
            { label: 'Yes', value: 'true'},
            { label: 'No', value: 'false'},
        ];
    }

    label = { List_Views_Initialized, List_Views_Need_Initialized, Refresh, Refresh_List_Views, Parameter_Name, Value, Select_A_Value,
              Available, Selected, Save, Processing_Status, List_View_Processing_Complete }

    renderedCallback() {
        console.log('SimpliUIListViewsAdmin.renderedCallback started');
        this.checkInitialized();
        if (this.config === undefined)
        {
            console.log('Starting getConfig()');
            this.getConfig();
        }

    }

    /*
     * Method called when a row is edited and the SAVE button on the row is clicked.
     */
    checkInitialized() {

        getIsInitialized({})
        .then(result => {
            console.log('Is Initialized called successfully - ' + result + ' for ' + this.pageName);
            this.isInitialized = result; 
            if (this.isInitialized === false)
            {
                this.spinner = false; //a special case where we set it directly.
            }
        })
        .catch(error => {
            console.log('Error Detected - ' + error.body.message + ' | ' + error.body.stackTrace + ' for ' + this.pageName);
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error Checking Initialization',
                message: 'There was an error checking for Simpli List Views initialization. Please see an administrator - ' + error.body.message,
                variant: 'error',
                mode: 'sticky'
            }));
        });

    }     

    @wire (getObjectNames, {})
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
            console.log('Error Detected - ' + error.body.message + ' | ' + error.body.stackTrace);
            this.listViewList = undefined; 
            this.spinnerOff(); 
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error Retrieving Object Names',
                message: 'There was an error retrieving all object names. Please see an administrator - ' + error.body.message,
                variant: 'error',
                mode: 'sticky'
            }));
        }
        console.log('Finished getObjectNames'); 
    }
    
    getConfig()
    {
        this.spinnerOn();
        getOrgWideConfig()
        .then(result => {
            console.log('Org wide config retrieved successfully - ' + result);
            this.config = result;
            this.spinnerOff();
        })
        .catch(error => {
            console.log('Error Detected - ' + error.body.message + ' | ' + error.body.stackTrace);
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error Handling User Config',
                message: 'There was an error handling the config. Please see an administrator - ' + error.body.message,
                variant: 'error',
                mode: 'sticky'
            }));
            this.spinnerOff();
        });
    }

    handleSaveClick(event) {
        if (this.parameters.size === 0) return;

        this.spinnerOn();

        var resultStr;
        var valuesMap = new Map();
        var strValuesMap;


        //get all the externally named values into a JSON string
        for (let [k, v] of this.parameters) {
            console.log('Adding key/value pair - (' + k + ',' + v + ')');
            valuesMap.set(k, v);
        }

        strValuesMap = JSON.stringify( Array.from(valuesMap) );
        console.log('Field/Value  - ' + strValuesMap);

        saveOrgWideConfig({ paramStr: strValuesMap})
            .then(result => {
                resultStr = result;

                //get the status
                let status = resultStr.substring(0, resultStr.indexOf(':'));
                
                //get any associated message
                let message = resultStr.substring(resultStr.indexOf(':')+1);
                if (message === '' && status === 'Ok') {
                    message = 'All configuration has been saved successfully.';
                } else if (message === '' && status != 'Ok') {
                    message = 'There was an error saving the configuration.';
                }

                if (status === 'Ok') {
                    this.dispatchEvent(new ShowToastEvent({
                        title: 'Save Successful!',
                        message: message,
                        variant: 'success',
                        mode: 'dismissable'
                    }));
                    this.getConfig();
                
                } else {
                    this.dispatchEvent(new ShowToastEvent({
                        title: 'Processing Error!',
                        message: message,
                        variant: 'error',
                        mode: 'sticky'
                    }));
                    this.spinnerOff();
                    return;
                }
            })
            .catch(error => {
                resultStr = undefined;
                console.log('Error Detected - ' + error.body.message + ' | ' + error.body.stackTrace);

                this.dispatchEvent(new ShowToastEvent({
                    title: 'Processing Error',
                    message: 'There was an error saving the admin config. Please see an administrator - ' + error.body.message,
                    variant: 'error',
                    mode: 'sticky'
                }));
                this.spinnerOff();
                return;
        });

        this.spinnerOff();
    }

    //called when a user clicks the button to refresh the list views.
    handleProcessListViewsButtonClick() {

        this.spinnerOn();
        console.log('Listview process button clicked and updating all list views');

        updateAllListViews({ })
        .then(result => {

            //if we have an error then send an ERROR toast.
            if (result === 'failed')
            {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Processing Error',
                    message: 'There was an error processing the list views. Please see an administrator - ' + error.body.message,
                    variant: 'error',
                    mode: 'sticky'
                }));
                this.spinnerOff();

            //else send a SUCCESS toast.
            } else {

                this.batchId = result;

                this.showProgress = true;

                this.dispatchEvent(new ShowToastEvent({
                    title: 'List View Processing',
                    message: 'List view processing has started for all list views. You must do a full page refresh after completion to see changes.',
                    variant: 'success',
                    mode: 'dismissable'
                }));
                this.dispatchEvent(new CustomEvent('processlistviewclick'));
                this.spinnerOff();
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
            this.spinnerOff();
        });

    }

    handleParamUpdate(event) {
        var name = event.target.name;
        var value = event.target.value;

        console.log('Handling Param Update (Name/Value) - ' + name + '/' + value );

        this.parameters.set(name, value);
    }

    handleScheduleJobRefreshed(event) {
        this.getConfig();
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
import { LightningElement, wire, track, api  } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
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

    renderedCallback() {
        console.log('SimpliUIListViewsAdmin.renderedCallback started');
        if (this.config === undefined)
        {
            console.log('Starting getConfig()');
            this.getConfig();
        }

    }

    @wire (getIsInitialized, { })
    wiredIsInitialized({ error, data }) {
        if (data) { 
            console.log('Is Initialized called successfully - ' + data); 
            this.isInitialized = data; 
            this.error = undefined; 
        } else if (error) { 
            this.error = error; 
            console.log('Error Detected ' + error.message + ' - ' + error.stackTrace); 
            this.objectActionList = undefined; 
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error Checking Initialization',
                message: 'There was an error checking for Simpli List Views initialization. Please see an administrator\n\n' + error.message,
                variant: 'error',
                mode: 'sticky'
            }));
        }
    }

    @wire (getObjectNames, {})
    wiredObjectListViews(wiredObjectListViewsResult) {
        this.spinnerOn();
        console.log('Starting getObjectNames'); 
        const { data, error } = wiredObjectListViewsResult;
        if (data) { 
            console.log('Object names retrieval successful'); 
            this.objNamesList = data; 
            this.error = undefined; 
            console.log('Object names size - ' + this.objNamesList.length); 
            this.spinnerOff(); 
        } else if (error) { 
            this.error = error; 
            console.log('Error Detected ' + error.body.message + ' - ' + error.body.stackTrace); 
            this.listViewList = undefined; 
            this.spinnerOff(); 
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error Retrieving Object Names',
                message: 'There was an error retrieving all object names.',
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
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error Handling User Config',
                message: 'There was an error handling the config. Please see an administrator\n\n' + error.message + '\n\n' + error.stackTrace,
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
                this.error = undefined;

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
                this.error = error;

                this.dispatchEvent(new ShowToastEvent({
                    title: 'Processing Error',
                    message: 'There was an error saving the admin config\n\n' + error.body.message + '\n\n' + error.body.stackTrace,
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
                    message: 'There was an error processing the list views. Please see an administrator',
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
            this.dispatchEvent(new ShowToastEvent({
                title: 'Processing Error',
                message: 'There was an error processing the list views. Please see an administrator\n\n' + error.message,
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

    spinnerOn() {
        this.spinner = true;
        console.log('Spinner ON');
    }

    spinnerOff() {
        this.spinner = false;
        console.log('Spinner OFF');
    }

}
import { LightningElement, track } from 'lwc';
import * as SLVHelper from 'c/simpliUIListViewsHelper';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

//------------------------ METHODS ------------------------
import createGlobalConfig from '@salesforce/apex/ListViewAdminController.createGlobalConfig';
import getConfigExportJSON from '@salesforce/apex/ListViewAdminController.getConfigExportJSON';
import importConfigJSON from '@salesforce/apex/ListViewAdminController.importConfigJSON';

export default class SimpliUIListViewsExportImport extends LightningElement {

    @track calloutCount = 1;            //indicates the number of callouts made for this component
    @track inRenderedCallback = false;
    @track exportJSONStr = '';

    renderedCallback() {
        if (this.inRenderedCallback === false)
        {
            this.inRenderedCallback = true;

            getConfigExportJSON()
            .then(result => {
                this.exportJSONStr = result;
            })
            .catch(error => {
                this.dispatchEvent(SLVHelper.createToast('error', error, 'Error', 'There was an error retrieving the export file - ', true)); 
            });
    
        }
    }

    handleCreateButtonClick(event) {
        this.spinnerOn('createStart');
        console.log('Export/Import CALLOUT - createGlobalConfig - ' + this.calloutCount++);
        createGlobalConfig()
        .then(result => {
            if (result === true)
            {
                this.dispatchEvent(SLVHelper.createToast('success', '', 'Success', 'Global config created successfully.', false)); 
                //this.dispatchEvent(new CustomEvent('created', { detail: {name: 'createEnd', status: 'Ok'}}));
                this.spinnerOff('createEnd');
            }
        })
        .catch(error => {
            this.dispatchEvent(SLVHelper.createToast('error', error, 'Error', 'There was an error creating the config - ', true)); 
            this.spinnerOff('createEnd');
        });

    }

    handleExportButtonClick(event) {
        console.log('Export/Import CALLOUT - getConfigExportJSON - ' + this.calloutCount++);
        var data = new Blob([this.exportJSONStr]);
        event.target.href = URL.createObjectURL(data);    
    }

    async handleImportButtonClick(event) {

        this.spinnerOn('importStart');
        const fileInput = this.template.querySelector('input');

        var reader = new FileReader(); 

        //create the function to import the JSON once its finished reading the file.
        reader.onload = function(){ 
            var text = reader.result;
            importConfigJSON({configStr: text})
            .then(result => {
                console.log('Import result - ' + result);
                dispatchEvent(new CustomEvent('created', { detail: {name: 'importEnd', status: 'Ok', data: result}}));
                if (result.includes('There was an error'))
                {
                    dispatchEvent(new ShowToastEvent({
                        title: 'File import error',
                        message: result,
                        variant: 'error',
                        mode: 'sticky'
                    }));
                } else {
                    dispatchEvent(new ShowToastEvent({
                        title: 'File imported successfully (Object:Success:Failure)',
                        message: result,
                        variant: 'success',
                        mode: 'sticky'
                    }));

                }
            })
            .catch(error => {
                dispatchEvent(SLVHelper.createToast('error', error, 'Error', 'There was an error processing the provided config - ', true)); 
            });
        };
        reader.readAsText(fileInput.files[0]);

        setTimeout(() =>  {this.spinnerOff('importEnd');}, 5000);

    }

    spinnerOn(eventName) {
        this.dispatchEvent(new CustomEvent('created', { detail: {name: eventName, status: 'Ok'}}));
    }

    spinnerOff(eventName) {
        this.dispatchEvent(new CustomEvent('created', { detail: {name: eventName, status: 'Ok'}}));
    }

}
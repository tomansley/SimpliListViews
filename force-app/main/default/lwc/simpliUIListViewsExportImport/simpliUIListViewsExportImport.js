/* eslint-disable no-console */
import { LightningElement, track } from 'lwc';
import * as SLVHelper from 'c/simpliUIListViewsHelper';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

//------------------------ METHODS ------------------------
import createGlobalConfig from '@salesforce/apex/ListViewAdminController.createGlobalConfig';
import getConfigExportJSON from '@salesforce/apex/ListViewAdminController.getConfigExportJSON';
import importConfigJSON from '@salesforce/apex/ListViewAdminController.importConfigJSON';

import Import_Export from '@salesforce/label/c.Import_Export';
import Import_Export_Verbage from '@salesforce/label/c.Import_Export_Verbage';
import Export from '@salesforce/label/c.Export';
import Import from '@salesforce/label/c.Import';
import Create from '@salesforce/label/c.Create';

export default class SimpliUIListViewsExportImport extends LightningElement {

    @track calloutCount = 1;            //indicates the number of callouts made for this component
    @track inRenderedCallback = false;
    @track exportJSONStr = '';

    label = { Import_Export, Import_Export_Verbage, Export, Import, Create };

    renderedCallback() {
        if (this.inRenderedCallback === false) {
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

    handleCreateButtonClick() {
        this.spinnerOn('createStart');
        console.log('Export/Import CALLOUT - createGlobalConfig - ' + this.calloutCount++);
        createGlobalConfig()
            .then(result => {
                if (result === true) {
                    this.dispatchEvent(SLVHelper.createToast('success', '', 'Success', 'Global config created successfully.', false));
                    //this.dispatchEvent(new CustomEvent('created', { detail: {name: 'createEnd', status: 'Ok'}}));
                    this.spinnerOff('createEnd');
                }
            })
            .catch(error => {
                this.dispatchEvent(SLVHelper.createToast('error', error, 'Error', 'Error creating the config ', true));
                this.spinnerOff('createEnd');
            });

    }

    handleExportButtonClick(event) {
        console.log('Export/Import CALLOUT - getConfigExportJSON - ' + this.calloutCount++);
        const data = new Blob([this.exportJSONStr]);
        event.target.href = URL.createObjectURL(data);
    }

    async handleImportButtonClick() {

        this.spinnerOn('importStart');
        const fileInput = this.template.querySelector('input');

        const reader = new FileReader();

        //create the function to import the JSON once its finished reading the file.
        reader.onload = function () {
            var text = reader.result;
            importConfigJSON({ configStr: text })
                .then(result => {
                    console.log('Import result - ' + result);
                    dispatchEvent(new CustomEvent('created', { detail: { name: 'importEnd', status: 'Ok', data: result } }));
                    if (result.includes('There was an error')) {
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

        // eslint-disable-next-line @lwc/lwc/no-async-operation
        setTimeout(() => { this.spinnerOff('importEnd'); }, 5000);

    }

    spinnerOn(eventName) {
        this.dispatchEvent(new CustomEvent('created', { detail: { name: eventName, status: 'Ok' } }));
    }

    spinnerOff(eventName) {
        this.dispatchEvent(new CustomEvent('created', { detail: { name: eventName, status: 'Ok' } }));
    }

}
/* eslint-disable no-console */
import { LightningElement, track, api } from 'lwc';
import * as SLVHelper from 'c/simpliUIListViewsHelper';

import getEmailTemplates from '@salesforce/apex/ListViewActionEmailController.getEmailTemplates';
import getEmailTemplateDetails from '@salesforce/apex/ListViewActionEmailController.getEmailTemplateDetails';
import processEmails from '@salesforce/apex/ListViewActionEmailController.processEmails';

import Create from '@salesforce/label/c.Create';
import Cancel from '@salesforce/label/c.Cancel';
import Save_All_Data from '@salesforce/label/c.Save_All_Data';
import Reset_All_Data from '@salesforce/label/c.Reset_All_Data';
import Send_Email_From_Template from '@salesforce/label/c.Send_Email_From_Template';
import Select_Template from '@salesforce/label/c.Select_Template';
import Email_Templates from '@salesforce/label/c.Email_Templates';
import Record_Count from '@salesforce/label/c.Record_Count';
import Description from '@salesforce/label/c.Description';
import Email_Subject from '@salesforce/label/c.Email_Subject';
import Email_Body from '@salesforce/label/c.Email_Body';
import Send_Emails from '@salesforce/label/c.Send_Emails';



export default class SimpliUIListViewsEmailTemplateModal extends LightningElement {

    @api showModal;                     //whether this modal dialog should be displayed or not.
    @api folderName;                    //the name of the folder containing the email templates to display
    @api recordIds;                     //the record ids of the selected records that are to be used for sending emails
    @api whatIdField;                   //if the template needs a what Id it can be passed in here.

    @track selectedTemplate;            //the selected email template SOBJECT holding email template details.
    @track selectedTemplateName;        //the selected email template name that will be used when sending the emails.
    @track templateList;                //holds the list of email templates that can be chosen from.
    @track spinner = false;
    @track isInitialized = false;
    @track calloutCount = 1;            //indicates the number of callouts made for this component
    @track inRenderedCallback = false;  //indicates whether the rendered callback method is processing
    get recordCount() {                 //count of records provided.
        return this.recordIds.size;
    }

    label = { Create, Cancel, Save_All_Data, Reset_All_Data, Send_Email_From_Template, Select_Template, Email_Templates, Record_Count, Description, Email_Subject, Email_Body, Send_Emails };

    /*
     * Method which gets called after the class has been instantiated
     * but before it is rendered. We do have access to variables in this method.
     */
    async renderedCallback() {

        console.log('Starting simpliUIListViewsEmailTemplateModal.renderedCallback for MassCreateModal');

        if (this.showModal && this.inRenderedCallback === false) {
            this.inRenderedCallback = true;
            this.getEmailTemplates();
        }
    }

    handleClose() {
        this.dispatchEvent(new CustomEvent('close'));
    }

    handleCancelClick() {
        this.dispatchEvent(new CustomEvent('close'));
    }

    getEmailTemplates() {
        if (this.folderName !== '') {
            this.spinnerOn();
            console.log('simpliUIListViewsEmailTemplateModal CALLOUT - getEmailTemplates - ' + this.calloutCount++);
            getEmailTemplates({ folderName: this.folderName })
                .then(result => {

                    this.templateList = result;

                    if (this.templateList.length === 0) {
                        this.dispatchEvent(SLVHelper.createToast('error', '', 'No Email Templates Available', 'No email templates available in the specified email folder(' + this.folderName + ')', false));
                    }
                })
                .catch(error => {
                    this.dispatchEvent(SLVHelper.createToast('error', error, 'Processing Error', 'There was an error retrieving the email templates - ', true));
                }).finally(() => this.spinnerOff());
        }
    }

    async handleTemplateChange(event) {
        this.spinnerOn();
        try {
            const { target } = event;
            this.selectedTemplateName = target.value ?? '';
            const result = await getEmailTemplateDetails({ devName: this.selectedTemplateName });
            if (result) {
                this.selectedTemplate = result;
            }
        } catch (error) {
            this.dispatchEvent(SLVHelper.createToast('error', error, 'Processing Error', 'There was an error retrieving the chosen email template - ', true));
        } finally {
            this.spinnerOff();
        }
    }

    handleProcessClick() {

        this.spinnerOn();

        if (this.selectedTemplateName !== undefined) {
            let selectedRecordIdsStr = JSON.stringify(Array.from(this.recordIds));

            console.log('simpliUIListViewsEmailTemplateModal CALLOUT - processEmails - ' + this.calloutCount++);
            processEmails({ templateDevName: this.selectedTemplateName, whatId: this.whatIdField, recordIdsStr: selectedRecordIdsStr })
                .then(result => {
                    if (result.endsWith(':success')) {
                        this.dispatchEvent(SLVHelper.createToast('success', '', 'Success', this.recordCount + ' email(s) processed successfully.', false));
                        this.handleClose();
                    } else if (result.endsWith(':submitted')) {
                        this.dispatchEvent(SLVHelper.createToast('success', '', 'Submitted', this.recordCount + ' email(s) submitted for processing.', false));
                        this.handleClose();
                    } else {
                        this.dispatchEvent(SLVHelper.createToast('error', '', 'Processing Error', 'There was an error processing the emails - ' + result, false));
                    }
                })
                .catch(error => {
                    this.dispatchEvent(SLVHelper.createToast('error', error, 'Processing Error', 'There was an error processing the emails - ', true));
                }).finally(() => this.spinnerOff());

        }
    }


    spinnerOn() {
        this.spinner = true;
        console.log('Spinner ON  for MassCreateModal');
    }

    spinnerOff() {
        this.spinner = false;
        console.log('Spinner OFF  for MassCreateModal');
    }

}
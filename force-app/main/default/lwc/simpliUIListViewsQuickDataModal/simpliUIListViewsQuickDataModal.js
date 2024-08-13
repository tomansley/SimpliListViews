/* eslint-disable no-console */
import { LightningElement, api, track } from 'lwc';
import * as SLVHelper from 'c/simpliUIListViewsHelper';

export default class SimpliUIListViewsQuickDataModal extends LightningElement {

    @api type;
    @api heading;
    @api fieldLabel;
    @api okLabel;
    @api cancelLabel;
    @api showModal;
    @api fieldValue;
    @api fieldType = 'string';
    @api fieldName;
    _fieldDataId = '';
    @api get fieldDataId() { return this._fieldDataId; }
    set fieldDataId(value) {
        if (!SLVHelper.isEmpty(value)) {
            this._fieldDataId = value;
            this.sfdcId = this._fieldDataId.split(':')[0];
        }
    }
    @api objectName;

    @track sfdcId = '';
    @track isInitialized = false;
    @track isString = true;
    @track isRichText = false;
    @track isTextArea = false;
    @track isMultiSelect = false;

    renderedCallback() {
        console.log('SimpliUIListViewsQuickDataModal.renderedCallback starting');
        console.log('this.showModal - ' + this.showModal);
        console.log('this.isInitialized - ' + this.isInitialized);
        if (this.showModal && !this.isInitialized) {
            if (this.cancelLabel === undefined)
                this.cancelLabel = 'Cancel';

            if (this.okLabel === undefined)
                this.okLabel = 'Ok';

            this.isTextArea = false;
            this.isString = false;
            this.isRichText = false;
            this.isMultiSelect = false

            if (this.fieldType === 'string') {
                this.isString = true;
            } else if (this.fieldType === 'textarea') {
                this.isTextArea = true;
            } else if (this.fieldType === 'rich textarea') {
                this.isRichText = true;
            } else if (this.fieldType === 'multipicklist') {
                this.isMultiSelect = true;
            }
            this.isInitialized = true;
        }
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        setTimeout(() => this.setComponentFocus(), 200);
        console.log('------ Quick Data Component Logging ------');
        console.log('Heading       - ' + this.heading);
        console.log('Field Label   - ' + this.fieldLabel);
        console.log('Row Id        - ' + this.fieldDataId);
        console.log('Field Type    - ' + this.fieldType);
        console.log('Field Value   - ' + this.fieldValue);
        console.log('Field Name    - ' + this.fieldName);
        console.log('Object Name   - ' + this.objectName);
        console.log('isInitialized - ' + this.isInitialized);

    }

    setComponentFocus() {
        if (this.isInitialized) {
            if (this.isRichText) {
                this.template.querySelector('lightning-input-rich-text').focus();
            } else if (this.isTextArea) {
                this.template.querySelector('textarea').focus();
            } else if (this.isString) {
                this.template.querySelector('lightning-input').focus();
            } else if (this.isMultiSelect) {
                this.template.querySelector('lightning-dual-listbox').focus();
            }
        }
    }

    resetComponent() {
        this.fieldValue = undefined;
        this.isInitialized = false;
    }

    handleCancelClick() {
        this.dispatchEvent(new CustomEvent('cancel', { detail: { value: undefined, fieldDataId: undefined } }));
        this.resetComponent();
    }

    handleOkClick() {
        this.dispatchEvent(new CustomEvent('ok', { detail: { value: this.fieldValue, fieldDataId: this.fieldDataId, fieldName: this.fieldName } }));
        this.resetComponent();
    }

    handleFieldUpdate(event) {
        if (!SLVHelper.isEmpty(event.target.value)) {
            this.fieldValue = event.target.value;

        } else if (!SLVHelper.isEmpty(event.detail.selectedValue)) {
            this.fieldValue = event.detail.selectedValue;
        }
    }
}
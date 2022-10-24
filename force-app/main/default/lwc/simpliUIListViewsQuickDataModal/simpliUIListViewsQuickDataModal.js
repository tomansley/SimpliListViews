import { LightningElement, api, track} from 'lwc';

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
    @api fieldDataId;

    @track isInitialized = false;
    @track isString = true;
    @track isRichText = false;
    @track isTextArea = false;

    renderedCallback() {
        if (this.showModal && !this.isInitialized)
        {
            if (this.cancelLabel === undefined)
                this.cancelLabel = 'Cancel';

            if (this.okLabel === undefined)
                this.okLabel = 'Ok';

            this.isTextArea = false;
            this.isString = false;
            this.isRichText = false;

            if (this.fieldType === 'string') {
                this.isString = true;
            } else if (this.fieldType === 'textarea') {
                this.isTextArea = true;
            } else if (this.fieldType === 'rich textarea') {
                this.isRichText = true;
            }
            this.isInitialized = true;
        }
        setTimeout(()=>this.setComponentFocus(), 200);

    }

    setComponentFocus() {
        if (this.isInitialized)
        {
            if (this.isRichText) {
                this.template.querySelector('lightning-input-rich-text').focus();
            } else if (this.isTextArea) {
                this.template.querySelector('textarea').focus();
            } else if (this.isString) {
                this.template.querySelector('lightning-input').focus();
            }
        }
    }

    handleCancelClick(event) {
        this.isInitialized = false;
        this.dispatchEvent(new CustomEvent('cancel', { detail: {value: undefined, fieldDataId: undefined}}));
    }

    handleOkClick(event) {
        this.isInitialized = false;
        this.dispatchEvent(new CustomEvent('ok', { detail: {value: this.fieldValue, fieldDataId: this.fieldDataId, fieldName: this.fieldName}}));
    }

    handleFieldUpdate(event) {
        this.fieldValue = event.target.value;
    }
}
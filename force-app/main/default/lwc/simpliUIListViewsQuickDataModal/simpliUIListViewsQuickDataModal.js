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
        console.log('SimpliUIListViewsQuickDataModal.renderedCallback starting');
        console.log('this.showModal - ' + this.showModal);
        console.log('this.isInitialized - ' + this.isInitialized);
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
        console.log('------ Quick Data Component Logging ------');
        console.log('Heading       - ' + this.heading);
        console.log('Field Label   - ' + this.fieldLabel);
        console.log('Row Id        - ' + this.fieldDataId);
        console.log('Field Type    - ' + this.fieldType);
        console.log('Field Value   - ' + this.fieldValue);
        console.log('Field Name    - ' + this.fieldName);
        console.log('isInitialized - ' + this.isInitialized);

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

    resetComponent() {
        this.fieldValue = undefined;
        this.isInitialized = false;
    }

    handleCancelClick(event) {
        this.dispatchEvent(new CustomEvent('cancel', { detail: {value: undefined, fieldDataId: undefined}}));
        this.resetComponent();
    }

    handleOkClick(event) {
        this.dispatchEvent(new CustomEvent('ok', { detail: {value: this.fieldValue, fieldDataId: this.fieldDataId, fieldName: this.fieldName}}));
        this.resetComponent();
    }

    handleFieldUpdate(event) {
        this.fieldValue = event.target.value;
    }
}
import { LightningElement, api, track } from 'lwc';

export default class SimpliUIListViewsHoverDetail extends LightningElement {
    @api recordId;                 //record Id
    @api recordApiName;            //API name of the record
    @api recordLabelName;          //Name of the record
    @api isDisplayed = false;      //identifies if the hover details are being displayed or not.
    @api positionTop;              //identifies the Y coord of the details to be displayed
    @api positionLeft;             //identifies the X coord of the details to be displayed
    iconName = 'standard:account'; //holds the name of the icon displayed in the hover details
 
    renderedCallback() {

        const div = this.template.querySelector('[data-id="hoverDetails"]');
        if (div !== undefined && div !== null && this.recordApiName !== undefined && this.recordApiName !== null)
        {
            div.style.left = this.positionLeft + 'px';
            div.style.top = this.positionTop + 'px';
            this.iconName = 'standard:' + this.recordApiName.toLowerCase();
        }
    }

    handleHoverError(event) {
        this.dispatchEvent(new CustomEvent('error', { detail: this.recordApiName }));
    }
}
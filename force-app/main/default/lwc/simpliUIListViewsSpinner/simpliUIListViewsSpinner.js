import { LightningElement, api } from 'lwc';

export default class SimpliUIListViewsSpinner extends LightningElement {

    @api text = '';
    @api size = 'small'; //small, medium, large
    @api variant = 'base'; //base, brand, inverse
    @api styleClass = '';

    get helpText() {
        return this.text ? this.text : 'Working...';
    }
}
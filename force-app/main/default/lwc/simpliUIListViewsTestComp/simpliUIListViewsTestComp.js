import { LightningElement, track } from 'lwc';

export default class SimpliUIListViewsTestComp extends LightningElement {

    @track selectedAccountId = '';

    handleExample4DataChange(event) {
        console.log('Handling Example 4 Data Change - ' + event.detail.selectedValue);
        this.selectedAccountId = event.detail.selectedValue;
    }
}
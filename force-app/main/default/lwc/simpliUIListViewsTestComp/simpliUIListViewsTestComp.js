import { LightningElement, track } from 'lwc';

export default class SimpliUIListViewsTestComp extends LightningElement {

    @track selectedAccountId = '';
    @track standAlone1ColumnData = '[{"label":"Account Name","columnWidth":"width: 415px;","name":"Name"},{"label":"Account Site","columnWidth":"width: 305px;","name":"Site"},{"label":"Billing State/Province","columnWidth":"width: 294px;","name":"BillingState"},{"label":"Last Modified Date","columnWidth":"width: 175px;","name":"LastModifiedDate"},{"label":"Active","columnWidth":"width: 90px;","name":"Active"}]';
    @track standAlone1RowData = '[{"fields":[{"value":"Express Logistics and Transport","isString":true},{"value":"Other Site 1","isString":true},{"value":"TX","isString":true},{"value":"1673989622000","isDate":true},{"value":"No","isPicklist":true}]},{"fields":[{"value":"Express Logistics and Transport","isString":true},{"value":"Other Site 1","isString":true},{"value":"TX","isString":true},{"value":"1673989622000","isDate":true},{"value":"No","isPicklist":true}]}]';

    handleExample4DataChange(event) {
        console.log('Handling Example 4 Data Change - ' + event.detail.selectedValue);
        this.selectedAccountId = event.detail.selectedValue;
    }
}
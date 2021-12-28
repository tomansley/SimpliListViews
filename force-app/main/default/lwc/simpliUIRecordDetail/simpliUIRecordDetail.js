/* eslint-disable vars-on-top */
/* eslint-disable no-console */
import { LightningElement, wire, track } from 'lwc';
import  LISTVIEW_MC  from '@salesforce/messageChannel/SimpliListViewMessageChannel__c';
import { subscribe, unsubscribe, APPLICATION_SCOPE, MessageContext } from 'lightning/messageService';

export default class simpliUIRecordDetail extends LightningElement {
        
    @track recordId = '';
    @track objectType = '';
    @track isInitialized = false;

    subscription = null;
    receivedMessage;

    /*
     * Method which gets called after the class has been instantiated
     * but before it is rendered. We do have access to variables in this method.
     */
    async renderedCallback() {
        this.subscribeMC();
    }
    /*
     * Used for handling the message channel
     */
    @wire(MessageContext)
    messageContext;
    
    /*
     * Method which subscribes this component to a defined message channel. This subscription
     * allows the components to send messages to each other.
     */
    subscribeMC() {
        if (this.subscription) {
            return;
        }
        this.subscription = subscribe(this.messageContext, LISTVIEW_MC, 
            (message) => { this.handleMessage(message); },
                         { scope: APPLICATION_SCOPE     });
    }

    /*
     * Method which unsubscribes this component from any channels. 
     * This method will be called automatically by the SFDC framework.
     */
    unsubscribeMC() {
        unsubscribe(this.subscription);
        this.subscription = null;
    }

    /*
     * Called when a component within the same APP as this component sends a message that records
     * have just been selected by that component.
     */
    handleMessage(message) {

        this.receivedMessage = message;
        console.log('simpliUIRecordDetail received a message from ' + this.receivedMessage.uniqueComponentId);

        this.recordId = this.receivedMessage.recordIds;
        this.objectType = this.receivedMessage.objectType;
        this.isInitialized = true;
    }

}
/* eslint-disable no-console */
import { LightningElement, api } from 'lwc';

export default class simpliUIListViewsFlow extends LightningElement {
    @api width;
    @api height;
    @api flowName;
    @api flowParams;
    url;

    connectedCallback() {

        //create an event listener which listens to the iframe for incoming messages. When one is 
        //received if the event is a FINISHED event it passes the message back
        window.addEventListener("message", (event) => {
            console.log('Flow status changed - ' + event.data.flowStatus);
            if (event.data.flowOrigin !== this.url) {
                return;
            }
            if (event.data.flowStatus === 'FINISHED') {
                const moveEvt = new CustomEvent('finish', {
                    detail: {
                        //flowStatus: event.data.flowStatus,
                        //flowParams: event.data.flowParams,
                        flowName: this.flowName
                    }
                });
                this.dispatchEvent(moveEvt);
            }
        });


        let sfIdent = 'force.com';
        this.url = window.location.href.substring(0, window.location.href.indexOf(sfIdent) + sfIdent.length) + '/apex/simpli_lv__simpliUIListViewsFlow?flowName=';
    }

    get finalWidth() {
        let finalWidth = '100%';
        if (this.width !== undefined && this.width !== '') {
            finalWidth = this.width;
        }

        return finalWidth;
    }

    get finalHeight() {
        let finalHeight = '300';
        if (this.height !== undefined && this.height !== '') {
            finalHeight = this.height;
        }

        return finalHeight;
    }

    //method to get the full URL including the ORIGIN and RECORDIDS.
    get fullUrl() {
        let recordIdStr = '';
        this.flowParams.forEach(recordId => {
            if (recordId !== '' && recordId !== undefined)
                recordIdStr = recordIdStr + '"' + recordId + '",';
        });


        if (recordIdStr.startsWith(',')) {
            recordIdStr = recordIdStr.replace(',', '');
        }
        if (recordIdStr.endsWith(',')) {
            recordIdStr = recordIdStr.substring(0, recordIdStr.length - 1);
        }

        if (recordIdStr !== '')
            recordIdStr = '&recordIds=' + encodeURI(recordIdStr);

        let origin = '&origin=' + encodeURI(this.url);
        let finalURL = this.url + this.flowName + recordIdStr + origin;

        console.log('FINAL URL - ' + finalURL);

        return finalURL;
    }
}
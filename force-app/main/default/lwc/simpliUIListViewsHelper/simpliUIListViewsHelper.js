/* eslint-disable no-console */
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

/*
* Method to handle the display of error messages on the screen using a toast.
* @param error        - OBJECT (or string if none) which holds the exception information.
* @param title        - String - the title of the toast to be displayed
* @param message      - String - the message body to be displayed
* @param includeStack - Boolean - indicates whether the stacktrace should be displayed with the message
*/
export function createToast(type, error, title, message, includeStack) {
    let mode = 'sticky';
    if (type === 'success' || type === 'info')
        mode = 'dismissable';

    let errorStr = message;
    if (error !== '' && error.body !== undefined) {
        if (includeStack === true)
            errorStr = message + ' - ' + error.body.message;
        console.log('Error Detected - ' + error.body.message + ' | ' + error.body.stackTrace);
    } else if (error !== '') {
        if (includeStack === true)
            errorStr = message + ' - ' + error.message;
        console.log('Error Detected - ' + error.message + ' | ' + error.stack);
    }

    return new ShowToastEvent({
        title: title,
        message: errorStr,
        variant: type,
        mode: mode
    });
}

export function invokeWorkspaceAPI(methodName, methodArgs) {
    return new Promise((resolve, reject) => {
        const apiEvent = new CustomEvent("internalapievent", {
            bubbles: true,
            composed: true,
            cancelable: false,
            detail: {
                category: "workspaceAPI",
                methodName: methodName,
                methodArgs: methodArgs,
                callback: (err, response) => {
                    if (err) {
                        return reject(err);
                    }
                    return resolve(response);
                }
            }
        });

        window.dispatchEvent(apiEvent);
    });
}

export function isEmpty(str) {
    if (str === undefined || str === null || str === '') return true;
    return false;
}

export function toBool(value) {
    var strValue = String(value).toLowerCase();
    strValue = ((!isNaN(strValue) && strValue !== '0') &&
        strValue !== '' &&
        strValue !== 'null' &&
        strValue !== 'undefined') ? '1' : strValue;
    return strValue === 'true' || strValue === '1' ? true : false
}

export function setFieldTypes(type, obj) {
    if (type === 'boolean') obj.isBoolean = true; else obj.isBoolean = false;
    if (type === 'currency') obj.isCurrency = true; else obj.isCurrency = false;
    if (type === 'date') obj.isDate = true; else obj.isDate = false;
    if (type === 'datetime') obj.isDateTime = true; else obj.isDateTime = false;
    if (type === 'decimal') obj.isDecimal = true; else obj.isDecimal = false;
    if (type === 'double') obj.isDouble = true; else obj.isDouble = false;
    if (type === 'email') obj.isEmail = true; else obj.isEmail = false;
    if (type === 'html') obj.isHTML = true; else obj.isHTML = false;
    if (type === 'image') obj.isImage = true; else obj.isImage = false;
    if (type === 'integer') obj.isInteger = true; else obj.isInteger = false;
    if (type === 'lookup') obj.isLookup = true; else obj.isLookup = false;
    if (type === 'multipicklist') obj.isMultiPicklist = true; else obj.isMultiPicklist = false;
    if (type === 'percent') obj.isPercent = true; else obj.isPercent = false;
    if (type === 'phone') obj.isPhone = true; else obj.isPhone = false;
    if (type === 'picklist') obj.isPicklist = true; else obj.isPicklist = false;
    if (type === 'richtextarea') obj.isRichTextArea = true; else obj.isRichTextArea = false;
    if (type === 'string') obj.isString = true; else obj.isString = false;
    if (type === 'textarea') obj.isTextArea = true; else obj.isTextArea = false;
    if (type === 'time') obj.isTime = true; else obj.isTime = false;
    if (type === 'url') obj.isURL = true; else obj.isURL = false;
    if (type === 'id') obj.isId = true; else obj.isId = false;

    return obj;
}

//-------------------------------------------------------------------------------------------
//PDF TABLES
//-------------------------------------------------------------------------------------------            

export function headRows(fieldMetaData) {
    let headers = [];
    let headerRow = [];
    headers.push(headerRow);
    fieldMetaData.forEach(column => { headerRow.push(column.label); });
    return headers;
}

export function bodyRows(selectedRecordIds, listViewDataRows) {
    var body = []
    listViewDataRows.forEach(row => {

        //if no rows are selected or the Id has been selected.
        if (selectedRecordIds.size === 0 || selectedRecordIds.has(row.salesforceId)) {
            let bodyRow = [];

            for (let i = 0; i < row.fields.length; i++) {
                const field = row.fields[i];
                if (field.isDate || field.isDateTime || field.isTime) {
                    bodyRow.push(field.prettyValue);
                } else {
                    bodyRow.push(field.value);
                }
            }
            body.push(bodyRow)
        }
    });
    return body;
}
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

/*
* Method to handle the display of error messages on the screen using a toast.
* @param error        - OBJECT (or string if none) which holds the exception information.
* @param title        - String - the title of the toast to be displayed
* @param message      - String - the message body to be displayed
* @param includeStack - Boolean - indicates whether the stacktrace should be displayed with the message
*/
export function createToast(type, error, title, message, includeStack) 
{
    let mode = 'sticky';
    if (type === 'success' || type === 'info')
        mode = 'dismissable';

    let errorStr = message;
    if (error != '' && error.body !== undefined)
    {
        if (includeStack === true)
            errorStr = message + ' - ' + error.body.message;
        console.log('Error Detected - ' + error.body.message + ' | ' + error.body.stackTrace);
    } else if (error != '') {
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
            } else {
                return resolve(response);
            }
            }
        }
        });
    
        window.dispatchEvent(apiEvent);
    });
}

export function toBool(value) {
    var strValue = String(value).toLowerCase();
    strValue = ((!isNaN(strValue) && strValue !== '0') &&
        strValue !== '' &&
        strValue !== 'null' &&
        strValue !== 'undefined') ? '1' : strValue;
    return strValue === 'true' || strValue === '1' ? true : false
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
        if (selectedRecordIds.size === 0 || selectedRecordIds.has(row.salesforceId))
        {
            var bodyRow = [];

            for (var i = 0; i < row.fields.length; i++) {
                var field = row.fields[i];
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

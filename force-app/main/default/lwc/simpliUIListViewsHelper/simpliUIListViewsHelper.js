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
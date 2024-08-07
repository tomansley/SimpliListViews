/**
 * @description       : 
 * @author            : tom@ansleyllc.com
 * @last modified on  : 08-02-2024
 * @last modified by  : tom@ansleyllc.com
 * Modifications Log 
 * Ver   Date         Author                       Modification
 * 1.0   10-27-2020   tom@ansleyllc.com   Initial Version
**/
public with sharing class ListViewException extends Exception {

    public static String getExtendedString(Exception e)
    {
        String prefix = e.getMessage() + ' - Type: ' + e.getTypeName() + ' - line: ' + e.getLineNumber() + ' - ' + e.getStackTraceString() + '\n';
        String stackString = '';
        do {
            stackString += e.getMessage() + ' - Type: ' + e.getTypeName() + ' - line: ' + e.getLineNumber() + '\n';
            e = e.getCause();
        } while (e != null);

        return prefix + ' - ' + stackString + '\n';
    }
}
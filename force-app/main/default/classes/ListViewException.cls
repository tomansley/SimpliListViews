/**
 * @description       : 
 * @author            : tom@ansleyllc.com
 * @last modified on  : 10-22-2021
 * @last modified by  : tom@ansleyllc.com
 * Modifications Log 
 * Ver   Date         Author                       Modification
 * 1.0   10-27-2020   tom@ansleyllc.com   Initial Version
**/
public with sharing class ListViewException extends Exception {

    public static String getExtendedString(Exception e)
    {
        return ' - ' + e.getMessage() + ' - line: ' + e.getLineNumber() + ' - ' + e.getStackTraceString();
    }
}
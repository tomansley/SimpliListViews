/**
 * @description       : 
 * @author            : tom.h.ansley@medtronic.com
 * @last modified on  : 08-20-2021
 * @last modified by  : tom.h.ansley@medtronic.com
 * Modifications Log 
 * Ver   Date         Author                       Modification
 * 1.0   10-27-2020   tom.h.ansley@medtronic.com   Initial Version
**/
public with sharing class ListViewException extends Exception {

    public static String getExtendedString(Exception e)
    {
        return ' - ' + e.getMessage() + ' - line: ' + e.getLineNumber() + ' - ' + e.getStackTraceString();
    }
}
public with sharing class ListViewsPicklistController {

    @AuraEnabled
    public static String getRecordTypeId(String recordId)
    {
        System.debug(LoggingLevel.DEBUG, 'Getting record type for record id: ' + recordId);
        return HelperSchema.getRecordTypeId(recordId);
    }


}
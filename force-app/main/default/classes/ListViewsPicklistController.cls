public with sharing class ListViewsPicklistController {

    @AuraEnabled
    public static String getRecordTypeId(String recordId)
    {
        return HelperSchema.getRecordTypeId(recordId);
    }


}
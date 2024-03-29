/*
 * Class to handle the querying and manipulation of meta data information.
 */
global with sharing class HelperMetadata implements Metadata.DeployCallback {
    
    global static Map<String, List_View_Metadata_Type_Name__mdt> metadataTypes = new Map<String, List_View_Metadata_Type_Name__mdt>();

    /*
     * Method which, given the name of the meta data to be retrieved returns the list of CUSTOM metadata.
     * Note that this method returns the data in no specific order. Also, the name that should be 
     * provided to retrieve the meta data comes from the List_View_Metadata_Type_Name__mdt table. The label
     * should be provided. All fields in the table are returned.
       System.debug(LoggingLevel.DEBUG, 'RESULT - ' + HelperMetadata.getMetaData('List View Config Description'));
     */
    public static List<SObject> getCustomMetaData(String name)
    {
        if (metadataTypes.get(name) == null)
        {
            List<List_View_Metadata_Type_Name__mdt> types = [SELECT MasterLabel, DeveloperName, Metadata_API_Name__c FROM List_View_Metadata_Type_Name__mdt WHERE MasterLabel = :name LIMIT 2000];
            
            if (types.size() == 0) throw new HelperMetadataException('Cannot find requested metadata with name - ' + name + '. Please add an entry in the custom metadata type called Metadata Type Name (Metadata_Type_Name__mdt)');
                        
            metadataTypes.put(name, types[0]);
        }
        
        //we build the SOQL query to get the data based on the returned API information.        
        Map<String, Schema.SObjectField> objFields = HelperSchema.getFieldsForObject(metadataTypes.get(name).Metadata_API_Name__c, HelperSchema.NAME);

        String soql = 'SELECT ' + String.escapeSingleQuotes(String.join(new List<String>(objFields.keySet()), ',')) + ' FROM ' + String.escapeSingleQuotes(metadataTypes.get(name).Metadata_API_Name__c);
        
        System.debug(LoggingLevel.FINE, 'Metadata SOQL - ' + soql);

        HelperSchema.checkObjectAccessible(metadataTypes.get(name).Metadata_API_Name__c); 

        List<SObject> metaData = Database.query(soql);
        
        return metaData;
    }
      
    /*
     * DEPRECATED
     */
    global static List<SObject> getMetaData(String name) { return null; }
    global static SObject getMetaData(String name, String masterlabel) { return null; }
    global static String getOrgWideSettingValue(String name, String valueIfNull) { return null; }
    global static void setOrgWideSettingValue(String recordName, String value) { }
    public void handleResult(Metadata.DeployResult result, Metadata.DeployCallbackContext context) { }
    

    global class HelperMetadataException extends Exception { }

}
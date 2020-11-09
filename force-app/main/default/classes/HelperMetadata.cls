/*
 * Class to handle the querying and manipulation of meta data information.
 */
global with sharing class HelperMetadata implements Metadata.DeployCallback {
    
    global static Map<String, List_View_Metadata_Type_Name__mdt> metadataTypes = new Map<String, List_View_Metadata_Type_Name__mdt>();

    /*
     * DEPRECATED
     * 
     * Method which, given the name of the meta data to be retrieved returns the list of meta data.
     * Note that this method returns the data in no specific order. Also, the name that should be 
     * provided to retrieve the meta data comes from the List_View_Metadata_Type_Name__mdt table. The label
     * should be provided. All fields in the table are returned.
       System.debug(LoggingLevel.DEBUG, 'RESULT - ' + HelperMetadata.getMetaData('simpli_lv__List_View_Org_Wide_Setting__mdt'));
     */
    global static List<SObject> getMetaData(String name)
    {
                
        //we build the SOQL query to get the data based on the returned API information.        
        Map<String, Schema.SObjectField> objFields = HelperSchema.getFieldsForObject(name, HelperSchema.NAME);
        
        String soql = 'SELECT ' + String.escapeSingleQuotes(String.join(new List<String>(objFields.keySet()), ',')) + ' FROM ' + name;
        
        List<SObject> metaData = Database.query(soql);
        
        return metaData;

    }
        
    /*
     * DEPRECATED
     * 
     * Method which, given the name of the meta data to be retrieved and the MasterLabel of the 
     * particular metadata row returns the single meta data record if there is a match. Note that 
     * the name that should be provided to retrieve the meta data comes from the 
     * List_View_Metadata_Type_Name__mdt table. The label should be provided. All fields in the table are returned.
     */
    global static SObject getMetaData(String name, String masterlabel)
    {
        /*
        SObject record = null;
        
        List<SObject> metaData = getMetaData(name);
        
        for (SObject obj: metaData)
        {
            if (obj.get('MasterLabel') == masterLabel)
            {
                record = obj;
                break;
            }
        }
        
        return record;
        */
        return null;
    }
    
    /*
     * DEPRECATED
     */
    global static String getOrgWideSettingValue(String name, String valueIfNull)
    {
        return null;
    }
        
    /*
     * DEPRECATED
     */
    global static void setOrgWideSettingValue(String recordName, String value)
    {
    }

    /*
     * DEPRECATED
     */
    public void handleResult(Metadata.DeployResult result, Metadata.DeployCallbackContext context) {
    }
    
    global class HelperMetadataException extends Exception { }

}
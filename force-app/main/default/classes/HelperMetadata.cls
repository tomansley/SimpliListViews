/*
 * Class to handle the querying and manipulation of meta data information.
 */
global with sharing class HelperMetadata {
    
    global static Map<String, List_View_Metadata_Type_Name__mdt> metadataTypes = new Map<String, List_View_Metadata_Type_Name__mdt>();

    /*
     * Method which, given the name of the meta data to be retrieved returns the list of meta data.
     * Note that this method returns the data in no specific order. Also, the name that should be 
     * provided to retrieve the meta data comes from the List_View_Metadata_Type_Name__mdt table. The label
     * should be provided. All fields in the table are returned.
     */
    global static List<SObject> getMetaData(String name)
    {
        
        if (metadataTypes.get(name) == null)
        {
            List<List_View_Metadata_Type_Name__mdt> types = [SELECT MasterLabel, DeveloperName, Metadata_API_Name__c FROM List_View_Metadata_Type_Name__mdt WHERE MasterLabel = :name];
            
            if (types.size() == 0) throw new HelperMetadataException('Cannot find requested metadata with name - ' + name + '. Please add an entry in the custom metadata type called Metadata Type Name (List_View_Metadata_Type_Name__mdt)');
                        
            metadataTypes.put(name, types[0]);
        }
        
        //we build the SOQL query to get the data based on the returned API information.        
        Map<String, Schema.SObjectField> objFields = HelperSchema.getFieldsForObject(metadataTypes.get(name).Metadata_API_Name__c, HelperSchema.NAME);
        
        String soql = 'SELECT ' + String.escapeSingleQuotes(String.join(new List<String>(objFields.keySet()), ',')) + ' FROM ' + String.escapeSingleQuotes(metadataTypes.get(name).Metadata_API_Name__c);
        
        List<SObject> metaData = Database.query(soql);
        
        return metaData;
    }
        
    /*
     * Method which, given the name of the meta data to be retrieved and the MasterLabel of the 
     * particular metadata row returns the single meta data record if there is a match. Note that 
     * the name that should be provided to retrieve the meta data comes from the 
     * List_View_Metadata_Type_Name__mdt table. The label should be provided. All fields in the table are returned.
     */
    global static SObject getMetaData(String name, String masterlabel)
    {
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
    }
    
    /*
     * Method which, given the name of a usage setting returns the value as a string.
     * This is a convenience method to specifically handle general usage application settings.
     */
    global static String getOrgWideSettingValue(String name, String valueIfNull)
    {
        String value = null;

        List<List_View_Org_Wide_Setting__mdt> metaData = (List<List_View_Org_Wide_Setting__mdt>) getMetaData('List View Org Wide Setting');
        
        for (List_View_Org_Wide_Setting__mdt obj: metaData)
        {
            if (obj.MasterLabel == name)
            {
                value = String.valueOf(obj.Value__c);
                break;
            }
        }

        //this allows us to handily specify a value if its null
        if (value == null)
            value = valueIfNull;

        return value;
    }
        
    global class HelperMetadataException extends Exception { }

}
public with sharing class ListViewActionUpdate  extends ListViewAction {

    public ListViewActionUpdate() {

    }

    public override String process(List<String> recordIds, Map<String, Object> fieldValues)
    {
        String returnStr = ListViewAction.RESULT_OK;

        try {

            if (recordIds == null || recordIds.size() == 0) return ListViewAction.RESULT_OK;

            System.debug(LoggingLevel.DEBUG, 'Record Ids Size   - ' + recordIds.size());
            System.debug(LoggingLevel.DEBUG, 'Record Ids        - ' + recordIds);
            System.debug(LoggingLevel.DEBUG, 'Field Values Size - ' + fieldValues.size());
            System.debug(LoggingLevel.DEBUG, 'Field Values      - ' + fieldValues);

            //get the type of object from the provided Ids
            String objType = HelperSchema.getObjectTypeFromId((String) recordIds[0]);

            //get an apex Type of the object type
            Type t = Type.forName(objType);

            Map<String, SObject> updatedObjs = new Map<String, SObject>();
            for (String recordId: recordIds)
            {

                //create a new instance
                SObject obj = (SObject) t.newInstance();

                //set the Id
                obj.put('Id', recordId);

                //set all the other fields on the update
                for (String fieldName: fieldValues.keySet())
                {
                    if (fieldValues.get(fieldName) != null && ((String) fieldValues.get(fieldName)) != '')
                        obj.put(fieldName, fieldValues.get(fieldName));
                }
            
                updatedObjs.put(recordId, obj);
            }

            //security review
            HelperSchema.checkObjectUpdateable(objType);
            for (String fieldName: fieldValues.keySet())
                HelperSchema.checkObjectFieldUpdateable(objType, fieldName);

            update updatedObjs.values();

        } catch (Exception e) {
            returnStr = e.getMessage();
        }
        
        return returnStr;
    }
    
}
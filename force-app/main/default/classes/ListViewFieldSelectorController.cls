public with sharing class ListViewFieldSelectorController {

    /**
    * @description Method to get the object field data for a given obj
    * @author  | 04-08-2022 
    * @param   String objName the API object name 
    * @return   List<FieldSelectOption> the list of fields with metadata
    **/
    @AuraEnabled
    public static List<FieldSelectOption> getObjectFieldData(String objName)
    {
        System.debug(LoggingLevel.DEBUG, 'Starting ListViewFieldSelectorController.getObjectFieldData()');
        List<FieldSelectOption> fieldOptions = new List<FieldSelectOption>();

        Map<String, Schema.SObjectField> fields = HelperSchema.getFieldsForObject(objName, HelperSchema.NAME);

        for (Schema.SObjectField field: fields.values())
        {
            Schema.DescribeFieldResult fieldDesc = field.getDescribe();
            System.debug(LoggingLevel.DEBUG, 'Starting field - ' + fieldDesc.getName());
            
            //if we have a field referencing an object
            if (fieldDesc.getRelationshipName() != null)
            {
                String type = 'Object';
                String label = fieldDesc.getLabel() + ' >';
                String value = fieldDesc.getRelationshipName();

                if (fieldDesc.getReferenceTo().size() > 0)
                {
                    String relObj = fieldDesc.getReferenceTo()[0].getDescribe().getName();

                    FieldSelectOption option = new FieldSelectOption(value, label, type);
                    option.relationshipObj = relObj;
                    fieldOptions.add(option);
                }
                
            } else {
                String type = 'Field';
                String label = fieldDesc.getLabel();
                String value = fieldDesc.getName();
                FieldSelectOption option = new FieldSelectOption(value, label, type);
                option.relationshipObj = '';
                fieldOptions.add(option);
            }
        }

        HelperString.debug(fieldOptions, 'Field Options');

        fieldOptions.sort();

        return fieldOptions;
    }

    /* 
    * Have to build our own SelectOption object as Lightning cannot use System.SelectOption
    */
    public class FieldSelectOption implements Comparable 
    {
        @AuraEnabled
        public String label { get;set; }
        @AuraEnabled
        public String value { get;set; }
        @AuraEnabled
        public String type { get;set; }
        @AuraEnabled
        public String relationshipObj { get;set; }

        public FieldSelectOption(String value, String label, String type) 
        {
            this.value = value;
            this.label = label;
            this.type  = type;
        }

        public Integer compareTo(Object compareTo) {
            FieldSelectOption option2 = (FieldSelectOption) compareTo;
            return label.compareTo(option2.label);
        }
    }


}
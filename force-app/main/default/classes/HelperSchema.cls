/**
 * @File Name          : HelperSchema.cls
 * @Description        : 
 * @Author             : tom@ansleyllc.com
 * @Group              : 
 * @Last Modified By   : tom@ansleyllc.com
 * @Last Modified On   : 11-09-2021
 * @Modification Log   : 
 * Ver       Date            Author          Modification
 * 1.0    06/11/2020   tom@ansleyllc.com     Initial Version
 * 2.0    07/27/2020   tom@ansleyllc.com     Added getAllObjectNames(), beefed up getValueForField() to correctly handle null values, added isEditable field to the field wrapper.
 * 3.0    08-02-2021   tom@ansleyllc.com     Added getFieldData(Map<String, Object>, String, String) method for Tooling API
 * 4.0    08-19-2021   tom@ansleyllc.com     Added getObjectPluralName(String) method, added getFieldLabel(String, String)
 * 5.0    10-19-2021   tom@ansleyllc.com     Added getAllObjectsByName() method, resolved null pointer exception with getObjectLabel(String)
 * 5.0    10-27-2021   tom@ansleyllc.com     Added getSFDCFieldLabel() method, resolved issue where getting column labels from first row and no data returns empty column name
 **/
public with sharing class HelperSchema {

	public static Map<String, Schema.SObjectType> objectDescribeByName = new Map<String, Schema.SObjectType>();
	public static Map<String, Schema.SObjectType> objectDescribeByPrefix = new Map<String, Schema.SObjectType>();
	public static Map<String, Map<String, Schema.SObjectField>> objectDescribeFieldsByObjectNameAndKey = new Map<String, Map<String, Schema.SObjectField>>();

	public static final String LABEL = 'label';
    public static final String NAME = 'name';
    public static final String DOMAIN_NAME = 'simpli_lv__';

    public static final String ACCESSIBLE = 'accessible';
    public static final String CREATABLE  = 'creatable';
    public static final String DELETABLE  = 'deletable';
    public static final String MERGEABLE  = 'mergeable';
    public static final String QUERYABLE = 'queryable';
    public static final String SEARCHABLE = 'searchable';
    public static final String UNDELETABLE = 'undeletable';
    public static final String UPDATEABLE = 'updateable';

    public static Map<String, Schema.SObjectType> getAllObjectsByName() 
    {
		Map<String,Schema.SobjectType> describe = Schema.getGlobalDescribe();

        return describe;
    }

	/*
	 * Method to get an SObject's type from its Id.
	 */
	public static String getSObjectTypeFromId(Id id)
	{
		return id.getSObjectType().getDescribe().getName();
	}

	/*
	 * Method to return the object that a given objects field looks up to. For example, if the 
	 * obj = User and the field = ProfileId the value returned will be "Profile"
        System.debug(LoggingLevel.FINE, 'RESULT - ' + HelperSchema.getFieldLookupObject('Account', 'LastModifiedById'));

	 */
	public static String getFieldLookupObject(String obj, String field)
	{

		initSObjectSchema(obj);

		Schema.SObjectField fieldSchema = getFieldByKey(obj, field, NAME);

		if (fieldSchema == null) throw new ListViewException('Cannot find provided field - ' + obj + '.' + field + '. Please ensure to use field API name, not label name');

		Schema.DescribeFieldResult fDescribe = fieldSchema.getDescribe();

		//if (fDescribe != null) throw new ListViewException('FDescribe - ' + fDescribe);

		String objString = null;
		
		if (!fDescribe.getReferenceTo().isEmpty())
			objString = fDescribe.getReferenceTo()[0].getDescribe().getName();
		else {
			objString = obj;
		}

		return objString;

	}

	/*
	 * Method to return a describe result for a given object and field.
       System.debug(LoggingLevel.FINE, 'RESULT - ' + HelperSchema.getFieldDescribeResult('Account','LastModifiedBy'));  
	 */
	public static Schema.DescribeFieldResult getFieldDescribeResult(String obj, String field)
	{
        System.debug(LoggingLevel.FINE, 'getFieldDescribeResult(' + obj + ', ' + field + ')');
        Schema.DescribeFieldResult result = null;
        
        initSObjectSchema(obj);

        //see if there is a regular field name
        Schema.SObjectField sField = getFieldByKey(obj, field, NAME);

        //see if there is a field with an Id at the end. i.e. ContactId
        if (sField == null)
            sField = getFieldByKey(obj, field + 'Id', NAME);
        
        //see if there is a lookup field name
        if (sField == null)
            sField = getFieldByKey(obj, field.removeEnd('__r') + '__c', NAME);

        if (sField != null)
             result = sField.getDescribe();

            //see if we are working with a relationship field
        if (result == null)
        {
            List<Schema.ChildRelationship> relationships = getObjectSchema(obj).getChildRelationships();

            for (Schema.ChildRelationship relationship: relationships)
            {
                if (relationship.getRelationshipName() == field)
                {
                    result = getFieldDescribeResult(relationship.getChildSObject().getDescribe().getName(), field);
                }
            }
        }

		return result;
	}

    /**
    * @description Method to get a map of all object names and API names
    * @author tom@ansleyllc.com | 07-07-2021 
    **/
    public static Map<String, String> getAllObjectNames() 
    {
        Map<String, String> objMap = new Map<String, String>();
        for (Schema.SObjectType o : Schema.getGlobalDescribe().values() )
        {
            Schema.DescribeSObjectResult objResult = o.getDescribe();
            if (!objResult.getLabel().contains('__MISSING LABEL__') //REALLY?
                && !objResult.getLabel().contains('__History')
                && !objResult.getLabel().contains('__ChangeEvent')
                && !objResult.getLabel().contains('__Share')) 
                objMap.put(objResult.getName(), objResult.getLabel());   
        }

        return objMap;
    }

	/*
	 * Method that returns the describe result of an SObject.
    
       System.debug(LoggingLevel.FINE, 'RESULT - ' + HelperSchema.getObjectSchema('simpli_lv__List_View_Org_Wide_Setting__mdt'));
       System.debug(LoggingLevel.FINE, 'RESULT - ' + HelperSchema.getObjectSchema('Bogus'));
	 
     */
	public static Schema.DescribeSObjectResult getObjectSchema(String name)
	{
        Schema.DescribeSObjectResult result = null;
		initSObjectSchema(name);
        Schema.SObjectType objType = objectDescribeByName.get(name);
        if (objType != null)
            result = objType.getDescribe();
        
        return result;
    }
    
	public static String getObjectPluralName(String objName)
	{
		return getObjectSchema(objName).getLabelPlural();
    }
    
	public static String getObjectLabel(String objName)
	{
        Schema.DescribeSObjectResult result = getObjectSchema(objName);
        if (result != null)
    		return result.getLabel();
        else
            return '';
    }
    
    /*
       System.debug(LoggingLevel.FINE, 'FAKE RESULT - ' + HelperSchema.isObject('Fake Object'));
       System.debug(LoggingLevel.FINE, 'FAKE RESULT - ' + HelperSchema.isObject('ApexLog'));
     */
    public static Boolean isObject(String objName)
    {
        Boolean isObject = false;
		initSObjectSchema(objName);

        if (objectDescribeByName.get(objName) != null)
            isObject = true;

        return isObject;
    }

	/*
	 * Returns the API object type for a provided lookup field name. Currently
	 * this method does not work with hierarchical field names 
	 * 
	 * Method will return an empty string if the field is not a lookup field.
	 * 
	  System.debug(LoggingLevel.FINE, 'RESULT 1 - ' + HelperSchema.getObjectTypeForField('Contact', 'Name'));
	  System.debug(LoggingLevel.FINE, 'RESULT 2 - ' + HelperSchema.getObjectTypeForField('Contact', 'AccountId'));
	 */
	public static String getObjectTypeForField(String obj, String field)
	{
		String objType = '';

		Schema.SObjectField fieldSchema = getFieldByKey(obj, field, NAME);

		List <Schema.SObjectType> sObjTypes = fieldSchema.getDescribe().getReferenceTo();

		if (!sObjTypes.isEmpty())
			objType = sObjTypes[0].getDescribe().getName();

		return objType;
	}

	/*
	 * Returns the API object name based on a provided Id. Record IDs are prefixed 
	 * with three-character codes that specify the type of the object (for example, 
	 * accounts have a prefix of 001 and opportunities have a prefix of 006). 
     
       System.debug(LoggingLevel.DEBUG, 'RESULT - ' + HelperSchema.getObjectTypeFromId('00G3h000000GElpEAG')); //Group
	 */
	public static String getObjectTypeFromId(Id objId)
	{
		if (objectDescribeByPrefix.isEmpty())
			initObjectDescribeByPrefix();

		return objectDescribeByPrefix.get(String.valueOf(objId).substring(0,3)).getDescribe().getName();
	}

	public static String getObjectType(SObject obj)
	{
		return obj.getSObjectType().getDescribe().getName();
    }
    
    public static Schema.SObjectField getFieldSchema(String obj, String field)
    {
        return getFieldByKey(obj, field, NAME);
    }
	
	public static String getFieldLabel(String obj, String field)
	{
		String label = '';
		Schema.SObjectField objField = getFieldByKey(obj, field, NAME);
		
		if (objField != null)
			label = objField.getDescribe().getLabel();
		
		return label;
		
    }
    
	public static Schema.DisplayType getFieldType(String obj, String field)
	{
		
		Schema.DisplayType fieldType = null;
		
		Schema.SObjectField objField = getFieldByKey(obj, field, NAME);
		
		if (objField != null)
			fieldType = objField.getDescribe().getType();
		
		return fieldType;
		
    }
    
 	/*
	 * Method which, given an object type and field will convert the provided value into the 
	 * correct object based on the provided fields type.
	 */
	public static Object getValueForField(String obj, String field, String value)
	{
        System.debug(LoggingLevel.FINE, 'Starting getValueForField - ' + obj + '/' + field + '/' + value);
		Object objValue = null;
		Schema.DisplayType displayType = getFieldType(obj, field);

		if (displayType != null)
		{
			if (displayType == Schema.DisplayType.Boolean) return Boolean.valueOf(value);
			else if (displayType == Schema.DisplayType.Double) { 
                                                                if (String.isEmpty(value)) return null;
                                                                objValue = Double.valueOf(value);
                                                                }
			else if (displayType == Schema.DisplayType.Base64) return Blob.valueOf(value);
			else if (displayType == Schema.DisplayType.Currency) {
                                                                    if (String.isEmpty(value)) return null;
                                                                    objValue = Double.valueOf(value);
                                                                 } 
			else if (displayType == Schema.DisplayType.Date) { 
                                                                 if (String.isEmpty(value)) return null;
                                                                 objValue = Date.valueOf(value);
                                                             }
			else if (displayType == Schema.DisplayType.Integer) {
                                                                    if (String.isEmpty(value)) return null;
                                                                    objValue = Integer.valueOf(value);
                                                                }
			else if (displayType == Schema.DisplayType.Percent) { 
                                                                    if (String.isEmpty(value)) return null;
                                                                    objValue = Double.valueOf(value);
                                                                }
			else if (displayType == Schema.DisplayType.DateTime) { 
                                                                    if (String.isEmpty(value)) return null;
                                                                    objValue = DateTime.valueOfGmt(value.replace('T', ' ').remove('.000Z')); //2021-07-21 20:45:00
                                                                 }
			else if (displayType == Schema.DisplayType.Time) { 
                                                                    if (String.isEmpty(value)) return null;
                                                                    objValue = Time.newInstance(Integer.valueOf(value.substring(0, 2)), 
                                                                                                Integer.valueOf(value.substring(3, 5)),
                                                                                                Integer.valueOf(value.substring(6, 8)), 
                                                                                                Integer.valueOf(value.substring(9).removeEnd('Z'))); //03:15:00.000
                                                                 }
            else objValue = value;		 
		}
        System.debug(LoggingLevel.FINE, 'Finished getValueForField - ' + obj + '/' + field + '/' + objValue);

		return objValue;
	}

	/*
	 * Method which, given an object API name and a field label or name returns the schema of the field.
      System.debug(LoggingLevel.FINE, 'Field Data - ' + HelperSchema.getFieldByKey('Account', 'LastModifiedBy', HelperSchema.NAME));
	 */
	public static Schema.SObjectField getFieldByKey(String obj, String key, String keyType)
	{

        //initialize if necessary
		initSObjectSchema(obj);

		//get the fields of the object in question
		Map<String, Schema.SObjectField> fieldsByKeyType = objectDescribeFieldsByObjectNameAndKey.get(obj + ':' + keyType);

        //get the field by key
        Schema.SObjectField field = fieldsByKeyType.get(key.toLowerCase());

		return field;
		
	}
	
	/*
	 * Method which given an object API name returns those fields that are available for the object.
	 * The returned map has its keys based on either the fields Label or Name, depending on the 
	 * provided keyType.
       System.debug(LoggingLevel.FINE, 'RESULT - ' + HelperSchema.getFieldsForObject('simpli_lv__List_View_Org_Wide_Setting__mdt', HelperSchema.NAME));
       Map<String, Schema.SObjectField> fields = HelperSchema.getFieldsForObject('Account', HelperSchema.NAME);
       for (Schema.SObjectField field: fields.values())
            System.debug(LoggingLevel.FINE, 'FIELD - ' + field);
	 */
	public static Map<String, Schema.SObjectField> getFieldsForObject(String obj, String keyType)
	{
		//initialize if necessary
		initSObjectSchema(obj);
		
		return objectDescribeFieldsByObjectNameAndKey.get(obj + ':' + keyType);

    }
    
    /*
     * Debugging method to show fields by key type
     */
    @TestVisible
    private static String getObjectFieldDebug(String obj, String keyType, Map<String, Schema.SObjectField> fieldsByKeyType)
    {
		String debug = '\n-----------------------------------------------\n';
		debug += 'OBJ      - ' + obj + '\n';
		debug += 'KEY TYPE - ' + keyType + '\n\n';
		for (String key: fieldsByKeyType.keySet())
			debug += 'KEY - ' + key + ', VALUE - ' + fieldsByKeyType.get(key) + '\n';
		debug += '-----------------------------------------------\n';

		return debug;
    }

	/*
	 * Method to determine if a given object and field name is valid.
       System.debug(LoggingLevel.FINE, 'Result ' + HelperSchema.isValidSFDCFieldName('Contact', 'Email'));
	 */
	public static String getSFDCFieldLabel(String objName, String sfdcFieldName)
	{
        if (objName == null || sfdcFieldName == null) throw new ListViewException('An object (' + objName + ') and field (' + sfdcFieldName + ') name must be provided when using getSFDCFieldLabel() method');
        String label = '';
		try {

            //initialize if necessary
            initSObjectSchema(objName);

            //scrub the field of weird stuff like spaces and toLabel() etc.
			sfdcFieldName = scrubFieldName(sfdcFieldName);

            //split field into parts.
			List<String> fieldHierarchy = sfdcFieldName.split('\\.');
            System.debug(LoggingLevel.FINE, 'Field Hierarchy - ' + fieldHierarchy);

            String objType = objName;
            Schema.DescribeSObjectResult objDescribe = HelperSchema.getObjectSchema(objType);

			for (String field: fieldHierarchy)
			{
                System.debug(LoggingLevel.FINE, 'Current Field - ' + field);
                System.debug(LoggingLevel.FINE, 'Current Object - ' + objType);
                
				//if we are at the last field then get the value and return
				if (fieldHierarchy.indexOf(field) == fieldHierarchy.size()-1)
				{
					//get the object type                    
                    System.debug(LoggingLevel.FINE, 'Last Field!');
                    
                    Schema.SObjectField objField = HelperSchema.getFieldByKey(objType, field, NAME);
                    if (objField != null)
                    {
                        label = objField.getDescribe().getLabel();
                        break;
                    }
        

				//if we are not at the last field then get the fields object
				} else {
                    
                    //get all field metadata
                    Schema.DescribeFieldResult fieldDesc = HelperSchema.getFieldDescribeResult(objType,field);
                    
                    //use the REAL name to determine fields lookup object
                    objType = HelperSchema.getFieldLookupObject(objType, fieldDesc.getName());
				}
			}

        } catch (Exception e) {
            ListViewErrorHelper.createFutureUsageError('Exception during HelperSchema.getSFDCFieldLabel(' + objName + ',' + sfdcFieldName + ') ' + ListViewException.getExtendedString(e));
            label = '';
        }

        System.debug(LoggingLevel.FINE, 'Field label result for ' + objName + '/' + sfdcFieldName + ' is ' + label);
		return label;
		
	}

    /*
	 * Method to determine if a given object and field name is valid.
       System.debug(LoggingLevel.FINE, 'Result ' + HelperSchema.isValidSFDCFieldName('Contact', 'Email'));
	 */
	public static Boolean isValidSFDCFieldName(String objName, String sfdcFieldName)
	{
        if (objName == null || sfdcFieldName == null) return false;
        Boolean isValid = false;
		try {

            //initialize if necessary
            initSObjectSchema(objName);

            //scrub the field of weird stuff like spaces and toLabel() etc.
			sfdcFieldName = scrubFieldName(sfdcFieldName);

            //split field into parts.
			List<String> fieldHierarchy = sfdcFieldName.split('\\.');
            System.debug(LoggingLevel.FINE, 'Field Hierarchy - ' + fieldHierarchy);

            String objType = objName;
            Schema.DescribeSObjectResult objDescribe = HelperSchema.getObjectSchema(objType);

			for (String field: fieldHierarchy)
			{
                System.debug(LoggingLevel.FINE, 'Current Field - ' + field);
                System.debug(LoggingLevel.FINE, 'Current Object - ' + objType);
                
				//if we are at the last field then get the value and return
				if (fieldHierarchy.indexOf(field) == fieldHierarchy.size()-1)
				{
					//get the object type                    
                    System.debug(LoggingLevel.FINE, 'Last Field!');
                    
                    Schema.SObjectField objField = HelperSchema.getFieldByKey(objType, field, NAME);
                    if (objField != null)
                    {
                        isValid = true;
                        break;
                    }
        

				//if we are not at the last field then get the fields object
				} else {
                    
                    //get all field metadata
                    Schema.DescribeFieldResult fieldDesc = HelperSchema.getFieldDescribeResult(objType,field);
                    
                    //use the REAL name to determine fields lookup object
                    objType = HelperSchema.getFieldLookupObject(objType, fieldDesc.getName());
				}
			}

        } catch (Exception e) {
            ListViewErrorHelper.createFutureUsageError('Exception during HelperSchema.isValidSFDCFieldName(' + objName + ',' + sfdcFieldName + ') ' + ListViewException.getExtendedString(e));
            isValid = false;
        }

        System.debug(LoggingLevel.FINE, 'Field validation result for ' + objName + '/' + sfdcFieldName + ' is ' + isValid);
		return isValid;
		
	}

	/*
	 * Method to determine if a given object name is valid.
	 */
	public static Boolean isValidSFDCObjectName(String sfdcObjectName)
	{
		Boolean isValid = true;
		try {
			List<String> objName = new List<String>();
			objName.add(sfdcObjectName);
			Schema.describeSObjects(objName);
        } catch (Exception e) {
            ListViewErrorHelper.createFutureUsageError('Exception during HelperSchema.isValidSFDCObjectName(' + sfdcObjectName + ') ' + ListViewException.getExtendedString(e)); 
            isValid = false;
        }
		
		return isValid;
		
    }
    
    /*
     * Method which given an sobject and a field name will retrieve
     * the value for the field as well as field information. This data
     * is returned in a structure which includes the following data - 
     * 
	 *	objValue - a pointer to the SObject holding the field
     *  name  - the API name of the field
     *  label - the label of the field
     *  type - the type of the field holding the data value
     *  value - the value of the field.

	 * 
	   Account acc = [SELECT Name, Owner.Name, Owner.Alias, Owner.Profile.Name FROM Account WHERE Name LIKE 'Burling%' LIMIT 1];
	   HelperSchema.FieldData d = HelperSchema.getFieldData(acc, 'Owner.Alias');
	   System.debug(LoggingLevel.FINE, 'Account Name - ' + d.name + ', ' + d.label + ', ' + d.type + ', ' + d.value);
	 * 
     */
    public static FieldData getFieldData(SObject obj, String fieldName)
    {
        System.debug(LoggingLevel.FINE, 'Starting getFieldData(' + fieldName + ', ' + obj + ')');
		FieldData data = null;
        String objValueId = null;
		String label = '';

		try {

			fieldName = scrubFieldName(fieldName);
			
			if (obj == null || fieldName == null || fieldName == '')
				throw new ListViewException('HelperSchema.getFieldData() called with empty values. obj = ' + obj + ', fieldName = ' + fieldName);

			List<String> fieldHierarchy = fieldName.split('\\.');

            System.debug(LoggingLevel.FINE, 'Field Hierarchy - ' + fieldHierarchy);

            SObject currentObj = obj;
            
            String objType = getObjectType(currentObj);

            Schema.DescribeSObjectResult objDescribe = HelperSchema.getObjectSchema(objType);

			for (String field: fieldHierarchy)
			{
                
				//if we are at the last field then get the value and return
				if (fieldHierarchy.indexOf(field) == fieldHierarchy.size()-1)
				{
					//get the object type                    
                    System.debug(LoggingLevel.FINE, 'Object Type - ' + objType);
                    System.debug(LoggingLevel.FINE, 'Field       - ' + field);


					//get the field describe
					Schema.DescribeFieldResult fieldDesc = getFieldDescribeResult(objType, field);

                    //if we do not have a field describe it could be because there is no data in the relationship
					if (fieldDesc == null) {
                        data = new FieldData(field, label, Schema.DisplayType.STRING, '', currentObj);
                        System.debug(LoggingLevel.ERROR, 'Cannot find field with name ' + field + ' for object of type ' + objType);

                    //if there is a field describe then get the label and set the data.
                    } else {

                        if (fieldHierarchy.size() == 1)
						    label = fieldDesc.getLabel();
					    else
						    label = objType + ' ' + fieldDesc.getLabel();

                        data = new FieldData(field, label, fieldDesc.getType(), currentObj.get(field), currentObj);
						data.parentObjType = getObjectType(currentObj);
                        data.objValueId = objValueId;
                        data.isEditable = fieldDesc.isUpdateable();
					}
					
				//if we are not at the last field then get the fields object
				} else {
                    System.debug(LoggingLevel.FINE, 'Not at last field. Current field - ' + field);
                    Boolean isSet = false;

                    System.debug(LoggingLevel.FINE, 'old currentObj - ' + currentObj);

                    Map<String, Object> fieldsToValue = currentObj.getPopulatedFieldsAsMap();

                    if (fieldsToValue.get(field) != null)
                    {
                        Object tmpObj = fieldsToValue.get(field);

                        if (tmpObj instanceof List<SObject>)
                            currentObj = ((List<SObject>) tmpObj)[0];
                        else if (tmpObj instanceof SObject)
                            currentObj = (SObject) tmpObj;
    
                    } else {
                        System.debug(LoggingLevel.FINE, 'No field with name ' + field);
                    }
                    
                    System.debug(LoggingLevel.FINE, 'new currentObj - ' + currentObj);

                    if (currentObj != null)
                    {
                        isSet = true;
                        objType = getObjectType(currentObj);

                        //only provide the Id value if there are only two fields in the hierarchy. i.e. CreatedBy.Name
                        if (objValueId == null && fieldHierarchy.size() == 2)
                        {
                            objValueId = String.valueOf(currentObj.get('Id'));
                        }

                    } else {
                        //we might have a currentObj with no data so it bugs out. But, if this is the case 
                        //and we are trying to retrieve column data that is bad....so we get the label if we can.
                        if (label == '')
                            label = getSFDCFieldLabel(objType, fieldName);
                        data = new FieldData(field, label, Schema.DisplayType.STRING, '', null);
                        data.isChildRel = true;
                        return data;
                    }

				}
			}
        } catch (Exception e) {
            ListViewErrorHelper.createFutureUsageError('Exception during HelperSchema.getFieldData(' + obj + ',' + fieldName + ')  ' + ListViewException.getExtendedString(e)); 
			data = null;
        }
        
        if (data != null)
            System.debug(LoggingLevel.FINE, data.getDebugString());
        
            return data;
    }

    /**
    * @description Method which, given a field name and an object returns the field data.
    *              This method is used for JSON structures returned via API's. For regular
    *              SObjects the getFieldData(SObject, String) method should be used.
    * @author tom@ansleyllc.com | 08-01-2021 
    * @param structure the structure holding the data necessary to find the field value
    * @param fieldName the field name
    * @return FieldData 
    **/
    public static FieldData getFieldData(Map<String, Object> structure, String fieldName, String objType)
    {
        System.debug(LoggingLevel.FINE, 'Starting getFieldData(' + fieldName + ', ' + objType + ', ' + structure + ')');

        FieldData data = null;
        String objValueId = null;
		String label = '';

		try {

			fieldName = scrubFieldName(fieldName);
			
			if (structure == null || fieldName == null || fieldName == '')
				throw new ListViewException('HelperSchema.getFieldData() called with empty values. obj = ' + structure + ', fieldName = ' + fieldName);

			List<String> fieldHierarchy = fieldName.split('\\.');

            System.debug(LoggingLevel.FINE, 'Field Hierarchy - ' + fieldHierarchy);

            Map<String, Object> currentStructure = structure;
            String currentParentObjType = objType;
            
			for (String field: fieldHierarchy)
			{
                
				//if we are at the last field then get the value and return
				if (fieldHierarchy.indexOf(field) == fieldHierarchy.size()-1)
				{

                    System.debug(LoggingLevel.FINE, 'Field - ' + field);
                    System.debug(LoggingLevel.FINE, 'Value - ' + currentStructure.get(field));
                    System.debug(LoggingLevel.FINE, 'Parent Obj - ' + currentParentObjType);

                    data = new FieldData(field, currentStructure.get(field));
                    data.parentObjType = currentParentObjType;

                    //get the Id if this is a lookup to another object
                    if (currentStructure.get('attributes') != null)
                    {
                        System.debug(LoggingLevel.FINE, 'We have attribs!');
                        Map<String, Object> attribs = (Map<String, Object>) currentStructure.get('attributes');
                        String url = (String) attribs.get(ListViewHelper.TYPE_URL);
                        data.objValueId = url.substringAfterLast('/');
                        System.debug(LoggingLevel.FINE, 'Id - ' + data.objValueId);
                    }

				//if we are not at the last field then get the fields object
				} else {
                    System.debug(LoggingLevel.FINE, 'Old structure - ' + currentStructure);
                    currentStructure = (Map<String, Object>) currentStructure.get(field);
                    currentParentObjType = field;
                    System.debug(LoggingLevel.FINE, 'New structure - ' + currentStructure);
				}
			}
        } catch (Exception e) {
            ListViewErrorHelper.createFutureUsageError('Exception during HelperSchema.getFieldData(' + structure + ',' + fieldName + ')  ' + ListViewException.getExtendedString(e)); 
			data = null;
        }
        
        if (data != null)
            System.debug(LoggingLevel.FINE, data.getDebugString());
        
            return data;
    }

    public static void checkObjectPermissions(String objAPIName, String action)
    {
        if (objAPIName == 'Simpli_lv__List_View__c')
        { 
            if (action == CREATABLE) checkListViewCreatable();
            else if (action == UPDATEABLE) HelperSchema.checkListViewUpdateable();
            else if (action == ACCESSIBLE) HelperSchema.checkObjectAccessible(objAPIName);
            else if (action == DELETABLE) checkObjectDeletable('Simpli_lv__List_View__c');
            else throw new ListViewException('No permission check for Simpli_lv__List_View__c with action - ' + action);

        } else if (objAPIName == 'Simpli_lv__List_View_Config__c')
        {
            if (action == CREATABLE) checkListViewConfigsCreatable();
            else if (action == UPDATEABLE) checkListViewConfigsUpdateable();
            else if (action == DELETABLE) checkObjectDeletable('Simpli_lv__List_View_Config__c');
            else throw new ListViewException('No permission check for Simpli_lv__List_View_Config__c with action - ' + action);
        
        }  else if (objAPIName == 'Simpli_lv__List_View_Config_Parameter__c')
        {
            if (action == CREATABLE) checkListViewConfigsCreatable();
            else if (action == UPDATEABLE) checkListViewConfigsUpdateable();
            else if (action == DELETABLE) checkObjectDeletable('Simpli_lv__List_View_Config_Parameter__c');
            else throw new ListViewException('No permission check for Simpli_lv__List_View_Config_Parameter__c with action - ' + action);
        
        }  else if (objAPIName == 'simpli_lv__List_View_Config_Condition__c')
        {
            if (action == CREATABLE) checkListViewConfigsCreatable();
            else if (action == UPDATEABLE) checkListViewConfigsUpdateable();
            else if (action == DELETABLE) checkObjectDeletable('simpli_lv__List_View_Config_Condition__c');
            else throw new ListViewException('No permission check for simpli_lv__List_View_Config_Condition__c with action - ' + action);
        
        } else if (objAPIName == 'Simpli_lv__List_View_Action__c')
        {
            if (action == CREATABLE) checkListViewActionsCreatable();
            else if (action == UPDATEABLE) checkListViewActionsCreatable();
            else if (action == DELETABLE) checkObjectDeletable('Simpli_lv__List_View_Action__c');
            else throw new ListViewException('No permission check for Simpli_lv__List_View_Action__c with action - ' + action);
        
        } else if (objAPIName == 'Simpli_lv__List_View_Action_Parameter__c')
        {
            if (action == CREATABLE) checkListViewConfigsCreatable();
            else if (action == UPDATEABLE) checkListViewConfigsUpdateable();
            else if (action == DELETABLE) checkObjectDeletable('Simpli_lv__List_View_Action_Parameter__c');
            else throw new ListViewException('No permission check for Simpli_lv__List_View_Action_Parameter__c with action - ' + action);
        
        }  else if (objAPIName == 'simpli_lv__List_View_User_Config__c')
        {
            if (action == CREATABLE) checkListViewUserConfigsCreatable();
            else if (action == UPDATEABLE) checkListViewUserConfigsUpdateable();
            else if (action == DELETABLE) checkObjectDeletable('simpli_lv__List_View_User_Config__c');
            else throw new ListViewException('No permission check for simpli_lv__List_View_User_Config__c with action - ' + action);
        
        }else {
            if (action == CREATABLE) HelperSchema.checkObjectCreateable(objAPIName);
            else if (action == UPDATEABLE) HelperSchema.checkObjectUpdateable(objAPIName);
            else if (action == DELETABLE) HelperSchema.checkObjectDeletable(objAPIName);
            else if (action == ACCESSIBLE) HelperSchema.checkObjectAccessible(objAPIName);
            else throw new ListViewException('No permission check for ' + objAPIName + ' with action - ' + action);
            
        }
    }

	private static void checkListViewCreatable()
    {
        HelperSchema.checkObjectCreateable('Simpli_lv__List_View__c');
        HelperSchema.checkObjectFieldCreateable('Simpli_lv__List_View__c', 'Simpli_lv__API_Name__c');
        HelperSchema.checkObjectFieldCreateable('Simpli_lv__List_View__c', 'Simpli_lv__Object_Name__c');
        HelperSchema.checkObjectFieldCreateable('Simpli_lv__List_View__c', 'Simpli_lv__Describe__c');
        HelperSchema.checkObjectFieldCreateable('Simpli_lv__List_View__c', 'OwnerId');
        HelperSchema.checkObjectFieldCreateable('Simpli_lv__List_View__c', 'Simpli_lv__Label__c');
        HelperSchema.checkObjectFieldCreateable('Simpli_lv__List_View__c', 'Simpli_lv__Core_ListView_Columns__c');
        HelperSchema.checkObjectFieldCreateable('Simpli_lv__List_View__c', 'Simpli_lv__Core_ListView_Query__c');
        HelperSchema.checkObjectFieldCreateable('Simpli_lv__List_View__c', 'Simpli_lv__Core_ListView_Id__c');
        HelperSchema.checkObjectFieldCreateable('Simpli_lv__List_View__c', 'Simpli_lv__Primary_Key__c');
    }

	private static void checkListViewUpdateable()
    {
        HelperSchema.checkObjectUpdateable('Simpli_lv__List_View__c');
        HelperSchema.checkObjectFieldUpdateable('Simpli_lv__List_View__c', 'Simpli_lv__API_Name__c');
        HelperSchema.checkObjectFieldUpdateable('Simpli_lv__List_View__c', 'Simpli_lv__Object_Name__c');
        HelperSchema.checkObjectFieldUpdateable('Simpli_lv__List_View__c', 'Simpli_lv__Describe__c');
        HelperSchema.checkObjectFieldUpdateable('Simpli_lv__List_View__c', 'OwnerId');
        HelperSchema.checkObjectFieldUpdateable('Simpli_lv__List_View__c', 'Simpli_lv__Label__c');
        HelperSchema.checkObjectFieldUpdateable('Simpli_lv__List_View__c', 'Simpli_lv__Core_ListView_Columns__c');
        HelperSchema.checkObjectFieldUpdateable('Simpli_lv__List_View__c', 'Simpli_lv__Core_ListView_Query__c');
        HelperSchema.checkObjectFieldUpdateable('Simpli_lv__List_View__c', 'Simpli_lv__Core_ListView_Id__c');
        HelperSchema.checkObjectFieldUpdateable('Simpli_lv__List_View__c', 'Simpli_lv__Primary_Key__c');
    }

	public static void checkListViewAccessible()
    {
        HelperSchema.checkObjectAccessible('Simpli_lv__List_View__c');
        HelperSchema.checkObjectFieldAccessible('Simpli_lv__List_View__c', 'Simpli_lv__API_Name__c');
        HelperSchema.checkObjectFieldAccessible('Simpli_lv__List_View__c', 'Simpli_lv__Object_Name__c');
        HelperSchema.checkObjectFieldAccessible('Simpli_lv__List_View__c', 'Simpli_lv__Describe__c');
        HelperSchema.checkObjectFieldAccessible('Simpli_lv__List_View__c', 'OwnerId');
        HelperSchema.checkObjectFieldAccessible('Simpli_lv__List_View__c', 'Simpli_lv__Label__c');
        HelperSchema.checkObjectFieldAccessible('Simpli_lv__List_View__c', 'Simpli_lv__Core_ListView_Columns__c');
        HelperSchema.checkObjectFieldAccessible('Simpli_lv__List_View__c', 'Simpli_lv__Core_ListView_Query__c');
        HelperSchema.checkObjectFieldAccessible('Simpli_lv__List_View__c', 'Simpli_lv__Core_ListView_Id__c');
        HelperSchema.checkObjectFieldAccessible('Simpli_lv__List_View__c', 'Simpli_lv__Primary_Key__c');
    }

    private static void checkListViewActionsCreatable()
    {
        HelperSchema.checkObjectCreateable('Simpli_lv__List_View_Action__c');
        HelperSchema.checkObjectFieldCreateable('Simpli_lv__List_View_Action__c', 'Simpli_lv__Apex_Class_Name__c');
        HelperSchema.checkObjectFieldCreateable('Simpli_lv__List_View_Action__c', 'Simpli_lv__Label__c');
        HelperSchema.checkObjectFieldCreateable('Simpli_lv__List_View_Action__c', 'Simpli_lv__Object_Type__c');

        HelperSchema.checkObjectCreateable('Simpli_lv__List_View_Action_Parameter__c');
        HelperSchema.checkObjectFieldCreateable('Simpli_lv__List_View_Action_Parameter__c', 'Simpli_lv__Field_API_Name__c');
        HelperSchema.checkObjectFieldCreateable('Simpli_lv__List_View_Action_Parameter__c', 'Simpli_lv__Label__c');
        HelperSchema.checkObjectFieldCreateable('Simpli_lv__List_View_Action_Parameter__c', 'Simpli_lv__List_View_Action__c');
        HelperSchema.checkObjectFieldCreateable('Simpli_lv__List_View_Action_Parameter__c', 'Simpli_lv__Placeholder_Text__c');
        HelperSchema.checkObjectFieldCreateable('Simpli_lv__List_View_Action_Parameter__c', 'Simpli_lv__Type__c');
    }

    public static void checkListViewActionsAccessible()
    {
        HelperSchema.checkObjectAccessible('Simpli_lv__List_View_Action__c');
        HelperSchema.checkObjectFieldAccessible('Simpli_lv__List_View_Action__c', 'Simpli_lv__Apex_Class_Name__c');
        HelperSchema.checkObjectFieldAccessible('Simpli_lv__List_View_Action__c', 'Simpli_lv__Label__c');
        HelperSchema.checkObjectFieldAccessible('Simpli_lv__List_View_Action__c', 'Simpli_lv__Object_Type__c');

        HelperSchema.checkObjectAccessible('Simpli_lv__List_View_Action_Parameter__c');
        HelperSchema.checkObjectFieldAccessible('Simpli_lv__List_View_Action_Parameter__c', 'Simpli_lv__Field_API_Name__c');
        HelperSchema.checkObjectFieldAccessible('Simpli_lv__List_View_Action_Parameter__c', 'Simpli_lv__Label__c');
        HelperSchema.checkObjectFieldAccessible('Simpli_lv__List_View_Action_Parameter__c', 'Simpli_lv__List_View_Action__c');
        HelperSchema.checkObjectFieldAccessible('Simpli_lv__List_View_Action_Parameter__c', 'Simpli_lv__Placeholder_Text__c');
        HelperSchema.checkObjectFieldAccessible('Simpli_lv__List_View_Action_Parameter__c', 'Simpli_lv__Type__c');
    }

    private static void checkListViewConfigsCreatable()
    {
        HelperSchema.checkObjectCreateable('Simpli_lv__List_View_Config__c');
        HelperSchema.checkObjectFieldCreateable('Simpli_lv__List_View_Config__c', 'Name');
        HelperSchema.checkObjectFieldCreateable('Simpli_lv__List_View_Config__c', 'Simpli_lv__List_View_Object__c');

        HelperSchema.checkObjectCreateable('Simpli_lv__List_View_Config_Parameter__c');
        HelperSchema.checkObjectFieldCreateable('Simpli_lv__List_View_Config_Parameter__c', 'Simpli_lv__List_View_Config__c');
        HelperSchema.checkObjectFieldCreateable('Simpli_lv__List_View_Config_Parameter__c', 'Simpli_lv__Parameter_Name__c');
        HelperSchema.checkObjectFieldCreateable('Simpli_lv__List_View_Config_Parameter__c', 'Simpli_lv__Parameter_Type__c');
        HelperSchema.checkObjectFieldCreateable('Simpli_lv__List_View_Config_Parameter__c', 'Simpli_lv__Parameter_Value__c');

        HelperSchema.checkObjectCreateable('simpli_lv__List_View_Config_Condition__c');
        HelperSchema.checkObjectFieldCreateable('simpli_lv__List_View_Config_Condition__c', 'simpli_lv__Field_Name__c');
        HelperSchema.checkObjectFieldCreateable('simpli_lv__List_View_Config_Condition__c', 'simpli_lv__Highlight_Color__c');
        HelperSchema.checkObjectFieldCreateable('simpli_lv__List_View_Config_Condition__c', 'simpli_lv__List_View_Config__c');
        HelperSchema.checkObjectFieldCreateable('simpli_lv__List_View_Config_Condition__c', 'simpli_lv__Operator__c');
        HelperSchema.checkObjectFieldCreateable('simpli_lv__List_View_Config_Condition__c', 'simpli_lv__Order__c');
        HelperSchema.checkObjectFieldCreateable('simpli_lv__List_View_Config_Condition__c', 'simpli_lv__Value__c');

    }

    private static void checkListViewConfigsUpdateable()
    {
        HelperSchema.checkObjectUpdateable('Simpli_lv__List_View_Config__c');
        HelperSchema.checkObjectFieldUpdateable('Simpli_lv__List_View_Config__c', 'Name');
        HelperSchema.checkObjectFieldUpdateable('Simpli_lv__List_View_Config__c', 'Simpli_lv__List_View_Object__c');

        HelperSchema.checkObjectUpdateable('Simpli_lv__List_View_Config_Parameter__c');
        HelperSchema.checkObjectFieldUpdateable('Simpli_lv__List_View_Config_Parameter__c', 'Simpli_lv__List_View_Config__c');
        HelperSchema.checkObjectFieldUpdateable('Simpli_lv__List_View_Config_Parameter__c', 'Simpli_lv__Parameter_Name__c');
        HelperSchema.checkObjectFieldUpdateable('Simpli_lv__List_View_Config_Parameter__c', 'Simpli_lv__Parameter_Type__c');
        HelperSchema.checkObjectFieldUpdateable('Simpli_lv__List_View_Config_Parameter__c', 'Simpli_lv__Parameter_Value__c');

        HelperSchema.checkObjectUpdateable('simpli_lv__List_View_Config_Condition__c');
        HelperSchema.checkObjectFieldUpdateable('simpli_lv__List_View_Config_Condition__c', 'simpli_lv__Field_Name__c');
        HelperSchema.checkObjectFieldUpdateable('simpli_lv__List_View_Config_Condition__c', 'simpli_lv__Highlight_Color__c');
        HelperSchema.checkObjectFieldUpdateable('simpli_lv__List_View_Config_Condition__c', 'simpli_lv__List_View_Config__c');
        HelperSchema.checkObjectFieldUpdateable('simpli_lv__List_View_Config_Condition__c', 'simpli_lv__Operator__c');
        HelperSchema.checkObjectFieldUpdateable('simpli_lv__List_View_Config_Condition__c', 'simpli_lv__Order__c');
        HelperSchema.checkObjectFieldUpdateable('simpli_lv__List_View_Config_Condition__c', 'simpli_lv__Value__c');

    }

    public static void checkListViewConfigsAccessible()
    {
        HelperSchema.checkObjectAccessible('Simpli_lv__List_View_Config__c');
        HelperSchema.checkObjectFieldAccessible('Simpli_lv__List_View_Config__c', 'Name');
        HelperSchema.checkObjectFieldAccessible('Simpli_lv__List_View_Config__c', 'Simpli_lv__List_View_Object__c');

        HelperSchema.checkObjectAccessible('Simpli_lv__List_View_Config_Parameter__c');
        HelperSchema.checkObjectFieldAccessible('Simpli_lv__List_View_Config_Parameter__c', 'Simpli_lv__List_View_Config__c');
        HelperSchema.checkObjectFieldAccessible('Simpli_lv__List_View_Config_Parameter__c', 'Simpli_lv__Parameter_Name__c');
        HelperSchema.checkObjectFieldAccessible('Simpli_lv__List_View_Config_Parameter__c', 'Simpli_lv__Parameter_Type__c');
        HelperSchema.checkObjectFieldAccessible('Simpli_lv__List_View_Config_Parameter__c', 'Simpli_lv__Parameter_Value__c');

        HelperSchema.checkObjectAccessible('simpli_lv__List_View_Config_Condition__c');
        HelperSchema.checkObjectFieldAccessible('simpli_lv__List_View_Config_Condition__c', 'simpli_lv__Field_Name__c');
        HelperSchema.checkObjectFieldAccessible('simpli_lv__List_View_Config_Condition__c', 'simpli_lv__Highlight_Color__c');
        HelperSchema.checkObjectFieldAccessible('simpli_lv__List_View_Config_Condition__c', 'simpli_lv__List_View_Config__c');
        HelperSchema.checkObjectFieldAccessible('simpli_lv__List_View_Config_Condition__c', 'simpli_lv__Operator__c');
        HelperSchema.checkObjectFieldAccessible('simpli_lv__List_View_Config_Condition__c', 'simpli_lv__Order__c');
        HelperSchema.checkObjectFieldAccessible('simpli_lv__List_View_Config_Condition__c', 'simpli_lv__Value__c');

    }

    public static void checkListViewUserConfigsAccessible()
    {
        HelperSchema.checkObjectAccessible('Simpli_lv__List_View_User_Config__c');
        HelperSchema.checkObjectFieldAccessible('Simpli_lv__List_View_User_Config__c', 'simpli_lv__Ltn_Component_Name__c');
        HelperSchema.checkObjectFieldAccessible('Simpli_lv__List_View_User_Config__c', 'simpli_lv__Name__c');
        HelperSchema.checkObjectFieldAccessible('Simpli_lv__List_View_User_Config__c', 'simpli_lv__Primary_Key__c');
        HelperSchema.checkObjectFieldAccessible('Simpli_lv__List_View_User_Config__c', 'simpli_lv__User__c');
        HelperSchema.checkObjectFieldAccessible('Simpli_lv__List_View_User_Config__c', 'simpli_lv__Value__c');

    }

    private static void checkListViewUserConfigsUpdateable()
    {
        HelperSchema.checkObjectUpdateable('Simpli_lv__List_View_User_Config__c');
        HelperSchema.checkObjectFieldUpdateable('Simpli_lv__List_View_User_Config__c', 'simpli_lv__Ltn_Component_Name__c');
        HelperSchema.checkObjectFieldUpdateable('Simpli_lv__List_View_User_Config__c', 'simpli_lv__Name__c');
        HelperSchema.checkObjectFieldUpdateable('Simpli_lv__List_View_User_Config__c', 'simpli_lv__Primary_Key__c');
        HelperSchema.checkObjectFieldUpdateable('Simpli_lv__List_View_User_Config__c', 'simpli_lv__User__c');
        HelperSchema.checkObjectFieldUpdateable('Simpli_lv__List_View_User_Config__c', 'simpli_lv__Value__c');

    }
    
    private static void checkListViewUserConfigsCreatable()
    {
        HelperSchema.checkObjectCreateable('Simpli_lv__List_View_User_Config__c');
        HelperSchema.checkObjectFieldCreateable('Simpli_lv__List_View_User_Config__c', 'simpli_lv__Ltn_Component_Name__c');
        HelperSchema.checkObjectFieldCreateable('Simpli_lv__List_View_User_Config__c', 'simpli_lv__Name__c');
        HelperSchema.checkObjectFieldCreateable('Simpli_lv__List_View_User_Config__c', 'simpli_lv__Primary_Key__c');
        HelperSchema.checkObjectFieldCreateable('Simpli_lv__List_View_User_Config__c', 'simpli_lv__User__c');
        HelperSchema.checkObjectFieldCreateable('Simpli_lv__List_View_User_Config__c', 'simpli_lv__Value__c');

    }
    
	//------------------------------------------------
	// PRIVATE METHODS BELOW
	//------------------------------------------------

	private static void initObjectDescribeByPrefix()
	{
		objectDescribeByPrefix = new Map<String, Schema.SobjectType>();
		Map<String,Schema.SobjectType> describe = Schema.getGlobalDescribe();
		for(String s:describe.keyset())
			objectDescribeByPrefix.put(describe.get(s).getDescribe().getKeyPrefix(), describe.get(s));
	}
    
    private static void initSObjectSchema(String obj)
    {
        initSObjectSchema(obj, true);
    }

	/*
	 * Method to initialize an sobject schema if it hasn't already been initialized. This has a small hack
	 * in it to detect if an object name being requested needs a domain prefix. If it does then it rerequests
	 * the schema. Once the schema is returned it places the schema into the map with both the domain prefix
	 * and without it. This hack ensures that tests will run in both the package dev org and other orgs.
     * HelperSchema.initSObjectSchema('simpli_lv__List_View__c');
     * HelperSchema.initSObjectSchema('');
	 */
	private static void initSObjectSchema(String obj, Boolean allowRecurring)
	{
		//if this object has not been described yet get the data
		if (objectDescribeByName.get(obj) == null)
		{
			System.debug(LoggingLevel.FINE, 'Trying to initialize schema with name - ' + obj);
			Schema.SObjectType objSchema = Schema.getGlobalDescribe().get(obj);
			if (objSchema != null)
			{
				System.debug(LoggingLevel.FINE, 'Found schema with name - ' + obj);
                objectDescribeByName.put(obj, objSchema);
                
                List<Schema.SObjectField> fields = objSchema.getDescribe().fields.getMap().values();

                Map<String,Schema.SObjectField> fieldsByLabel = new Map<String,Schema.SObjectField>();
                Map<String,Schema.SObjectField> fieldsByName = new Map<String,Schema.SObjectField>();

                for (Schema.SObjectField objField: fields)
                {
                    fieldsByName.put(objField.getDescribe().getName().toLowerCase(), objField);
                    fieldsByLabel.put(objField.getDescribe().getLabel().toLowerCase(), objField);
                }
				objectDescribeFieldsByObjectNameAndKey.put(obj + ':' + LABEL, fieldsByLabel);
				objectDescribeFieldsByObjectNameAndKey.put(obj + ':' + NAME, fieldsByName);

				//if schema contain "simpli_lv" then remove and try again (this is the hack)
				if (obj.contains(DOMAIN_NAME))
				{
					objectDescribeByName.put(obj.removeStart(DOMAIN_NAME), objSchema);
    
                    objectDescribeFieldsByObjectNameAndKey.put(obj.removeStart(DOMAIN_NAME) + ':' + LABEL, fieldsByLabel);
                    objectDescribeFieldsByObjectNameAndKey.put(obj.removeStart(DOMAIN_NAME) + ':' + NAME, fieldsByName);
				}

			} else if (allowRecurring) {
				System.debug(LoggingLevel.FINE, 'NO schema with name - ' + obj);
				initSObjectSchema(DOMAIN_NAME + obj, false);
			}
		}
		
	}

	private static String scrubFieldName(String fieldName)
    {
        if (fieldName == null) return fieldName;
        //remove whitespace
        fieldName = fieldName.deleteWhitespace();

        //remove toLabel keyword
        if (fieldName.contains('toLabel(')) fieldName = fieldName.substringBetween('(', ')');
        
        return fieldName;
    }


    //---------------------------------------------------------------------------------
    // ACCESSIBILITY METHODS
    //---------------------------------------------------------------------------------
    public static void checkSelectAccessible(String selectStr) 
    {

        List<String> fields = selectStr.substringBetween('SELECT', 'FROM').split(',');
        
        String objAPIName = null;
        if (!selectStr.containsIgnoreCase('WHERE'))
            objAPIName = selectStr.substringAfter('FROM ');
        else
            objAPIName = selectStr.substringBetween('FROM ', ' WHERE');
        
        HelperSchema.checkObjectAccessible(objAPIName);

        for (String field: fields)
        {
            //do security validation on additional fields. If the field is a lookup the security is performed later
            if (!field.contains('.'))
                HelperSchema.checkObjectFieldAccessible(objAPIName, field);
        }
 
    }

	/*
	 * Method to determine if an SObject field is accessible. This is used
	 * for security to ensure user is allowed to see a field for the given object.
	 */
	public static Boolean checkObjectFieldAccessible(String objName, String fieldName, Boolean throwExc)
	{
		System.debug(LoggingLevel.FINE, 'checkObjectFieldAccessible called with objName - ' + objName + '.' + fieldName.deleteWhitespace());

        fieldName = scrubFieldName(fieldName);

        Schema.DescribeFieldResult fieldDesc = getFieldDescribeResult(objName, fieldName);
		if (fieldDesc != null && fieldDesc.isAccessible()) {
			return true;
		} else {
			if (throwExc)
				throw new ListViewException('Field with name ' + objName + '.' + fieldName + ' is not accessible or does not exist. Please check user permissions');
			return false;
		}
	}

	/*
	 * Method to determine if an SObject field is accessible. This is used
	 * for security to ensure user is allowed to see a field for the given object.
	 */
	public static void checkObjectFieldAccessible(String objName, String fieldName)
	{
		checkObjectFieldAccessible(objName, fieldName, true);
	}

    /*
	 * Method to determine if an SObject field is createable. This is used
	 * for security to ensure user is allowed to set a field for the given object.
	 */
	public static Boolean checkObjectFieldCreateable(String objName, String fieldName, Boolean throwExc)
	{
		System.debug(LoggingLevel.FINE, 'checkObjectFieldCreateable called with objName - ' + objName + '.' + fieldName.deleteWhitespace());

        fieldName = scrubFieldName(fieldName);

		if (getFieldDescribeResult(objName, fieldName).isCreateable()) {
			return true;
		} else {
			if (throwExc)
				throw new ListViewException('Field with name ' + objName + '.' + fieldName.deleteWhitespace() + ' is not creatable or does not exist. Please check user permissions');
			return false;
		}
	}

	/*
	 * Method to determine if an SObject field is createable. This is used
	 * for security to ensure user is allowed to set a field for the given object.
	 */
	public static void checkObjectFieldCreateable(String objName, String fieldName)
	{
		checkObjectFieldCreateable(objName, fieldName, true);
	}

	/*
	 * Method to determine if an SObject field is createable. This is used
	 * for security to ensure user is allowed to set a field for the given object.
	 */
	public static Boolean checkObjectFieldUpdateable(String objName, String fieldName, Boolean throwExc)
	{
		System.debug(LoggingLevel.FINE, 'checkObjectFieldUpdateable called with objName - ' + objName + '.' + fieldName.deleteWhitespace());

        fieldName = scrubFieldName(fieldName);

		if (getFieldDescribeResult(objName, fieldName).isUpdateable()) {
			return true;
		} else {
			if (throwExc)
				throw new ListViewException('Field with name ' + objName + '.' + fieldName + ' is not updateable or does not exist. Please check user permissions');
			return false;
		}
	}

	/*
	 * Method to determine if an SObject field is createable. This is used
	 * for security to ensure user is allowed to set a field for the given object.
	 */
	public static void checkObjectFieldUpdateable(String objName, String fieldName)
	{
		checkObjectFieldUpdateable(objName, fieldName, true);
	}

	/*
	 * Method to determine if an SObject is createable. This is used
	 * for security to ensure user is allowed to create records for the given object.
	 */
	public static Boolean checkObjectCreateable(String objName, Boolean throwExc)
	{
		System.debug(LoggingLevel.FINE, 'checkObjectCreateable called with objName - ' + objName);

		if (getObjectSchema(objName).isCreateable()) {
			return true;
		} else {
			if (throwExc)
				throw new ListViewException('Records of type ' + objName + ' are not creatable by this user or does not exist in this org. Please check user permissions');
			return false;
		}
	}

	/*
	 * Method to determine if an SObject is createable. This is used
	 * for security to ensure user is allowed to create records for the given object.
	 */
	public static void checkObjectCreateable(String objName)
	{
		checkObjectCreateable(objName, true);
	}

	/*
	 * Method to determine if an SObject is accessible. This is used
	 * for security to ensure user is allowed to create records for the given object.
	 */
	public static Boolean checkObjectAccessible(String objName, Boolean throwExc)
	{
		System.debug(LoggingLevel.FINE, 'checkObjectAccessible called with objName - ' + objName);

        //if we are using Tooling API the object might not be in the schema.
		if (getObjectSchema(objName) != null)
        {
            if (getObjectSchema(objName).isAccessible()) {
			    return true;
            }  else {
                if (throwExc)
                    throw new ListViewException('Records of type ' + objName + ' are not accessible. Please check user permissions');
                return false;
            }
		}

        return true;
	}

	/*
	 * Method to determine if an SObject is accessible. This is used
	 * for security to ensure user is allowed to create records for the given object.
	 */
	public static void checkObjectAccessible(String objName)
	{
		checkObjectAccessible(objName, true);
	}

    /*
	 * Method to determine if an SObject is createable. This is used
	 * for security to ensure user is allowed to create records for the given object.
	 */
	public static Boolean checkObjectUpdateable(String objName, Boolean throwExc)
	{
		System.debug(LoggingLevel.FINE, 'checkObjectUpdateable called with objName - ' + objName);

		if (getObjectSchema(objName).isUpdateable()) {
			return true;
		} else {
			if (throwExc)
				throw new ListViewException('Records of type ' + objName + ' are not updateable or do not exist. Please check user permissions');
			return false;
		}
	}

	/*
	 * Method to determine if an SObject is createable. This is used
	 * for security to ensure user is allowed to create records for the given object.
	 */
	public static void checkObjectUpdateable(String objName)
	{
		checkObjectUpdateable(objName, true);
	}

	/*
	 * Method to determine if an SObject is deletable. This is used
	 * for security to ensure data being queried is deletable by the user.
	 */
	public static Boolean checkObjectDeletable(SObject obj, Boolean throwExc)
	{
		System.debug(LoggingLevel.FINE, 'checkObjectDeletable called with obj - ' + obj);

		if (obj == null || obj.Id == null)
			throw new ListViewException('HelperSchema.checkObjectDeletable called with null Object or object with empty Id');

		String objName = getSObjectTypeFromId(obj.Id);

		if (getObjectSchema(objName).isDeletable()) {
			return true;
		} else {
			if (throwExc)
				throw new ListViewException('Records of type ' + objName + ' are not deletable or do not exist. Please check user permissions');
			return false;
		}
	}

	/*
	 * Method to determine if an SObject is deletable. This is used
	 * for security to ensure data being queried is deletable by the user.
	 */
	public static void checkObjectDeletable(SObject obj)
	{
		checkObjectDeletable(obj, true);
	}

	/*
	 * Method to determine if an SObject type is deletable. This is used
	 * for security to ensure data being queried is deletable by the user.
	 */
	public static Boolean checkObjectDeletable(String objName, Boolean throwExc)
	{
		System.debug(LoggingLevel.FINE, 'checkObjectDeletable called with objName - ' + objName);

		if (getObjectSchema(objName).isDeletable()) {
			return true;
		} else {
			if (throwExc)
				throw new ListViewException('Records of type ' + objName + ' are not deletable or do not exist. Please check user permissions');
			return false;
		}
	}
	
	/*
	 * Method to determine if an SObject type is deletable. This is used
	 * for security to ensure data being queried is deletable by the user.
	 */
	public static void checkObjectDeletable(String objName)
	{
		checkObjectDeletable(objName, true);
	}

	//------------------------------------------------
	// INNER CLASSES
	//------------------------------------------------

    public class FieldData 
    {

        public SObject objValue        {get; set;}
        public String parentObjType    {get; set;}
        public String name             {get; set;}
        public String label            {get; set;}
        public Schema.DisplayType type {get; set;}
        public Object value            {get; set;} //holds the string value. i.e. CreatedBy.Name = "Tom Ansley" 
        public String objValueId          {get; set;} //holds the id value if its a lookup. i.e. CreatedBy.Name = 0053h000000xrj3AAA
        public Boolean isChildRel      {get; set;}
        public Boolean isEditable      {get; set;}

        public FieldData(String name, String label, Schema.DisplayType type, Object value, SObject objValue)
        {
			this.objValue      = objValue;
            this.name          = name;
            this.label         = label;
            this.type          = type;
            this.value         = value;
            this.isChildRel    = false;
            this.isEditable    = false;
            this.parentObjType = '';
        }

        public FieldData(String name, Object value)
        {
            this.name          = name;
            this.value         = value;
            this.isChildRel    = false;
            this.isEditable    = false;
            this.parentObjType = '';
        }

        public String getDebugString()
        {
            String debug = '\n\n----------------\n';
            debug += 'objValue      - ' + objValue + '\n';
            debug += 'parentObjType - ' + parentObjType + '\n';
            debug += 'name          - ' + name + '\n';
            debug += 'label         - ' + label + '\n';
            debug += 'type          - ' + type + '\n';
            debug += 'value         - ' + value + '\n';
            debug += 'objValueId    - ' + objValueId + '\n';
            debug += 'isChildRel    - ' + isChildRel + '\n';
            debug += 'isEditable    - ' + isEditable + '\n';
            debug += '----------------\n';

            return debug;
        }
	}
	

}
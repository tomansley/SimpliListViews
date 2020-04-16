public with sharing class HelperSchema {

	public static Map<String, Schema.SObjectType> objectDescribeByName = new Map<String, Schema.SObjectType>();
	public static Map<String, Schema.SObjectType> objectDescribeByPrefix = new Map<String, Schema.SObjectType>();
	public static Map<String, Map<String, Schema.SObjectField>> objectDescribeFieldsByObjectName = new Map<String, Map<String, Schema.SObjectField>>();

	public static final String LABEL = 'label';
    public static final String NAME = 'name';
    public static final String DOMAIN_NAME = 'simpli_lv__';

	/*
	 * Method to get an SObject's type from its Id.
	 */
	public static String getSObjectTypeFromId(Id id)
	{
		return id.getSObjectType().getDescribe().getName();
	}

	/*
	 * Method to determine if an SObject field is createable. This is used
	 * for security to ensure user is allowed to set a field for the given object.
	 */
	public static Boolean checkObjectFieldCreateable(String objName, String fieldName, Boolean throwExc)
	{
		System.debug(LoggingLevel.FINE, 'checkObjectCreateable called with objName - ' + objName + '.' + fieldName);

		if (getFieldDescribeResult(objName, fieldName).isCreateable()) {
			return true;
		} else {
			if (throwExc)
				throw new HelperSchemaException('Field with name ' + objName + '.' + fieldName + ' is not creatable. Please check user permissions');
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
		System.debug(LoggingLevel.FINE, 'checkObjectFieldUpdateable called with objName - ' + objName + '.' + fieldName);

		if (getFieldDescribeResult(objName, fieldName).isUpdateable()) {
			return true;
		} else {
			if (throwExc)
				throw new HelperSchemaException('Field with name ' + objName + '.' + fieldName + ' is not updateable. Please check user permissions');
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
				throw new HelperSchemaException('Object of type ' + objName + ' is not creatable. Please check user permissions');
			return false;
		}
	}

	/*
	 * Method to determine if an SObject is createable. This is used
	 * for security to ensure user is allowed to create records for the given object.
	 */
	public static void checkObjectCreatable(String objName)
	{
		checkObjectCreateable(objName, true);
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
				throw new HelperSchemaException('Object of type ' + objName + ' is not updateable. Please check user permissions');
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
		System.debug(LoggingLevel.DEBUG, 'checkObjectDeletable called with obj - ' + obj);

		if (obj == null || obj.Id == null || obj.Id == '')
			throw new HelperSchemaException('HelperSchema.checkObjectDeletable called with null Object or object with empty Id');

		String objName = getSObjectTypeFromId(obj.Id);

		if (getObjectSchema(objName).isDeletable()) {
			return true;
		} else {
			if (throwExc)
				throw new HelperSchemaException('Object of type ' + objName + ' is not deletable. Please check user permissions');
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
		System.debug(LoggingLevel.DEBUG, 'checkObjectDeletable called with objName - ' + objName);

		if (getObjectSchema(objName).isDeletable()) {
			return true;
		} else {
			if (throwExc)
				throw new HelperSchemaException('Object of type ' + objName + ' is not creatable. Please check user permissions');
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

	/*
	 * Method to return the object that a given objects field looks up to. For example, if the 
	 * obj = User and the field = ProfileId the value returned will be "Profile"
	 */
	public static String getFieldLookupObject(String obj, String field)
	{

		initSObjectSchema(obj);

		Schema.SObjectField fieldSchema = getFieldByKey(obj, field, NAME);

		if (fieldSchema == null) throw new HelperSchemaException('Cannot find provided field - ' + obj + '.' + field + '. Please ensure to use field API name, not label name');

		Schema.DescribeFieldResult fDescribe = fieldSchema.getDescribe();

		//if (fDescribe != null) throw new HelperSchemaException('FDescribe - ' + fDescribe);

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
	 */
	public static Schema.DescribeFieldResult getFieldDescribeResult(String obj, String field)
	{
		initSObjectSchema(obj);

		Schema.SObjectField fieldSchema = getFieldByKey(obj, field, NAME);

        if (fieldSchema == null)
            fieldSchema = getFieldByKey(obj, field + 'Id', NAME);
        
        if (fieldSchema == null)
            fieldSchema = getFieldByKey(obj, field.removeEnd('__r') + '__c', NAME);
            
        if (fieldSchema == null)
            return null;

		return fieldSchema.getDescribe();
	}

	/*
	 * Method that returns the describe result of an SObject.
	 */
	public static Schema.DescribeSObjectResult getObjectSchema(String name)
	{
		initSObjectSchema(name);

		return objectDescribeByName.get(name).getDescribe();
	}

	/*
	 * Returns the API object name based on a provided Id. Record IDs are prefixed 
	 * with three-character codes that specify the type of the object (for example, 
	 * accounts have a prefix of 001 and opportunities have a prefix of 006). 
	 */
	public static String getObjectTypeFromId(Id objId)
	{
		System.debug(LoggingLevel.DEBUG, '@getObjectTypeFromId(' + objId + ')');
		System.debug(LoggingLevel.DEBUG, 'objectDescribeByPrefix.size - ' + objectDescribeByPrefix.size());
		if (objectDescribeByPrefix.isEmpty())
			initObjectDescribeByPrefix();

		return objectDescribeByPrefix.get(String.valueOf(objId).substring(0,3)).getDescribe().getName();
	}

	public static String getObjectType(SObject obj)
	{
		return obj.getSObjectType().getDescribe().getName();
	}

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
			System.debug(LoggingLevel.DEBUG, 'Trying to initialize schema with name - ' + obj);
			Schema.SObjectType objSchema = Schema.getGlobalDescribe().get(obj);
			if (objSchema != null)
			{
				System.debug(LoggingLevel.DEBUG, 'Found schema with name - ' + obj);
				objectDescribeByName.put(obj, objSchema);
				objectDescribeFieldsByObjectName.put(obj, objSchema.getDescribe().fields.getMap());

				//if schema contain "simpli_lv" then remove and try again (this is the hack)
				if (obj.contains(DOMAIN_NAME))
				{
					objectDescribeByName.put(obj.removeStart(DOMAIN_NAME), objSchema);
					objectDescribeFieldsByObjectName.put(obj.removeStart(DOMAIN_NAME), objSchema.getDescribe().fields.getMap());
				}

			} else if (allowRecurring) {
				System.debug(LoggingLevel.DEBUG, 'NO schema with name - ' + obj);
				initSObjectSchema(DOMAIN_NAME + obj, false);
			}
		}
		
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
	public static Object getValueForField(String obj, String key, String keyType, String value)
	{
		Object objValue = null;
		Schema.DisplayType displayType = getFieldType(obj, key);
		if (displayType != null)
		{
			if (displayType == Schema.DisplayType.Boolean) return Boolean.valueOf(value);
			else if (displayType == Schema.DisplayType.Double) return Double.valueOf(value);
			else if (displayType == Schema.DisplayType.Base64) return Blob.valueOf(value);
			else if (displayType == Schema.DisplayType.Currency) return Double.valueOf(value);
			else if (displayType == Schema.DisplayType.Date) return Date.valueOf(value);
			else if (displayType == Schema.DisplayType.DateTime) return DateTime.valueOf(value);
			else if (displayType == Schema.DisplayType.Integer) return Integer.valueOf(value);
			else if (displayType == Schema.DisplayType.Percent) return Double.valueOf(value);
			else return value;		 
		}

		return objValue;
	}

	/*
	 * Method which, given an object API name and a field label or name returns the schema of the field.
	 */
	public static Schema.SObjectField getFieldByKey(String obj, String key, String keyType)
	{
		
		//get the fields of the object in question
		Map<String, Schema.SObjectField> fieldsByKeyType = getFieldsForObject(obj, keyType);
		
		//get the field by key
		Schema.SObjectField field = fieldsByKeyType.get(key.toLowerCase());

		return field;
		
	}
	
	/*
	 * Method which given an object API name returns those fields that are available for the object.
	 * The returned map has its keys based on either the fields Label or Name, depending on the 
	 * provided keyType.
	 */
	public static Map<String, Schema.SObjectField> getFieldsForObject(String obj, String keyType)
	{
		Map<String, Schema.SObjectField> fieldsByKeyType = new Map<String, Schema.SObjectField>();
		
		//initialize if necessary
		initSObjectSchema(obj);
		
		//get the fields of the object in question
		List<Schema.SObjectField> fields = objectDescribeFieldsByObjectName.get(obj).values();
		
		//create a map of fields by name
		for (Schema.SObjectField objField: fields)
		{
			if (keyType == NAME)
				fieldsByKeyType.put(objField.getDescribe().getName().toLowerCase(), objField);
			else if (keyType == LABEL)
				fieldsByKeyType.put(objField.getDescribe().getLabel().toLowerCase(), objField);
		}
		
		String debug = '\n-----------------------------------------------\n';
		debug += 'OBJ      - ' + obj + '\n';
		debug += 'KEY TYPE - ' + keyType + '\n\n';
		for (String key: fieldsByKeyType.keySet())
			debug += 'KEY - ' + key + ', VALUE - ' + fieldsByKeyType.get(key) + '\n';
		debug += '-----------------------------------------------\n';

		System.debug(LoggingLevel.FINE, debug);

		return fieldsByKeyType;
		
	}

	/*
	 * Method to determine if a given object and field name is valid.
	 */
	public static Boolean isValidSFDCFieldName(String objName, String sfdcFieldName)
	{
		Boolean isValid = false;
		try {
			Map<String, Schema.SObjectField> fields = HelperSchema.getFieldsForObject(objName, NAME);
			if (fields.get(sfdcFieldName.toLowerCase()) != null)
				isValid = true;
		} catch (Exception e) {
			isValid = false;
		}

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
			isValid = false;
		}
		
		return isValid;
		
	}

	public class HelperSchemaException extends Exception { }

}
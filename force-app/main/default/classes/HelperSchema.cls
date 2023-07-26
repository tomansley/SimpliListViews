/**
 * @File Name          : HelperSchema.cls
 * @Description        : 
 * @Author             : tom@ansleyllc.com
 * @Group              : 
 * @Last Modified By   : tom@ansleyllc.com
 * @Last Modified On   : 07-26-2023
 * @Modification Log   : 
 * Ver       Date            Author          Modification
 * 1.0    06/11/2020   tom@ansleyllc.com     Initial Version
 * 2.0    07/27/2020   tom@ansleyllc.com     Added getAllObjectNames(), beefed up getValueForField() to correctly handle null values, added isEditable field to the field wrapper.
 * 3.0    08-02-2021   tom@ansleyllc.com     Added getFieldData(Map<String, Object>, String, String) method for Tooling API
 * 4.0    08-19-2021   tom@ansleyllc.com     Added getObjectPluralName(String) method, added getFieldLabel(String, String)
 * 5.0    10-19-2021   tom@ansleyllc.com     Added getAllObjectsByName() method, resolved null pointer exception with getObjectLabel(String)
 * 5.0    10-27-2021   tom@ansleyllc.com     Added getSFDCFieldLabel() method, resolved issue where getting column labels from first row and no data returns empty column name
 * 6.0    12-15-2021   tom@ansleyllc.com     Removed old methods for checking object accessibility.
 * 7.0    12-15-2021   tom@ansleyllc.com     Added getClassType() method.
**/
public with sharing class HelperSchema {

	public static Map<String, Schema.SObjectType> objectDescribeByName = new Map<String, Schema.SObjectType>();
	public static Map<String, Schema.SObjectType> objectDescribeByPrefix = new Map<String, Schema.SObjectType>();
	public static Map<String, Map<String, Schema.SObjectField>> objectDescribeFieldsByObjectNameAndKey = new Map<String, Map<String, Schema.SObjectField>>();
    public static Map<String, String> fieldLabels = new Map<String, String>();
    public static Map<String, Boolean> validFieldNames = new Map<String, Boolean>();
    public static Set<String> objectPermissions = new Set<String>();
    public static Map<String, String> fieldLookupObjs = new Map<String, String>();
    public static Map<String, String> fieldRelType = new Map<String, String>();

	public static final String LABEL       = 'label';
    public static final String NAME        = 'name';
    public static final String DOMAIN_NAME = [SELECT NamespacePrefix FROM Organization].NamespacePrefix + '__';

    public static final String ACCESSIBLE  = 'accessible';
    public static final String CREATABLE   = 'creatable';
    public static final String DELETABLE   = 'deletable';
    public static final String MERGEABLE   = 'mergeable';
    public static final String QUERYABLE   = 'queryable';
    public static final String SEARCHABLE  = 'searchable';
    public static final String UNDELETABLE = 'undeletable';
    public static final String UPDATEABLE  = 'updateable';

    public static final String REL_TYPE_FIELD     = 'field';
    public static final String REL_TYPE_CORE_ID   = 'coreid';
    public static final String REL_TYPE_LOOKUP    = 'lookup';
    public static final String REL_TYPE_CHILD_REL = 'childrel';

    public static Map<String, Schema.SObjectType> getAllObjectsByName() 
    {
		Map<String,Schema.SobjectType> describe = Schema.getGlobalDescribe();

        return describe;
    }

    /*
        System.debug(LoggingLevel.DEBUG, 'RESULT - ' + HelperSchema.getHasRecordTypes('Account'));
        System.debug(LoggingLevel.DEBUG, 'RESULT - ' + HelperSchema.getHasRecordTypes('Opportunity'));
        System.debug(LoggingLevel.DEBUG, 'RESULT - ' + HelperSchema.getHasRecordTypes('Contact'));
        System.debug(LoggingLevel.DEBUG, 'RESULT - ' + HelperSchema.getHasRecordTypes('simpli_lv__List_View__c'));
        System.debug(LoggingLevel.DEBUG, 'RESULT - ' + HelperSchema.getHasRecordTypes('Task'));
        System.debug(LoggingLevel.DEBUG, 'RESULT - ' + HelperSchema.getHasRecordTypes('Event'));
     */
    public static Boolean getHasRecordTypes(String obj)
    {
        Boolean result = false;
        Schema.DescribeSObjectResult objSchema = getObjectSchema(obj);

        for (Schema.RecordTypeInfo rtInfo: objSchema.getRecordTypeInfos())
        {
            if (rtInfo.isActive() && !rtInfo.isMaster())
            {
                result = true;
                break;
            }
        }

        return result;
    }

    public static Id getMasterRecordType(String obj)
    {
        String recordTypeId = null;
        Schema.DescribeSObjectResult objSchema = getObjectSchema(obj);

        for (Schema.RecordTypeInfo rtInfo: objSchema.getRecordTypeInfos())
        {
            if (rtInfo.isActive() && rtInfo.isMaster())
            {
                recordTypeId = rtInfo.getRecordTypeId();
                break;
            }
        }

        return recordTypeId;
    }

    /*
        HelperSchema.getRecordTypeId
     */
    public static String getRecordTypeId(SObject obj)
    {
        String recordTypeId = null;
        String objApiName = obj.getSObjectType().getDescribe().getName();
        Schema.DescribeSObjectResult objSchema = getObjectSchema(objApiName);

        try {
            if (getHasRecordTypes(objApiName))
            {
                recordTypeId = (String) obj.get('RecordTypeId');
                System.debug(LoggingLevel.DEBUG, 'Using PROVIDED record type Id ' + recordTypeId);   
                if (String.isEmpty(recordTypeId))
                {
                    recordTypeId = getMasterRecordType(objApiName);
                    System.debug(LoggingLevel.DEBUG, 'Null record type so falling back to MASTER record type Id ' + recordTypeId);
                }
            } else {
                recordTypeId = getMasterRecordType(objApiName);
                System.debug(LoggingLevel.DEBUG, 'Using MASTER record type Id ' + recordTypeId);
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.DEBUG, 'Record type id field does not exist for ' + obj.getSObjectType().getDescribe().getName());
            recordTypeId = getMasterRecordType(objApiName);
            System.debug(LoggingLevel.DEBUG, 'Using MASTER record type Id ' + recordTypeId);
        }

        System.debug(LoggingLevel.DEBUG, 'Output recordTypeId - ' + recordTypeId);
        return recordTypeId;

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
        System.debug(LoggingLevel.DEBUG, 'Starting getFieldLookupObject(' + obj + ',' + field + ')');

        String objString = null;

        String key = obj + ':' + field;

        objString = fieldLookupObjs.get(key);
        if (!String.isEmpty(objString))
        {
            System.debug(LoggingLevel.DEBUG, 'USED CACHE(getFieldLookupObject)');
            return objString;
        }

		Schema.SObjectField fieldSchema = getFieldByKey(obj, field, NAME);

		if (fieldSchema == null) throw new ListViewException('Cannot find provided field - ' + obj + '.' + field + '. Please ensure to use field API name, not label name');

		Schema.DescribeFieldResult fDescribe = fieldSchema.getDescribe();

		//if (fDescribe != null) throw new ListViewException('FDescribe - ' + fDescribe);
		
		if (!fDescribe.getReferenceTo().isEmpty())
			objString = fDescribe.getReferenceTo()[0].getDescribe().getName();
		else {
			objString = obj;
		}

        fieldLookupObjs.put(key, objString);

		return objString;

	}

    public static String getFieldRelationshipType(String obj, String field)
    {
        System.debug(LoggingLevel.DEBUG, 'Starting getFieldRelationshipType(' + obj + ',' + field + ')');
        
        obj = obj.replace('__r', '__c');

        String relType = null;
        String key = obj + ':' + field;

        relType = fieldRelType.get(key);
        if (!String.isEmpty(relType))
        {
            System.debug(LoggingLevel.DEBUG, 'USED CACHE(getFieldRelationshipType)');
            return relType;
        }

        //see if there is a regular field name
        Schema.SObjectField sField = getFieldByKey(obj, field, NAME);

        if (sField != null)
        {
            relType = REL_TYPE_FIELD;
        
        } else { 

            //see if there is a field with an Id at the end. i.e. ContactId
            sField = getFieldByKey(obj, field + 'Id', NAME);

            if (sField != null)
            {
                relType = REL_TYPE_CORE_ID;
            
            } else {
            
                //see if there is a lookup field name
                sField = getFieldByKey(obj, field.replace('__r', '__c'), NAME);

                if (sField != null)
                {
                    relType = REL_TYPE_LOOKUP;
                } else {
                    List<Schema.ChildRelationship> relationships = getObjectSchema(obj).getChildRelationships();

                    for (Schema.ChildRelationship relationship: relationships)
                    {
                        if (relationship.getRelationshipName() == field)
                        {
                            relType = REL_TYPE_CHILD_REL;
                            break;
                        }
                    }
                }
            }
        }

        fieldRelType.put(key, relType);
        return relType;

    }

	/*
	 * Method to return a describe result for a given object and field.
       System.debug(LoggingLevel.DEBUG, 'RESULT - ' + HelperSchema.getFieldDescribeResult('Account','simpli_lv__Test_Text_Rich__c'));  
	 */
	public static Schema.DescribeFieldResult getFieldDescribeResult(String obj, String field)
	{

        System.debug(LoggingLevel.FINE, 'Starting getFieldDescribeResult(' + obj + ', ' + field + ')');
        Schema.DescribeFieldResult result = null;
        
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
                    result = relationship.getField().getDescribe();
                    break;
                }
            }
        }

        System.debug(LoggingLevel.FINE, 'Ending getFieldDescribeResult(' + result + ')');

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
       Schema.DescribeSObjectResult objDescribeSobject = HelperSchema.getObjectSchema('Event'));
        Map<String, Schema.SObjectField> mapFields = objDescribeSobject.fields.getMap();
        List<Schema.PicklistEntry> lstPickListValues = mapFields.get(strPicklistField).getDescribe().getPickListValues();
        for (Schema.PicklistEntry objPickList : lstPickListValues) {
            System.debug('Value = ' +objPickList.getValue() +' , Label = ' +objPickList.getLabel());
        }	 
     */
	public static Schema.DescribeSObjectResult getObjectSchema(String name)
	{
        Schema.DescribeSObjectResult result = null;
        Schema.SObjectType objType = objectDescribeByName.get(name);
        if (objType == null)
        {
            initSObjectSchema(name, false);
            objType = objectDescribeByName.get(name);
            if (objType != null)
                result = objType.getDescribe();        
        } else {
            result = objType.getDescribe();
        }
        return result;
    }
    
	public static String getObjectPluralName(String objName)
	{
		return getObjectSchema(objName).getLabelPlural();
    }
    
	public static String getObjectLabelCache(String objName)
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

        if (objectDescribeByName.get(objName) == null)
        {
            initSObjectSchema(objName, false);
            if (objectDescribeByName.get(objName) != null)
                isObject = true;
        } else {
            isObject = true;
        }
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

        System.debug(LoggingLevel.DEBUG, 'Type from field - ' + obj + '/' + field + ' - ' + objType);
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
        if (String.isEmpty(objId))
            return 'BAD ID';
            
		if (objectDescribeByPrefix.isEmpty())
			initObjectDescribeByPrefix();

        String objType = objectDescribeByPrefix.get(String.valueOf(objId).substring(0,3)).getDescribe().getName();
        System.debug(LoggingLevel.DEBUG, 'Type from id result - ' + objId + '/' + objType);
		return objType;
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
      System.debug(LoggingLevel.FINE, 'Field Data - ' + HelperSchema.getFieldByKey('Account', 'LastModifiedBy', HelperSchema.NAME));
	 */
	public static Schema.SObjectField getFieldByKey(String obj, String key, String keyType)
	{
        System.debug(LoggingLevel.DEBUG, 'Starting getFieldByKey(' + obj + ', ' + key + ', ' + keyType + ')');
		//get the fields of the object in question
		Map<String, Schema.SObjectField> fieldsByKeyType = objectDescribeFieldsByObjectNameAndKey.get(obj + ':' + keyType);

        //if we cannot find the data we initialize and try again.....this is to reduce load
        if (fieldsByKeyType == null)
        {
            initSObjectFieldSchema(obj, keyType);
            fieldsByKeyType = objectDescribeFieldsByObjectNameAndKey.get(obj + ':' + keyType);
        }

        if (fieldsByKeyType == null)
        {
    		initSObjectSchema(obj, true);
            fieldsByKeyType = objectDescribeFieldsByObjectNameAndKey.get(obj + ':' + keyType);
        }

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
        initSObjectFieldSchema(obj, keyType);

		//get the fields of the object in question
		Map<String, Schema.SObjectField> fieldsByKeyType = objectDescribeFieldsByObjectNameAndKey.get(obj + ':' + keyType);

        if (fieldsByKeyType == null)
        {
    		initSObjectSchema(obj, true);
            fieldsByKeyType = objectDescribeFieldsByObjectNameAndKey.get(obj + ':' + keyType);
        }
		
		return fieldsByKeyType;

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
	 * Method to retrieve the field label for a given object and API field name.
       System.debug(LoggingLevel.DEBUG, 'Result ' + HelperSchema.getSFDCFieldLabel('simpli_lv__List_View_Action_Parameter__c','List_View_Action__r.LastModifiedBy.Name'));
       System.debug(LoggingLevel.DEBUG, 'Result ' + HelperSchema.getSFDCFieldLabel('Account','User.Alias'));
	 */
	public static String getSFDCFieldLabel(String objName, String sfdcFieldName)
	{        
        if (objName == null || sfdcFieldName == null) throw new ListViewException('An object (' + objName + ') and field (' + sfdcFieldName + ') name must be provided when using getSFDCFieldLabel() method');
        String label = '';

        String key = objName + ':' + sfdcFieldName;
        try {
            label = fieldLabels.get(key);
            if (!String.isEmpty(label))
            {
                System.debug(LoggingLevel.DEBUG, 'USED CACHE(getSFDCFieldLabel)');
                return label;
            }

            //scrub the field of weird stuff like spaces and toLabel() etc.
			sfdcFieldName = scrubFieldName(sfdcFieldName);

            //split field into parts.
			List<String> fieldHierarchy = sfdcFieldName.split('\\.');
            System.debug(LoggingLevel.DEBUG, 'Field Hierarchy - ' + objName + '/' + fieldHierarchy);

            String objType = objName;
            Schema.DescribeSObjectResult objDescribe = HelperSchema.getObjectSchema(objType);

            while (fieldHierarchy.size() > 1) {

                String currentField = fieldHierarchy.remove(0);
                System.debug(LoggingLevel.DEBUG, 'Current objType/field - ' + objType + '/' + currentField);
                String relType = getFieldRelationshipType(objType, currentField);
                System.debug(LoggingLevel.DEBUG, 'Relationship type - ' + relType);

                if (relType == REL_TYPE_CHILD_REL)
                {
                    List<Schema.ChildRelationship> relationships = getObjectSchema(objType).getChildRelationships();
        
                    for (Schema.ChildRelationship relationship: relationships)
                    {
                        if (relationship.getRelationshipName() == currentField)
                        {
                            objType = relationship.getChildSObject().getDescribe().getName();
                            break;
                        }
                    }
        
                } else if (relType == REL_TYPE_CORE_ID)
                { 
                    objType = getFieldLookupObject(objType.replace('__r', '__c'), currentField + 'Id');

                } else if (relType == REL_TYPE_LOOKUP)
                {
                    objType = getFieldLookupObject(objType.replace('__r', '__c'), currentField.removeEnd('__r') + '__c');
  
                } else {
                    objType = currentField;
                }

            }

            String currentField = fieldHierarchy.remove(0);
            System.debug(LoggingLevel.DEBUG, 'Final objType/field - ' + objType + '/' + currentField);

            Schema.SObjectField objField = HelperSchema.getFieldByKey(objType, currentField, NAME);
            if (objField != null)
                label = objField.getDescribe().getLabel();
        
        } catch (Exception e) {
            System.debug(LoggingLevel.DEBUG, ListViewException.getExtendedString(e));
            ListViewErrorHelper.createFutureUsageError('Exception during HelperSchema.getSFDCFieldLabel(' + objName + ',' + sfdcFieldName + ') ' + ListViewException.getExtendedString(e));
            label = '';
        }

        fieldLabels.put(key, label);
        System.debug(LoggingLevel.DEBUG, 'Field label result for ' + objName + '/' + sfdcFieldName + ' is ' + label);
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
        String key = objName + ':' + sfdcFieldName;
		try {

            isValid = HelperSchema.validFieldNames.get(key);
            if (isValid != null) 
            {
                System.debug(LoggingLevel.DEBUG, 'USED CACHE(isValidSFDCFieldName)');
                return isValid;
            } else {
                isValid = false;
            }

            //scrub the field of weird stuff like spaces and toLabel() etc.
			sfdcFieldName = scrubFieldName(sfdcFieldName);

            //split field into parts.
			List<String> fieldHierarchy = sfdcFieldName.split('\\.');
            System.debug(LoggingLevel.FINE, 'Field Hierarchy - ' + fieldHierarchy);

            String objType = objName;
            Schema.DescribeSObjectResult objDescribe = HelperSchema.getObjectSchema(objType);
            objType = objDescribe.getName(); //it could have changed if we are working with a domain. i.e. it could go from List_View_Config_Condition__c --> simpli_lv__List_View_Config_Condition__c

            while (fieldHierarchy.size() > 1) {

                String currentField = fieldHierarchy.remove(0);
                System.debug(LoggingLevel.DEBUG, 'Current objType/field - ' + objType + '/' + currentField);
                String relType = getFieldRelationshipType(objType, currentField);
                System.debug(LoggingLevel.DEBUG, 'Relationship type - ' + relType);

                if (relType == REL_TYPE_CHILD_REL)
                {
                    List<Schema.ChildRelationship> relationships = getObjectSchema(objType).getChildRelationships();
        
                    for (Schema.ChildRelationship relationship: relationships)
                    {
                        if (relationship.getRelationshipName() == currentField)
                        {
                            objType = relationship.getChildSObject().getDescribe().getName();
                            break;
                        }
                    }
        
                } else if (relType == REL_TYPE_CORE_ID)
                { 
                    objType = getFieldLookupObject(objType, currentField + 'Id');

                } else if (relType == REL_TYPE_LOOKUP)
                {
                    objType = getFieldLookupObject(objType, currentField.removeEnd('__r') + '__c');
  
                } else {
                    objType = currentField;
                }

            }

            String currentField = fieldHierarchy.remove(0);
            System.debug(LoggingLevel.DEBUG, 'Final objType/field - ' + objType + '/' + currentField);

            Schema.SObjectField objField = HelperSchema.getFieldByKey(objType, currentField, NAME);
            if (objField != null)
                isValid = true;
        

        } catch (Exception e) {
            ListViewErrorHelper.createFutureUsageError('Exception during HelperSchema.isValidSFDCFieldName(' + objName + ',' + sfdcFieldName + ') ' + ListViewException.getExtendedString(e));
            isValid = false;
        }

        validFieldNames.put(key, isValid);
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
			List<String> objName = new List<String>{sfdcObjectName};
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
	   Account acc = [SELECT Name, Owner.Name, Owner.Alias, Owner.Profile.Name, Case__r.Status FROM Account WHERE Name LIKE 'Express%' LIMIT 1];
	   HelperSchema.FieldData d = HelperSchema.getFieldData(acc, 'Case__r.Status');
	   System.debug(LoggingLevel.FINE, 'Account Name - ' + d.name + ', ' + d.label + ', ' + d.getType() + ', ' + d.value);
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

					    label = fieldDesc.getLabel();
					    
                        //if we have a lookup field then determine if we add the object name to the label
                        String addObjName = ListViewConfigHelper.getOrgWideConfigParam('AddObjNameOnLookupLabels');
                        if (addObjName == ListViewHelper.TTRUE)
                            label = objType + ' ' + fieldDesc.getLabel();

                        data = new FieldData(field, label, fieldDesc.getType(), currentObj.get(field), currentObj);
						data.parentObjType = getObjectType(currentObj);
                        //data.objValueId = objValueId;
                        data.isEditable = fieldDesc.isUpdateable();

                        if (fieldDesc.isHtmlFormatted())
                            data.isHTML = true;
					}
					
				//if we are not at the last field then get the fields object
				} else {
                    System.debug(LoggingLevel.FINE, 'Not at last field. Current field - ' + field);
                    Boolean isSet = false;

                    System.debug(LoggingLevel.FINE, 'old currentObj - ' + currentObj);

                    Map<String, Object> fieldsToValue = currentObj.getPopulatedFieldsAsMap();

                    //if there is a value for the field
                    if (fieldsToValue.get(field) != null)
                    {
                        Object tmpObj = fieldsToValue.get(field);

                        if (tmpObj instanceof List<SObject>)
                            currentObj = ((List<SObject>) tmpObj)[0];
                        else if (tmpObj instanceof SObject)
                            currentObj = (SObject) tmpObj;
    
                    //if there is no value
                    } else {
                        System.debug(LoggingLevel.FINE, 'No field value for name ' + field);
                        //if we are trying to retrieve column data we need to get the label....so we get the label if we can.
                        if (label == '')
                            label = getSFDCFieldLabel(objType, fieldName);
                        data = new FieldData(field, label, Schema.DisplayType.STRING, '', currentObj);
                        return data;
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
        String key = objAPIName + ':' + action;
        if (HelperSchema.objectPermissions.contains(key)) 
        {
            System.debug(LoggingLevel.DEBUG, 'USED CACHE(checkObjectPermissions)');
            return;
        }

        if (objAPIName == 'Simpli_lv__List_View__c')
        { 
            if (action == DELETABLE) checkObjectDeletable('Simpli_lv__List_View__c');
            else throw new ListViewException('No permission check for Simpli_lv__List_View__c with action - ' + action);

        } else if (objAPIName == 'Simpli_lv__List_View_Config__c')
        {
            if (action == DELETABLE) checkObjectDeletable('Simpli_lv__List_View_Config__c');
            else throw new ListViewException('No permission check for Simpli_lv__List_View_Config__c with action - ' + action);
        
        }  else if (objAPIName == 'Simpli_lv__List_View_Config_Parameter__c')
        {
            if (action == DELETABLE) checkObjectDeletable('Simpli_lv__List_View_Config_Parameter__c');
            else throw new ListViewException('No permission check for Simpli_lv__List_View_Config_Parameter__c with action - ' + action);
        
        }  else if (objAPIName == 'simpli_lv__List_View_Config_Condition__c')
        {
            if (action == DELETABLE) checkObjectDeletable('simpli_lv__List_View_Config_Condition__c');
            else throw new ListViewException('No permission check for simpli_lv__List_View_Config_Condition__c with action - ' + action);
        
        } else if (objAPIName == 'Simpli_lv__List_View_Action__c')
        {
            if (action == DELETABLE) checkObjectDeletable('Simpli_lv__List_View_Action__c');
            else throw new ListViewException('No permission check for Simpli_lv__List_View_Action__c with action - ' + action);
        
        } else if (objAPIName == 'Simpli_lv__List_View_Action_Parameter__c')
        {
            if (action == DELETABLE) checkObjectDeletable('Simpli_lv__List_View_Action_Parameter__c');
            else throw new ListViewException('No permission check for Simpli_lv__List_View_Action_Parameter__c with action - ' + action);
        
        }  else if (objAPIName == 'simpli_lv__List_View_User_Config__c')
        {
            if (action == DELETABLE) checkObjectDeletable('simpli_lv__List_View_User_Config__c');
            else throw new ListViewException('No permission check for simpli_lv__List_View_User_Config__c with action - ' + action);
        
        }else {
            if (action == DELETABLE) HelperSchema.checkObjectDeletable(objAPIName);
            else throw new ListViewException('No permission check for ' + objAPIName + ' with action - ' + action);
            
        }

        objectPermissions.add(key);
    }

	public static String scrubFieldNameForSOQL(String fieldName)
    {
        if (fieldName == null) return fieldName;
        //remove whitespace
        fieldName = fieldName.deleteWhitespace();

        //remove toLabel keyword
        if (fieldName.contains('toLabel(')) fieldName = fieldName.substringBetween('(', ')');
        
        return fieldName;
    }

	public static String scrubFieldName(String fieldName)
    {
        if (fieldName == null) return fieldName;
        //remove whitespace
        fieldName = fieldName.deleteWhitespace();

        //remove toLabel keyword
        if (fieldName.contains('toLabel(')) fieldName = fieldName.substringBetween('(', ')');
        else if (fieldName.contains('convertCurrency(')) fieldName = fieldName.substringBetween('(', ')');
        
        return fieldName;
    }

    public static Map<String, String> getPicklistMap(String obj, String field)
    {
		Map<String, String> lstPickvals = new Map<String, String>();

		Schema.DescribeSObjectResult sObjectDesc = HelperSchema.getObjectSchema(obj);

		Map<String, Schema.SObjectField> fields = sObjectDesc.fields.getMap();
		List<Schema.PicklistEntry> pickListValues = fields.get(field).getDescribe().getPickListValues();
		for (Schema.PicklistEntry a : pickListValues)
		{ 
			lstPickvals.put(a.getLabel(), a.getValue());
		}
		
		return lstPickvals;

    }

    /*
        Found at https://glyntalkssalesforce.blogspot.com/2018/08/dependent-picklist-values-in-apex.html
        HelperString.debug(HelperSchema.getDependentPicklistValues('Account', 'simpli_lv__Controlled_Picklist__c'), 'VALUES');
     */
    public static Map<Object,List<String>> getDependentPicklistValues(String sObjName, String fieldName)
    {
        return getDependentPicklistValues(Schema.getGlobalDescribe().get(sObjName).getDescribe().fields.getMap().get(fieldName));
    }

    //public static List<String> getDependentPicklistValues(String sObjName, String fieldName, String recordTypeId)
    //{
    //    return getDependentPicklistValues(Schema.getGlobalDescribe().get(sObjName).getDescribe().fields.getMap().get(fieldName));
    //}

    /*
        Found at https://glyntalkssalesforce.blogspot.com/2018/08/dependent-picklist-values-in-apex.html
     */
    public static Map<Object,List<String>> getDependentPicklistValues(Schema.sObjectField dependToken)
    {
        System.debug(LoggingLevel.DEBUG, 'Depend Token - ' + dependToken);
        Schema.DescribeFieldResult depend = dependToken.getDescribe();
        System.debug(LoggingLevel.DEBUG, 'Depend - ' + depend);
        Schema.sObjectField controlToken = depend.getController();
        System.debug(LoggingLevel.DEBUG, 'Control Token - ' + controlToken);
        if (controlToken == null) return null;
        Schema.DescribeFieldResult control = controlToken.getDescribe();
        List<Schema.PicklistEntry> controlEntries =
        (   control.getType() == Schema.DisplayType.Boolean
        ?   null
        :   control.getPicklistValues()
        );

        String base64map = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
        Map<Object,List<String>> dependentPicklistValues = new Map<Object,List<String>>();
        for (Schema.PicklistEntry entry : depend.getPicklistValues()) 
        {
            if (entry.isActive())
            {
                System.debug(LoggingLevel.DEBUG, 'ENntry - ' + entry);
                
                List<String> base64chars = String.valueOf(((Map<String,Object>) JSON.deserializeUntyped(JSON.serialize(entry))).get('validFor')).split('');
                for ( Integer index = 0; index < (controlEntries != null ? controlEntries.size() : 2); index++ )
                {
                    Object controlValue =
                    (   controlEntries == null
                    ?   (Object) (index == 1)
                    :   (Object) (controlEntries[ index ].isActive() ? controlEntries[ index ].getLabel() : null)
                    );
                    Integer bitIndex = index / 6, bitShift = 5 - Math.mod( index, 6 );
                    if  (   controlValue == null
                        ||  (base64map.indexOf( base64chars[ bitIndex ] ) & (1 << bitShift)) == 0
                        ) continue;
                    if ( !dependentPicklistValues.containsKey( controlValue ) )
                    {
                        dependentPicklistValues.put( controlValue, new List<String>() );
                    }
                    dependentPicklistValues.get( controlValue ).add( entry.getLabel() );
                }
            }
        }
        return dependentPicklistValues;
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

    public static String getDMLDecisionDebug(String objAPIName, SObjectAccessDecision dec)
    {
        String log = '\n\n--------------- Decision ---------------\n';
        log += 'Object - ' + objAPIName + '\n';
        for (Integer index: dec.getModifiedIndexes())
            log += index + ', ';
        log.removeEnd(', ');

        for (String field: dec.getRemovedFields().keySet())
            log += field + dec.getRemovedFields().get(field) + '\n';

        log += '----------------------------------------\n';

        return log;

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

    private static void initSObjectFieldSchema(String obj, String keyType)
    {
        Schema.SObjectType objSchema = Schema.getGlobalDescribe().get(obj);
        if (objSchema != null && objectDescribeFieldsByObjectNameAndKey.get(obj + ':' + keyType) == null)
        {
            System.debug(LoggingLevel.FINE, 'Found schema with name - ' + obj);


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
        }
    }
    
    private static void initSObjectSchema(String obj, Boolean includeFields)
    {
        initSObjectSchema(obj, true, includeFields);
    }

	/*
	 * Method to initialize an sobject schema if it hasn't already been initialized. This has a small hack
	 * in it to detect if an object name being requested needs a domain prefix. If it does then it rerequests
	 * the schema. Once the schema is returned it places the schema into the map with both the domain prefix
	 * and without it. This hack ensures that tests will run in both the package dev org and other orgs.
     * HelperSchema.initSObjectSchema('simpli_lv__List_View__c');
     * HelperSchema.initSObjectSchema('');
	 */
	private static void initSObjectSchema(String obj, Boolean allowRecurring, Boolean includeFields)
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
                
                if (obj.contains(DOMAIN_NAME))
                    objectDescribeByName.put(obj.removeStart(DOMAIN_NAME), objSchema);
                    
                if (includeFields)
                {
                    initSObjectFieldSchema(obj, LABEL);
                }

			} else if (allowRecurring) {
				System.debug(LoggingLevel.FINE, 'NO schema with name - ' + obj);
				initSObjectSchema(DOMAIN_NAME + obj, false, includeFields);
			}
		}
		
	}

    public static Type getClassType(String typeStr)
    {
        Type t = null;
		Integer index = typeStr.indexOf('.');
    	if (index != -1) {
        	// With namespace "ns.Type"
        	t = Type.forName(typeStr.substring(index), typeStr.substring(index + 1, typeStr.length()));
    	} else {
        	// Just "Type"
        	t = Type.forName(null, typeStr);
    	}

        if (t == null)
            throw new ListViewException('Provided type not found - ' + typeStr);
        return t;
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
        private Schema.DisplayType type {get; set;}
        public Object value            {get; set;} //holds the string value. i.e. CreatedBy.Name = "Tom Ansley" 
        public String objValueId       {get; set;} //holds the id value if its a lookup. i.e. CreatedBy.Name = 0053h000000xrj3AAA
        public Boolean isChildRel      {get; set;}
        public Boolean isEditable      {get; set;}
        public Boolean isHTML          {get; set;} //identifies if its a rich text field

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
            this.isHTML        = false;
            if (objValue != null)
                objValueId = String.valueOf(objValue.get('Id'));
        }

        public FieldData(String name, Object value)
        {
            this.name          = name;
            this.value         = value;
            this.isChildRel    = false;
            this.isEditable    = false;
            this.parentObjType = '';
            this.isHTML        = false;
        }

        public String getType() {
            if (isHTML)
                return 'rich textarea';
            else
                return type.name().toLowerCase();
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
            debug += 'isHTML        - ' + isHTML + '\n';
            debug += '----------------\n';

            return debug;
        }
	}
	

}
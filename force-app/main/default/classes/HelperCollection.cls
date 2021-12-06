/**
 * @description       : 
 * @author            : tom@ansleyllc.com
 * @last modified on  : 12-05-2021
 * @last modified by  : tom.h.ansley@medtronic.com
**/
public with sharing class HelperCollection {

    /*
     * Method which takes a list of objects and a field name and returns a map containing the field
     * as the key and a list of objects which are related to the key.  If the field that the name
     * refers to is not of type Id then an exception is thrown.
     * @param objects the list of SObjects which holds the field to create the map from.
     * @param fieldName the name of the field that the map should use for its key.
     */
    public static Map<String, SObject> getStringMappedObjects(List<SObject> objects, String fieldName) {
        
        Map<String, SObject> mappedObjs = new Map<String, SObject>();
        
        if (objects != null && objects.size() != 0) {
            
            for (SObject obj: objects)
                mappedObjs.put((String) obj.get(fieldName), obj);
            
        }
        
        return mappedObjs;
        
    }

    /*
     * Method which takes a list of SObjects and a field name and returns a set
     * of ID's which corresponds to the field name.  If the field that the name
     * refers to is not of type Id then an exception is thrown.
     * @param objects the list of SObjects which holds the field to create the set from.
     * @param fieldName the name of the field that the set should be created from.
     */
    public static Set<Id> getIdFieldSet(List<SObject> objects, String fieldName) 
    {

        List<Id> values = HelperCollection.getIdFieldList(objects, fieldName);

        Set<Id> setValues = new Set<Id>();

        setValues.addAll(values);

        return setValues;

    }

    /*
     * Method which takes a list of SObjects and a field name and returns a list
     * of ID's which corresponds to the field name.  If the field that the name
     * refers to is not of type Id then an exception is thrown.
     * @param objects the list of SObjects which holds the field to create the set from.
     * @param fieldName the name of the field that the set should be created from.
     */
    public static List<Id> getIdFieldList(List<SObject> objects, String fieldName) 
    {

        List<Id> values = new List<Id>();

        if (objects != null && objects.size() != 0) 
        {

            for (SObject obj: objects)
                values.add((Id) obj.get(fieldName));
        }

        return values;

    }

}
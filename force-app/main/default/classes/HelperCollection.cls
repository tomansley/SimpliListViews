/**
 * @description       : 
 * @author            : tom@ansleyllc.com
 * @last modified on  : 11-12-2021
 * @last modified by  : tom@ansleyllc.com
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
}
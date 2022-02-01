/**
 * @description       : 
 * @author            : tom@ansleyllc.com
 * @last modified on  : 01-29-2022
 * @last modified by  : tom.h.ansley@medtronic.com
**/
public with sharing class CacheListViews {

    public static final String LOAD_TYPE_OBJ  = 'Object';
    public static final String LOAD_TYPE_TYPE = 'Type';

    public static Object get(String key)
    {
        Object result = null;
        List<String> keys = key.split(CacheHelper.SPLITTER); //get the keys as full strings
        key = CacheHelper.getValidKey(key); //remove invalid chars from key
    	System.debug(LoggingLevel.DEBUG, 'CacheListViews.get(' + key + ')');    
        if (key.length() < 50) //stupid restriction on key size!!
        {	
            result = CacheHelper.PARTITION.get(key);
            if (result == null)
            {
                result = getData(keys);
                CacheHelper.PARTITION.put(key, result, 300);    
            }
        } else {
            result = getData(keys);
        }
        return result;
    }

    public static void remove(String key)
    {
        key = CacheHelper.getValidKey(key);
    	System.debug(LoggingLevel.DEBUG, 'CacheListViews.remove(' + key + ')');    	
        CacheHelper.PARTITION.remove(key);
    }

    /*
	 * Implement the Cache.CacheBuilder interface
	 */
    private static Object getData(List<String> keys) 
    {
        String loadType = keys[0]; //either Name, Object or Type
        String userId   = keys[1];

    	System.debug(LoggingLevel.DEBUG, 'loadType - ' + loadType);    	
    	System.debug(LoggingLevel.DEBUG, 'userId   - ' + userId);    	

        if (loadType == LOAD_TYPE_OBJ)
            return ListViewHelper.getListViewsByObjectCache(keys[2]); 
        else if (loadType == LOAD_TYPE_TYPE)
            return ListViewHelper.getListViewsByTypeCache(keys[2], true); 
        else 
            throw new ListViewException('Cannot determine visible list views load type');
    }

}
/**
 * @description       : 
 * @author            : tom@ansleyllc.com
 * @last modified on  : 03-21-2022
 * @last modified by  : tom@ansleyllc.com
**/
public with sharing class CacheListViews {

    public static final String LOAD_TYPE_OBJ  = 'Object';
    public static final String LOAD_TYPE_TYPE = 'Type';

    /*
     * The key is split as follows - 
     *  1. Load Type (Object or Type)
        2. User Id (15 char)
        3. Object API Name
     */
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
                CacheHelper.PARTITION.put(key, result);    
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
        if (key.length() < 50)
            CacheHelper.PARTITION.remove(key);
    }

    /*
	 * Implement the Cache.CacheBuilder interface
	 */
    private static Object getData(List<String> keys) 
    {
        String loadType = keys[0]; //either Object or Type
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
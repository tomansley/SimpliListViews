/**
 * @description       : 
 * @author            : tom@ansleyllc.com
 * @last modified on  : 01-27-2022
 * @last modified by  : tom@ansleyllc.com
**/
public with sharing class CacheListViews {

    public static final String LOAD_TYPE_OBJ  = 'Object';
    public static final String LOAD_TYPE_TYPE = 'Type';

    public static Object get(String key)
    {
        key = CacheAbstract.getValidKey(key);
    	System.debug(LoggingLevel.DEBUG, 'CacheListViews.get(' + key + ')');    	
        Object result = Cache.Org.get(CacheAbstract.PARTITION + key);
        if (result == null)
        {
            result = getData(key);
            Cache.Org.put(CacheAbstract.PARTITION + key, result, 300);    
        }

        return result;
    }

    public static void remove(String key)
    {
        key = CacheAbstract.getValidKey(key);
    	System.debug(LoggingLevel.DEBUG, 'CacheListViews.remove(' + key + ')');    	
        Cache.org.remove(CacheAbstract.PARTITION + key);
    }

    /*
	 * Implement the Cache.CacheBuilder interface
	 */
    private static Object getData(String key) 
    {
        List<String> keys = key.split(CacheAbstract.SPLITTER);

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

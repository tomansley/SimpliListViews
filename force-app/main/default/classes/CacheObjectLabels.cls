/**
 * @description       : 
 * @author            : tom@ansleyllc.com
 * @last modified on  : 08-31-2022
 * @last modified by  : tom@ansleyllc.com
**/
public with sharing class CacheObjectLabels {

    private static final String PREFIX = 'Label' + CacheHelper.SPLITTER;
    public static final String ALL_OBJECTS = 'AllObjects';

    public static String get(String key)
    {
        String result = null;

        String storedKey = PREFIX + CacheHelper.getValidKey(key); //add prefix and remove invalid chars from key
    	System.debug(LoggingLevel.DEBUG, 'CacheObjectLabels.get(' + storedKey + ')');    

        if (storedKey.length() < 50) //stupid restriction on key size!!
        {	
            result = (String) CacheHelper.PARTITION.get(storedKey);
            if (result == null)
            {
                result = getData(key);
                CacheHelper.PARTITION.put(storedKey, result);    
            }
        } else {
            result = getData(key);
        }
        return result;
    }

    public static void remove(String key)
    {
        key = PREFIX + CacheHelper.getValidKey(key);
    	System.debug(LoggingLevel.DEBUG, 'CacheObjectLabels.remove(' + key + ')');    	
        if (key.length() < 50)
            CacheHelper.PARTITION.remove(key);
    }

    /*
	 * Implement the Cache.CacheBuilder interface
	 */
    private static String getData(String key) 
    {
        if (key == ALL_OBJECTS)
            return JSON.serialize(HelperSchema.getAllObjectNames());
        else
            return HelperSchema.getObjectLabelCache(key);
    }

}
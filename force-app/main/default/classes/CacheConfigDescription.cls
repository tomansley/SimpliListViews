/**
 * @description       : 
 * @author            : tom@ansleyllc.com
 * @last modified on  : 01-29-2022
 * @last modified by  : tom.h.ansley@medtronic.com
**/
public with sharing class CacheConfigDescription {

    private static final String PREFIX = 'Desc' + CacheHelper.SPLITTER;

    public static String get(String key)
    {
        String result = null;

        String storedKey = PREFIX + CacheHelper.getValidKey(key); //add prefix and remove invalid chars from key
    	System.debug(LoggingLevel.DEBUG, 'CacheConfigDescription.get(' + key + ')');    

        if (key.length() < 50) //stupid restriction on key size!!
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
        String storedKey = PREFIX + CacheHelper.getValidKey(key);
    	System.debug(LoggingLevel.DEBUG, 'CacheConfigDescription.remove(' + storedKey + ')');    	
        CacheHelper.PARTITION.remove(storedKey);
    }

    /*
	 * Implement the Cache.CacheBuilder interface
	 */
    private static String getData(String key) 
    {
        return ListViewConfigDescriptions.getLongDescriptionCache(key);
    }

}
/**
 * @description       : 
 * @author            : tom@ansleyllc.com
 * @last modified on  : 03-25-2024
 * @last modified by  : tom@ansleyllc.com
**/
public with sharing class CacheSystemConfig {

    private static final String PREFIX = 'System' + CacheHelper.SPLITTER;

    public static Object get(String key)
    {
        Object result = null;

        String storedKey = PREFIX + CacheHelper.getValidKey(key); //add prefix and remove invalid chars from key
    	System.debug(LoggingLevel.DEBUG, 'CacheSystemConfig.get(' + storedKey + ')');    

        if (storedKey.length() < 50) //stupid restriction on key size!!
        {	
            result = CacheHelper.PARTITION.get(storedKey);
        }

        return result;
    }

    public static void put(String key, Object value)
    {
        String storedKey = PREFIX + CacheHelper.getValidKey(key); //add prefix and remove invalid chars from key
    	System.debug(LoggingLevel.DEBUG, 'CacheSystemConfig.put(' + storedKey + ')');    

        if (storedKey.length() < 50) //stupid restriction on key size!!
        {	
            CacheHelper.PARTITION.put(storedKey, value);    
        }
    }

    public static void remove(String key)
    {
        key = PREFIX + CacheHelper.getValidKey(key);
    	System.debug(LoggingLevel.DEBUG, 'CacheSystemConfig.remove(' + key + ')');    	
        if (key.length() < 50)
            CacheHelper.PARTITION.remove(key);
    }

}
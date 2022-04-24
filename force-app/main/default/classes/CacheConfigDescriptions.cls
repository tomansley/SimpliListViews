/**
 * @description       : 
 * @author            : tom@ansleyllc.com
 * @last modified on  : 04-19-2022
 * @last modified by  : tom@ansleyllc.com
**/
public with sharing class CacheConfigDescriptions {

    private static final String PREFIX = 'Descs' + CacheHelper.SPLITTER;

    public static List<simpli_lv__List_View_Config_Description__mdt> get(String key)
    {
        List<simpli_lv__List_View_Config_Description__mdt> result = null;

        String storedKey = PREFIX + CacheHelper.getValidKey(key); //add prefix and remove invalid chars from key
    	System.debug(LoggingLevel.DEBUG, 'CacheConfigDescriptions.get(' + key + ')');    

        if (storedKey.length() < 50) //stupid restriction on key size!!
        {	
            result = (List<simpli_lv__List_View_Config_Description__mdt>) CacheHelper.PARTITION.get(storedKey);
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
    	System.debug(LoggingLevel.DEBUG, 'CacheConfigDescriptions.remove(' + key + ')');    	
        if (key.length() < 50)
            CacheHelper.PARTITION.remove(key);
    }

    /*
	 * Implement the Cache.CacheBuilder interface
	 */
    private static List<simpli_lv__List_View_Config_Description__mdt> getData(String key) 
    {
        return ListViewConfigDescriptions.getDescriptionsCache(key);
    }

}
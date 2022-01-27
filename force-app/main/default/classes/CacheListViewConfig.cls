/**
 * @description       : 
 * @author            : tom@ansleyllc.com
 * @last modified on  : 01-27-2022
 * @last modified by  : tom@ansleyllc.com
**/
public with sharing class CacheListViewConfig {

    public static Object get(String objectName, String listViewName)
    {
        String key = CacheAbstract.getValidKey(objectName + CacheAbstract.SPLITTER + listViewName);
    	System.debug(LoggingLevel.DEBUG, 'CacheListViews.get(' + key + ')');    	
        Object result = Cache.Org.get(CacheAbstract.PARTITION + key);
        if (result == null)
        {
            result = getData(objectName, listViewName);
            Cache.Org.put(CacheAbstract.PARTITION + key, result, 300);    
        }

        return result;
    }

    public static void remove(String objectName, String listViewName)
    {
        String key = CacheAbstract.getValidKey(objectName + CacheAbstract.SPLITTER + listViewName);
    	System.debug(LoggingLevel.DEBUG, 'CacheListViews.remove(' + key + ')');    	
        Cache.org.remove(CacheAbstract.PARTITION + key);
    }

    private static Object getData(String objectName, String listViewName) 
    {
        return ListViewConfigHelper.getListViewConfigCache(objectName, listViewName); 
    }

}

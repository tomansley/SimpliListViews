/**
 * @description       : 
 * @author            : tom@ansleyllc.com
 * @last modified on  : 10-16-2022
 * @last modified by  : 
**/
public with sharing class CacheListViewConfig {

    public static List_View_Config__c get(String objectName, String listViewName)
    {
        List_View_Config__c result = null;

        String key = CacheHelper.getValidKey(objectName + CacheHelper.SPLITTER + listViewName);
    	System.debug(LoggingLevel.DEBUG, 'CacheListViews.get(' + key + ')');    	
        if (key.length() < 50) //stupid restriction on key size!!
        {	
            result = (List_View_Config__c) CacheHelper.PARTITION.get(key);
            if (result == null)
            {
                System.debug(LoggingLevel.DEBUG, 'RESULT IS NULL');
                result = getData(objectName, listViewName);
                System.debug(LoggingLevel.DEBUG, 'RESULT IS NOW ' + result);
                if (result != null)
                    CacheHelper.PARTITION.put(key, result);    
            } else {
                System.debug(LoggingLevel.DEBUG, 'RESULT NOT NULL - ' + result);
            }
        } else {
            result = getData(objectName, listViewName);
        }
        return result;
    }

    public static void remove(String objectName, String listViewName)
    {
        String key = CacheHelper.getValidKey(objectName + CacheHelper.SPLITTER + listViewName);
    	System.debug(LoggingLevel.DEBUG, 'CacheListViews.remove(' + key + ')');    	
        if (key.length() < 50)
            CacheHelper.PARTITION.remove(key);
    }

    private static List_View_Config__c getData(String objectName, String listViewName) 
    {
        return ListViewConfigHelper.getListViewConfigCache(objectName, listViewName); 
    }

}
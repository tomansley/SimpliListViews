/**
 * @description       : 
 * @author            : tom@ansleyllc.com
 * @last modified on  : 01-26-2022
 * @last modified by  : tom@ansleyllc.com
**/
public with sharing class CacheListViewConfig extends CacheAbstract {

	/*
	 * Implement the Cache.CacheBuilder interface
	 */
    override public Object doLoad(String key) 
    {
    	System.debug(LoggingLevel.DEBUG, 'CacheListViewConfig KEY - ' + key);    	

        List<String> keys = key.split(':');

        return ListViewConfigHelper.getListViewConfigCache(keys[0], keys[1]); 
    	
    }

}

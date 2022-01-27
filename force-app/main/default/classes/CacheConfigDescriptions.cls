/**
 * @description       : 
 * @author            : tom@ansleyllc.com
 * @last modified on  : 01-26-2022
 * @last modified by  : tom@ansleyllc.com
**/
public with sharing class CacheConfigDescriptions extends CacheAbstract {

	/*
	 * Implement the Cache.CacheBuilder interface
	 */
    override public Object doLoad(String key) 
    {
    	System.debug(LoggingLevel.DEBUG, 'CacheConfigDescriptions KEY - ' + key);    	
        return ListViewConfigDescriptions.getDescriptionsCache(key);
    }

}

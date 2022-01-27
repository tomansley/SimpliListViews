/**
 * @description       : 
 * @author            : tom@ansleyllc.com
 * @last modified on  : 01-27-2022
 * @last modified by  : tom@ansleyllc.com
**/
public with sharing abstract class CacheAbstract implements Cache.CacheBuilder {

    public static final String PARTITION = 'simpli_lv.SimpliListViewsCache.';
    public static final String SPLITTER  = 'ZZZ'; //has to be alphanumeric

    abstract public Object doLoad(String request);

    public static String getValidKey(String inputKey) 
	{
		Pattern nonAlphanumeric = Pattern.compile('[^a-zA-Z0-9]');
		Matcher matcher = nonAlphanumeric.matcher(inputKey);
		
		String key = matcher.replaceAll('');
		
		System.debug(LoggingLevel.DEBUG, 'Valid Key - ' + key);
		
		return key;
	}
    
}

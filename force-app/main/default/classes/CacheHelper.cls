/**
 * @description       : 
 * @author            : tom.h.ansley@medtronic.com
 * @last modified on  : 03-21-2022
 * @last modified by  : tom@ansleyllc.com
**/
public with sharing class CacheHelper {

    public static final String SPLITTER        = 'ZZ'; //has to be alphanumeric
    public static final String PARTITION_NAME = 'simpli_lv.SimpliListViewsCache';
    public static Cache.OrgPartition PARTITION = Cache.Org.getPartition(PARTITION_NAME);

    public static String getValidKey(String inputKey) 
	{
		Pattern nonAlphanumeric = Pattern.compile('[^a-zA-Z0-9]');
		Matcher matcher = nonAlphanumeric.matcher(inputKey);
		
		String key = matcher.replaceAll('');
		
		System.debug(LoggingLevel.DEBUG, 'Valid Key - ' + key);
		
		return key;
	}

    /*
        System.debug(LoggingLevel.DEBUG, CacheHelper.debugCache());
    */
    public static String debugCache()
    {
        String debug = '\n\n----------- Cache Keys -----------\n';
        Cache.OrgPartition orgPartition = Cache.Org.getPartition(PARTITION_NAME);
        List<String> keys = new List<String>(orgPartition.getKeys());
        keys.sort();
        for (String key: keys)
            debug += key + '\n';
        return debug;
    }

    public static void clearCache(String containsStr)
    {
        Cache.OrgPartition orgPartition = Cache.Org.getPartition(PARTITION_NAME);
        Set<String> keys = orgPartition.getKeys();
        for (String key: keys)
        {
            if (key.length() < 50 && (String.isEmpty(containsStr) || keys.contains(containsStr)))
                orgPartition.remove(key);
        }
    }

    public static void clearAllCache()
    {
        clearCache(null);
    }

    public static Set<String> getCacheKeys()
    {
        Cache.OrgPartition orgPartition = Cache.Org.getPartition(PARTITION_NAME);
        return orgPartition.getKeys();
    }
 
}
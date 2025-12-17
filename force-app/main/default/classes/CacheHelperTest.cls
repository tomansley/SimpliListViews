/**
 * @description       : 
 * @author            : tom@ansleyllc.com
 * @last modified on  : 03-21-2022
 * @last modified by  : tom@ansleyllc.com
**/
@isTest
private class CacheHelperTest {

 	@isTest
	static void clearCacheTest()
	{
        Test.startTest();

            CacheHelper.clearAllCache();

            String debug = '\n\n------ 1 ------\n' + CacheHelper.debugCache();

            System.assertEquals(0, CacheHelper.getCacheKeys().size()); //show cache is empty

            ListViewHelper.insertCoreGlobalConfig();
            ListViewConfigHelper.getOrgWideConfigParams(); //populate the cache

            debug += '\n\n------ 2 ------\n' + CacheHelper.debugCache();

            Set<String> keys = CacheHelper.getCacheKeys();

            System.assertEquals(1, CacheHelper.getCacheKeys().size()); //show cache now contains 1 element

            CacheHelper.clearCache('All' + CacheHelper.SPLITTER + 'All'); //clear the cache

            debug += '\n\n------ 3 ------\n' + CacheHelper.debugCache();

            System.assertEquals(0, CacheHelper.getCacheKeys().size()); //show cache is empty




            ListViewConfigHelper.resetCache(ListViewConfigHelper.ALL, ListViewConfigHelper.ALL); //reset the cache 
            ListViewConfigHelper.getOrgWideConfigParams(); //populate the cache AGAIN

            debug += '\n\n------ 4 ------\n' + CacheHelper.debugCache();

            keys = CacheHelper.getCacheKeys();

            System.assertEquals(1, CacheHelper.getCacheKeys().size()); //show cache contains 1 element

            CacheHelper.clearAllCache();

            debug += '\n\n------ 5 ------\n' + CacheHelper.debugCache();

            System.debug(LoggingLevel.DEBUG, debug);

            System.assertEquals(0, CacheHelper.getCacheKeys().size()); //show cache is empty

        Test.stopTest();
    }

    @isTest
	static void longCacheNameTest()
	{
        Test.startTest();

            String longDesc = ListViewConfigDescriptions.getLongDescription('This is the longest description name I could think of that has more than 50 characters in it');

            System.assertEquals('', longDesc);

            List<List_View_Config_Description__mdt> results = ListViewConfigDescriptions.getDescriptions('This is the longest description type I could think of that has more than 50 characters in it');

            System.assertEquals(0, results.size());

            String objLabel = CacheObjectLabels.get('This is the longest description object API name I could think of that has more than 50 characters in it');

            System.assertEquals('', objLabel);

            String excStr = '';
            List_View_Config__c config = CacheListViewConfig.get('This is a very long object API name that I could think of', 'This is also a very long list view name that I could think of');
            System.assertEquals(null, config);

            CacheListViewConfig.remove('This is a very long object API name that I could think of', 'This is also a very long list view name that I could think of');

        Test.stopTest();
    }
}
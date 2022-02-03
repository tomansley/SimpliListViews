/**
 * @description       : 
 * @author            : tom@ansleyllc.com
 * @last modified on  : 02-03-2022
 * @last modified by  : tom@ansleyllc.com
**/
@isTest
private class CacheHelperTest {

 	@isTest
	static void clearCacheTest()
	{
        Test.startTest();

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

            CacheHelper.clearCache(null); //clear ALL cache

            debug += '\n\n------ 5 ------\n' + CacheHelper.debugCache();

            System.debug(LoggingLevel.DEBUG, debug);

            System.assertEquals(0, CacheHelper.getCacheKeys().size()); //show cache is empty

        Test.stopTest();
    }

}
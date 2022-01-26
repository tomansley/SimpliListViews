/**
 * @description       : 
 * @author            : tom@ansleyllc.com
 * @last modified on  : 01-26-2022
 * @last modified by  : tom@ansleyllc.com
**/
public with sharing abstract class CacheAbstract implements Cache.CacheBuilder {
    
    public static String PARTITION = 'simpli_lv.SimpliListViewsCache.';

    abstract public Object doLoad(String request);
    
}

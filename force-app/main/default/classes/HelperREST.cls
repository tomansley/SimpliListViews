/**
 * @description       : 
 * @author            : tom@ansleyllc.com
 * @last modified on  : 04-10-2022
 * @last modified by  : tom@ansleyllc.com
 * Modifications Log 
 * Ver   Date         Author              Modification
 * 1.0   10-26-2020   tom@ansleyllc.com   Initial Version
**/
public with sharing class HelperREST {

    public static String sessionId = null;

    /*
     * Hack to get the session Id in Lightning - https://salesforce.stackexchange.com/questions/110515/getting-session-id-in-lightning
     */
    public static String getSessionIdFromVFPage(PageReference visualforcePage){
        if (sessionId == null)
        {
            String content = visualforcePage.getContent().toString();
            
            Integer startStr = content.indexOf('Start') + 'Start_Of_Session_Id'.length();
            Integer endStr   = content.indexOf('End');

            sessionId = content.substring(startStr, endStr);
        }
        
        return sessionId;
    }
    
    /*
     * Method to perform an internal callout using the current session Id for
     * security purposes. The body can be null.
        String endPoint = URL.getOrgDomainUrl().toExternalForm() + '/services/data/v52.0/sobjects/simpli_lv__List_View_Metadata_Type_Name__mdt/listviews/00B3h000007cUeiEAE/describe';
        String callResponse = HelperREST.performInternalCallout(endPoint, null);

     */
    public static String performInternalCallout(String endPoint, String body)
    {
       
        String sessionId;
        
        if(!Test.isRunningTest()) {
            sessionId = getSessionIdFromVFPage(Page.SessionId);
        }
        
        HttpRequest req = new HttpRequest();
        req.setHeader('Authorization', 'Bearer ' + sessionId);
        req.setHeader('Content-Type', 'application/json');
        req.setEndpoint(endPoint);
        req.setMethod('GET');
        if (body != null)
            req.setBody(body);
            
        System.debug(LoggingLevel.DEBUG, 'REQUEST - ' + req);
        System.debug(LoggingLevel.DEBUG, 'REQUEST BODY - ' + body);
        
        Http h = new Http();
        HttpResponse res = h.send(req);

        System.debug(LoggingLevel.DEBUG, 'RESPONSE - ' + res);
        System.debug(LoggingLevel.DEBUG, 'RESPONSE BODY - ' + res.getBody());

        return res.getBody();
    }

    /**
    * @description Method to get the latest API version that is being used on the calling system
    * @author tom@ansleyllc.com | 10-29-2020 
    * @return String 
    *
        System.debug(LoggingLevel.DEBUG, 'VERSION - ' + HelperREST.getNewestAPIVersion());
    **/
    public static String getNewestAPIVersion()
    {

        String url = URL.getSalesforceBaseUrl().toExternalForm() + '/services/data';

        String json = null;
        if (!Test.isRunningTest())
            json = performInternalCallout(url, null);
        else {
            json = '[{"label":"Winter \'21","url":"/services/data/v50.0","version":"50.0"},{"label":"Spring \'21","url":"/services/data/v51.0","version":"51.0"},{"label":"Summer \'21","url":"/services/data/v52.0","version":"52.0"}]';
        }
    
        List<VersionResponse> parsedList = (List<VersionResponse>)System.JSON.deserialize(json, List<VersionResponse>.class); 
    
        String latestVersion = '0'; 
        for (VersionResponse item : parsedList)
        {
            if (latestVersion.compareTo(item.version) < 0)
                latestVersion = item.version; 
        }
    
        return latestVersion;
    }

    public class VersionResponse
    {
        public String label; 
        public String url; 
        public String version; 
    }
}
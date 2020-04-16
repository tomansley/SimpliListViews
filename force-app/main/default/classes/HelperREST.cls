public with sharing class HelperREST {

    /*
     * Hack to get the session Id in Lightning - https://salesforce.stackexchange.com/questions/110515/getting-session-id-in-lightning
     */
    public static String getSessionIdFromVFPage(PageReference visualforcePage){
        String content = visualforcePage.getContent().toString();
        
        Integer startStr = content.indexOf('Start') + 'Start_Of_Session_Id'.length();
        Integer endStr   = content.indexOf('End');

        return content.substring(startStr, endStr);
    }
    
    /*
     * Method to perform an internal callout using the current session Id for
     * security purposes. The body can be null.
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

        Http h = new Http();
        HttpResponse res = null;
        
        if (!Test.isRunningTest())
            res = h.send(req);
        else {
            res = new HttpResponse();
            res.setBody('');
            res.setStatusCode(200);
        }
        if(res.getStatusCode() == 200){              
            System.debug('Callout successful - ' + res.getBody());
        }
        else{
           System.debug('Callout error - ' + res.getStatusCode() + ' ' + res.getBody());
        }
        
        return res.getBody();
    }

}
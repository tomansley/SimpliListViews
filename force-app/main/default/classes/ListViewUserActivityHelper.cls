public with sharing class ListViewUserActivityHelper {

    private static final String TYPE_ACTION_PROC    = 'ActionProcessed';
    private static final String TYPE_LISTVIEW_VIEW = 'ListViewView';

    public static void registerAction(String pageName, String objectName, String actionName, String actionId, Integer rows)
    {
        //if SLVE is not installed as a package we ignore.
        if (!HelperSchema.isPackageInstalled(HelperSchema.SLVE_NAMESPACE)) return;

        Activity activity      = new Activity();
        activity.actionId      = actionId;
        activity.actionName    = actionName;
        activity.rowsProcessed = rows;
        activity.userId        = UserInfo.getUserId();
        activity.sessionId     = UserInfo.getSessionId();
        activity.activityTime  = System.now();
        activity.pageName      = pageName;
        activity.objectName    = objectName;

        registerActivity(TYPE_ACTION_PROC, activity);
    }

    public static void registerListViewView(String pageName, String pageMode, String objectName, String listViewName, String listViewId, Integer rows)
    {
        //if SLVE is not installed as a package we ignore.
        if (!HelperSchema.isPackageInstalled(HelperSchema.SLVE_NAMESPACE)) return;

        Activity activity      = new Activity();
        activity.listViewId    = listViewId;
        activity.listViewName  = listViewName;
        activity.rowsProcessed = rows;
        activity.userId        = UserInfo.getUserId();
        activity.sessionId     = UserInfo.getSessionId();
        activity.activityTime  = System.now();
        activity.pageMode      = pageMode;
        activity.pageName      = pageName;
        activity.objectName    = objectName;

        registerActivity(TYPE_LISTVIEW_VIEW, activity);
    }


    /**
    * @description Method to register a users activity. This method requires that
    *              SLVE is installed in the same org.
    * @author tom@ansleyllc.com | 03-25-2024 
    * @param type 
    **/
    private static void registerActivity(String activityType, Activity activity)
    {
        System.Type t = Type.forName('simpli_lv_ent', 'Activity__e');

        SObject payload = (SObject) t.newInstance();

        payload.put('simpli_lv_ent__Activity_Type__c', activityType);
        payload.put('simpli_lv_ent__Payload__c', JSON.serialize(activity));

        EventBus.publish(payload);
    }

    class Activity {
        public String actionName      {get; set;}
        public String actionId        {get; set;}
        public Integer rowsProcessed  {get; set;}
        public String listViewId      {get; set;}
        public String listViewName    {get; set;}
        public String sessionId       {get; set;}
        public String userId          {get; set;}
        public DateTime activityTime  {get; set;}
        public String pageName        {get; set;}
        public String pageMode        {get; set;}
        public String objectName      {get; set;}
    }
}
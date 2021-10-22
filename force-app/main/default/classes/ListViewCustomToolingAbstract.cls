/**
 * @description       : 
 * @author            : tom@ansleyllc.com
 * @last modified on  : 10-22-2021
 * @last modified by  : tom@ansleyllc.com
 * Modifications Log 
 * Ver   Date         Author                       Modification
 * 1.0   10-22-2020   tom@ansleyllc.com   Initial Version
 * 2.0   08-18-2021   tom@ansleyllc.com   Updated strings to static final variables
**/
public with sharing abstract class ListViewCustomToolingAbstract extends ListViewCustomAbstract {
    
    public static final String ACTION_QUERY = 'query';
    public static final String ACTION_GET   = 'get';
    public String action                    = null;

    private ListViewCustomToolingRequestData requestData = null;

    public ListViewCustomToolingAbstract(String action)
    {
        this.action   = action;
    }

    public abstract String getEndPoint(ListViewCustomToolingRequestData data);

    public abstract ListViewAbstract.RowsWrapper handleResponse(String responseStr, ListViewCustomToolingRequestData data);

    public void setRequestData(String key, String value)
    {
        requestData.data.put(key, value);
    }

    public override ListViewAbstract.RowsWrapper getData()
    {
        this.requestData = new ListViewCustomToolingRequestData(listview.Object_Name__c);
        this.requestData.action = this.action;

        //set the query into the request data
        setRequestData('query', listview.Core_ListView_Query__c);

        String endPoint = this.getEndPoint(requestData);

        String resultStr = HelperREST.performInternalCallout(endPoint, null);

        ListViewAbstract.RowsWrapper rows = this.handleResponse(resultStr, requestData);

        return rows;
    }

    public override List<List_View_Config_Parameter__c> getConfigParams(List_View_Config__c config)
    {
        List<List_View_Config_Parameter__c> params = new List<List_View_Config_Parameter__c>();

        Map<String, List_View_Config_Parameter__c> paramsByName = new Map<String, List_View_Config_Parameter__c>(); 
        for (List_View_Config_Parameter__c param: config.List_View_Config_Parameters__r)
        {
            paramsByName.put(param.Parameter_Name__c, param); //map to determine parameter existence
            params.add(param); //list returned with ALL params
        }

        if (paramsByName.get('TotalColumns') == null)
        {
            List_View_Config_Parameter__c param = new List_View_Config_Parameter__c();
            param.List_View_Config__c = config.Id;
            param.Parameter_Name__c   = 'TotalColumns';
            param.Parameter_Type__c   = ListViewHelper.TYPE_STRING;
            param.Parameter_Value__c  = '';
            param.Parameter_Label__c  = 'Total Columns';
            params.add(param);
        } else {
            params.add(paramsByName.get('TotalColumns'));
        }

        if (paramsByName.get('TotalColumnsColor') == null)
        {
            List_View_Config_Parameter__c param = new List_View_Config_Parameter__c();
            param.List_View_Config__c = config.Id;
            param.Parameter_Name__c   = 'TotalColumnsColor';
            param.Parameter_Type__c   = 'Color';
            param.Parameter_Value__c  = '';
            param.Parameter_Label__c  = 'Total Column Color';
            params.add(param);
        } else {
            params.add(paramsByName.get('TotalColumnsColor'));
        }

        if (paramsByName.get('ReturnSize') == null)
        {
            List_View_Config_Parameter__c param = new List_View_Config_Parameter__c();
            param.List_View_Config__c = config.Id;
            param.Parameter_Name__c   = 'ReturnSize';
            param.Parameter_Type__c   = ListViewHelper.TYPE_NUMBER;
            param.Parameter_Value__c  = '75';
            param.Parameter_Label__c  = 'Return Size';
            params.add(param);
        } else {
            params.add(paramsByName.get('ReturnSize'));
        }
        
        if (paramsByName.get('RefreshRate') == null)
        {        
            List_View_Config_Parameter__c param = new List_View_Config_Parameter__c();
            param.List_View_Config__c = config.Id;
            param.Parameter_Name__c   = 'RefreshRate';
            param.Parameter_Type__c   = ListViewHelper.TYPE_NUMBER;
            param.Parameter_Value__c  = '45';
            param.Parameter_Label__c  = 'Refresh Rate';
            params.add(param);
        } else {
            params.add(paramsByName.get('RefreshRate'));
        }

        return params;
    }

    public class ListViewCustomToolingRequestData 
    {
        public Map<String, String> data = new Map<String, String>();
        public String objectType        = null;                       //tooling or rest
        public String action            = null;                       //query or get

        public ListViewCustomToolingRequestData(String objectType)
        {
            this.objectType = objectType;
        }

    }

    public class ListViewCustomToolingResponseData 
    {
        public ListViewCustomToolingRequestData requestData = null;
        public ListViewAbstract.RowsWrapper rows            = null;

        public ListViewCustomToolingResponseData(ListViewCustomToolingRequestData requestData)
        {
            this.requestData = requestData;
        }
    }

}
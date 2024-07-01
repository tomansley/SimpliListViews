/**
 * @description       : 
 * @author            : tom@ansleyllc.com
 * @last modified on  : 04-28-2024
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

    public override String getQuery()
    {
        return '';
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

        if (paramsByName.get(ListViewHelper.PARAM_TOTAL_COLUMNS) == null)
        {
            List_View_Config_Parameter__c param = new List_View_Config_Parameter__c();
            param.List_View_Config__c = config.Id;
            param.Parameter_Name__c   = ListViewHelper.PARAM_TOTAL_COLUMNS;
            param.Parameter_Type__c   = ListViewHelper.TYPE_STRING;
            param.Parameter_Value__c  = '';
            param.Parameter_Label__c  = ListViewHelper.PARAM_TOTAL_COLUMNS;
            params.add(param);
        } else {
            params.add(paramsByName.get('TotalColumns'));
        }

        if (paramsByName.get(ListViewHelper.PARAM_TOTAL_COLUMN_COLOR) == null)
        {
            List_View_Config_Parameter__c param = new List_View_Config_Parameter__c();
            param.List_View_Config__c = config.Id;
            param.Parameter_Name__c   = ListViewHelper.PARAM_TOTAL_COLUMN_COLOR;
            param.Parameter_Type__c   = 'Color';
            param.Parameter_Value__c  = '';
            param.Parameter_Label__c  = ListViewHelper.PARAM_TOTAL_COLUMN_COLOR;
            params.add(param);
        } else {
            params.add(paramsByName.get('TotalColumnsColor'));
        }

        if (paramsByName.get(ListViewHelper.PARAM_RETURN_SIZE) == null)
        {
            List_View_Config_Parameter__c param = new List_View_Config_Parameter__c();
            param.List_View_Config__c = config.Id;
            param.Parameter_Name__c   = ListViewHelper.PARAM_RETURN_SIZE;
            param.Parameter_Type__c   = ListViewHelper.TYPE_NUMBER;
            param.Parameter_Value__c  = '75';
            param.Parameter_Label__c  = 'Return Size';
            params.add(param);
        } else {
            params.add(paramsByName.get(ListViewHelper.PARAM_RETURN_SIZE));
        }
        
        if (paramsByName.get(ListViewHelper.PARAM_REFRESH_RATE) == null)
        {        
            List_View_Config_Parameter__c param = new List_View_Config_Parameter__c();
            param.List_View_Config__c = config.Id;
            param.Parameter_Name__c   = ListViewHelper.PARAM_REFRESH_RATE;
            param.Parameter_Type__c   = ListViewHelper.TYPE_NUMBER;
            param.Parameter_Value__c  = '45';
            param.Parameter_Label__c  = 'Refresh Rate';
            params.add(param);
        } else {
            params.add(paramsByName.get(ListViewHelper.PARAM_REFRESH_RATE));
        }

        if (paramsByName.get(ListViewHelper.PARAM_SINGLE_CLICK_REFRESH) == null)
        {        
            List_View_Config_Parameter__c param = new List_View_Config_Parameter__c();
            param.List_View_Config__c = config.Id;
            param.Parameter_Name__c   = ListViewHelper.PARAM_SINGLE_CLICK_REFRESH;
            param.Parameter_Type__c   = ListViewHelper.TYPE_BOOLEAN;
            param.Parameter_Value__c  = ListViewHelper.FFALSE;
            param.Parameter_Label__c  = 'Single Click For Automatic Data Refresh';
            params.add(param);
        } else {
            params.add(paramsByName.get(ListViewHelper.PARAM_SINGLE_CLICK_REFRESH));
        }

        if (paramsByName.get(ListViewHelper.PARAM_EXPORT_HEADER_TYPE) == null)
        {      
            List_View_Config_Parameter__c param = new List_View_Config_Parameter__c();
            param.List_View_Config__c = config.Id;
            param.Parameter_Name__c   = ListViewHelper.PARAM_EXPORT_HEADER_TYPE;
            param.Parameter_Type__c   = ListViewHelper.TYPE_BOOLEAN;
            param.Parameter_Value__c  = ListViewHelper.FFALSE;
            param.Parameter_Label__c  = 'Use API Names For File Export Headers';
            params.add(param);
        } else {
            params.add(paramsByName.get(ListViewHelper.PARAM_EXPORT_HEADER_TYPE));
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
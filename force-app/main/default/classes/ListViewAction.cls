global with sharing abstract class ListViewAction {

        global static final String RESULT_OK = 'Ok';
        global static final String RESULT_ERROR = 'Error';
        global static final String ALL = 'all';
    
        /*
         * The one method that needs to be implemented when using the ListViewAction abstract class.
         */
        global abstract String process(List<String> recordIds, Map<String, Object> fieldValues);
    }
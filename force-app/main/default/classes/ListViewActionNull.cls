/**
 * @description       : 
 * @author            : tom.h.ansley@medtronic.com
 * @group             : 
 * @last modified on  : 02-17-2021
 * @last modified by  : tom.h.ansley@medtronic.com
 * Modifications Log 
 * Ver   Date         Author                       Modification
 * 1.0   09-08-2020   tom.h.ansley@medtronic.com   Initial Version
**/
public with sharing class ListViewActionNull  extends ListViewAction {
    
    public ListViewActionNull() {

    }

    public override String process(List<String> recordIds, Map<String, Object> fieldValues)
	{
        String returnStr = ListViewAction.RESULT_OK + ':';

        return returnStr;
    }
    
}
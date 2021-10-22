/**
 * @description       : 
 * @author            : tom@ansleyllc.com
 * @last modified on  : 10-22-2021
 * @last modified by  : tom@ansleyllc.com
**/
public with sharing class ListViewFlowController {
    
    public String recordIds {get; set;}

    public ListViewFlowController() {
        recordIds = ApexPages.currentPage().getParameters().get('recordIds');

        System.debug(LoggingLevel.FINE, 'Record Ids coming in - ' + recordIds);
        
        //we need to check the record Ids are valid and not an injection for security
        //they should come in as follows - 
        //"0013h000007JTggAAG","0013h000007JTghAAG","0013h000007JTgcAAG]"
        String recordIdStr = recordIds.replaceAll('"', ''); //get rid of double quotes
        Set<String> recordIdSet = HelperString.getSetFromString(recordIdStr, ','); //create set
        for (String recordId: recordIdSet)
        {
            if (recordId.length() != 18) throw new ListViewException('Invalid Id provided');
            recordId = EncodingUtil.urlEncode(recordId, 'UTF-8'); //encode record Id
        }
        recordIds = HelperString.getStringFromSet(recordIdSet, ','); //create string
        recordIds = recordIds.replaceAll(',', '","');
        if (!recordIdSet.isEmpty())
            recordIds = '"' + recordIds + '"';

        System.debug(LoggingLevel.FINE, 'Record Ids going out - ' + recordIds);
    }
}
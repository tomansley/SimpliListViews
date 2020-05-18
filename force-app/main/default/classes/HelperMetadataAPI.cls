public class HelperMetadataAPI
{
    public class HelperMetadataAPIException extends Exception { }
    
    /*
        HelperMetadataAPI.getListView('simpli_lv.Contact.AllContacts');
     */
    public static List_View__c enrichListViewFromMetadata(List_View__c coreListView)
    {
        ListViewMetadataAPIService.MetadataPort service = createService();

        ListViewMetadataAPIService.ListView listView = null;
        // Read List View information
        if (Test.isRunningTest())
        {
            listView = new ListViewMetadataAPIService.ListView();
            listView.columns = new List<String>();
            listView.columns.add('NAME');
            listView.label = 'Test Label';
            listView.sharedTo = new ListViewMetadataAPIService.SharedTo();
            

        } else {
            listView = (ListViewMetadataAPIService.ListView) service.readMetadata('ListView', new String[] { coreListView.Object_Name__c + '.' + coreListView.API_Name__c }).getRecords()[0];
        }

        ListViewMetadataAPIService.SharedTo sharedTo = null;
        //we might have no listview returned.
        if (listView.label != null)
        {
            
            System.debug(LoggingLevel.DEBUG, 'List View - ' + listView);
            
            System.debug(LoggingLevel.DEBUG, 'ListView.booleanFilter - ' + listView.booleanFilter);
            System.debug(LoggingLevel.DEBUG, 'ListView.columns - ' + listView.columns);
            System.debug(LoggingLevel.DEBUG, 'ListView.division - ' + listView.division);
            System.debug(LoggingLevel.DEBUG, 'ListView.filters - ' + listView.filters);
            System.debug(LoggingLevel.DEBUG, 'ListView.filterScope - ' + listView.filterScope);
            System.debug(LoggingLevel.DEBUG, 'ListView.fullName - ' + listView.fullName);
            System.debug(LoggingLevel.DEBUG, 'ListView.label - ' + listView.label);
            System.debug(LoggingLevel.DEBUG, 'ListView.language - ' + listView.language);
            System.debug(LoggingLevel.DEBUG, 'ListView.queue - ' + listView.queue);
            System.debug(LoggingLevel.DEBUG, 'ListView.sharedTo - ' + listView.sharedTo);
            System.debug(LoggingLevel.DEBUG, 'ListView.type - ' + listView.type);
            System.debug(LoggingLevel.DEBUG, 'ListView.columns - ' + listView.columns);
            System.debug(LoggingLevel.DEBUG, 'ListView.filters - ' + listView.filters);

            if(listView.sharedTo != null)
            {
                sharedTo = listView.sharedTo;

                System.debug(LoggingLevel.DEBUG, 'SharedTo.allCustomerPortalUsers - ' + sharedTo.allCustomerPortalUsers);
                System.debug(LoggingLevel.DEBUG, 'SharedTo.allInternalUsers - ' + sharedTo.allInternalUsers);
                System.debug(LoggingLevel.DEBUG, 'SharedTo.allPartnerUsers - ' + sharedTo.allPartnerUsers);
                System.debug(LoggingLevel.DEBUG, 'SharedTo.group_x - ' + sharedTo.group_x);
                System.debug(LoggingLevel.DEBUG, 'SharedTo.role - ' + sharedTo.role);
                System.debug(LoggingLevel.DEBUG, 'SharedTo.roleAndSubordinates - ' + sharedTo.roleAndSubordinates);
                System.debug(LoggingLevel.DEBUG, 'SharedTo.roleAndSubordinatesInternal - ' + sharedTo.roleAndSubordinatesInternal);
                System.debug(LoggingLevel.DEBUG, 'SharedTo.territory - ' + sharedTo.territory);
                System.debug(LoggingLevel.DEBUG, 'SharedTo.territoryAndSubordinates - ' + sharedTo.territoryAndSubordinates);
            }

            coreListview.Boolean_Filter__c = listView.booleanFilter;
            coreListview.Filter_Scope__c = listView.filterScope;

            if(sharedTo != null)
            {
                if (sharedTo.allInternalUsers != null)
                    coreListview.All_Internal_Users__c = true;
                else 
                    coreListview.All_Internal_Users__c = false;

                if (sharedTo.group_x != null)
                    coreListview.Groups__c = String.join(sharedTo.group_x, ',');
                else
                    coreListview.Groups__c = null;

                if (sharedTo.role != null)
                    coreListview.Roles__c = String.join(sharedTo.role, ',');
                else
                    coreListview.Roles__c = null;

                if (sharedTo.roleAndSubordinates != null)
                    coreListview.Roles_And_Subordinates__c = String.join(sharedTo.roleAndSubordinates, ',');
                else
                    coreListview.Roles_And_Subordinates__c = null;

                if (sharedTo.territory != null)
                    coreListview.Territories__c = String.join(sharedTo.territory, ',');
                else
                    coreListview.Territories__c = null;
                
                if (sharedTo.territoryAndSubordinates != null)
                    coreListview.Territories_And_Subordinates__c = String.join(sharedTo.territoryAndSubordinates, ',');
                else
                    coreListview.Territories_And_Subordinates__c = null;
        
            } else {
                coreListview.All_Internal_Users__c = false;
                coreListview.Groups__c = null;
                coreListview.Roles__c = null;
                coreListview.Roles_And_Subordinates__c = null;
                coreListview.Territories__c = null;
                coreListview.Territories_And_Subordinates__c = null;
            }

        }

        return coreListView;
        
    }

    /*
     * Private method to create the metadata API service that is used to make all SOAP calls
     */
    private static ListViewMetadataAPIService.MetadataPort createService()
    {
        ListViewMetadataAPIService.MetadataPort service = new ListViewMetadataAPIService.MetadataPort();
        service.SessionHeader = new ListViewMetadataAPIService.SessionHeader_element();
        if (!Test.isRunningTest())
            service.SessionHeader.sessionId = HelperREST.getSessionIdFromVFPage(Page.SessionId);
        return service;
    }    

}
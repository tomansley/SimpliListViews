/**
 * Copyright (c), FinancialForce.com, inc
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification,
 *   are permitted provided that the following conditions are met:
 *
 * - Redistributions of source code must retain the above copyright notice,
 *      this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright notice,
 *      this list of conditions and the following disclaimer in the documentation
 *      and/or other materials provided with the distribution.
 * - Neither the name of the FinancialForce.com, inc nor the names of its contributors
 *      may be used to endorse or promote products derived from this software without
 *      specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 *  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 *  OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL
 *  THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 *  OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 *  OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 *  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
**/
global class ListViewMetadataAPIService {

    global static String SOAP_M_URI = 'http://soap.sforce.com/2006/04/metadata';

    /*
     * Private method to create the metadata API service that is used to make all SOAP calls
     */
    global static ListViewMetadataAPIService.MetadataPort createService()
    {
        MetadataPort service = new MetadataPort();
        service.SessionHeader = new SessionHeader_element();
        if (!Test.isRunningTest())
            service.SessionHeader.sessionId = HelperREST.getSessionIdFromVFPage(Page.SessionId);
        return service;
    }    


    global class SessionHeader_element {
        global String sessionId;
        private String[] sessionId_type_info = new String[]{'sessionId',SOAP_M_URI,null,'1','1','false'};
        private String[] apex_schema_type_info = new String[]{SOAP_M_URI,'true','false'};
        private String[] field_order_type_info = new String[]{'sessionId'};
    }

    global class DebuggingInfo_element {
        global String debugLog;
        private String[] debugLog_type_info = new String[]{'debugLog',SOAP_M_URI,null,'1','1','false'};
        private String[] apex_schema_type_info = new String[]{SOAP_M_URI,'true','false'};
        private String[] field_order_type_info = new String[]{'debugLog'};
    }

    global class CallOptions_element {
        global String client;
        private String[] client_type_info = new String[]{'client',SOAP_M_URI,null,'1','1','false'};
        private String[] apex_schema_type_info = new String[]{SOAP_M_URI,'true','false'};
        private String[] field_order_type_info = new String[]{'client'};
    }

    global class DebuggingHeader_element {
        global ListViewMetadataAPIService.LogInfo[] categories;
        global String debugLevel;
        private String[] categories_type_info = new String[]{'categories',SOAP_M_URI,null,'0','-1','false'};
        private String[] debugLevel_type_info = new String[]{'debugLevel',SOAP_M_URI,null,'1','1','false'};
        private String[] apex_schema_type_info = new String[]{SOAP_M_URI,'true','false'};
        private String[] field_order_type_info = new String[]{'categories','debugLevel'};
    }

    global class updateMetadataResponse_element {
        global ListViewMetadataAPIService.SaveResult[] result;
        private String[] result_type_info = new String[]{'result',SOAP_M_URI,null,'0','-1','false'};
        private String[] apex_schema_type_info = new String[]{SOAP_M_URI,'true','false'};
        private String[] field_order_type_info = new String[]{'result'};
    }

    global class upsertMetadataResponse_element {
        global ListViewMetadataAPIService.UpsertResult[] result;
        private String[] result_type_info = new String[]{'result',SOAP_M_URI,null,'0','-1','false'};
        private String[] apex_schema_type_info = new String[]{SOAP_M_URI,'true','false'};
        private String[] field_order_type_info = new String[]{'result'};
    }

    global class deleteMetadataResponse_element {
        global ListViewMetadataAPIService.DeleteResult[] result;
        private String[] result_type_info = new String[]{'result',SOAP_M_URI,null,'0','-1','false'};
        private String[] apex_schema_type_info = new String[]{SOAP_M_URI,'true','false'};
        private String[] field_order_type_info = new String[]{'result'};
    }

    global class upsertMetadata_element {
        global ListViewMetadataAPIService.Metadata[] metadata;
        private String[] metadata_type_info = new String[]{'metadata',SOAP_M_URI,null,'0','-1','false'};
        private String[] apex_schema_type_info = new String[]{SOAP_M_URI,'true','false'};
        private String[] field_order_type_info = new String[]{'metadata'};
    }

    global class createMetadata_element {
        global ListViewMetadataAPIService.Metadata[] metadata;
        private String[] metadata_type_info = new String[]{'metadata',SOAP_M_URI,null,'0','-1','false'};
        private String[] apex_schema_type_info = new String[]{SOAP_M_URI,'true','false'};
        private String[] field_order_type_info = new String[]{'metadata'};
    }

    global class updateMetadata_element {
        global ListViewMetadataAPIService.Metadata[] metadata;
        private String[] metadata_type_info = new String[]{'metadata',SOAP_M_URI,null,'0','-1','false'};
        private String[] apex_schema_type_info = new String[]{SOAP_M_URI,'true','false'};
        private String[] field_order_type_info = new String[]{'metadata'};
    }

    global class deleteMetadata_element {
        global String type_x;
        global String[] fullNames;
        private String[] type_x_type_info = new String[]{'type',SOAP_M_URI,null,'1','1','false'};
        private String[] fullNames_type_info = new String[]{'fullNames',SOAP_M_URI,null,'0','-1','false'};
        private String[] apex_schema_type_info = new String[]{SOAP_M_URI,'true','false'};
        private String[] field_order_type_info = new String[]{'type_x','fullNames'};
    }

    global class UpsertResult {
        global Boolean created;
        global ListViewMetadataAPIService.Error[] errors;
        global String fullName;
        global Boolean success;
        private String[] created_type_info = new String[]{'created',SOAP_M_URI,null,'1','1','false'};
        private String[] errors_type_info = new String[]{'errors',SOAP_M_URI,null,'0','-1','false'};
        private String[] fullName_type_info = new String[]{'fullName',SOAP_M_URI,null,'1','1','false'};
        private String[] success_type_info = new String[]{'success',SOAP_M_URI,null,'1','1','false'};
        private String[] apex_schema_type_info = new String[]{SOAP_M_URI,'true','false'};
        private String[] field_order_type_info = new String[]{'created','errors','fullName','success'};
    }

    global class SaveResult {
        global ListViewMetadataAPIService.Error[] errors;
        global String fullName;
        global Boolean success;
        private String[] errors_type_info = new String[]{'errors',SOAP_M_URI,null,'0','-1','false'};
        private String[] fullName_type_info = new String[]{'fullName',SOAP_M_URI,null,'1','1','false'};
        private String[] success_type_info = new String[]{'success',SOAP_M_URI,null,'1','1','false'};
        private String[] apex_schema_type_info = new String[]{SOAP_M_URI,'true','false'};
        private String[] field_order_type_info = new String[]{'errors','fullName','success'};
    }

    global class DeleteResult {
        global ListViewMetadataAPIService.Error[] errors;
        global String fullName;
        global Boolean success;
        private String[] errors_type_info = new String[]{'errors',SOAP_M_URI,null,'0','-1','false'};
        private String[] fullName_type_info = new String[]{'fullName',SOAP_M_URI,null,'1','1','false'};
        private String[] success_type_info = new String[]{'success',SOAP_M_URI,null,'1','1','false'};
        private String[] apex_schema_type_info = new String[]{SOAP_M_URI,'true','false'};
        private String[] field_order_type_info = new String[]{'errors','fullName','success'};
    }

    global class MetadataPort {
        global String endpoint_x = URL.getSalesforceBaseUrl().toExternalForm() + '/services/Soap/m/51.0';
        global Map<String,String> inputHttpHeaders_x;
        global Map<String,String> outputHttpHeaders_x;
        global String clientCertName_x;
        global String clientCert_x;
        global String clientCertPasswd_x;
        global Integer timeout_x;
        global ListViewMetadataAPIService.SessionHeader_element SessionHeader;
        global ListViewMetadataAPIService.DebuggingInfo_element DebuggingInfo;
        global ListViewMetadataAPIService.CallOptions_element CallOptions;
        global ListViewMetadataAPIService.DebuggingHeader_element DebuggingHeader;
        private String SessionHeader_hns = 'SessionHeader=http://soap.sforce.com/2006/04/metadata';
        private String DebuggingInfo_hns = 'DebuggingInfo=http://soap.sforce.com/2006/04/metadata';
        private String CallOptions_hns = 'CallOptions=http://soap.sforce.com/2006/04/metadata';
        private String DebuggingHeader_hns = 'DebuggingHeader=http://soap.sforce.com/2006/04/metadata';
        private String[] ns_map_type_info = new String[]{SOAP_M_URI, 'ListViewMetadataAPIService'};

        global ListViewMetadataAPIService.IReadResult readMetadata(String type_x,String[] fullNames) {
            ListViewMetadataAPIService.readMetadata_element request_x = new ListViewMetadataAPIService.readMetadata_element();
            request_x.type_x = type_x;
            request_x.fullNames = fullNames;
            ListViewMetadataAPIService.IReadResponseElement response_x;
            Map<String, ListViewMetadataAPIService.IReadResponseElement> response_map_x = new Map<String, ListViewMetadataAPIService.IReadResponseElement>();
            response_map_x.put('response_x', response_x);

            if (Test.isRunningTest())
            {

            } else {
                WebServiceCallout.invoke(
                this,
                request_x,
                response_map_x,
                new String[]{endpoint_x,
                '',
                SOAP_M_URI,
                'readMetadata',
                SOAP_M_URI,
                'readMetadataResponse',
                'ListViewMetadataAPIService.read' + type_x + 'Response_element'}
                );
            }
            response_x = response_map_x.get('response_x');
            System.debug(LoggingLevel.FINE, 'RESPONSE_X - ' + response_x);
            return response_x.getResult();
        }

        global ListViewMetadataAPIService.SaveResult[] updateMetadata(ListViewMetadataAPIService.Metadata[] metadata) {
            ListViewMetadataAPIService.updateMetadata_element request_x = new ListViewMetadataAPIService.updateMetadata_element();
            request_x.metadata = metadata;
            ListViewMetadataAPIService.updateMetadataResponse_element response_x;
            Map<String, ListViewMetadataAPIService.updateMetadataResponse_element> response_map_x = new Map<String, ListViewMetadataAPIService.updateMetadataResponse_element>();
            response_map_x.put('response_x', response_x);
            WebServiceCallout.invoke(
              this,
              request_x,
              response_map_x,
              new String[]{endpoint_x,
              '',
              SOAP_M_URI,
              'updateMetadata',
              SOAP_M_URI,
              'updateMetadataResponse',
              'ListViewMetadataAPIService.updateMetadataResponse_element'}
            );
            response_x = response_map_x.get('response_x');
            return response_x.result;
        }

        global ListViewMetadataAPIService.SaveResult[] createMetadata(ListViewMetadataAPIService.Metadata[] metadata) {
            ListViewMetadataAPIService.createMetadata_element request_x = new ListViewMetadataAPIService.createMetadata_element();
            request_x.metadata = metadata;
            ListViewMetadataAPIService.createMetadataResponse_element response_x;
            Map<String, ListViewMetadataAPIService.createMetadataResponse_element> response_map_x = new Map<String, ListViewMetadataAPIService.createMetadataResponse_element>();
            response_map_x.put('response_x', response_x);
            WebServiceCallout.invoke(
              this,
              request_x,
              response_map_x,
              new String[]{endpoint_x,
              '',
              SOAP_M_URI,
              'createMetadata',
              SOAP_M_URI,
              'createMetadataResponse',
              'ListViewMetadataAPIService.createMetadataResponse_element'}
            );
            response_x = response_map_x.get('response_x');
            return response_x.result;
        }

        global ListViewMetadataAPIService.UpsertResult[] upsertMetadata(ListViewMetadataAPIService.Metadata[] metadata) {
            ListViewMetadataAPIService.upsertMetadata_element request_x = new ListViewMetadataAPIService.upsertMetadata_element();
            request_x.metadata = metadata;
            ListViewMetadataAPIService.upsertMetadataResponse_element response_x;
            Map<String, ListViewMetadataAPIService.upsertMetadataResponse_element> response_map_x = new Map<String, ListViewMetadataAPIService.upsertMetadataResponse_element>();
            response_map_x.put('response_x', response_x);
            WebServiceCallout.invoke(
              this,
              request_x,
              response_map_x,
              new String[]{endpoint_x,
              '',
              SOAP_M_URI,
              'upsertMetadata',
              SOAP_M_URI,
              'upsertMetadataResponse',
              'ListViewMetadataAPIService.upsertMetadataResponse_element'}
            );
            response_x = response_map_x.get('response_x');
            return response_x.result;
        }

        global ListViewMetadataAPIService.DeleteResult[] deleteMetadata(String type_x,String[] fullNames) {
            ListViewMetadataAPIService.deleteMetadata_element request_x = new ListViewMetadataAPIService.deleteMetadata_element();
            request_x.type_x = type_x;
            request_x.fullNames = fullNames;
            ListViewMetadataAPIService.deleteMetadataResponse_element response_x;
            Map<String, ListViewMetadataAPIService.deleteMetadataResponse_element> response_map_x = new Map<String, ListViewMetadataAPIService.deleteMetadataResponse_element>();
            response_map_x.put('response_x', response_x);
            WebServiceCallout.invoke(
              this,
              request_x,
              response_map_x,
              new String[]{endpoint_x,
              '',
              SOAP_M_URI,
              'deleteMetadata',
              SOAP_M_URI,
              'deleteMetadataResponse',
              'ListViewMetadataAPIService.deleteMetadataResponse_element'}
            );
            response_x = response_map_x.get('response_x');
            return response_x.result;
        }
    }

    global class createMetadataResponse_element {
        global ListViewMetadataAPIService.SaveResult[] result;
        private String[] result_type_info = new String[]{'result',SOAP_M_URI,null,'0','-1','false'};
        private String[] apex_schema_type_info = new String[]{SOAP_M_URI,'true','false'};
        private String[] field_order_type_info = new String[]{'result'};
    }

    global class LogInfo {
        global String category;
        global String level;
        private String[] category_type_info = new String[]{'category',SOAP_M_URI,null,'1','1','false'};
        private String[] level_type_info = new String[]{'level',SOAP_M_URI,null,'1','1','false'};
        private String[] apex_schema_type_info = new String[]{SOAP_M_URI,'true','false'};
        private String[] field_order_type_info = new String[]{'category','level'};
    }

    global class Error {
        global String[] fields;
        global String message;
        global String statusCode;
        private String[] fields_type_info = new String[]{'fields',SOAP_M_URI,null,'0','-1','false'};
        private String[] message_type_info = new String[]{'message',SOAP_M_URI,null,'1','1','false'};
        private String[] statusCode_type_info = new String[]{'statusCode',SOAP_M_URI,null,'1','1','false'};
        private String[] apex_schema_type_info = new String[]{SOAP_M_URI,'true','false'};
        private String[] field_order_type_info = new String[]{'fields','message','statusCode'};
    }

    global class readMetadataResponse_element {
        global ListViewMetadataAPIService.ReadResult result;
        private String[] result_type_info = new String[]{'result',SOAP_M_URI,null,'1','1','false'};
        private String[] apex_schema_type_info = new String[]{SOAP_M_URI,'true','false'};
        private String[] field_order_type_info = new String[]{'result'};
    }

    global class readMetadata_element {
        global String type_x;
        global String[] fullNames;
        private String[] type_x_type_info = new String[]{'type',SOAP_M_URI,null,'1','1','false'};
        private String[] fullNames_type_info = new String[]{'fullNames',SOAP_M_URI,null,'0','-1','false'};
        private String[] apex_schema_type_info = new String[]{SOAP_M_URI,'true','false'};
        private String[] field_order_type_info = new String[]{'type_x','fullNames'};
    }
    global interface IReadResult {
        ListViewMetadataAPIService.Metadata[] getRecords();
    }
    global interface IReadResponseElement {
        IReadResult getResult();
    }
    global class ReadListViewResult implements IReadResult {
        global ListViewMetadataAPIService.ListView[] records;
        global ListViewMetadataAPIService.Metadata[] getRecords() { return records; }
        private String[] records_type_info = new String[]{'records',SOAP_M_URI,null,'0','-1','false'};
        private String[] apex_schema_type_info = new String[]{SOAP_M_URI,'true','false'};
        private String[] field_order_type_info = new String[]{'records'};
    }
    global class readListViewResponse_element implements IReadResponseElement {
        global ListViewMetadataAPIService.ReadListViewResult result;
        global IReadResult getResult() { return result; }
        private String[] result_type_info = new String[]{'result',SOAP_M_URI,null,'1','1','false'};
        private String[] apex_schema_type_info = new String[]{SOAP_M_URI,'true','false'};
        private String[] field_order_type_info = new String[]{'result'};
    }
    global class ReadResult {
        global ListViewMetadataAPIService.Metadata[] records;
        private String[] records_type_info = new String[]{'records',SOAP_M_URI,null,'0','-1','false'};
        private String[] apex_schema_type_info = new String[]{SOAP_M_URI,'true','false'};
        private String[] field_order_type_info = new String[]{'records'};
    }
    global class ListViewFilter {
        global String field;
        global String operation;
        global String value;
        private String[] field_type_info = new String[]{'field',SOAP_M_URI,null,'1','1','false'};
        private String[] operation_type_info = new String[]{'operation',SOAP_M_URI,null,'1','1','false'};
        private String[] value_type_info = new String[]{'value',SOAP_M_URI,null,'0','1','false'};
        private String[] apex_schema_type_info = new String[]{SOAP_M_URI,'true','false'};
        private String[] field_order_type_info = new String[]{'field','operation','value'};
    }
    
    global class ListView extends Metadata {
        global String type = 'ListView';
        global String fullName;
        global String booleanFilter;
        global String[] columns;
        global String division;
        global String filterScope;
        global ListViewMetadataAPIService.ListViewFilter[] filters;
        global String label;
        global String language;
        global String queue;
        global ListViewMetadataAPIService.SharedTo sharedTo;
        private String[] booleanFilter_type_info = new String[]{'booleanFilter',SOAP_M_URI,null,'0','1','false'};
        private String[] columns_type_info = new String[]{'columns',SOAP_M_URI,null,'0','-1','false'};
        private String[] division_type_info = new String[]{'division',SOAP_M_URI,null,'0','1','false'};
        private String[] filterScope_type_info = new String[]{'filterScope',SOAP_M_URI,null,'1','1','false'};
        private String[] filters_type_info = new String[]{'filters',SOAP_M_URI,null,'0','-1','false'};
        private String[] label_type_info = new String[]{'label',SOAP_M_URI,null,'1','1','false'};
        private String[] language_type_info = new String[]{'language',SOAP_M_URI,null,'0','1','false'};
        private String[] queue_type_info = new String[]{'queue',SOAP_M_URI,null,'0','1','false'};
        private String[] sharedTo_type_info = new String[]{'sharedTo',SOAP_M_URI,null,'0','1','false'};
        private String[] apex_schema_type_info = new String[]{SOAP_M_URI,'true','false'};
        private String[] type_att_info = new String[]{'xsi:type'};
        private String[] fullName_type_info = new String[]{'fullName','http://www.w3.org/2001/XMLSchema','string','0','1','false'};
        private String[] field_order_type_info = new String[]{'fullName', 'booleanFilter','columns','division','filterScope','filters','label','language','queue','sharedTo'};
    }

    global class SharedTo {
        global String allCustomerPortalUsers;
        global String allInternalUsers;
        global String allPartnerUsers;
        global String[] group_x;
        global String[] groups;
        global String[] managerSubordinates;
        global String[] managers;
        global String[] portalRole;
        global String[] portalRoleAndSubordinates;
        global String[] queue;
        global String[] role;
        global String[] roleAndSubordinates;
        global String[] roleAndSubordinatesInternal;
        global String[] roles;
        global String[] rolesAndSubordinates;
        global String[] territories;
        global String[] territoriesAndSubordinates;
        global String[] territory;
        global String[] territoryAndSubordinates;
        private String[] allCustomerPortalUsers_type_info = new String[]{'allCustomerPortalUsers',SOAP_M_URI,null,'0','1','false'};
        private String[] allInternalUsers_type_info = new String[]{'allInternalUsers',SOAP_M_URI,null,'0','1','false'};
        private String[] allPartnerUsers_type_info = new String[]{'allPartnerUsers',SOAP_M_URI,null,'0','1','false'};
        private String[] group_x_type_info = new String[]{'group',SOAP_M_URI,null,'0','-1','false'};
        private String[] groups_type_info = new String[]{'groups',SOAP_M_URI,null,'0','-1','false'};
        private String[] managerSubordinates_type_info = new String[]{'managerSubordinates',SOAP_M_URI,null,'0','-1','false'};
        private String[] managers_type_info = new String[]{'managers',SOAP_M_URI,null,'0','-1','false'};
        private String[] portalRole_type_info = new String[]{'portalRole',SOAP_M_URI,null,'0','-1','false'};
        private String[] portalRoleAndSubordinates_type_info = new String[]{'portalRoleAndSubordinates',SOAP_M_URI,null,'0','-1','false'};
        private String[] queue_type_info = new String[]{'queue',SOAP_M_URI,null,'0','-1','false'};
        private String[] role_type_info = new String[]{'role',SOAP_M_URI,null,'0','-1','false'};
        private String[] roleAndSubordinates_type_info = new String[]{'roleAndSubordinates',SOAP_M_URI,null,'0','-1','false'};
        private String[] roleAndSubordinatesInternal_type_info = new String[]{'roleAndSubordinatesInternal',SOAP_M_URI,null,'0','-1','false'};
        private String[] roles_type_info = new String[]{'roles',SOAP_M_URI,null,'0','-1','false'};
        private String[] rolesAndSubordinates_type_info = new String[]{'rolesAndSubordinates',SOAP_M_URI,null,'0','-1','false'};
        private String[] territories_type_info = new String[]{'territories',SOAP_M_URI,null,'0','-1','false'};
        private String[] territoriesAndSubordinates_type_info = new String[]{'territoriesAndSubordinates',SOAP_M_URI,null,'0','-1','false'};
        private String[] territory_type_info = new String[]{'territory',SOAP_M_URI,null,'0','-1','false'};
        private String[] territoryAndSubordinates_type_info = new String[]{'territoryAndSubordinates',SOAP_M_URI,null,'0','-1','false'};
        private String[] apex_schema_type_info = new String[]{SOAP_M_URI,'true','false'};
        private String[] field_order_type_info = new String[]{'allCustomerPortalUsers','allInternalUsers','allPartnerUsers','group_x','groups','managerSubordinates','managers','portalRole','portalRoleAndSubordinates','queue','role','roleAndSubordinates','roleAndSubordinatesInternal','roles','rolesAndSubordinates','territories','territoriesAndSubordinates','territory','territoryAndSubordinates'};
    }
    
    global virtual class Metadata {
        global String fullName;
        private String[] fullName_type_info = new String[]{'fullName',SOAP_M_URI,null,'0','1','false'};
        private String[] apex_schema_type_info = new String[]{SOAP_M_URI,'true','false'};
        private String[] field_order_type_info = new String[]{'fullName'};
    }

}
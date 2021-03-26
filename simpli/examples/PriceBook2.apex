/*
 * Code to create a custom manual list view for Pricebook2 as one does not exist OOTB.
 */
simpli_lv__List_View__c lv = new simpli_lv__List_View__c();
lv.RecordTypeId                               = [SELECT Id FROM RecordType WHERE SObjectType = 'simpli_lv__List_View__c' AND Name = 'Custom'].Id;
lv.simpli_lv__All_Internal_Users__c           = false;
lv.simpli_lv__API_Name__c                     = 'PricebookStandard';
lv.simpli_lv__Core_ListView_Columns__c	      = '[ { "fieldNameOrPath":"Name", "type":"string", "label":"Name" }, { "fieldNameOrPath":"CreatedDate", "type":"date", "label":"Created Date" }, { "fieldNameOrPath":"IsActive", "type":"boolean", "label":"Is Active" }, { "fieldNameOrPath":"IsStandard", "type":"boolean", "label":"Is Standard" }, { "fieldNameOrPath":"LastModifiedDate", "type":"datetime", "label":"Last Modified Date" } ]';
lv.simpli_lv__Core_ListView_Id__c             = null;
lv.simpli_lv__Core_ListView_Query__c          = 'SELECT CreatedDate,IsActive,IsStandard,LastModifiedDate,Name FROM Pricebook2';
lv.simpli_lv__Custom_Apex_Class__c            = 'ListViewCustomManual';
lv.simpli_lv__Describe__c                     = null;
lv.simpli_lv__Filter_Scope__c                 = null;
lv.simpli_lv__Groups__c                       = null;
lv.simpli_lv__Label__c                        = Pricebook Standard
lv.simpli_lv__Object_Name__c                  = Pricebook2
lv.simpli_lv__Roles_And_Subordinates__c       = null;
lv.simpli_lv__Roles__c                        = null;
lv.simpli_lv__Subtype__c                      = 'Manual';
lv.simpli_lv__Territories_And_Subordinates__c = null;
lv.simpli_lv__Territories__c                  = null;

insert lv;


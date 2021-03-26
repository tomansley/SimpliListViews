/*
 * Code to create a CRAZY custom manual list view showing some of the intricacies of building a more complex custom example.
 * This example uses Opportunity along with opportunity line items.
 */
simpli_lv__List_View__c lv = new simpli_lv__List_View__c();
lv.RecordTypeId                               = [SELECT Id FROM RecordType WHERE SObjectType = 'simpli_lv__List_View__c' AND Name = 'Custom'].Id;
lv.simpli_lv__All_Internal_Users__c           = false;
lv.simpli_lv__API_Name__c                     = 'Opportunity';
lv.simpli_lv__Core_ListView_Columns__c	      = '[{"fieldNameOrPath": "Name","type": "string","label": "Opp Name"},{"fieldNameOrPath": "StageName","type": "string","label": "Stage"},{"fieldNameOrPath": "CloseDate","type": "date","label": "Close Date"},{"fieldNameOrPath": "ExpectedRevenue","type": "currency","label": "Revenue"},{"fieldNameOrPath": "Account.Name","type": "string","label": "Acct Name"},{"fieldNameOrPath": "Account.Type","type": "string","label": "Acct Type"},{"fieldNameOrPath": "Account.Industry","type": "string","label": "Acct Industry"},{"fieldNameOrPath": "PriceBook2.Name","type": "string","label": "Price Book"},{"fieldNameOrPath": "PriceBook2.IsActive","type": "string","label": "PB Active"},{"fieldNameOrPath": "OpportunityLineItems.Name","type": "string","label": "LI Name"},{"fieldNameOrPath": "OpportunityLineItems.ListPrice","type": "currency","label": "Price"},{"fieldNameOrPath": "OpportunityLineItems.Product2.ProductCode","type": "string","label": "Prod Code"},{"fieldNameOrPath": "OpportunityLineItems.Product2.LastModifiedBy.Name","type": "string","label": "Last Modified"},{"fieldNameOrPath": "OpportunityLineItems.Quantity","type": "decimal","label": "Quantity"},{"fieldNameOrPath": "OpportunityLineItems.TotalPrice","type": "currency","label": "Total"}]';
lv.simpli_lv__Core_ListView_Id__c             = null;
lv.simpli_lv__Core_ListView_Query__c          = 'SELECT Name, StageName, CloseDate, ExpectedRevenue, Account.Name, Account.Type, Account.Industry, Pricebook2.Name, PriceBook2.IsActive, (SELECT Name, ListPrice, Product2.Name, Product2.ProductCode, Product2.LastModifiedBy.Name, Quantity, TotalPrice FROM OpportunityLineItems) FROM Opportunity WHERE HasOpportunityLineItem = true AND IsWon = false AND IsClosed = false';
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


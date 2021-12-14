/**
 * @description       : 
 * @author            : tom.h.ansley@medtronic.com
 * @last modified on  : 12-11-2021
 * @last modified by  : tom.h.ansley@medtronic.com
**/
@isTest
public with sharing class ListViewConfigPicklistTest {

    @testSetup
    static void createSampleData()
    {
        ListViewHelper.insertCoreConfiguration();

        HelperTest.insertAccount('Test Account 1');
    }

    @IsTest
    static void getListViewsPicklistTest()
    {
    
        Test.startTest();
            
            ListViewConfigPicklistListViews picklist = new ListViewConfigPicklistListViews(null);

            VisualEditor.DataRow defRow = picklist.getDefaultValue();

            VisualEditor.DynamicPickListRows values = picklist.getValues();

        Test.stopTest();

        System.assertEquals(defRow.getLabel(), null);
        System.assertEquals(defRow.getValue(), null);

        System.assert(values.size() > 0);

    }

    @IsTest
    static void getObjectTypesPicklistTest()
    {
    
        Test.startTest();
            
            ListViewConfigPicklistObjectTypes picklist = new ListViewConfigPicklistObjectTypes(null);

            VisualEditor.DataRow defRow = picklist.getDefaultValue();

            VisualEditor.DynamicPickListRows values = picklist.getValues();

        Test.stopTest();

        System.assertEquals(defRow.getLabel(), 'Account');
        System.assertEquals(defRow.getValue(), 'Account');

        System.assert(values.size() > 0);

    }

}
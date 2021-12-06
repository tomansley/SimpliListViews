/**
 * @description       : 
 * @author            : tom.h.ansley@medtronic.com
 * @last modified on  : 12-06-2021
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

        System.assertEquals(defRow.getLabel(), '');
        System.assertEquals(defRow.getValue(), '');

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

        System.assertEquals(defRow.getLabel(), '');
        System.assertEquals(defRow.getValue(), '');

        System.assert(values.size() > 0);

    }

}
@isTest
public with sharing class SL_RemarketerMatrixTriggerHandlerTest {
    @isTest
    static void InsertRemarketerMatrix() {

        Schema.Location testLocation = new Schema.Location(Name='ALS');
        insert testLocation;

        Remarketer_Matrix_Obj__c newRM = new Remarketer_Matrix_Obj__c(
                Equipment_Type__c = 'Office Equipment(General)',
                Equipment_Subtype__c = 'Copiers',
                Return_Warehouse_Code__c = 'ALS',
                State__c = 'AK'
            );

        Test.startTest();
        insert newRM;
        Test.stopTest();
    }
    
	@isTest
    static void updateRemarketerMatrix() {

        Schema.Location testLocation = new Schema.Location(Name='ALS');
        insert testLocation;

        Remarketer_Matrix_Obj__c newRM = new Remarketer_Matrix_Obj__c(
                Equipment_Type__c = 'Office Equipment(General)',
                Equipment_Subtype__c = 'Copiers',
                Return_Warehouse_Code__c = 'ALS',
                State__c = 'AK'
            );
		insert newRM;


        Test.startTest();
        newRM.Equipment_Subtype__c = 'ATM';
        update newRM;
        Test.stopTest();
    }
}
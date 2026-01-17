@IsTest
public with sharing class TC_UpdateChildDealerAccountsTest {
    
    @TestSetup
    static void makeData(){
        
        Account parent = new Account();
        parent.Name = 'Parent';
        parent.Business_Phone__c = '1111111111';
        parent.RecordTypeId = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByName().get('Dealer Account').getRecordTypeId();
        insert parent;

        Account child = new Account();
        child.Name = 'Child';
        child.Business_Phone__c = '1111111111';
        child.RecordTypeId = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByName().get('Dealer Account').getRecordTypeId();
        child.ParentId = parent.Id;
        Test.startTest();
        insert child;
        Test.stopTest();
    }

    @IsTest
    static void testParentUpdate() {

        Account parent = [SELECT Id, Name, Equipment_Type__c FROM Account WHERE Name = 'Parent'];
        parent.Equipment_Type__c = 'ATM';
        
        Test.startTest();
        update parent;
        Test.stopTest();
    }

    @IsTest
    static void testChildUpdate() {
        
        Account child = [SELECT Id, Name, Equipment_Type__c FROM Account WHERE Name = 'Child'];
        child.Equipment_Type__c = 'ATM';
        
        Test.startTest();
        update child;
        Test.stopTest();
    }
    
    @IsTest
    static void testHandleParents() {
        
        Map<Id, Dealer_Child_Account_Field__mdt> dealerChildAccountFieldMap = TC_UpdateChildDealerAccounts.queryFieldsFromMetadata();
        List<String> fieldNames = TC_UpdateChildDealerAccounts.createListFromFieldNames(dealerChildAccountFieldMap);
        
        Account parent = Database.query('SELECT Id, ParentId, ' + String.join(fieldNames, ',') + ' FROM Account WHERE Name = \'Parent\' ');
        Map<Id, Account> accMap = new Map<Id, Account>();
        accMap.put(parent.Id, parent);
        
        TC_UpdateChildDealerAccounts.handleParents(accMap, accMap, 'Manager');
    }
}
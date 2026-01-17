@isTest
public with sharing class TC_BookToInfoLeaseByRecordIdTest {
    @testSetup 
    public static void setupData () {

        Account account = new Account(
            Name = 'TC_BookToInfoLeaseByRecordIdTest',
            Business_City__c = 'Minneapolis',
            Business_State__c = 'MN',
            Business_Address__c = '701 N 3rd St',
            Business_Zip__c = '55401',
            Business_Type__c = 'Proprietorship'
        );
        insert account;
        System.assertNotEquals(null, account.Id);
        
        Opportunity opportunity = new Opportunity(
            Name = 'TC_BookToInfoLeaseByRecordIdTest',
            StageName = 'Booking',
            CloseDate = Date.today(),
            Tax_ID__c = '123456789',
            Probability = 76,
            Credit_Stips_Completed_Date__c = Date.today(),
            Assign_To_CMS_User__c = UserInfo.getUserId(),
            AccountId = account.Id
        );
        Test.startTest();
        insert opportunity;
        System.assertNotEquals(null, opportunity.Id);
        Test.stopTest();
    }
    @IsTest
    static void bookToInfoLeaseByRecordIdTest() {
        Opportunity opp = [SELECT Id, OwnerId FROM Opportunity WHERE Name = 'TC_BookToInfoLeaseByRecordIdTest'];
        TC_BookToInfoLeaseByRecordId.bookToInfoLeaseByRecordId(opp.Id);
    }

}
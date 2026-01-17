@isTest
public with sharing class SL_AccountTriggerEmailsTest {
    @isTest
    public static void sendIt() {
        SL_SCTestData.createAccountAndContracts(1, 1);
        Account theAccount = SL_SCTestData.testAccounts[0];
        theAccount.IF_Decision_Status__c = 'M';
        List<AccountContactRelation> acctContRelationships = [SELECT Id, Roles FROM AccountContactRelation WHERE AccountId = :theAccount.Id];
        if(acctContRelationships.size() > 0){
            acctContRelationships[0].Roles = 'Primary Contact';
            update acctContRelationships;
        }
        Test.startTest();
        update theAccount;
        Test.stopTest();
    }
}
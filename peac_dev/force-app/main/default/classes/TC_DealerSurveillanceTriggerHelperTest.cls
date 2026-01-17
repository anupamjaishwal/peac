@isTest
public class TC_DealerSurveillanceTriggerHelperTest {
    
    @testSetup
    public static void insertDealerAndSurveillance () {
        Account acc = new Account (Name = 'dstest');
        insert acc;
        
        Dealer_Surveillance__c ds = new Dealer_Surveillance__c (Account__c = acc.Id, Status__c = 'Completed');
        //insert ds;
    }
    
    @isTest
    public static void createAdditionalDSTest () {
        Account acc = [SELECT Id FROM Account WHERE Name = 'dstest'][0];
        Dealer_Surveillance__c ds = new Dealer_Surveillance__c (Account__c = acc.Id, Status__c = 'Completed');
        //insert ds;
    }

}
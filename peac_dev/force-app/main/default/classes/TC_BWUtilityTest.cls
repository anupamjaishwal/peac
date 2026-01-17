@isTest
public class TC_BWUtilityTest {
    
    @TestSetup
    static void setup() {
    
        ORE__c o = new ORE__c(Bypass__c = true);
        insert o; 
        SL_SCTestData.createAccountAndContracts(1, 1);
        Account acc = new Account();
        acc.Name = 'TestAccount';
        acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('End User Account').getRecordTypeId();
        acc.Business_Type__c ='Proprietorship';
        insert acc;
        Test.startTest();
        List<opportunity> oppRec = new list<opportunity>();
        Opportunity opp = new Opportunity();
        opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Express Quote').getRecordTypeId();
        opp.Name = 'Test Opportunity';
        opp.AccountId = acc.Id;
        opp.StageName = 'Quote';
        opp.Primary_Source__c = 'Customer Inbound - Call';
        opp.CloseDate = System.today();
        opp.Account_Business_City__c = 'Test';
        opp.Account_Business_Country__c = 'Test2';
        opp.Account_Business_State_Province__c = 'PA';
        opp.Account_Business_Street__c ='Test4';
        opp.Account_Business_Street2__c = 'Test5';
        opp.Account_Business_Zip_Postal_Code__c = 'Test6';
        opp.Equipment_Cost__c = 10;
        opp.Branch__c ='IFP - Indirect Funding Pl';
        opp.Yield__c = 10;
        opp.Terms__c = 12;
        opp.amount = 1000;
        opp.Tax_ID__c = '213123245';
        opp.Application_Status__c = 'Automatically Approved';
        
        oppRec.add (opp);
        insert oppRec;
        Test.stopTest();
    }
    
    @IsTest
    static void TC_BWUtility(){
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Boolean isIL10, isAlsoIL9;
        Contract__c theContract = [SELECT Id, Infolease_Environment__c FROM Contract__c LIMIT 1];
        theContract.Infolease_Environment__c = '10';
        update theContract;
        Test.startTest();
        TC_BWUtility.getInstance();
        //TC_BWUtility.getServiceSettings();
        TC_BWUtility.getGuarantors(opp.Id, 'test');
        TC_BWUtility.getDealers(opp.Id);
        isIL10 = TC_BWUtility.isIL10Record(theContract);
        isAlsoIL9 = TC_BWUtility.isMigratedRecord(theContract);
        HttpRequest req = new HttpRequest();
        TC_BWUtility.requestToIL10(req);
        TC_BWUtility.requestToIL10(req, 'UCI');
        Test.stopTest();
        Assert.areEqual(true, isIL10);
        Assert.areEqual(false, isAlsoIL9);
    }
}
@isTest public class TC_TrustPilotAPITest {
    
    @testsetup
    public static void setupIntData () {
        insert new Trust_Pilot_App__c(API_Key__c = 'test', Secret__c = 'test', Business_Id__c = 'test', Invitation_URL__c = 'TrustPilot2Resp', Password__c = 'tes', Token_URL__c = 'TrustPilot1Resp', Username__c = 'test');
        Account acc = new Account (Name = 'test', Business_Phone__c = '1234567890');
        insert acc;
        Opportunity opp = new Opportunity (Name = 'trustpilot', StageName = 'Quote ', CloseDate = Date.today (), AccountId = acc.Id);
        insert opp;
        
        Contact con = new Contact (FirstName = 'test', LastName = 'tes', AccountId = acc.Id);
        insert con;
        
        insert new OpportunityContactRole (ContactId = con.Id, OpportunityId = opp.Id, IsPrimary = true);
    }
    
    @istest
    public static void syncTest () {
        Test.startTest();
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'trustpilot'][0];
        Test.setMock(HttpCalloutMock.class, new TC_TrustPilotResponseGenerator());
        TC_TrustPilotAPI.generateInvitation (opp.Id);
        Test.stopTest();
        
    }
    @istest
    public static void asyncTest () {
        Test.startTest();
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'trustpilot'][0];
        Test.setMock(HttpCalloutMock.class, new TC_TrustPilotResponseGenerator());
        System.enqueueJob (new TC_TrustPilotQueueable (new Set <Id> {opp.Id}));
        Test.stopTest();
        
    }

}
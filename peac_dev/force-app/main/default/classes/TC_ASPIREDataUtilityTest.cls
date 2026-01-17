@isTest
public class TC_ASPIREDataUtilityTest {
@isTest 
    public static void runTest(){
        
        Account acc = TestDataFactory.createAspireAccount();
	    Contact c=TestDataFactory.createTestContact(acc.Id);
        Opportunity opp = TestDataFactory.createAspireOpportunity(acc);
		String accid = acc.Id;
        TC_ASPIRE__Account__c aspireAcc = TestDataFactory.createTCAspireAccount(acc, accid);
        OpportunityContactRole crole=new OpportunityContactRole(OpportunityId=opp.Id, ContactId=c.Id);
        List<TC_ASPIRE__Account__c> aspireList=new List<TC_ASPIRE__Account__c>();
        aspireList.add(aspireAcc);
        Map<String, Object> oMap=new Map<String, Object>();
        oMap.put('accounts',aspireList);
        Guarantor__c g=new Guarantor__c(Account__c=acc.Id, Contact__c=c.Id, Opportunity__c=opp.Id, type__c='Personal Guarantor');
        insert g;
        Test.startTest();
        TC_AspireDataUtility.createASPIREObjectData(opp.Id);
        TC_AspireDataUtility.selectASPIREObjectData(opp.Id);
        TC_AspireDataUtility.deleteASPIREObjectData(oMap);
        List<TC_ASPIRE__Account__c> a = [SELECT Id FROM TC_ASPIRE__Account__c];
        System.assert(a.size() > 0, 'No Aspire Accounts were created.');
        Test.stopTest();
    }
}
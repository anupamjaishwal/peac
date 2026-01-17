@IsTest
private class TC_LeadOutcomeDateChangeTests {
    
    @IsTest static void testBehavior() {
        Test.startTest();
        List<PicklistEntry> ples = Lead.getSObjectType().getDescribe().fields.getMap().get('Lead_Outcome__c').getDescribe().picklistValues;
        Lead l = TC_SDR_TestUtility.constructLead('ln','fn','test',null);
        insert l;
        l.Lead_Outcome__c = ples[0].value;
        update l;
        l = [SELECT Id, LeadOutcomeDate__c FROM Lead WHERE Id = :l.Id];
        System.assert(l.LeadOutcomeDate__c != null);
        Test.stopTest();
    }
}
/**************************************************************************************************************
@Author:Rajesh Kumar(LTIMindtree)
@Description:PEAC_EmailMessageTriggerHelperTest class is used to test the business logic of
			Email message object and code cover of PEAC_EmailMessageTriggerHelper class.
@User Story:SL-2121	
@Created Date:August-15-2024
**************************************************************************************************************/
@isTest
private class PEAC_EmailMessageTriggerHelperTest
 {
    @isTest
    public static void fromClosedCase() {
        SL_SCTestData.createAccountAndContracts(1, 1);
        Contract__c ctr = [SELECT Id, Lessor_Code__c from Contract__c];
        ctr.Lessor_Code__c = '020';
        update ctr;
        insert new Case(Subject = 'test parent', Description = 'test parent case',
            Contract_custom__c = ctr.Id, Origin = 'Phone', Status = 'New');
        Case closedCase = [SELECT Id, Contract_custom__c FROM Case];
        closedCase.Status = 'Closed';
        update closedCase;
        EmailMessage sourceEmail = new EmailMessage(ToAddress = 'yet.another.email@address.com', 
            Subject = 'test', TextBody = 'body with ach test.', ParentId = closedCase.Id,
            Incoming = true);
        Test.startTest();
        insert sourceEmail;
        Test.stopTest();
        List<Case> casesAfter = [SELECT Id, ParentId, Contract_custom__c, Subject, Description FROM Case WHERE Id != :closedCase.Id];
        System.assertEquals(closedCase.Id, casesAfter[0].ParentId);
        System.assertEquals(closedCase.Contract_custom__c, casesAfter[0].Contract_custom__c);
        System.assertEquals('test', casesAfter[0].Subject);
        System.assertEquals('body with ach test.', casesAfter[0].Description);
    }
    

    
}
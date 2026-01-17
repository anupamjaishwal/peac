@isTest
public class SL_CaseTriggerHandlerTest {
    @isTest
    static void SLA4_Partner() {
        Group ownerQueue = [SELECT Id, DeveloperName FROM Group WHERE Type = 'Queue' AND DeveloperName = 'Partner'];
        EmailMessage sourceEmail = new EmailMessage(ToAddress = 'buyouts@peacsolutions.com');
        insert sourceEmail;
        SL_SCTestData.createAccountAndContracts(3, 1);
        AccountContactRelation acr = [SELECT Roles FROM AccountContactRelation 
            WHERE AccountId = : SL_SCTestData.testAccounts[0].Id AND ContactId =:SL_SCTestData.testContacts[0].Id];
        acr.Roles = 'Primary Contact';
        update acr;
        insert new Contract_Contact_Role__c(Contract__c = SL_SCTestData.testContracts[1].Id, Contact__c = SL_SCTestData.testContacts[1].Id, Role__c = 'Primary Contact');
        Test.startTest();
        Case newCase = new Case(Subject = 'test', Description = 'test case', OwnerId = ownerQueue.Id, SourceId = sourceEmail.Id);
        List<Case> newCases = new List<Case>{
            new Case(Subject = 'test from account', Description = 'test case 2', AccountId = SL_SCTestData.testAccounts[0].Id, Contract_custom__c=null),
            new Case(Subject = 'test from Contract', Description = 'test case', Contract_custom__c = SL_SCTestData.testContracts[1].Id),
            new Case(Subject = 'test from Contract', Description = 'test case without Contract contact Roles', Contract_custom__c = SL_SCTestData.testContracts[2].Id)};
        newCases.add(newCase);
        insert newCases;
        Test.stopTest();
        List<Case> casesAfter = [SELECT Id, Subject, Contract_custom__c, OwnerId, SourceId, Initial_Response_SLA__c, ContactId, AccountId FROM Case];
        System.assertEquals(4, casesAfter[3].Initial_Response_SLA__c);
        System.assertEquals(SL_SCTestData.testContacts[0].Id, casesAfter[0].ContactId);
        System.assertEquals(SL_SCTestData.testContacts[1].Id, casesAfter[1].ContactId);
        System.Assert.areEqual(SL_SCTestData.testAccounts[2].Id, casesAfter[2].AccountId, 'AccountId has to be populated from Contract_Custom__r.Customer__c');
    }
    @isTest
    static void SLA4_Working_Capital() {
        Group ownerQueue = [SELECT Id, DeveloperName FROM Group WHERE Type = 'Queue' AND DeveloperName = 'Working_Capital'];
        EmailMessage sourceEmail = new EmailMessage(ToAddress = 'yet.another.email@address.com', Subject = 'test weLcome tO maRlin title');
        insert sourceEmail;
        Test.startTest();
        Case newCase = new Case(Subject = 'test', Description = 'test case', OwnerId = ownerQueue.Id, SourceId = sourceEmail.Id);
        insert newCase;
        Test.stopTest();
        Case caseAfter = [SELECT Id, Initial_Response_SLA__c FROM Case];
        System.assertEquals(4, caseAfter.Initial_Response_SLA__c);
    }
    @isTest
    static void SLA72_All_Other() {
        Group ownerQueue = [SELECT Id, DeveloperName FROM Group WHERE Type = 'Queue' AND DeveloperName = 'All_Other'];
        EmailMessage sourceEmail = new EmailMessage(ToAddress = 'yet.another.email@address.com', TextBody = 'body with unloCk potential');
        insert sourceEmail;
        Test.startTest();
        Case newCase = new Case(Subject = 'test', Description = 'test case', OwnerId = ownerQueue.Id, SourceId = sourceEmail.Id);
        insert newCase;
        Test.stopTest();
        Case caseAfter = [SELECT Id, Initial_Response_SLA__c FROM Case];
        System.assertEquals(72, caseAfter.Initial_Response_SLA__c);
    }
    @isTest
    static void SLA72_Blind() {
        Group ownerQueue = [SELECT Id, DeveloperName FROM Group WHERE Type = 'Queue' AND DeveloperName = 'Blind'];
        EmailMessage sourceEmail = new EmailMessage(ToAddress = 'other.email@address.com');
        insert sourceEmail;
        Case newCase = new Case(Subject = 'test', Description = 'test case', OwnerId = ownerQueue.Id, SourceId = sourceEmail.Id, Origin = 'Email - CS Fax');
        insert newCase;
        newCase.SourceId = sourceEmail.Id;
        Test.startTest();
        update newCase;
        Test.stopTest();
        Case caseAfter = [SELECT Id, Initial_Response_SLA__c FROM Case];
        System.assertEquals(72, caseAfter.Initial_Response_SLA__c);
    }
    @isTest
    static void SLA72_End_of_Term() {
        Group ownerQueue = [SELECT Id, DeveloperName FROM Group WHERE Type = 'Queue' AND DeveloperName = 'End_of_Term'];
        EmailMessage sourceEmail = new EmailMessage(ToAddress = 'yet.another.email@address.com', TextBody = 'body with unloCk potential');
        insert sourceEmail;
        Test.startTest();
        Case newCase = new Case(Subject = 'test', Description = 'test case', OwnerId = ownerQueue.Id, SourceId = sourceEmail.Id);
        insert newCase;
        Test.stopTest();
        Case caseAfter = [SELECT Id, Initial_Response_SLA__c FROM Case];
        System.assertEquals(72, caseAfter.Initial_Response_SLA__c);
    }
    @isTest
    static void SLA72_File_Room() {
        Group ownerQueue = [SELECT Id, DeveloperName FROM Group WHERE Type = 'Queue' AND DeveloperName = 'File_Room'];
        EmailMessage sourceEmail = new EmailMessage(ToAddress = 'customercare@lease-services.com');
        insert sourceEmail;
        Test.startTest();
        Case newCase = new Case(Subject = 'test', Description = 'test case', OwnerId = ownerQueue.Id, SourceId = sourceEmail.Id, Origin = 'Email - Lease Services');
        insert newCase;
        Test.stopTest();
        Case caseAfter = [SELECT Id, Initial_Response_SLA__c FROM Case];
        System.assertEquals(72, caseAfter.Initial_Response_SLA__c);
    }
    @isTest
    static void SLA72_remainingQueues() {
        Group ownerQueue1 = [SELECT Id, DeveloperName FROM Group WHERE Type = 'Queue' AND DeveloperName = 'Insurance'];
        Group ownerQueue2 = [SELECT Id, DeveloperName FROM Group WHERE Type = 'Queue' AND DeveloperName = 'Internal_Servicing'];
        Group ownerQueue3 = [SELECT Id, DeveloperName FROM Group WHERE Type = 'Queue' AND DeveloperName = 'Ops_Email_Box'];
        Group ownerQueue4 = [SELECT Id, DeveloperName FROM Group WHERE Type = 'Queue' AND DeveloperName = 'Titled_Vehicle'];
        Test.startTest();
        Case newCase1 = new Case(Subject = 'test', Description = 'test case', OwnerId = ownerQueue1.Id);
        insert newCase1;
        Case newCase2 = new Case(Subject = 'test', Description = 'test case', OwnerId = ownerQueue2.Id);
        insert newCase2;
        Case newCase3 = new Case(Subject = 'test', Description = 'test case', OwnerId = ownerQueue3.Id);
        insert newCase3;
        Case newCase4 = new Case(Subject = 'test', Description = 'test case', OwnerId = ownerQueue4.Id);
        insert newCase4;
        Test.stopTest();
        List<Case> casesAfter = [SELECT Id, Initial_Response_SLA__c FROM Case];
        System.assertEquals(72, casesAfter[0].Initial_Response_SLA__c);
        System.assertEquals(72, casesAfter[1].Initial_Response_SLA__c);
        System.assertEquals(72, casesAfter[2].Initial_Response_SLA__c);
        System.assertEquals(72, casesAfter[3].Initial_Response_SLA__c);
    }
    // @isTest
    // static void SLA72_default() {
    //     Test.startTest();
    //     Case newCase = new Case(Subject = 'not null', Description = 'test case');
    //     insert newCase;
    //     Test.stopTest();
    //     Case caseAfter = [SELECT Id, Initial_Response_SLA__c FROM Case];
    //     System.assertEquals(72, caseAfter.Initial_Response_SLA__c);
    // }
    @isTest
    static void SLA_beforeInsert() {
        List<Group> ownerQueue = [SELECT Id, DeveloperName FROM Group WHERE Type = 'Queue' AND (DeveloperName = 'Insurance' OR DeveloperName = 'Titled_Vehicle') ];
        EmailMessage sourceEmail = new EmailMessage(ToAddress = 'buyouts@peacsolutions.com');
        insert sourceEmail;
        SL_Email_Addresses__c setting = new SL_Email_Addresses__c();
        setting.Name = 'Insurance_TitleVehicle';
        setting.TypeEmailAddress__c = 'Insurance@peacsolutions.com,TV@peacsolutions.com';
        insert setting;
         SL_Email_Addresses__c setting1 = new SL_Email_Addresses__c();
        setting1.Name = 'OtherTypes';
        setting1.TypeEmailAddress__c = 'Insurance@peacsolutions.com,TV@peacsolutions.com';
        insert setting1;
        Test.startTest();
        Case newCase = new Case(Subject = 'test', Description = 'test case', OwnerId = ownerQueue[0].Id, SourceId = sourceEmail.Id);
        insert newCase;
        Case newCase1 = new Case(Subject = 'test', Description = 'test case',IsEscalated= true, OwnerId = ownerQueue[1].Id, SourceId = sourceEmail.Id);
        insert newCase1;
        newCase1.OwnerId = newCase.ownerId;
        update newCase1;
        newCase.OwnerId = newCase1.ownerId;
        newCase.IsEscalated = true;
        update newCase;
        
        BusinessDays.isWithin();
        BusinessDays.nextStartDate();
        BusinessDays.nextStartDate(system.now());
        BusinessDays.getSLATimeByBusinessHour(system.now(),48);
        Test.stopTest();
        List<Case> caseAfter = [SELECT Id, OwnerId, SourceId, Initial_Response_SLA__c FROM Case];
        System.assertEquals(72, caseAfter[0].Initial_Response_SLA__c);
    }

    @isTest
    static void afterClosed() {
        insert new Case(Subject = 'test parent', Description = 'test parent case');
        Case closedCase = [SELECT Id, CaseNumber FROM Case];
        closedCase.Status = 'Closed';
        update closedCase;
        EmailMessage sourceEmail = new EmailMessage(ToAddress = 'yet.another.email@address.com', 
            Subject = 'test', TextBody = 'body with ach test. \r\nAn email has been received for case ' + closedCase.CaseNumber + ': testing');
        insert sourceEmail;
        EmailMessage sourceEmail2 = new EmailMessage(ToAddress = 'yet.another.email@address.com', 
            Subject = 'test new case email notification. case number ' + closedCase.CaseNumber, TextBody = 'body with test. : testing');
        insert sourceEmail2;
        Test.startTest();
        Case newCase = new Case(Subject = 'test revived 1', Description = 'test case 1', SourceId = sourceEmail.Id);
        Case newCase2 = new Case(Subject = 'test rekindled 2', Description = 'test case 2', SourceId = sourceEmail2.Id);
        insert newCase;
        insert newCase2;
        User adminUser = SL_SCTestData.createTestUser();
        System.runAs(adminUser){
            newCase2.OwnerId = adminUser.Id;
            newCase2.Status = 'New';
            update newCase2;
        }
        Test.stopTest();
        List<Case> casesAfter = [SELECT Id, ParentId, Status FROM Case WHERE Id != :closedCase.Id];
        System.assertEquals(closedCase.Id, casesAfter[0].ParentId);
        System.assertEquals(closedCase.Id, casesAfter[1].ParentId);
        Assert.areEqual('In Progress', casesAfter[1].Status);
    }
	@isTest
    static void testXBSCheckbox(){
        Id DEALER_REQUEST_RT_ID = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Dealer_Requests').getRecordTypeId();
        SL_SCTestData.createAccountAndContracts(1, 5);
        SL_SCTestData.testContracts[4].Program__c = 'XBS';

        UPDATE SL_SCTestData.testContracts[4];

        String contractNames = '';
        for(Contract__c contract :SL_SCTestData.testContracts){
            contractNames += contract.Name + ',';
        }
        
        List<Case> lstCase = new List<Case>();
        for(Integer i=0; i<10; i++){
            Case caseRec = new Case();
            caseRec.RecordtypeId = DEALER_REQUEST_RT_ID;
            caseRec.Status = 'New';
            caseRec.Web_Contracts__c = contractNames;
            if(i > 4){
                caseRec.Web_Contracts__c = contractNames.replaceAll(',', ';');
            }

            lstCase.add(caseRec);
        }

        Test.startTest();

        INSERT lstCase;

        Test.stopTest();

        List<Case> lstCaseCreated = [SELECT Id, XBS__c FROM Case];
        for(Case caseRec : lstCaseCreated){
            Assert.isTrue(caseRec.XBS__c, 'XBS Checkbox should be checked');
            caseRec.Web_Contracts__c = null;
        }
		lstCaseCreated[0].Web_Contracts__c = 'testNotFound';
        lstCaseCreated[0].Contract_custom__c = null;
        UPDATE lstCaseCreated[0];

        for(Case caseRec : [SELECT Id, XBS__c, XBS_Contract__c, Contract_custom__c, Web_Contracts__c FROM Case WHERE Id = :lstCaseCreated[0].Id]){
            Assert.isFalse(caseRec.XBS__c, 'XBS Checkbox should be unchecked');
        }
    }
    
    @isTest
    static void testAutoResponse(){
        Case testWebCase = new Case();
        testWebCase.Status = 'New';
        testWebCase.Origin = 'Web';
        Test.startTest();
        insert testWebCase;
        Test.stopTest();
    }
    
}
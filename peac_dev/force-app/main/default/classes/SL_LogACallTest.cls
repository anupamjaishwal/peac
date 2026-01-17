@isTest
public with sharing class SL_LogACallTest {
    @isTest
    static void loadEmulatedTask() {
        SL_MessageCodeHelper theHelper = new SL_MessageCodeHelper();
        String fieldList = 'Department__c,Activity__c,Primary_Call_Outcome__c,Secondary__c,Description';
        SL_SCTestData.createAccountAndContracts(1, 2);
        Account customer = [SELECT Id FROM Account];
        List<Contract__c> contracts = [SELECT Id, Customer__c FROM Contract__c];
        String result1 = '', result2 = '', result3 = ''; 
        Test.startTest();
        String department = 'Operations';
        String primaryCallOutcome = 'Updated AR Address';// SL-1832 Misael Romero
        Date followUpDate = theHelper.handleMessageCodes(department, primaryCallOutcome);
        Contact con = new Contact(LastName='lastname', FirstName = 'First Name', Phone='1234567890');
        insert con;
        List<String> saveParameters = new List<String>{
            String.valueOf(contracts[0].Id),
            department,
            'Call',
            primaryCallOutcome,
            'Shipping Instructions Issued',
            String.valueOf(followUpDate),
            'test description',
            con.Id
        };
        
        Contract_Contact_Role__c ccr = new Contract_Contact_Role__c();
            ccr.Contract__c = contracts[0].Id;
            ccr.Contact__c = con.Id;
        sL_LogACall.fetchCCRRecords(String.valueOf(contracts[0].Id));
        sL_LogACall.populateNewCreatedCCR(String.valueOf(contracts[0].Id));
        sL_LogACall.createContactRecord(ccr);
        result1 = SL_LogACall.hubExecute('loadEmulatedTask', new List<String>{fieldList});
        result2 = SL_LogACall.hubExecute('validateBusinessDay', new List<String>{String.valueOf(Date.newInstance(2022, 7, 6))});
        result3 = SL_LogACall.hubExecute('saveTask', saveParameters);
        
        Test.stopTest();
        List<Contract__c> contractsAfter = [SELECT Id, Customer__c, Followup_Date__c FROM Contract__c];
        Task taskAfter = [SELECT Id, Followup_Date__c FROM Task];
        Date expectedDate = theHelper.addBussinessDaysV2(Date.today(), 1);
        System.assert(result1.contains('{"dependencies": ') 
            && result1.contains(', "optionsByField": ')
            && result1.contains(', "controllingFields": ')
            && result1.contains(', "dependentFields": '));
        System.assertEquals('{"isValid": true}', result2);
        System.assertEquals('success', result3);
        System.assertEquals(expectedDate, taskAfter.Followup_Date__c);
        System.assertEquals(expectedDate, contractsAfter[0].Followup_Date__c);
        System.assertEquals(expectedDate, contractsAfter[1].Followup_Date__c);
    }

    @isTest
    static void calculateFollowup(){
        UserRole nonAdminRole = [SELECT Id, Name FROM UserRole WHERE Name = 'Collections Staff'];
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Services Admin'];
        User u = SL_SCTestData.createTestUser(p.Id);
        String result1 = '', result2 = '';
        System.runAs(u) {
            u.UserRoleId = nonAdminRole.Id;
            update u;
            Test.startTest();
            result1 = SL_LogACall.hubExecute('calculateFollowup', new List<String>{'Collections', 'Requested Deferral'});
            result2 = SL_LogACall.hubExecute('calculateFollowup', new List<String>{'Operations', 'R.A. Issued'});
            Test.stopTest();
        }
        SL_MessageCodeHelper theHelper = new SL_MessageCodeHelper();
        Date expectedDate = theHelper.addBussinessDaysV2(Date.today(), 5);
        System.Assert.isTrue(result1.contains(JSON.serialize(expectedDate)));
        System.Assert.isTrue(result1.contains('maxFollowup') && result1.contains('minFollowup'));
        System.Assert.areEqual('{"followupDate": null, "maxFollowup": null, "minFollowup": null}', result2);
    }
}
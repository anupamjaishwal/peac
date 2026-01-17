@isTest
public with sharing class SL_ManageBalanceCBRTest {
    
    @TestSetup static void setup() {
    UserRole adminRole = [SELECT Id, Name FROM UserRole WHERE Name = 'Collections Manager'];
            Profile p = [SELECT Id FROM Profile WHERE Name = 'Collections'];
            User u = new User(Alias = 'CBRTest', Email = 'CBRmarlinbusiness@silverlinecrm.com', EmailEncodingKey='UTF-8',
                    LastName = 'testing', FirstName = 'user', LanguageLocaleKey = 'en_US',
                    LocaleSidKey = 'en_US', ProfileId = p.Id, TimeZoneSidKey = 'America/Los_Angeles', IsActive=true,
                    Username = 'CBR.admin.test.user@silverlinecrm.com', Doc_Fee_Exception_Approver__c = true);
            insert u;   

            SL_SCTestData.createAccountAndContracts(1,1);
			Contract__c contract = [SELECT Id, Name, Contract_Balance_Remaining__c, Delinquency_Status_Code__c FROM Contract__c];
            contract.Delinquency_Status_Code__c = '01';
            contract.Contract_Balance_Remaining__c = 1300;
            update contract;
	}
    
    @isTest
    static void increaseMaximum() {
        User u = [SELECT Id, Alias, Username, Email, UserRoleId, ProfileId FROM User WHERE Alias='CBRTest' LIMIT 1];
		UserRole adminRole = [SELECT Id, Name FROM UserRole WHERE Name = 'Collections Manager'];
        u.UserRoleId=adminRole.Id;
        update u;
            Contract_Criteria__c criteriaSetting = [SELECT Id, Maximum_Balance_CBR__c, Maximum_CBR_XBS_ADR__c FROM Contract_Criteria__c LIMIT 1];
            System.debug('criteriaSetting  ' + criteriaSetting);
        String result2, result3;
        List<String> result1;
        System.runAs(u){
            Test.startTest();
            result1 = SL_ManageBalanceCBR.getMaxCBR();
            result2 = SL_ManageBalanceCBR.hubExecute('checkPermission', new List<String>());
            result3 = SL_ManageBalanceCBR.hubExecute('saveMaxCBR', new List<String>{'1500', '1500'});
            Test.stopTest();
        }
        
        Contract__c actual = [SELECT Collection_Group__c FROM Contract__c];
        System.assertEquals('1200.00', result1[0]);
        System.assertEquals('true', result2);
        System.assertEquals('Dialer Regular', actual.Collection_Group__c);
    }
    @isTest
    static void decreaseMaximum() {
        String result1, result2;
		UserRole nonAdminRole = [SELECT Id, Name FROM UserRole WHERE Name = 'Collections Staff'];
		User u = [SELECT Id, Alias, Username, Email, UserRoleId, ProfileId FROM User WHERE Alias='CBRTest' LIMIT 1];
        u.UserRoleId=nonAdminRole.Id;
        update u;

        Test.startTest();
        System.runAs(u){
            result1 = SL_ManageBalanceCBR.hubExecute('saveMaxCBR', new List<String>{'1100','1500'});
        }
        Test.stopTest();
        Contract__c actual = [SELECT Collection_Group__c FROM Contract__c];
        System.assertEquals('You don\'t have permission to change the Maximum Balance CBR, please contact your Administrator.', result1);
        System.assertEquals('Dialer Team Assigned', actual.Collection_Group__c);
    }
}
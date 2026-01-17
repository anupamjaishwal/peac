@isTest
public class SL_AccountTriggerHandlerTest {
    @isTest
    static void activeInsuranceToContracts() {
        Test.startTest();
        SL_AccountTriggerHandler.interimMethod();
        SL_SCTestData.createAccountAndContracts(2,10);
        Account acc = SL_SCTestData.testAccounts[0];
        Account dealerAccount = SL_SCTestData.testAccounts[1];
        SL_SCTestData.createInsurancesAndContractAssets(2, 1);
        List<Insurance__c> insurances = [SELECT Id, Account_Level__c, Expiration_Date__c FROM Insurance__c];
        insurances[0].Account_Level__c = true;
        insurances[0].Expiration_Date__c = Date.valueOf(Date.today() + 30);
        insurances[0].Customer__c = acc.Id;
        update insurances;
        acc.Account_Total_Active_Contracts__c = 10;
        dealerAccount.Account_Total_Active_Contracts__c = 100;
        dealerAccount.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Dealer Account').getRecordTypeId();
        update new List<Account>{acc, dealerAccount};
        Test.stopTest();
        List<Account> accountsAfter = [SELECT Id, Active_Insurance__c, Multiples__c, Collection_Group__c, Account_Branch__c,
            Account_Record_Type_Custom__c, RecordType.Name FROM Account];
        List<Contract__c> contractsAfter = [SELECT Id, Name, Insurance__c, Collection_Group__c FROM Contract__c];
        System.Assert.areEqual(accountsAfter[0].Active_Insurance__c, contractsAfter[0].Insurance__c);
        System.Assert.areEqual(true, accountsAfter[0].Multiples__c);
        // SL-2684
        // System.Assert.areEqual('Multiples', accountsAfter[0].Collection_Group__c);
        // System.Assert.areEqual('Multiples', contractsAfter[0].Collection_Group__c);
        System.Assert.areEqual(true, accountsAfter[1].Multiples__c);
        System.assert(accountsAfter[1].Collection_Group__c != 'Multiples');
        System.assert(contractsAfter[10].Collection_Group__c != 'Multiples');
        System.Assert.areEqual(null, accountsAfter[0].Account_Branch__c);
        System.Assert.areEqual('End User Account', accountsAfter[0].Account_Record_Type_Custom__c);
        system.debug('secondAccount: ' + accountsAfter[1]);
        system.debug('secondAccount.recordtype.name: ' + accountsAfter[1].RecordType.Name);
        system.debug('accountsAfter[1].RecordTypeId: ' + accountsAfter[1].RecordTypeId);
        system.debug('contains dealer word?: ' + accountsAfter[1].RecordType.Name.containsIgnoreCase('Dealer'));
        //System.Assert.areEqual('Dealer Account', accountsAfter[1].Account_Record_Type_Custom__c);
    }
    @isTest
    static void salesVertical1() {
        SL_SCTestData.createTestUser();
        SL_SCTestData.testUser.Vendor_Team__c = 'DLG';
        update SL_SCTestData.testUser;
        Test.startTest();
        System.runAs(SL_SCTestData.testUser){
            SL_SCTestData.createAccountAndContracts(1, 1);
            
        }
        SL_SCTestData.testUser.Vendor_Team__c = 'HC';
        update SL_SCTestData.testUser;
        System.runAs(SL_SCTestData.testUser){
            SL_SCTestData.createAccountAndContracts(1, 1);
        }
        SL_SCTestData.testUser.Vendor_Team__c = 'IFP';
        update SL_SCTestData.testUser;
        System.runAs(SL_SCTestData.testUser){
            SL_SCTestData.createAccountAndContracts(1, 1);
        }
        Test.stopTest();
        List<Account> accountsAfter = [SELECT Id, Account_Branch__c FROM Account];
        System.Assert.areEqual('Direct - End User', accountsAfter[0].Account_Branch__c);
        System.Assert.areEqual('Healthcare Division', accountsAfter[1].Account_Branch__c);
        System.Assert.areEqual('IFP - Indirect Funding Pl', accountsAfter[2].Account_Branch__c);
    }
    @isTest
    static void salesVertical2() {
        SL_SCTestData.createTestUser();
        SL_SCTestData.testUser.Vendor_Team__c = 'OEG';
        update SL_SCTestData.testUser;
        Test.startTest();
        System.runAs(SL_SCTestData.testUser){
            SL_SCTestData.createAccountAndContracts(1, 1);
        }
        SL_SCTestData.testUser.Vendor_Team__c = 'OEG NC';
        update SL_SCTestData.testUser;
        System.runAs(SL_SCTestData.testUser){
            SL_SCTestData.createAccountAndContracts(1, 1);
        }
        SL_SCTestData.testUser.Vendor_Team__c = 'SNAP';
        update SL_SCTestData.testUser;
        System.runAs(SL_SCTestData.testUser){
            SL_SCTestData.createAccountAndContracts(1, 1);
        }
        Test.stopTest();
        List<Account> accountsAfter = [SELECT Id, Account_Branch__c, Discount_for_Upgrade_to_Keep__c FROM Account];
        System.Assert.areEqual('Office Equip Group-OEG', accountsAfter[0].Account_Branch__c);
        System.Assert.areEqual('OEG Non-Copier', accountsAfter[1].Account_Branch__c);
        System.Assert.areEqual('SNAP (National Accounts)', accountsAfter[2].Account_Branch__c);
        System.Assert.areEqual('3.000', accountsAfter[0].Discount_for_Upgrade_to_Keep__c);
        accountsAfter[0].Discount_for_Upgrade_to_Keep__c = null;
        update accountsAfter[0];
        accountsAfter = [SELECT Id, Account_Branch__c, Discount_for_Upgrade_to_Keep__c FROM Account];
        System.Assert.areEqual(null, accountsAfter[0].Discount_for_Upgrade_to_Keep__c);
    }
    @isTest
    static void salesVertical3() {
        SL_SCTestData.createTestUser();
        SL_SCTestData.testUser.Vendor_Team__c = 'CTIF';
        update SL_SCTestData.testUser;
        Test.startTest();
        System.runAs(SL_SCTestData.testUser){
            SL_SCTestData.createAccountAndContracts(2, 1);
            
        }
        User adminUser = TestDataFactory.createTestUser();
        System.runAs(adminUser){
            Account acc = SL_SCTestData.testAccounts[0];
            Contact primaryContact = SL_SCTestData.testContacts[1];
            AccountContactRelation acr = new AccountContactRelation(ContactId = primaryContact.Id, AccountId = acc.Id, Roles='Primary Contact');
            insert acr;
            acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Dealer_Vendor').getRecordTypeId();
            acc.DM_Review_Status__c = 'Submitted for Review';
            acc.Review_For__c = 'Approval';
            update acc;
        }
        Test.stopTest();
        List<Account> accountsAfter = [SELECT Id, Account_Branch__c, Submitted_By__c, Review_For__c FROM Account];
        System.Assert.areEqual('CT&I Field', accountsAfter[0].Account_Branch__c);
        System.Assert.areEqual(adminUser.Id, accountsAfter[0].Submitted_By__c, 'when submitting for review to GDS Submitted by is set to current user(currently done by the flow, will fix later)');
        
    }
}
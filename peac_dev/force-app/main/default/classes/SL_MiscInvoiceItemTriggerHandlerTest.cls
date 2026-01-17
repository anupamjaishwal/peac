@isTest
public with sharing class SL_MiscInvoiceItemTriggerHandlerTest {
    @isTest
    static void miscInvoiceItemActionsFormerPB() {
        Id dealerVendorId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Dealer_Vendor').getRecordTypeId();
        insert new SL_Trigger_Settings__c(Name = 'default', KillList__c = 'Account\nOpportunity');
        SL_SCTestData.createAccountAndContracts(2,1);
        SL_SCTestData.createOpportunitiesAndAssets(SL_SCTestData.testAccounts[0].Id, 1, 1);
        List<Account> accounts = SL_SCTestData.testAccounts;
        accounts[1].RecordTypeId = dealerVendorId;
        update accounts[1];
        Opportunity theOpp = SL_SCTestData.testOpportunities[0];
        theOpp.Documentation_Fee__c = 101;
        theOpp.Security_Deposit__c = 102;
        theOpp.First_Payment_Date__c = Date.today();
        update theOpp;
        Test.startTest();
        insert new Dealer__c(Opportunity__c = theOpp.Id, Primary_Dealer__c = true, Dealer__c = accounts[1].Id);
        List<Miscellaneous_Invoice_Item__c> miscInvoiceItems = new List<Miscellaneous_Invoice_Item__c>{
            new Miscellaneous_Invoice_Item__c(Opportunity__c = theOpp.Id,
                                                GL_Code__c = '0000 - NOT ON FILE'),
            new Miscellaneous_Invoice_Item__c(Opportunity__c = theOpp.Id,
                                                GL_Code__c = '0003 - OneTime Documentation Fee'),
            new Miscellaneous_Invoice_Item__c(Opportunity__c = theOpp.Id,
                                                GL_Code__c = '0005 - Security Deposit')
        };
        insert miscInvoiceItems;
        miscInvoiceItems[0].GL_Code__c = '0001 - Interim Rent';
        update miscInvoiceItems;
        Test.stopTest();
        List<Miscellaneous_Invoice_Item__c> miisAfter = [SELECT Id, GL_Code__c, Description__c, Amount__c, CB_Disp__c, Pay_Code__c, Dealer__c
            FROM Miscellaneous_Invoice_Item__c ORDER BY GL_Code__c];
        System.Assert.areEqual('Interim Rent', miisAfter[0].Description__c, 'description gets parsed from the GL Code');
        System.Assert.areEqual(101, miisAfter[1].Amount__c, 'for 0003 amount comes from opp.Documentation_Fee__c');
        System.Assert.areEqual(102, miisAfter[2].Amount__c, 'for 0005 amount comes from opp.Security_Deposit__c');
        System.Assert.areEqual(true, miisAfter[2].CB_Disp__c, 'when opp.First_Payment_Date__c is filled CB/Disp is True');
        System.Assert.areEqual('0', miisAfter[2].Pay_Code__c, 'when opp.First_Payment_Date__c is filled Pay Code is Dont pay dealer (exept for new requirement on Booking)');
        System.Assert.areEqual(accounts[1].Id, miisAfter[2].Dealer__c, 'Dealer field is the opp.primary_Dealer__r.Dealer__c');
    }
}
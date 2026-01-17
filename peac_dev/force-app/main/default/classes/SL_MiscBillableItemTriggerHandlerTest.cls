@isTest
public with sharing class SL_MiscBillableItemTriggerHandlerTest {
    @isTest
    static void miscInvoiceActionsFormerPB() {
        SL_SCTestData.createAccountAndContracts(1,1);
        SL_SCTestData.createOpportunitiesAndAssets(SL_SCTestData.testAccounts[0].Id, 1, 1);
        Opportunity opp = SL_SCTestData.testOpportunities[0];
        Date firstPaymentDate = Date.newInstance(Date.today().year(), Date.today().addMonths(1).month(), 1);
        String cycle = 'Monthly';
        opp.First_Payment_Date__c = firstPaymentDate;
        opp.Payment_Frequency__c = cycle;
        update opp;
        Test.startTest();
        Miscellaneous_Billable_Item__c miscBillableItem = new Miscellaneous_Billable_Item__c(Opportunity__c = opp.Id,
            Misc_GL_Code__c = '0000 - NOT ON FILE');
        insert miscBillableItem;
        miscBillableItem.Misc_GL_Code__c = '0001 - Interim Rent';
        update miscBillableItem;
        // SAL-5897 Misael Romero
        Miscellaneous_Billable_Item__c miscBillableItem2 = new Miscellaneous_Billable_Item__c(Opportunity__c = opp.Id,
            Misc_GL_Code__c = '0017 - Service Contract', Final_Payment_Date__c = Date.today(), Amount__c = -1);
        insert miscBillableItem2;
        List<Miscellaneous_Billable_Item__c> mbisAfter = [SELECT Id, Misc_Item_Description__c, CB_Disp__c, Future_Bill_Misc_Type__c,
            Included_in_Rental__c, Pay_Code__c, Due_Date__c, First_Payment_Date__c, Billing_Cycle__c, Final_Payment_Date__c
            FROM Miscellaneous_Billable_Item__c];
        System.Assert.areEqual('Service Contract', mbisAfter[1].Misc_Item_Description__c, 'In MiscBillableDefaultRulesFormerPB description is taken from GL code');
        System.Assert.areEqual(true, mbisAfter[1].Future_Bill_Misc_Type__c, 'In MiscBillableDefaultRulesFormerPB future, cb/disp and include in rental are set to true');
        System.Assert.areEqual(firstPaymentDate, mbisAfter[1].Due_Date__c, 'In MiscBillableDefaultRulesFormerPB due date is taken from opp first Payment Date');
        System.Assert.areEqual(firstPaymentDate, mbisAfter[1].First_Payment_Date__c, 'In MiscBillableDefaultRulesFormerPB first payment date is taken from opp');
        System.Assert.areEqual(cycle, mbisAfter[1].Billing_Cycle__c, 'In MiscBillableDefaultRulesFormerPB billing cycle is taken from opp payment frequency');
        System.Assert.areEqual(null, mbisAfter[1].Final_Payment_Date__c, 'In MiscBillableDefaultRulesFormerPB final payment date is nullified if amount is negative?');
        // SAL-5897 Misael Romero
        System.Assert.areEqual('1', mbisAfter[1].Pay_Code__c, 'In MiscBillableDefaultRulesFormerPB paycode is set to 1 for specific GL Codes');
        System.Assert.areEqual(true, mbisAfter[1].Included_in_Rental__c, 'In MiscBillableDefaultRulesFormerPB Include in Rental is set according to the Misc Coding Matrix');
        miscBillableItem2.Misc_GL_Code__c = '0090 - Convenience Fee';
        update miscBillableItem2;
        mbisAfter = [SELECT Id, Pay_Code__c, Included_in_Rental__c
            FROM Miscellaneous_Billable_Item__c];
        System.Assert.areEqual('0', mbisAfter[1].Pay_Code__c, 'In MiscBillableDefaultRulesFormerPB paycode is set to 0 for specific GL Codes');
        System.Assert.areEqual(false, mbisAfter[1].Included_in_Rental__c, 'In MiscBillableDefaultRulesFormerPB Include in Rental is set according to the Misc Coding Matrix');
        Test.stopTest();
        
    }
}
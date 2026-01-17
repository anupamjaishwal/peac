@isTest
public with sharing class TC_AutoCreateMiscBillableItemsTest {
    

    @IsTest
    public static void scenario1(){
        SL_SCTestData.createAccountAndContracts(1, 1);
        SL_SCTestData.createOpportunitiesAndAssets(SL_SCTestData.testAccounts[0].Id, 1, 1);
        Test.startTest();
        Opportunity opp = SL_SCTestData.testOpportunities[0];
        opp.Beginning_Maintenance_Fee_Amount__c = 322;
        opp.First_Payment_Date__c = Date.today();
        System.Formula.recalculateFormulas(new List<Opportunity>{opp});
        Set<Id> oppsMovedToBooking = new Set<Id>{opp.Id};
        Map<Id, List<Miscellaneous_Billable_Item__c>> miscBillableItems = new Map<Id, List<Miscellaneous_Billable_Item__c>>();
        List<Miscellaneous_Billable_Item__c> miscBillablesToInsert = new List<Miscellaneous_Billable_Item__c>();
        Miscellaneous_Billable_Item__c existingMbi = new Miscellaneous_Billable_Item__c(Opportunity__c = opp.Id, Misc_GL_Code__c = '0017 - Service Contract', 
            Amount__c = 320);
        miscBillableItems.put(opp.Id, new List<Miscellaneous_Billable_Item__c>{existingMbi});
        TC_AutoCreateMiscBillableItems.autoCreateMiscBillableItems(opp, oppsMovedToBooking, miscBillableItems, miscBillablesToInsert);
        Test.stopTest();
        System.Assert.areEqual(1, miscBillablesToInsert.size());
        System.Assert.areEqual(opp.First_Payment_Date__c, miscBillablesToInsert[0].First_Payment_Date__c, 'when only one misc Billable inserted the First_Payment_Date__c is copied from the Opp');
        System.Assert.areEqual(opp.Year_1_Pass_Thru_Fee__c, miscBillablesToInsert[0].Amount__c, 'Amount in the first misc Billable inserted comes from the Year_1_Pass_Thru_Fee__c');
        opp.Num_Pass_Thru_Fees__c = 24;
        opp.Escalation_Rate__c = 1;
        System.Formula.recalculateFormulas(new List<Opportunity>{opp});
        miscBillableItems.get(opp.Id).addAll(miscBillablesToInsert);
        miscBillablesToInsert.clear();
        TC_AutoCreateMiscBillableItems.autoCreateMiscBillableItems(opp, oppsMovedToBooking, miscBillableItems, miscBillablesToInsert);
        System.Assert.areEqual(opp.Year_2_Pass_Thru_Fee__c, miscBillablesToInsert[0].Amount__c, 'Amount in the second misc Billable inserted comes from the Year_2_Pass_Thru_Fee__c');
    }
}
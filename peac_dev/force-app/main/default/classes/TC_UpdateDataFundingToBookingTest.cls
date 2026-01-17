@isTest
public with sharing class TC_UpdateDataFundingToBookingTest {
    
    @IsTest
    public static void UpdateDataFundingToBooking(){
        Decimal interimDaysToCheck = 5;
        SL_SCTestData.createAccountAndContracts(1, 1);
        SL_SCTestData.createOpportunitiesAndAssets(SL_SCTestData.testAccounts[0].Id, 1, 1);
        List<Miscellaneous_Invoice_Item__c> upsertMiscInvoiceList = new List<Miscellaneous_Invoice_Item__c>();
        Test.startTest();
        Opportunity opp = SL_SCTestData.testOpportunities[0];
        opp.StageName = 'Booking';
        opp.Opportunity_Status__c = 'Booking - In Process';
        opp.Account_Billing_Street__c = opp.Account.Account_Billing_Street__c;
        opp.Billing_Cycle__c = 'January;February';
        opp.Booking_Sheet_Generated__c = true;
        opp.Purchase_Options__c = 'FMV';
        opp.Contract_Type__c = 'TL';
        opp.Branch__c = 'Office Equip Group-OEG';
        opp.Terms__c = 60;
        opp.Waive_Interim_Rent__c = false;
        opp.Delivery_Guarantee_Fee__c =101;
        opp.Wire_Fee__c =102;
        opp.UPS_Fee__c =103;
        opp.Documentation_Fee__c =104;
        opp.Beginning_Maintenance_Fee_Amount__c = 719;
        opp.Commencement_Date__c = Date.today().addDays(Integer.valueOf(interimDaysToCheck));
        opp.Lease_Payment_Interim_Rent__c = 105;
        opp.Maintenance_Interim_Rent__c = 106;
        opp.Waive_Interim_Rent__c = false;
        opp.Program__c = 'XBS';
        Set<Id> oppsMovedToBooking = new Set<Id>{opp.Id};
        Map <Id, Dealer__c> dealers = new Map<Id, Dealer__c>();
        Map<Id, List<Miscellaneous_Invoice_Item__c>> miscInvoiceItems = new Map<Id, List<Miscellaneous_Invoice_Item__c>>();
        
        Set<Id> oppsChangedInterimRent = new Set<Id>();
        TC_UpdateDataFundingToBooking.updateDataFundingToBooking(opp, oppsMovedToBooking, dealers, miscInvoiceItems, upsertMiscInvoiceList, oppsChangedInterimRent);
        System.Assert.areEqual('0040 - Progress Payment Fees', upsertMiscInvoiceList[0].GL_Code__c);
        System.Assert.areEqual('0042 - UPS SHIPPING FEE', upsertMiscInvoiceList[1].GL_Code__c);
        System.Assert.areEqual('0042 - UPS SHIPPING FEE', upsertMiscInvoiceList[2].GL_Code__c);
        System.Assert.areEqual('0003 - OneTime Documentation Fee', upsertMiscInvoiceList[3].GL_Code__c);
        System.Assert.areEqual('0017 - Service Contract', upsertMiscInvoiceList[4].GL_Code__c);
        System.Assert.areEqual('0001 - Interim Rent', upsertMiscInvoiceList[5].GL_Code__c);// just one interim rent, dealer percentage was 0
        miscInvoiceItems.put(opp.Id, new List<Miscellaneous_Invoice_Item__c>());
        upsert upsertMiscInvoiceList;
        for(Miscellaneous_Invoice_Item__c upserted :upsertMiscInvoiceList){
            List<Miscellaneous_Invoice_Item__c> existingList = miscInvoiceItems.get(opp.Id);
            existingList.add(upserted.clone(true));
            miscInvoiceItems.put(opp.Id, existingList);
        }
        upsertMiscInvoiceList = new List<Miscellaneous_Invoice_Item__c>();
        TC_RecursiveTriggerHelper.oppsAlreadyMiiAdded.clear();
        TC_UpdateDataFundingToBooking.updateDataFundingToBooking(opp, oppsMovedToBooking, dealers, miscInvoiceItems, upsertMiscInvoiceList, oppsChangedInterimRent);
        System.Assert.isTrue(upsertMiscInvoiceList[0].Id != null, 'the upsert records must get an Id to update');
        upsertMiscInvoiceList = new List<Miscellaneous_Invoice_Item__c>();// now delete existing and respecting manually added miis
        TC_RecursiveTriggerHelper.oppsAlreadyMiiAdded.clear();
        opp.Delivery_Guarantee_Fee__c = null;
        opp.Wire_Fee__c = null;
        opp.UPS_Fee__c = null;
        opp.Documentation_Fee__c = null;
        insert new Miscellaneous_Invoice_Item__c(GL_Code__c = '0005 - Security Deposit', Amount__c = 1031, Opportunity__c = opp.Id);
        TC_UpdateDataFundingToBooking.updateDataFundingToBooking(opp, oppsMovedToBooking, dealers, miscInvoiceItems, upsertMiscInvoiceList, oppsChangedInterimRent);
        System.Assert.areEqual('0017 - Service Contract', upsertMiscInvoiceList[0].GL_Code__c);
        System.Assert.areEqual('0001 - Interim Rent', upsertMiscInvoiceList[1].GL_Code__c);// just one interim rent, dealer percentage was 0
        
        Test.stopTest();
        List<Opportunity> oppsAfter = [SELECT StageName, Interim_Rent__c,
            (SELECT Id, GL_Code__c, Description__c, Interim_Percentage__c, Amount__c, Pay_Code__c 
            FROM Miscellaneous_Invoice_Items__r ORDER BY GL_Code__c) FROM Opportunity];
        List<Miscellaneous_Invoice_Item__c> miis = oppsAfter[0].Miscellaneous_Invoice_Items__r;
        System.Assert.areEqual('0001 - Interim Rent', miis[0].GL_Code__c);
        System.Assert.areEqual('0005 - Security Deposit', miis[1].GL_Code__c);
        System.Assert.areEqual('0017 - Service Contract', miis[2].GL_Code__c);
        System.Assert.areEqual('0081 - Interim Rent Dealer', miis[3].GL_Code__c);
        System.Assert.areEqual('0115 - Interim Maintenance', miis[4].GL_Code__c);
        System.Assert.areEqual(5, miis.size());
    }
}
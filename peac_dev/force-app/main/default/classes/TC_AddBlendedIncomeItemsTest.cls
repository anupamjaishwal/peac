@isTest
public with sharing class TC_AddBlendedIncomeItemsTest {
    @testSetup
    static void setup() {
        SL_SCTestData.prepareFundingOpportunity();
    }

    @isTest
    static void lessor409() {
        List<Opportunity> opps = [SELECT Id, Name, Account.Account_Billing_Street__c, StageName,
        Loan_Record_Type__c, Lessor__c, Lease_Payment_Interim_Rent__c, Interim_Rent__c, Contract_Type__c,
        Broker_Fees__c, Documentation_Fee__c,
        Primary_Dealer__r.Dealer__r.Interim_Rent_Dealer_Percentage__c, Primary_Dealer__r.Dealer__r.Preferred_Dealer_Level__c
         FROM Opportunity];
        User theAdmin = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND FirstName = 'Test Owner' LIMIT 1];
        Decimal interimDaysToCheck = 5;
        Map<Id, List<Blended_Income_Item__c>> blendedIncomeItems = new Map<Id, List<Blended_Income_Item__c>>();
        Blended_Income_Item__c newBII = new Blended_Income_Item__c (Blended_Income_Code__c = '0029', Blended_Income_Amount__c = 11,
            Opportunity__c = opps[2].Id, Generated_Code__c = '0029');
        insert newBII;
        Test.startTest();
        System.runAs(theAdmin){
            opps[2].StageName = 'Booking';
            opps[2].Opportunity_Status__c = 'Booking - In Process';
            opps[2].Account_Billing_Street__c = opps[2].Account.Account_Billing_Street__c;
            opps[2].Billing_Cycle__c = 'January;February';
            opps[2].Booking_Sheet_Generated__c = true;
            opps[2].Purchase_Options__c = 'FMV';
            opps[2].Contract_Type__c = 'TL';
            opps[2].Branch__c = 'Office Equip Group-OEG';
            opps[2].Terms__c = 60;
            opps[2].First_12_Months_Free__c = false;
            opps[2].Beginning_Maintenance_Fee_Amount__c  = 100;
            opps[2].Lessor__c = 409;
            opps[2].Contract_Type__c = 'RL';
            opps[2].Documentation_Fee__c = 11;
            Opportunity opp = opps[2];
            Map<Id, Opportunity> newMap = new Map<Id, Opportunity>{opp.Id=> opp};
            Set<Id> oppsMovedToBooking = new Set<Id>();
            oppsMovedToBooking.add(opp.Id);
            blendedIncomeItems.put(opp.Id, new List<Blended_Income_Item__c>{newBII});
            Set<Id> oppsChangedInterimRent = new Set<Id>();
            Map<Id, Dealer__c> dealers = new Map<Id, Dealer__c>{opp.Primary_Dealer__c => opp.Primary_Dealer__r};
            TC_AddBlendedIncomeItems.addBlendedIncomeItems(newMap, oppsMovedToBooking, blendedIncomeItems, oppsChangedInterimRent, dealers);
        }
        Test.stopTest();
        // List<Blended_Income_Item__c> biisAfter = [SELECT Id, Blended_Income_Code__c FROM Blended_Income_Item__c 
        //     WHERE Opportunity__c = :opps[2].Id AND Generated_Code__c = '0029'];
        // System.Assert.areEqual(1, biisAfter.size(), 'must have created the Documentation Fee');
    }
    
    @isTest
    static void lessorNot409() {
        List<Opportunity> opps = [SELECT Id, Name, Account.Account_Billing_Street__c, StageName,
        Loan_Record_Type__c, Lessor__c, Lease_Payment_Interim_Rent__c, Interim_Rent__c, Contract_Type__c,
        Broker_Fees__c, Documentation_Fee__c,
        Primary_Dealer__r.Dealer__r.Interim_Rent_Dealer_Percentage__c, Primary_Dealer__r.Dealer__r.Preferred_Dealer_Level__c
         FROM Opportunity];
        User theAdmin = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND FirstName = 'Test Owner' LIMIT 1];
        Decimal interimDaysToCheck = 5;
        Map<Id, List<Blended_Income_Item__c>> blendedIncomeItems = new Map<Id, List<Blended_Income_Item__c>>();
        Blended_Income_Item__c newBII = new Blended_Income_Item__c (Blended_Income_Code__c = '0004', Blended_Income_Amount__c = 11,
            Opportunity__c = opps[2].Id, Generated_Code__c = '0004');
        insert newBII;
        Test.startTest();
        System.runAs(theAdmin){
            opps[2].StageName = 'Booking';
            opps[2].Opportunity_Status__c = 'Booking - In Process';
            opps[2].Account_Billing_Street__c = opps[2].Account.Account_Billing_Street__c;
            opps[2].Billing_Cycle__c = 'January;February';
            opps[2].Booking_Sheet_Generated__c = true;
            opps[2].Purchase_Options__c = 'FMV';
            opps[2].Contract_Type__c = 'TL';
            opps[2].Branch__c = 'Office Equip Group-OEG';
            opps[2].Terms__c = 60;
            opps[2].First_12_Months_Free__c = false;
            opps[2].Beginning_Maintenance_Fee_Amount__c  = 100;
            opps[2].Lessor__c = 211;
            opps[2].Contract_Type__c = 'RL';
            opps[2].Documentation_Fee__c = 11;
            Opportunity opp = opps[2];
            Map<Id, Opportunity> newMap = new Map<Id, Opportunity>{opp.Id=> opp};
            Set<Id> oppsMovedToBooking = new Set<Id>();
            oppsMovedToBooking.add(opp.Id);
            blendedIncomeItems.put(opp.Id, new List<Blended_Income_Item__c>{newBII});
            Set<Id> oppsChangedInterimRent = new Set<Id>();
            Map<Id, Dealer__c> dealers = new Map<Id, Dealer__c>{opp.Primary_Dealer__c => opp.Primary_Dealer__r};
            TC_AddBlendedIncomeItems.addBlendedIncomeItems(newMap, oppsMovedToBooking, blendedIncomeItems, oppsChangedInterimRent, dealers);
        }
        Test.stopTest();
        // List<Blended_Income_Item__c> biisAfter = [SELECT Id, Blended_Income_Code__c FROM Blended_Income_Item__c 
        //     WHERE Opportunity__c = :opps[2].Id AND Generated_Code__c = '0004'];
        // System.Assert.areEqual(1, biisAfter.size(), 'must have created the Documentation Fee');
    }
    

    // @IsTest
    // public static void AutoCreateMiscBillableItemsTest(){
    //     List<Opportunity> opp = [SELECT Id, StageName FROM Opportunity];
    //      Map<Id, Opportunity> oldMap = new Map<Id, Opportunity>();
    //      Map<Id, Opportunity> newMap = new Map<Id, Opportunity>();
 
    //      for(Opportunity op : opp){
    //             Opportunity o = new Opportunity(
    //             Id = op.Id, 
    //             StageName = 'Funding',
    //             Docs_In__c = Date.Today(),
    //             Ready_to_Doc__c = 'Yes');
    //             oldMap.put(op.Id, o);
    //     }

    //      for(Opportunity op : opp){
    //         Opportunity o = new Opportunity(
    //             Id = op.Id, 
    //             StageName = 'Booking',
    //             Docs_In__c = Date.Today(),
    //             First_12_Months_Free__c = false,
    //             Beginning_Maintenance_Fee_Amount__c  = 100,
    //             Lessor__c = 409,
    //             Contract_Type__c = 'RL',
    //             Ready_to_Doc__c = 'Yes');
    //         newMap.put(op.Id, o);
    //     }

    //     try{
    //         TC_AddBlendedIncomeItems.addBlendedIncomeItems(oldMap, newMap);
    //         }
    //         catch (DmlException e) {
             
    //         }
    //         catch (Exception e) {
               
    //         }
    // }

    // @IsTest
    // public static void AutoCreateMiscBillableItemsTest2(){
    //     List<Opportunity> opp = [SELECT Id, StageName FROM Opportunity];
    //      Map<Id, Opportunity> oldMap = new Map<Id, Opportunity>();
    //      Map<Id, Opportunity> newMap = new Map<Id, Opportunity>();
 
    //      for(Opportunity op : opp){
    //             Opportunity o = new Opportunity(
    //             Id = op.Id, 
    //             StageName = 'Funding',
    //             Docs_In__c = Date.Today(),
    //             Ready_to_Doc__c = 'Yes');
    //             oldMap.put(op.Id, o);
    //     }

    //      for(Opportunity op : opp){
    //         Opportunity o = new Opportunity(
    //             Id = op.Id, 
    //             StageName = 'Booking',
    //             Docs_In__c = Date.Today(),
    //             First_12_Months_Free__c = false,
    //             Beginning_Maintenance_Fee_Amount__c  = 100,
    //             Lessor__c = 410,
    //             Contract_Type__c = 'RL',
    //             Ready_to_Doc__c = 'Yes');
    //         newMap.put(op.Id, o);
    //     }

    //     try{
    //         TC_AddBlendedIncomeItems.addBlendedIncomeItems(oldMap, newMap);
    //         }
    //         catch (DmlException e) {
             
    //         }
    //         catch (Exception e) {
               
    //         }
    // }

}
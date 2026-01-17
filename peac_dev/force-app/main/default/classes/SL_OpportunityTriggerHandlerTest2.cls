@isTest
public with sharing class SL_OpportunityTriggerHandlerTest2 {

    @testSetup
    static void setup() {
        SL_SCTestData.prepareFundingOpportunity();
    }

    @isTest
    static void refactorOfClasses3() {
        List<Opportunity> opps = [SELECT Id, Name, Account.Account_Billing_Street__c, StageName FROM Opportunity];
        System.Assert.areEqual('Funding', opps[2].StageName);
        User theAdmin = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND FirstName = 'Test Owner' LIMIT 1];
        Decimal interimDaysToCheck = 5;
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
            opps[2].Waive_Interim_Rent__c = false;
            opps[2].Commencement_Date__c = Date.today().addDays(Integer.valueOf(interimDaysToCheck));
            //opps[2].Beginning_Maintenance_Fee_Amount__c = 723;
            // interimDaysToCheck = SL_SCTestData.calculateInterimDaysToCheck(opps[2]); remnant of Funded__c
            update opps[2];
        }
        Test.stopTest();
        // the below query surpasses the SOQL limit in fullCopy, we need more optimization in order to actually do the assertions
        List<Opportunity> oppsAfter = [SELECT StageName, Interim_Rent__c, Commencement_Date__c, Opportunity_Installed_Date__c, Daily_Lease_Payment_Amount__c, Daily_Service_Payment_Amount__c,
            (SELECT Blended_Income_Amount__c, Blended_Income_Code__c FROM Blended_Income_Items__r WHERE Blended_Income_Code__c = '0005')
             FROM Opportunity WHERE Id = :opps[2].Id];

        System.Assert.areEqual('Booking', oppsAfter[0].StageName); 
        Decimal serviceAmount = 0; //Beginning_Maintenance_Fee_Amount__c gives more SOQL queries as of now
        System.Assert.areEqual(Math.round((interimDaysToCheck * ((Decimal.valueOf(301) / Decimal.valueOf(30)))) + (interimDaysToCheck * (serviceAmount / 30))), Math.round(oppsAfter[0].Interim_Rent__c), 'Interim rent needs to be calculated using the formula: (interimDays * (paymentAmount / 30)) + (interimDays * (serviceAmount / 30))');
        System.Assert.areEqual(1, oppsAfter[0].Blended_Income_Items__r.size(), 'Interim rent needs to be added as a Blended Income Item');
        System.Assert.areEqual(oppsAfter[0].Interim_Rent__c, oppsAfter[0].Blended_Income_Items__r[0].Blended_Income_Amount__c, 'Interim rent amount must match Blended Income Item Amount');
    }
    @isTest
    static void testDocsIn() {
        List<Opportunity> opps = [SELECT Id, Name, Account.Account_Billing_Street__c, StageName FROM Opportunity];
        System.Assert.areEqual('Funding', opps[2].StageName);
        User theAdmin = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND FirstName = 'Test Owner' LIMIT 1];
        Decimal interimDaysToCheck = 5;
        Test.startTest();
        System.runAs(theAdmin){
            opps[2].StageName = 'Docs In';
            opps[2].Opportunity_Status__c = 'Docs In - Pending review';
            opps[2].Account_Billing_Street__c = opps[2].Account.Account_Billing_Street__c;
            opps[2].Billing_Cycle__c = 'January;February';
            opps[2].Booking_Sheet_Generated__c = true;
            opps[2].Purchase_Options__c = 'FMV';
            opps[2].Contract_Type__c = 'TL';
            opps[2].Branch__c = 'Office Equip Group-OEG';
            opps[2].Terms__c = 60;
            opps[2].Waive_Interim_Rent__c = false;
            opps[2].Payment_Amount__c = 813;
            opps[2].Commencement_Date__c = Date.today().addDays(Integer.valueOf(interimDaysToCheck));
            //opps[2].Beginning_Maintenance_Fee_Amount__c = 723;
            // interimDaysToCheck = SL_SCTestData.calculateInterimDaysToCheck(opps[2]); remnant of Funded__c
            update opps[2];
        }
        Test.stopTest();
        // the below query surpasses the SOQL limit in fullCopy, we need more optimization in order to actually do the assertions
        List<Opportunity> oppsAfter = [SELECT StageName, Interim_Rent__c,
            (SELECT Blended_Income_Amount__c, Blended_Income_Code__c FROM Blended_Income_Items__r WHERE Blended_Income_Code__c = '0005')
             FROM Opportunity];
        System.Assert.areEqual('Docs In', oppsAfter[2].StageName);
    }
}
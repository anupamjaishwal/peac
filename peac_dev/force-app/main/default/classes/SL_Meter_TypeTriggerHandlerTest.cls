@isTest
public class SL_Meter_TypeTriggerHandlerTest {
    @isTest
    static void afterDelete() {
        SL_SCTestData.createAccountAndContracts(1, 1);
        SL_SCTestData.createOpportunitiesAndAssets(SL_SCTestData.testAccounts[0].Id, 3, 3);
        List<Asset__c> assets = SL_SCTestData.testAssets;
        List<Meter_Type__c> meterTypes = new List<Meter_Type__c>();
        meterTypes.add(new Meter_Type__c(Asset__c = assets[0].Id));
        meterTypes.add(new Meter_Type__c(Asset__c = assets[1].Id));
        meterTypes.add(new Meter_Type__c(Asset__c = assets[2].Id));
        meterTypes.add(new Meter_Type__c(Asset__c = assets[3].Id));
        meterTypes.add(new Meter_Type__c(Asset__c = assets[6].Id));
        meterTypes.add(new Meter_Type__c(Asset__c = assets[6].Id));
        meterTypes.add(new Meter_Type__c(Asset__c = assets[6].Id));
        Test.startTest();
        insert meterTypes;
        List<Opportunity> oppsAfter = [SELECT Id, CPC__c FROM Opportunity];
        System.Assert.areEqual(true, oppsAfter[0].CPC__c, 'when adding a Meter Type To the Asset the Opp gets CPC__c = true');
        System.Assert.areEqual(true, oppsAfter[1].CPC__c, 'when adding a Meter Type To the Asset the Opp gets CPC__c = true');
        System.Assert.areEqual(true, oppsAfter[2].CPC__c, 'when adding a Meter Type To the Asset the Opp gets CPC__c = true');
        List<Meter_Type__c> mtToDelete = new List<Meter_Type__c>();
        mtToDelete.add(meterTypes[0]);
        mtToDelete.add(meterTypes[3]);
        mtToDelete.add(meterTypes[4]);
        mtToDelete.add(meterTypes[5]);
        mtToDelete.add(meterTypes[6]);
        delete mtToDelete;
        Test.stopTest();
        oppsAfter = [SELECT Id, CPC__c FROM Opportunity];
        System.Assert.areEqual(true, oppsAfter[0].CPC__c, 
            'when deleting a Meter Type the Opp keeps CPC__c = true if there is still at least one Meter Type left');
        System.Assert.areEqual(false, oppsAfter[1].CPC__c, 'when deleting a Meter Type the Opp gets CPC__c = false if there is no Meter Type left');
        // System.Assert.areEqual(false, oppsAfter[2].CPC__c); //this is very unlikely to be done by a user
    }
}
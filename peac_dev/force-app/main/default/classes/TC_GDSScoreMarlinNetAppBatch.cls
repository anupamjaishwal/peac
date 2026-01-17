/**
 * Created by andrewmayer on 2/12/20.
 */

public with sharing class TC_GDSScoreMarlinNetAppBatch implements Database.Batchable<sObject> {
    //GDS_Validation_Bypass__c

    public static Id informaticaUserId = [SELECT Id FROM User WHERE LastName = 'Informatica'][0].Id;

    // no minute literals so have to find it out
    //Datetime informaticaDelay = Datetime.now ().addMinutes(10); // assets need to be created after this
    Datetime afterFilter = Datetime.now ().addMinutes(-60); // only look at opps created within the last hour
    // assets should be filtered on first asset

    public Database.QueryLocator start(Database.BatchableContext BC) {

        ORE__c ore = ORE__c.getInstance(Userinfo.getProfileId());
        if (ore == null) ore = new ORE__c();
        ore.GDS_Validation_Bypass__c = true;
        upsert ore;
        String query = 'SELECT Id, (SELECT Id, CreatedDate FROM Assets__r ORDER BY CreatedDate ASC LIMIT 1) FROM Opportunity WHERE CreatedById = :informaticaUserId AND Portal_App_Completed__c = false AND CreatedDate >= :afterFilter AND Decision_Status__c = null';
        //String query = 'SELECT Id, (SELECT Id, CreatedDate FROM Assets__r ORDER BY CreatedDate ASC LIMIT 1) FROM Opportunity WHERE CreatedById = :informaticaUserId AND Portal_App_Completed__c = false AND CreatedDate = YESTERDAY AND Decision_Status__c = null';

        return Database.getQueryLocator(query);
    }
    public void execute(Database.BatchableContext BC, List<Opportunity> opportunities) {

        Integer informaticaDelay = 12;
        Datetime currentTime = Datetime.now ();

        system.debug ('job opportunities: ' + opportunities);
        List <Opportunity> updateList = new List <Opportunity> ();

        for (Opportunity opp : opportunities) {
            if (!opp.Assets__r.isEmpty()) {
                for (Asset__c asset : opp.Assets__r) {
                    System.debug ('job asset: ' + 'asset.CreatedDate ' + asset.CreatedDate + ' >= ' + ' informaticaDelay ' + informaticaDelay);
                    if ((asset.CreatedDate.addMinutes(informaticaDelay)) <= currentTime) updateList.add (new Opportunity (Id = opp.Id, Portal_App_Completed__c = true));
                }
            }
        }
        system.debug ('job updateList: ' + updateList);
        if (!updateList.isEmpty()) update updateList;

    }
    public void finish(Database.BatchableContext BC) {

        ORE__c ore = ORE__c.getInstance(Userinfo.getProfileId());
        ore.GDS_Validation_Bypass__c = false;

        upsert ore;

        System.debug ('TC_GDSScoreMarlinNetAppBatch Job Completed.');
    }

}
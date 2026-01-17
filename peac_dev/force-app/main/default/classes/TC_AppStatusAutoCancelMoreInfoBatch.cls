/**
 * Created by andrewmayer on 2/12/20.
 */

public with sharing class TC_AppStatusAutoCancelMoreInfoBatch implements Database.Batchable<sObject> {
    public Database.QueryLocator start(Database.BatchableContext BC) {
        // copied logic from this flow: Cancel approved App. 90 days
        //

        Date cancelFilter = Date.today().addDays (-45);
        String query = 'SELECT Initial_Approval_Date__c FROM Opportunity WHERE Initial_More_Info_Date__c <= :cancelFilter AND (Application_Status__c = \'More Info\' OR Application_Status__c = \'Returned to Submitter\')';
        return Database.getQueryLocator(query);
    }
    public void execute(Database.BatchableContext BC, List<Opportunity> opportunities) {
        List <Opportunity> updateList = new List <Opportunity> ();
        for (Opportunity opp : opportunities) {
            updateList.add (new Opportunity (Id = opp.Id, Application_Status__c = 'Cancelled'));
        }
        if (!updateList.isEmpty()) update updateList;

    }
    public void finish(Database.BatchableContext BC) {
        System.debug ('TC_AppStatusAutoCancelMoreInfoBatch Job Completed.');
    }

}
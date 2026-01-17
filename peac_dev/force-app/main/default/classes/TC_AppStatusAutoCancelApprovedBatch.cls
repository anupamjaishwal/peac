/**
 * Created by andrewmayer on 2/12/20.
 */

public with sharing class TC_AppStatusAutoCancelApprovedBatch implements Database.Batchable<sObject> {
    public Database.QueryLocator start(Database.BatchableContext BC) {
        // copied logic from this flow: Cancel approved App. 90 days
        //
 
        Date cancelFilter = Date.today().addDays (-90); 
        //String query = 'SELECT Initial_Approval_Date__c FROM Opportunity WHERE Initial_Approval_Date__c <= :cancelFilter AND (Application_Status__c = \'Automatically Approved\' OR Application_Status__c = \'Manually Approved\')';
        String query = 'SELECT Id, Approval_Date__c FROM Opportunity WHERE Approval_Date__c  <= :cancelFilter AND (Application_Status__c = \'Automatically Approved\' OR Application_Status__c = \'Manually Approved\')';
        return Database.getQueryLocator(query);
    }
    public void execute(Database.BatchableContext BC, List<Opportunity> opportunities) {
        List <Opportunity> updateList = new List <Opportunity> ();
        for (Opportunity opp : opportunities) {
            updateList.add (new Opportunity (Id = opp.Id, Application_Status__c = 'Cancelled'));
        }
        System.debug('!!! TC_AppStatusAutoCancelApprovedBatch: list: ' + updateList);
        if (!updateList.isEmpty()) Database.update(updateList, false);

    }
    public void finish(Database.BatchableContext BC) {
        System.debug ('TC_AppStatusAutoCancelApprovedBatch Job Completed.');
    }

}
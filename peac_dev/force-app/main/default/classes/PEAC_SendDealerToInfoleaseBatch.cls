/********************************************************************************************************************
@Author:Rajesh Kumar(LTIMindtree)
@Description: This batch calss is used to make a api call to onboard dealers in infolease.
@User Story:SAL-6561
@Created Date:January-16-2026 	    
*********************************************************************************************************************/

public with sharing class PEAC_SendDealerToInfoleaseBatch implements Database.Batchable<sObject>,database.stateful,Database.AllowsCallouts{
    string sobjectStr = '';
    public PEAC_SendDealerToInfoleaseBatch(string sobjectStr) {
        this.sobjectStr = sobjectStr;
    }
    public Database.querylocator start(Database.BatchableContext BC) {
        //below query will be used from developer console
        /*String theQuery = '';
        String type = 'Dealer Account';
        String dateString = '2026-01-01T00:00:00Z';
        String userIdString = '';
        theQuery = 'SELECT Id FROM ACCOUNT WHERE RecordType.Name = \'' + type + '\' AND CreatedDate = 2026-01-01T00:00:00Z AND CreatedById = ' + '\'' + userIdString + '\'';
       */
        
        return Database.getQueryLocator(sobjectStr);
    }
    public void execute(Database.BatchableContext BC, List<SObject> scopeList) {
        for(SObject sObj:scopeList)
        {
            if(!test.isRunningTest()){
                TC_BWcreateDealerCtrl.createDealer(sObj.Id);
            }
            
        }
    }
    public void finish(Database.BatchableContext BC) {
        // Perform any post-processing if needed
    }
}
public without sharing class SL_DPRemoveInactiveUsers implements Database.Batchable<sObject>, Database.Stateful, Schedulable{
    List<String> allErrors = new List<String>();

    public Database.QueryLocator start(Database.BatchableContext bc){        
        String query = 'SELECT Id, name, contactid, contact.accountId, IsPrmSuperUser, '
            + '(SELECT Id, Dealer_User__c FROM DealerUser_Contracts__r), (SELECT Id, Dealer_User__c FROM OpportunitiesDealerUser__r) '
            + 'FROM User WHERE IsActive = false ORDER BY IsPrmSuperUser DESC, CreatedDate DESC '
            +(Test.isRunningTest()?' LIMIT 200':'');
        return Database.getQueryLocator(query);   
    }
        
   
    public void execute(Database.BatchableContext bc, List<SObject> scope){
        List<Contract__c> contractsToUpdate = new List<Contract__c>();
        List<Opportunity> oppsToUpdate = new List<Opportunity>();
        for(SObject obj:scope){
            User theUser = (User)obj;
            if(theUser.DealerUser_Contracts__r.size() > 0){
                for(Contract__c aContract :theUser.DealerUser_Contracts__r){
                    aContract.Dealer_User__c = null;
                    contractsToUpdate.add(aContract);
                }
            }
            if(theUser.OpportunitiesDealerUser__r.size() > 0){
                for(Opportunity anOpp :theUser.OpportunitiesDealerUser__r){
                    anOpp.Dealer_User__c = null;
                    oppsToUpdate.add(anOpp);
                }
            }
        }
        if(contractsToUpdate.size() > 0){
            List<List<SObject>> bigUpdateList = SL_DPSharingRecalcBatch.splitDMLList(contractsToUpdate);
            allErrors = SL_DPSharingRecalcBatch.bigUpsert(bigUpdateList, false, allErrors);
        }
        if(oppsToUpdate.size() > 0){
            List<List<SObject>> bigUpdateList = SL_DPSharingRecalcBatch.splitDMLList(oppsToUpdate);
            allErrors = SL_DPSharingRecalcBatch.bigUpsert(bigUpdateList, false, allErrors);
        }
    }
    public void finish(Database.BatchableContext bc){
        if(allErrors.size() > 0){
            System.debug('allErrors: ' + String.join(allErrors, '\r\n'));
        }
    }

    public void execute(SchedulableContext sc){
        Database.ExecuteBatch(new SL_DPRemoveInactiveUsers());
     }
}
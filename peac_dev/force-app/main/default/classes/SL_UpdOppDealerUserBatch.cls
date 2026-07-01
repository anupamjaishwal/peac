// DP-2123 Misael Romero
public without sharing class SL_UpdOppDealerUserBatch implements Database.Batchable<SObject>, Database.Stateful {
    List<Id> activated = new List<Id>();
    Map<Id, Id> uByC = new Map<Id, Id>();
    @testVisible 
    List<String> allErrors = new List<String>();

    public SL_UpdOppDealerUserBatch(List<Id> activated) {
        this.activated = activated;
    }

    public Database.querylocator start(Database.BatchableContext BC){
        
        for(User u :[SELECT Id, ContactId FROM User WHERE ContactId IN :activated]){
            uByC.put(u.ContactId, u.Id);
        }
        return Database.getQueryLocator([SELECT Opportunity.Dealer_Account__c, Contact.AccountId
            FROM OpportunityContactRole 
            WHERE Opportunity.Dealer_User__c = null AND Opportunity.Dealer_Account__r.IsPartner = true 
            AND ((Opportunity.Portal_User_ID__c = 'SF-' AND Role = 'Dealer Primary Contact') OR (Opportunity.Portal_User_ID__c = 'PUDA-' AND Role = 'Dealer Sales Contact'))
            AND ContactId IN :activated]);
    }

    public void execute(Database.BatchableContext BC, List<OpportunityContactRole> scope){
        Map<Id, Opportunity> oById = new Map<Id, Opportunity>();
        for(OpportunityContactRole ocr :scope){
            if(ocr.Opportunity.Dealer_Account__c == ocr.Contact.AccountId){
                Opportunity o = new Opportunity(Id=ocr.OpportunityId, Dealer_User__c = uByC.get(ocr.ContactId));
                oById.put(ocr.OpportunityId, o);
            }
        }
        if(oById.values().size() > 0){
            List<List<SObject>> bigInsertList = SL_DPSharingRecalcBatch.splitDMLList(oById.values());
            allErrors = SL_DPSharingRecalcBatch.bigUpsert(bigInsertList, false, allErrors);
        }
    }
    public void finish(Database.BatchableContext BC){
        if(allErrors.size() > 0){
            String serializedMap = String.join(allErrors, '. \r\n');
            MARLIN_IntegrationLog.addLog ('DP Sharing Recalculation Batch', BC.getJobId(), 'Error', '', serializedMap.left(131071),
                'Error', 'Error encountered while assigning Opportunity.Dealer_User__c, Contact IDs: ' + activated);
            MARLIN_IntegrationLog.insertLogs();
            // System.enqueueJob(new SL_CollectionAssignmentQ('dl-salesforcesupport@peacsolutions.com', 'Error Summary shareObject: ' + shareObject, serializedMap));
        }
    }
}
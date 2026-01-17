public without sharing class SL_DealerPortalShareOppQ implements Queueable {
    Map<Id, List<Id>> usersByOppsToShare = new Map<Id, List<Id>>();
    List<Contract__c> contractsToUpdate = new List<Contract__c>();
    List<Dealer__c> primDealersToUpd = new List<Dealer__c>();
    List<Dealer__c> primDealersToInsert = new List<Dealer__c>();
    List<Dealer__c> primDealersToDelete = new List<Dealer__c>();
    
    public SL_DealerPortalShareOppQ(Map<Id, List<Id>> usersByOppsToShare) {
        this.usersByOppsToShare = usersByOppsToShare;
    }

    public SL_DealerPortalShareOppQ(List<Contract__c> contractsToUpdate, List<Dealer__c> primDealersToUpd, List<Dealer__c> primDealersToInsert,
    List<Dealer__c> primDealersToDelete){
        this.contractsToUpdate = contractsToUpdate;
        this.primDealersToUpd = primDealersToUpd;
        this.primDealersToInsert = primDealersToInsert;
        this.primDealersToDelete = primDealersToDelete;
    }

    public void execute(QueueableContext context) {
        if(contractsToUpdate.size() > 0 || primDealersToUpd.size() > 0 || primDealersToInsert.size() > 0){
            updateDealerAccountOnRelated();
        }
        if(usersByOppsToShare.keySet().size() > 0){
            shareOpsToUsers();
        }
    }

    void shareOpsToUsers(){
        Set<Id> allUsers = new Set<Id>();
        for(List<Id> userIds :this.usersByOppsToShare.values()){
            allUsers.addAll(userIds);
        }
        List<OpportunityShare> lstShareList = new List<OpportunityShare>();
        List<OpportunityShare> existingShares = [SELECT Id, OpportunityId, UserOrGroupId, OpportunityAccessLevel, RowCause
            FROM OpportunityShare 
            WHERE OpportunityId in :this.usersByOppsToShare.keySet() AND UserOrGroupId in :allUsers];
        for(Id oppId :this.usersByOppsToShare.keySet()){
            for(Id userId : this.usersByOppsToShare.get(oppId)){
                Boolean isEditable = false;
                for(OpportunityShare oppShare :existingShares){
                    if(oppShare.OpportunityId == oppId && oppShare.UserOrGroupId == userId
                        && (oppShare.OpportunityAccessLevel == 'Edit' || oppShare.OpportunityAccessLevel == 'All')){
                        isEditable = true;
                        break;
                    }
                }
                if(!isEditable){
                    OpportunityShare OpShare = new OpportunityShare();
                    OpShare.OpportunityAccessLevel = 'Edit';
                    OpShare.OpportunityId = oppId;
                    OpShare.RowCause = 'Manual';
                    OpShare.UserOrGroupId = userId;
                    if(userId != null){
                        lstShareList.add(OpShare);
                    }
                }
            }
        }
        insert lstShareList;
    }

    void updateDealerAccountOnRelated(){
         if(contractsToUpdate.size() > 0){
            update contractsToUpdate;
        }
        if(primDealersToUpd.size() > 0){
            update primDealersToUpd;
        }
        if(primDealersToInsert.size() > 0){
            insert primDealersToInsert;
        }
        if(primDealersToDelete.size() > 0){
            system.debug('primDealersToDelete: ' + primDealersToDelete);
            delete primDealersToDelete;
        }
        Set<String> dealersToReShare = new Set<String>();
        for(Dealer__c d:primDealersToUpd){
            dealersToReShare.add(d.Dealer__c);
        }
        for(Dealer__c d:primDealersToInsert){
            dealersToReShare.add(d.Dealer__c);
        }
        if(dealersToReShare.size() > 0 && !Test.isRunningTest()){
            System.enqueueJob(new SL_UserAccountShareQ('OpportunityShare', new List<String>(dealersToReShare)));
        }
    }
}
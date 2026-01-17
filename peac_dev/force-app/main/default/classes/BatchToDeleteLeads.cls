public class BatchToDeleteLeads implements Database.Batchable<sObject>, Database.Stateful {
    public Integer recordsProcessed = 0;
    public boolean validateOnly = false;   
    public batchToDeleteLeads(boolean validateOnly) {
        this.validateOnly = validateOnly;  // constructor copies in arg to local instance vbl
    }    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        if(Test.isRunningTest()){
            return Database.getQueryLocator(
                'Select Id, OwnerId,CurrentCampaign__c from lead'   
            );
            
        }else{
          
            return Database.getQueryLocator(
                'Select Id, OwnerId,CurrentCampaign__c from lead where status != \'Closed - Lost\' AND status != \'Closed - Converted\' AND (fml_CampaignName__c = \'Customer\' OR fml_CampaignName__c = \'Retail Guests & Actives\' OR fml_CampaignName__c = \'Retail Inactive\' OR fml_CampaignName__c = \'WCL Winback\' OR fml_CampaignName__c = \'Dealer\' OR fml_CampaignName__c = \'WCL Renewal - C\' OR fml_CampaignName__c = \'Retail Prospecting\'  OR fml_CampaignName__c = \'Digital\')' 
            );
        }
    }
    
    public void execute(Database.BatchableContext bc, List<lead> scope){
        List<Lead> leads = [SELECT Id,PrimaryAccount__c, PrimaryAccount__r.MostRecentLead__c, (select ID, AutoFollowUp__r.Name, fml_Auto_Follow_Up_Campaign_Name__c, OwnerId from tasks ), (select id,CurrentAutoFollowUpStep__r.Name,AutoFollowUpsCompleted__c from CampaignMembers), OwnerId FROM Lead where id IN: scope];
        List<lead> leadIds = new List<lead>();
        set<id> accIds = new set<id>();
        for(lead ld : leads){
            if((ld.Tasks.isEmpty() && !ld.CampaignMembers.isEmpty() && ld.CampaignMembers[0].AutoFollowUpsCompleted__c == false && ld.CampaignMembers[0].CurrentAutoFollowUpStep__r.Name == 'Step 1')|| ld.PrimaryAccount__r.MostRecentLead__c != ld.id ||
               (!ld.CampaignMembers.isEmpty() && ld.CampaignMembers[0].CurrentAutoFollowUpStep__c == null && ld.Tasks.isEmpty()) ||  (ld.CampaignMembers.isEmpty() && ld.Tasks.isEmpty())){
                   if(ld.PrimaryAccount__r.MostRecentLead__c == ld.id)
                       accIds.add(ld.PrimaryAccount__c);
                   leadIds.add(ld);
               }
        }
        recordsProcessed = recordsProcessed + leadIds.size();
        
        if(!leadIds.isEmpty() && validateOnly== false){
            delete leadIds;
            List<Account> accts = [select id from Account where id IN:accIds];
            String listType = 'List<Account>';
            List<SObject> castRecords = (List<SObject>)Type.forName(listType).newInstance();
            castRecords.addAll(accts);
            TC_AccountToLead ss = new TC_AccountToLead(castRecords);
            ss.createLeadsFromAccounts();
        }
        
    }
    public void finish(Database.BatchableContext bc){
        system.debug('validateOnly***'+ validateOnly);
        system.debug('recordsProcessed***'+ recordsProcessed);
    }
}
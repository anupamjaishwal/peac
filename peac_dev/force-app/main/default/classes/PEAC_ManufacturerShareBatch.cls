/********************************************************************************************************************
@Author:Rajesh Kumar(LTIMindtree)
@Description: This class is reasponsilbe for sharing the related list of Manufacture Account related records with the 
            associated dealer user.
@User Story:DP-1241
@Created Date:October-15-2024 	    
*********************************************************************************************************************/

public class PEAC_ManufacturerShareBatch implements Database.Batchable<sObject>,database.stateful, Schedulable {
    String accessType = PEAC_ConstantClass.READ_ACCESS;
    public void execute(SchedulableContext sc){
        Database.ExecuteBatch(new PEAC_ManufacturerShareBatch(),Integer.ValueOf(Label.Manufacturer_Batch_Limit));
     }
    public Database.querylocator start(Database.BatchableContext BC) {
        // Return the list of AccountShare to be inserted
        String theQuery = '';
        String type = 'M';
        theQuery = 'SELECT Id FROM ACCOUNT WHERE Type = \'' + type + '\'';
        
        return Database.getQueryLocator(theQuery);
    }
    
    public void execute(Database.BatchableContext BC, List<Account> scopeList) {
        // Process the list of AccountShare and insert them
        try {
            Set<Id> userIdSet = new Set<Id>();
            userIdSet = New Map<Id,User>([SELECT Id, Name FROM User WHERE isActive = True AND IsPortalEnabled = True]).keyset();
            
            List<AccountShare> accountShareList = new List<AccountShare>();
            for(Account acc : scopeList) {
                for(Id userId : userIdSet){
                    AccountShare accountShare = new AccountShare();
                    accountShare.AccountId = acc.Id;
                    accountShare.AccountAccessLevel = accessType;  
                    accountShare.OpportunityAccessLevel = accessType;
                    accountShare.CaseAccessLevel = accessType;
                    accountShare.RowCause = PEAC_ConstantClass.MANUAL ;
                    accountShare.UserOrGroupId = userId;
                    accountShareList.add(accountShare);
                }
                
            }
            if(!accountShareList.isEmpty())
            {
                Insert accountShareList;
            }
        } catch (Exception ex) {
            // Handle exceptions as needed
            system.debug('ex....'+ex);
        }
    }
    
    
    public void finish(Database.BatchableContext BC) {
        // Perform any post-processing if needed
    }
    
}
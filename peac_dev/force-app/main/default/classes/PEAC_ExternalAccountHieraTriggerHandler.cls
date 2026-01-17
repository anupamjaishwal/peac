/**************************************************************************************************************
@Author:Rajesh Kumar(LTIMindtree)
@Description: This is a ExternalAccountHierarchy trigger handler and exceute the business logic upon
creation and updation of the record
@User Story:DP-1587  
@Created Date:March-26-2025       
**************************************************************************************************************/
global class PEAC_ExternalAccountHieraTriggerHandler {
    
    global class ExternalAccountDetails {
        @InvocableVariable(required=true)
        global  ExternalAccountHierarchy newDealerAccounts;

        @InvocableVariable(required=true)
        global  ExternalAccountHierarchy oldDealerAccounts;
        
        @InvocableVariable(required=true)
        global  String actionType;
    }
    
    /**************************************************************************************************************
    @Author:Rajesh Kumar(LTIMindtree)
    @Description: This method will be called when the ExternalAccountHierarchy is created
    @User Story:DP-1587  
    @Created Date:March-26-2025     
    **************************************************************************************************************/
    @InvocableMethod(label='Share Contracts with Parent dealers' description='Share Contracts with Parent dealers')
    public static void shareContracts(List<ExternalAccountDetails> newDealerAccountsList) {
        Set<Id> newAccountIdSet = new Set<Id>();
        Set<Id> oldAccountIdSet = new Set<Id>();
        Map<Id,Id> oldExternalIdWithAccountMap = new Map<Id,Id>();
        Map<Id,Id> newExternalIdWithAccountMap = new Map<Id,Id>();
        for (ExternalAccountDetails eachAccount : newDealerAccountsList) {
            if(eachAccount.actionType == 'Insert' &&  eachAccount.newDealerAccounts.accountId !=null){
                newAccountIdSet.add(eachAccount.newDealerAccounts.accountId);
            }
            if(eachAccount.actionType == 'Update' &&  eachAccount.newDealerAccounts.parentId !=null && eachAccount.newDealerAccounts.parentId != eachAccount.oldDealerAccounts.parentId){
                newAccountIdSet.add(eachAccount.newDealerAccounts.accountId);
            }
            if(eachAccount.actionType == 'Update' &&  eachAccount.oldDealerAccounts.parentId !=null && eachAccount.newDealerAccounts.parentId != eachAccount.oldDealerAccounts.parentId){
                oldExternalIdWithAccountMap.put(eachAccount.oldDealerAccounts.accountId,eachAccount.oldDealerAccounts.parentId);
            }
            
                
        }
        
        if(!newAccountIdSet.isEmpty() || !oldExternalIdWithAccountMap.isEmpty())
        {
                    
            PEAC_RemoveParentDealerContractsBatch batchJob = New PEAC_RemoveParentDealerContractsBatch(newAccountIdSet,oldExternalIdWithAccountMap);
            Database.executeBatch(batchJob, Integer.ValueOf(label.PEAC_Contract_Share_Batch_Size)); // Adjust the batch size
        }   
        
    }
       
       
}
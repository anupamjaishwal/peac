/********************************************************************************************************************
@Author:Rajesh Kumar(LTIMindtree)
@Description: This class is responsilbe for sharing the Contracts with super dealer user based on 
                Dealer Assignment.
@User Story:DP-1587
@Created Date:March-13-2025 	    
*********************************************************************************************************************/

public with sharing class PEAC_SuperPartnerDealerChange implements TC_TriggerActionI {
    /**************************************************************************************************************
    @Author:Rajesh Kumar(LTIMindtree)
    @Description: This method is being called from Contact trigger using custom metadata.
                    When super partner contact's account changed then contract resharing should be happening.
    @User Story:DP-1585
    @Created Date:March-13-2025    
    @Param: TC_TriggerContext
	@Return:None
    **************************************************************************************************************/

    public void doAction(TC_TriggerContext tc) {
        Map<Id,Id> newContAccountMap = new Map<Id, Id>();
        Map<Id,Id> oldContAccountMap = new Map<Id, Id>();
        
        for (Contact cont : tc.getNewList() == null ? (List<Contact>) tc.getOldMap().values() : tc.getNewList()) {
            Contact contOld = tc.getOldMap() == null ? null : (Contact)tc.getOldMap().get(cont.Id);
            if(cont.AccountId !=null && cont.AccountId != contOld.AccountId )
            {
                newContAccountMap.put(cont.Id, cont.AccountId);
                oldContAccountMap.put(cont.Id, contOld.AccountId);
            }
        }
        
        if(!newContAccountMap.isEmpty())
        {
            removeUserAccessOnContracts(oldContAccountMap,newContAccountMap);
        }
        
    } 
    /**************************************************************************************************************
    @Author:Rajesh Kumar(LTIMindtree)
    @Description: This method is being called from doaction method.
    @User Story:DP-1585
    @Created Date:March-13-2025    
    @Param: Map of new contact id and old account id, Map of new contact id and new account id
	@Return:None
    **************************************************************************************************************/

    public Static void removeUserAccessOnContracts(Map<Id,Id> oldContAccountMap, Map<Id,Id> newContAccountMap)
    {
        List<User> userList = New List<User>();
        Map<Id,Id> userAccountMap = New Map<Id,Id>();
        userList = [SELECT Id, ContactId FROM User WHERE IsActive = True AND IsPrmSuperUser = True AND ContactId IN:oldContAccountMap.keySet()];
        for(user updatedUser :userList)
        {
            userAccountMap.put(updatedUser.Id, oldContAccountMap.get(updatedUser.ContactId));
        }
        if(!userAccountMap.isEmpty())
        {
            PEAC_RemoveContractShareBatch batchJob = New PEAC_RemoveContractShareBatch(userAccountMap,newContAccountMap,'Contact');
            Database.executeBatch(batchJob, Integer.ValueOf(label.PEAC_Contract_SUser_Sharing)); // Adjust the batch size
        }

    }
    /**************************************************************************************************************
    @Author:Rajesh Kumar(LTIMindtree)
    @Description: This method is being called from Contract trigger.
                    When super partner contract's account changed then contract resharing should be happening.
    @User Story:DP-1585
    @Created Date:March-13-2025    
    @Param: Map of contract
	@Return:None
    **************************************************************************************************************/

    public static void removeContractShare(Map <Id, Contract__c> newMapContract,Map <Id, Contract__c> oldMapContract )
    {
        Map<Id,Id> oldContractAccountMap = new Map<Id, Id>();
        Map<Id,Id> oldContractDealerUserMap = new Map<Id, Id>();
        Map<Id,Id> newContractAccountMap = new Map<Id, Id>();
        Map<Id,Id> newContractDealerUserMap = new Map<Id, Id>();
        Set<Id> oldContractIdSet = new Set<Id>();
        Map<Id,Set<Id>> dealerSuperUserIdMap = new Map<Id,Set<Id>>();
        
        for(contract__c contrct : newMapContract.values()){
            if(oldMapContract.get(contrct.Id).dealer_Name__c !=null && contrct.dealer_Name__c != oldMapContract.get(contrct.Id).dealer_Name__c){
                oldContractAccountMap.put(contrct.Id, oldMapContract.get(contrct.Id).dealer_Name__c);
            }
            if(contrct.dealer_Name__c !=null && contrct.dealer_Name__c != oldMapContract.get(contrct.Id).dealer_Name__c){
                newContractAccountMap.put(contrct.Id, contrct.dealer_Name__c);
            }
            if(contrct.dealer_User__c != oldMapContract.get(contrct.Id).dealer_User__c){
                oldContractDealerUserMap.put(contrct.Id, oldMapContract.get(contrct.Id).dealer_User__c);
                newContractDealerUserMap.put(contrct.Id, contrct.dealer_User__c);
            }
            
        }
        if(!oldContractAccountMap.isEmpty () || !newContractAccountMap.isEmpty()) 
        {
            Set<Id> oldAccountSet = new Set<Id>();
            oldAccountSet.addAll(oldContractAccountMap.values());
            
            PEAC_ContractShareHelperBatch.getParentDealers(oldAccountSet);// get all parent dealers if any
            dealerSuperUserIdMap.putAll(PEAC_ContractShareHelperBatch.dealerSuperUserIdMap);// add parent dealer users if any
            //Get all super users and their associated account ids
            Map<Id, User>  userMap = new Map<Id, User>([SELECT Id, Contact.AccountId FROM User WHERE IsActive = True AND IsPrmSuperUser = true AND Contact.AccountId IN:oldContractAccountMap.values()]);
            if(!userMap.isEmpty())
            {
                for (User superUser:userMap.values()) {
                    if(!dealerSuperUserIdMap.containsKey(superUser.Contact.AccountId))
                    {
                        dealerSuperUserIdMap.put(superUser.Contact.AccountId,new set<Id>());
                    }
                    dealerSuperUserIdMap.get(superUser.Contact.AccountId).add(superUser.Id);//adding super users from old dealers
                }
            }
            Map<Id,Set<Id>> contractIdwithUsersMap = new Map<id,Set<Id>>();
            for(id oldContractId: oldContractAccountMap.keySet())
            {
                contractIdwithUsersMap.put(oldContractId, new Set<Id>());
                if(!dealerSuperUserIdMap.isEmpty() && dealerSuperUserIdMap.containsKey(oldContractAccountMap.get(oldContractId)))
                contractIdwithUsersMap.get(oldContractId).addAll(dealerSuperUserIdMap.get(oldContractAccountMap.get(oldContractId)));// add all super partner users with parent account
            }
            system.debug(LoggingLevel.ERROR, 'contractIdwithUsersMap....'+oldContractDealerUserMap+'...'+newContractAccountMap+'....'+contractIdwithUsersMap);
            PEAC_RemoveContractShareBatch batchJob = New PEAC_RemoveContractShareBatch(contractIdwithUsersMap,newContractAccountMap,oldContractAccountMap);
            Database.executeBatch(batchJob, Integer.ValueOf(Label.PEAC_Contract_Share_Batch_Size)); // Adjust the batch size
            
        }
        if(!oldContractDealerUserMap.isEmpty() || !newContractDealerUserMap.isEmpty())
        {
            PEAC_AddRemoveContractDearlerUserBatch dealerBatchJob = New PEAC_AddRemoveContractDearlerUserBatch(oldContractDealerUserMap,newContractDealerUserMap);
            Database.executeBatch(dealerBatchJob, Integer.ValueOf(Label.PEAC_Contract_Share_Batch_Size)); // Adjust the batch size  
        }
        

    }
    /**************************************************************************************************************
    @Author:Rajesh Kumar(LTIMindtree)
    @Description: This method is being called from Contract trigger. When new contract is created with dealer account.
    @User Story:DP-1585
    @Created Date:March-13-2025    
    @Param: Map of contract id and contract
	@Return:None
    **************************************************************************************************************/

    public static void contractShare(Map <Id, Contract__c> newMapContract )
    {
        Map<Id,Id> newContractAccountMap = new Map<Id, Id>();
        for(contract__c contrct : newMapContract.values()){
            //Check for dealer account is there or not
            if(contrct.dealer_Name__c !=null){
                newContractAccountMap.put(contrct.Id, contrct.dealer_Name__c);
            }
        }
        if(!newContractAccountMap.isEmpty ()) 
        {
            // Run the batch class to share contract records with dealer super users and their associated accounts
            PEAC_ContractShareBatch batchJob = New PEAC_ContractShareBatch(newContractAccountMap,True);
            Database.executeBatch(batchJob, Integer.ValueOf(Label.PEAC_Contract_Share_Batch_Size)); // Adjust the batch size
        }
        

    }
}
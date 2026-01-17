/********************************************************************************************************************
@Author:Rajesh Kumar(LTIMindtree)
@Description: This class is responsilbe for sharing the related list of Contract records with the 
            associated dealer user.
@User Story:DP-1585
@Created Date:March-31-2025 	    
*********************************************************************************************************************/

public class PEAC_AddRemoveContractDearlerUserBatch implements Database.Batchable<sObject>,database.stateful {
    Map<Id,Id> contractIdwithOldDUsersMap = new Map<Id,Id>();
    Map<Id,Id> contractIdwithNewDUsersMap = new Map<Id,Id>();
    String editAccess = 'Edit';
    String contractRowCause = 'Dealer_Contract_Sharing__c';
    //Call this constructor from contract trigger handlers.
       
    public PEAC_AddRemoveContractDearlerUserBatch(Map<Id,Id> contractIdwithOldDUsersMap,Map<Id,Id> contractIdwithNewDUsersMap ) {
        this.contractIdwithOldDUsersMap = contractIdwithOldDUsersMap;
        this.contractIdwithNewDUsersMap = contractIdwithNewDUsersMap;
        
    }
    
    /**************************************************************************************************************
    @Author:Rajesh Kumar(LTIMindtree)
    @Description: This is start method of the batch class
    @User Story:DP-1585
    @Created Date:February-20-2025    
    @Param: Database.BatchableContext
	@Return:Get list of contract to be shared
    **************************************************************************************************************/

    public Database.querylocator start(Database.BatchableContext BC) {
        String dealerIdsString = '\'' + String.join(contractIdwithNewDUsersMap.keySet(), '\',\'') + '\''; // used for contracts
        String theQuery = '';
        theQuery = 'SELECT Id, Dealer_Name__c, Dealer_User__c, Dealer_User__r.IsActive, OwnerId FROM Contract__c WHERE ID IN ('
        + dealerIdsString + ') ';
        
        return Database.getQueryLocator(theQuery);

    }
    
    /**************************************************************************************************************
    @Author:Rajesh Kumar(LTIMindtree)
    @Description: Execute method of the batch class
    @User Story:DP-1585
    @Created Date:February-20-2025    
    @Param: Database.BatchableContext and List of Contract__Share
	@Return:None
    **************************************************************************************************************/
    public void execute(Database.BatchableContext bc, List<sObject> scopeList) {
        List<SObject> sharesToDeleteList = new List<SObject>();
        List<Contract__Share> contractShareList = new List<Contract__Share>();
        Set<Id> dealerIdSet = new Set<Id>();
        Map<Id,Set<Id>> dealerSuperUserIdMap = new Map<Id,Set<Id>>();
        Set<Id> contractIdSet = new Set<Id>();
        List<Contract__Share> contractSharetoProcessList = New List<Contract__Share>();
        Map<Id, User> userMap = new Map<Id, User>();
        for(sObject objR : scopeList) {
            Contract__c contr = (Contract__c)objR;
            dealerIdSet.add(contr.Dealer_Name__c);
            contractIdSet.add(contr.Id);
            if(contr.Dealer_User__c != null)
            {
                contractShareList.add(PEAC_ContractShareHelperBatch.contractShare(contr.Id, contr.Dealer_User__c,editAccess,contractRowCause));
           
            }
            
        }
        userMap = new Map<Id, User>([SELECT Id, Contact.AccountId FROM User WHERE IsActive = True AND IsPrmSuperUser = true AND Contact.AccountId IN:dealerIdSet ]);

        contractSharetoProcessList = [SELECT Id, ParentId,Parent.Dealer_Name__c,Parent.Dealer_User__c, UserOrGroupId, RowCause, UserOrGroup.IsActive 
                                    FROM Contract__Share WHERE RowCause =:contractRowCause 
                                    AND AccessLevel =:editAccess AND parentId IN : contractIdSet ];
        
        PEAC_ContractShareHelperBatch.getParentDealers(dealerIdSet);
        dealerSuperUserIdMap = PEAC_ContractShareHelperBatch.dealerSuperUserIdMap;
        for(Contract__Share contrShare : contractSharetoProcessList){
            //check if dealer user is not a super partner user
            if(userMap.get(contrShare.UserOrGroupId) == null || (userMap.get(contrShare.UserOrGroupId) != null && userMap.get(contrShare.UserOrGroupId).Contact.Accountid != contrShare.Parent.Dealer_Name__c ))
            {
                if(dealerSuperUserIdMap.get(contrShare.Parent.Dealer_Name__c) == null || (dealerSuperUserIdMap.get(contrShare.Parent.Dealer_Name__c) != null && !dealerSuperUserIdMap.get(contrShare.Parent.Dealer_Name__c).contains(contrShare.UserOrGroupId)))
                {
                    if(contractIdwithOldDUsersMap.get(contrShare.ParentId) != null && contractIdwithOldDUsersMap.get(contrShare.ParentId) == contrShare.UserOrGroupId){
                        sharesToDeleteList.add(contrShare);//add share record to be deleted
                    }
                }
            }
            
            
                        
        }
        
        if(!sharesToDeleteList.isEmpty()){
            Delete sharesToDeleteList ;// Delete the share records
            
        }
        if(!contractShareList.isEmpty()){
            Insert contractShareList ;// Delete the share records
        }
    }
    /**************************************************************************************************************
    @Author:Rajesh Kumar(LTIMindtree)
    @Description:Finish method of the batch class
    @User Story:DP-1585
    @Created Date:February-20-2025    
    @Param: Database.BatchableContext
	@Return:None
    **************************************************************************************************************/

    public void finish(Database.BatchableContext bc) {
         //empty
    }
}
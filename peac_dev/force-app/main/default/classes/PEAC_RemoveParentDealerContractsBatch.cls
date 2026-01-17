/********************************************************************************************************************
@Author:Rajesh Kumar(LTIMindtree)
@Description: This class is responsilbe for sharing the related list of Contract records with the 
            associated super dealer user.
@User Story:DP-1585
@Created Date:February-20-2025 	    
*********************************************************************************************************************/

public class PEAC_RemoveParentDealerContractsBatch implements Database.Batchable<sObject>,database.stateful {
    Map<Id, User> userMap = new Map<Id, User>();
    Map<Id,Set<Id>> contractIdwithUsersMap = new Map<id,Set<Id>>();
    Map<Id,Id> newContAccountMap = new Map<Id,Id>();
    Set<Id> oldParentIdSet = new Set<Id>();
    List<Id> allDealerIdsList = new List<Id>();
    Map<Id,Set<Id>> childAccountMap = new Map<Id,Set<Id>>();
    Map<Id,Id> newContractAccountMap = new Map<Id,Id>();
    Map<Id,Id> oldContractAccountMap = new Map<Id,Id>();
    public Map<Id,Set<Id>> dealerSuperUserIdMap = new Map<Id,Set<Id>>();
    Set<Id> dealerAccountIdsList = new Set<Id>();
    Map<Id,Id> oldExternalIdWithAccountMap = new Map<Id,Id>();
    
    //Call this constructor from External account flow.
    public PEAC_RemoveParentDealerContractsBatch(Set<Id> dealerAccountIdsset , Map<Id,Id> oldExternalIdWithAccountMap) {
        this.oldExternalIdWithAccountMap = oldExternalIdWithAccountMap;
        this.dealerAccountIdsList = dealerAccountIdsset;
        this.allDealerIdsList.addAll(dealerAccountIdsset);
        
        
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
        prepareData();// get required data for contract sharing
        String dealerIdsString = '\'' + String.join(allDealerIdsList, '\',\'') + '\'';// used this for Users and Contacts
         String theQuery = '';
        theQuery = 'SELECT Id, ParentId,Parent.Dealer_Name__c,Parent.Dealer_User__c, UserOrGroupId,UserOrGroup.Name, RowCause, UserOrGroup.IsActive '
                        + 'FROM Contract__Share WHERE RowCause = \'Dealer_Contract_Sharing__c\' AND AccessLevel = \'Edit\' ';
       
        theQuery += 'AND parent.Dealer_Name__c IN ('+ dealerIdsString + ')'; 
       
        return Database.getQueryLocator(theQuery);

    }
    /**************************************************************************************************************
    @Author:Rajesh Kumar(LTIMindtree)
    @Description: Get partner super user and partner account
    @User Story:DP-1585
    @Created Date:February-20-2025    
    @Param: None
	@Return:None
    **************************************************************************************************************/

    public void prepareData()
    {
        PEAC_ContractShareHelperBatch.getExternalAccounts(oldExternalIdWithAccountMap);
        dealerSuperUserIdMap = PEAC_ContractShareHelperBatch.dealerSuperUserIdMap;
            
       
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
        List<SObject> sharesToDelete = new List<SObject>();
        Set<Id> contShareIdsSet = new Set<Id>();
        
        for(SObject obj : scopeList){
            Contract__Share contrShare = (Contract__Share)obj;//get contract share record
            //User theUser = userMap.get(contrShare.UserOrGroupId);//get partner or super partner user
            
                for(id dealerId: oldExternalIdWithAccountMap.keySet())
                {
                    //System.debug(LoggingLevel.ERROR, 'dealerSuperUserIdMap.....'+dealerSuperUserIdMap);
                    //System.debug(LoggingLevel.ERROR, 'oldExternalIdWithAccountMap.get(dealerId)....'+oldExternalIdWithAccountMap.get(dealerId)+'.....'+dealerId);
                    if(contrShare.parent.Dealer_Name__c == dealerId && dealerSuperUserIdMap.get(oldExternalIdWithAccountMap.get(dealerId)) !=null)
                    {
                        for (Id parentUserId : dealerSuperUserIdMap.get(oldExternalIdWithAccountMap.get(dealerId))) {
                            //Check for user id which is already a contract dealer user and contract owner
                            if(parentUserId == contrShare.UserOrGroupId && parentUserId != contrShare.parent.Dealer_User__c ){
                                //Pass the below parameters in the method and add contract__share into list
                                sharesToDelete.add(obj);//add share record to be deleted
                                System.debug(LoggingLevel.ERROR, 'parentUserId....'+parentUserId);
                                break;
                                
                            } 
                        }
                    }
                    
                }
                
                }
                    
                
            
        
        
        if(!sharesToDelete.isEmpty()){
           Delete sharesToDelete ;// Delete the share records
            
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
        
        //Call share batch calss to share contract records with the new accounts in contracts
        if(!dealerAccountIdsList.isEmpty()){
          PEAC_ContractShareToParentBatch batchJob = New PEAC_ContractShareToParentBatch(dealerAccountIdsList);
          Database.executeBatch(batchJob, Integer.ValueOf(Label.PEAC_Contract_Share_Batch_Size)); // Adjust the batch size
           
        }
    }
}
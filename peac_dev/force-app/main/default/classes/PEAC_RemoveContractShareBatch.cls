/********************************************************************************************************************
@Author:Rajesh Kumar(LTIMindtree)
@Description: This class is responsilbe for sharing the related list of Contract records with the 
            associated super dealer user.
@User Story:DP-1585
@Created Date:February-20-2025 	    
*********************************************************************************************************************/

public class PEAC_RemoveContractShareBatch implements Database.Batchable<sObject>,database.stateful {
    Map<Id, User> userMap = new Map<Id, User>();
    Map<Id,Id> sDPUserAccountIDMap = new Map<Id,Id>();
    String invokedFrom = 'User';
    Map<Id,Set<Id>> contractIdwithUsersMap = new Map<id,Set<Id>>();
    Map<Id,Id> newContAccountMap = new Map<Id,Id>();
    Set<Id> updatedContractIdSet = new Set<Id>();
    List<Id> allDealerIdsList = new List<Id>();
    Map<Id,Set<Id>> childAccountMap = new Map<Id,Set<Id>>();
    Map<Id,Id> newContractAccountMap = new Map<Id,Id>();
    Map<Id,Id> oldContractAccountMap = new Map<Id,Id>();
   
    public PEAC_RemoveContractShareBatch() {

    }
    //Call this constructor from user and contact trigger handlers.
    public PEAC_RemoveContractShareBatch(Map<Id,Id> sDPUserAccountIDMap,  String invokedFrom) {
        this.sDPUserAccountIDMap = sDPUserAccountIDMap;
        this.allDealerIdsList = sDPUserAccountIDMap.values();
        this.invokedFrom = invokedFrom;
    }
    //Call this constructor from contact trigger handlers.
    public PEAC_RemoveContractShareBatch(Map<Id,Id> sDPUserAccountIDMap,Map<Id,Id> newContAccountMap,  String invokedFrom) {
        this.sDPUserAccountIDMap = sDPUserAccountIDMap;
        this.newContAccountMap = newContAccountMap;
        this.invokedFrom = invokedFrom;
        this.allDealerIdsList = sDPUserAccountIDMap.values();
    }
     
    //Call this constructor from contract trigger handlers.
       
    public PEAC_RemoveContractShareBatch(Map<Id,Set<Id>> contractIdwithUsersMap,Map<Id,Id> newContractAccountMap,Map<Id,Id> oldContractAccountMap ) {
        this.contractIdwithUsersMap = contractIdwithUsersMap;
        this.newContractAccountMap = newContractAccountMap;
        this.oldContractAccountMap = oldContractAccountMap;
        this.allDealerIdsList = oldContractAccountMap.values();
        this.invokedFrom = 'Contract';
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
        String contractIdString = '\'' + String.join(contractIdwithUsersMap.keySet(), '\',\'') + '\''; // used for contracts
        String theQuery = '';
        theQuery = 'SELECT Id, ParentId,Parent.Dealer_Name__c,Parent.Dealer_User__c, UserOrGroupId, RowCause, UserOrGroup.IsActive '
                        + 'FROM Contract__Share WHERE RowCause = \'Dealer_Contract_Sharing__c\' AND AccessLevel = \'Edit\' ';
        if (invokedFrom == 'User' || invokedFrom == 'Contact') {
            theQuery += 'AND parent.Dealer_Name__c IN ('+ dealerIdsString + ')'; 
        }    
        else if (invokedFrom == 'Contract') {
            theQuery += 'AND parentId IN ('+ contractIdString + ')';
        }
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
        userMap = new Map<Id, User>([SELECT Id, Contact.AccountId,IsPrmSuperUser FROM User WHERE 
                IsActive = True AND ID IN: sDPUserAccountIDMap.keySet()]); 
        if(userMap.isEmpty())
        {
            userMap = new Map<Id, User>([SELECT Id, Contact.AccountId,IsPrmSuperUser FROM User WHERE 
            IsActive = True AND Contact.AccountId IN: allDealerIdsList]);  
        }
        //Check for all dealer ids is not empty
        if(!allDealerIdsList.isEmpty()){
            //get all child accounts
            childAccountMap = PEAC_ContractShareHelperBatch.getDealerChildAccounts(allDealerIdsList);
            for(Id childDealer : childAccountMap.keySet())
            {
                allDealerIdsList.addAll(childAccountMap.get(childDealer));//add child accounts into all dealer accounts list
            }
        }
        userMap = new Map<Id, User>([SELECT Id, Contact.AccountId,IsPrmSuperUser FROM User WHERE 
                IsActive = True AND ID IN: sDPUserAccountIDMap.keySet()]); 
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
            User theUser = userMap.get(contrShare.UserOrGroupId);//get partner or super partner user
            system.debug(LoggingLevel.Error, 'contractIdwithUsersMap.....'+contractIdwithUsersMap);
            //check for user is a partner super user and contact is associated with the account of the user
            if(theUser != null && ((theUser.IsPrmSuperUser && invokedFrom == 'Contact') || (invokedFrom == 'User' && !theUser.IsPrmSuperUser)) &&  theUser.Id !=contrShare.Parent.Dealer_User__c ){
                sharesToDelete.add(obj);//add share record to be deleted
                contShareIdsSet.add(obj.id);//handle duplicate list of deleted records
            }
           else if(invokedFrom == 'Contract' && contractIdwithUsersMap.get(contrShare.ParentId) != null && contractIdwithUsersMap.get(contrShare.ParentId).contains(contrShare.UserOrGroupId)){
                sharesToDelete.add(obj);//add share record to be deleted
                contShareIdsSet.add(obj.id);//handle duplicate list of deleted records
            }
            for (Id dealerID: childAccountMap.keySet()) {
                for (Id childDealerId : childAccountMap.get(dealerID)) {
                    if (!contShareIdsSet.contains(obj.id) && theUser != null && childDealerId == contrShare.parent.Dealer_Name__c && theUser.Id !=contrShare.Parent.Dealer_User__c ) {
                        sharesToDelete.add(obj);//add share record to be deleted
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
         //Call share batch calss to share contract records with the new accounts in contacts  
        if(!newContAccountMap.isEmpty()){
            PEAC_SuperUsersContractShareBatch batchJob = New PEAC_SuperUsersContractShareBatch(newContAccountMap, 'Contact');
            Database.executeBatch(batchJob, Integer.ValueOf(Label.PEAC_Contract_Share_Batch_Size)); // Adjust the batch size
           
        }
        //Call share batch calss to share contract records with the new accounts in contracts
        if(!newContractAccountMap.isEmpty()){
            PEAC_ContractShareBatch batchJob = New PEAC_ContractShareBatch(newContractAccountMap,True);
            Database.executeBatch(batchJob, Integer.ValueOf(Label.PEAC_Contract_Share_Batch_Size)); // Adjust the batch size
           
        }
    }
}
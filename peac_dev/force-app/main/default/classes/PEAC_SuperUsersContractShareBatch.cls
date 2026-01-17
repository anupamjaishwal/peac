/********************************************************************************************************************
@Author:Rajesh Kumar(LTIMindtree)
@Description: This class is responsilbe for sharing the related list of Contract records with the 
            associated super dealer user.
@User Story:DP-1585
@Created Date:February-20-2025 	    
*********************************************************************************************************************/

public class PEAC_SuperUsersContractShareBatch implements Database.Batchable<sObject>,database.stateful {
    Map<Id,Id> sDPUserAccountIDMap = New Map<Id,Id>();
    List<Id> dealerAccountIdList =  New List<Id>();
    Map<Id, User> userMap = New Map<Id, User>();
    String editAccess = 'Edit';
    String contractRowCause = 'Dealer_Contract_Sharing__c';
    Map<Id,Set<Id>> parentChildAccountMap = new Map<Id,Set<Id>>();
    public Map<Id,Set<Id>> dealerSuperUserIdMap = new Map<Id,Set<Id>>();
    Map<Id,Id> newContAccountMap = new Map<Id,Id>();
    Map<Id,Id> oldContAccountMap = new Map<Id,Id>();
    Map<Id,Set<Id>> childAccountMap = new Map<Id,Set<Id>>();
    List<String> allErrors = new List<String>();
    String calledFrom = 'User';
    //Call this constructor from Super partner user creation
    public PEAC_SuperUsersContractShareBatch(Map<Id,Id> sDPUserAccountIDMap) {
        this.sDPUserAccountIDMap = sDPUserAccountIDMap;
        this.dealerAccountIdList = this.sDPUserAccountIDMap.values();
    }
    
    //Call this constructor from Super partner user contact dealer change
    public PEAC_SuperUsersContractShareBatch(Map<Id,Id> newContAccountMap, String calledFrom) {
        this.newContAccountMap = newContAccountMap;
        this.calledFrom = calledFrom;
        this.dealerAccountIdList = this.newContAccountMap.values();
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
        String theQuery = '';
        
        //dealerAccountIdList.addAll(sDPUserAccountIDMap.values());
        System.debug(LoggingLevel.ERROR, 'dealerAccountIdList....'+dealerAccountIdList);
        String dealerIdsString = '\'' + String.join(dealerAccountIdList, '\',\'') + '\'';
        
        theQuery = 'SELECT Id, Dealer_Name__c, Dealer_User__c, Dealer_User__r.IsActive, OwnerId FROM Contract__c WHERE Dealer_Name__c IN ('
                    + dealerIdsString + ') ';
        
        
        theQuery += ' ORDER BY Dealer_Name__c ASC,CreatedDate DESC' ;   
                
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
        Map<Id, User> userMap = new Map<Id, User>();
        if(!dealerAccountIdList.isEmpty())
        {
            childAccountMap = PEAC_ContractShareHelperBatch.getDealerChildAccounts(dealerAccountIdList);
            for(Id childDealer : childAccountMap.keySet())
            {
              dealerAccountIdList.addall(childAccountMap.get(childDealer));
            }
        }
        if(!newContAccountMap.isEmpty())
        {
            userMap = new Map<Id, User>([SELECT Id, Contact.AccountId FROM User WHERE IsActive = True AND IsPrmSuperUser = true AND ContactId IN: newContAccountMap.keySet()]); 
            addDealerSuperUser(userMap);
        }
        //Get super users with specified user id
        userMap = new Map<Id, User>([SELECT Id, Contact.AccountId FROM User WHERE IsActive = True AND IsPrmSuperUser = true AND ID IN:sDPUserAccountIDMap.keySet() ]);
        
        addDealerSuperUser(userMap);
        
    }
    public void addDealerSuperUser(Map<Id,User> userMap)
    {
        for(user superDuser: userMap.values()){
            sDPUserAccountIDMap.Put(superDuser.Id,superDuser.Contact.AccountId);// add super partner user id and account id into map
        }
    }
   
    /**************************************************************************************************************
    @Author:Rajesh Kumar(LTIMindtree)
    @Description: Execute method of the batch class
    @User Story:DP-1585
    @Created Date:February-20-2025    
    @Param: Database.BatchableContext and List of Contract__c
	@Return:None
    **************************************************************************************************************/

    public void execute(Database.BatchableContext BC, List<sObject> scopeList) {
        // Process the list of Contract__Share and insert them
        Map<Id,Set<Id>> contractUserIDMap = new Map<Id,Set<Id>>();
        try {
            List<Contract__Share> contractShareList = new List<Contract__Share>();
            
            for(sObject obj : scopeList) {
                Contract__c contractRec = (Contract__c)obj;
                //Check for contract dealer user is not null and active
                contractUserIDMap.put(contractRec.id,new Set<Id>());
                for(Id userId : sDPUserAccountIDMap.keySet()){
                    //Check for user id which is already a contract dealer user and contract owner
                    if(!contractUserIDMap.get(contractRec.id).contains(userId) && sDPUserAccountIDMap.get(userId) == contractRec.Dealer_Name__c && contractRec.OwnerId !=userId ){
                        //Pass the below parameters in the method and add contract__share into list
                        contractShareList.add(contractShare(contractRec.id, userId,editAccess,contractRowCause));
                        contractUserIDMap.get(contractRec.id).add(userId) ;// add contract id and dealer user into map
                
                    }
                    for (Id dealerID: childAccountMap.keySet()) {
                
                        for (Id childDealerId : childAccountMap.get(dealerID)) {
                            if ( !contractUserIDMap.get(contractRec.id).contains(userId) && childDealerId == contractRec.Dealer_Name__c) {
                                //Pass the below parameters in the method and add contract__share into list
                                contractShareList.add(contractShare(contractRec.id, userId,editAccess,contractRowCause));
                                contractUserIDMap.get(contractRec.id).add(userId) ;// add contract id and dealer user into map
                                system.debug(LoggingLevel.Error, 'childDealerId....'+childDealerId+'Count...'+contractUserIDMap.size());
           
                            }
                        }
                    }  
                    system.debug(LoggingLevel.Error, 'contractUserIDMap....'+contractUserIDMap+'Count...'+contractUserIDMap.size());
           
                }
                
                
                
                
                
            }
            system.debug(LoggingLevel.Error, 'contractShareList....'+contractShareList+'Count...'+contractShareList.size());
           
            if(!contractShareList.isEmpty())
            {
                Insert contractShareList;// insert contract share records here
                
            }
        } catch (Exception ex) {
            // Handle exceptions as needed
            system.debug('ex....'+ex);
            allErrors.add('sDPUserAccountIDMap...'+sDPUserAccountIDMap+ '\r\n'+ ' \r\n' + ex.getMessage()+ ' \r\n' );
            
        }
    }
    /**************************************************************************************************************
    @Author:Rajesh Kumar(LTIMindtree)
    @Description:Prepare Contract__Share record for insertion
    @User Story:DP-1585
    @Created Date:February-20-2025    
    @Param: parent record id, userorgroupid and access level
	@Return:Contract__Share
    **************************************************************************************************************/

    public Contract__Share contractShare(Id parentId, Id userOrGroupId,String accessLevel, String rowCause)
    {
        
        Contract__Share accountShare = new Contract__Share();
        accountShare.ParentId = parentId;
        accountShare.AccessLevel = accessLevel;  
        accountShare.RowCause =  rowCause;
        accountShare.UserOrGroupId = userOrGroupId;
        return accountShare;
    }
    
    /**************************************************************************************************************
    @Author:Rajesh Kumar(LTIMindtree)
    @Description:Finish method of the batch class
    @User Story:DP-1585
    @Created Date:February-20-2025    
    @Param: Database.BatchableContext
	@Return:None
    **************************************************************************************************************/

    public void finish(Database.BatchableContext BC) {
        if(!allErrors.isEmpty()){
            String serializedMap = String.join(allErrors, '. \r\n');
            MARLIN_IntegrationLog.addLog ('PEAC_ContractShareBatch', BC.getJobId(), 'Error', '', serializedMap.left(131071),
                'Error', 'Error encountered while trying to give access to the Dealer Super Users described in the Response_Message__c field, shareObject: ' + 'Contract__Share');
            MARLIN_IntegrationLog.insertLogs();
            System.enqueueJob(new SL_CollectionAssignmentQ('dl-salesforcesupport@peacsolutions.com', 'Error Summary shareObject: ' + 'Contract__Share', serializedMap));
        }
    }
        
}
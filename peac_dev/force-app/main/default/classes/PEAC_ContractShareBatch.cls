/********************************************************************************************************************
@Author:Rajesh Kumar(LTIMindtree)
@Description: This class is responsilbe for sharing the related list of Contract records with the 
            associated super dealer user.
@User Story:DP-1585
@Created Date:February-20-2025 	    
*********************************************************************************************************************/

public class PEAC_ContractShareBatch implements Database.Batchable<sObject>,database.stateful, Schedulable {
    Map<Id,Id> sDPUserAccountIDMap = New Map<Id,Id>();
    List<Id> dealerAccountIdList =  New List<Id>();
    Map<Id, User> userMap = New Map<Id, User>();
    Set<Id> contractIDSet = New Set<Id>();
    Boolean isSchedulerBatch = False;
    Boolean isCalledFromContract = False;
    String editAccess = 'Edit';
    String createdDate_STR = 'TODAY';
    String contractRowCause = 'Dealer_Contract_Sharing__c';
    Boolean isContractReshare = False;
    Map<Id,Set<Id>> parentChildAccountMap = new Map<Id,Set<Id>>();
    public Map<Id,Set<Id>> dealerSuperUserIdMap = new Map<Id,Set<Id>>();
    Map<Id,Id> newContAccountMap = new Map<Id,Id>();
    Map<Id,Id> oldContAccountMap = new Map<Id,Id>();
    String calledFrom = 'User';
    Map<Id,Set<Id>> childAccountMap = new Map<Id,Set<Id>>();
    List<String> allErrors = new List<String>();
    public PEAC_ContractShareBatch() {
        //Empty contructor
    }
    //Call this constructor from Super partner user creation
    public PEAC_ContractShareBatch(Map<Id,Id> sDPUserAccountIDMap) {
        this.sDPUserAccountIDMap = sDPUserAccountIDMap;
        this.dealerAccountIdList = this.sDPUserAccountIDMap.values();
    }
    //Call this constructor from contract updates
    public PEAC_ContractShareBatch(Map<Id,Id> newContractAccountMap,Boolean isCalledFromContract) {
        this.contractIDSet = newContractAccountMap.keySet();
        this.dealerAccountIdList = newContractAccountMap.values();
        this.isCalledFromContract = isCalledFromContract;
    }
    
    //call this constructor to execute dynamic Created Datetime to share contracts
    public PEAC_ContractShareBatch(String createdDate_STR,Boolean isSchedulerBatch)
    {
        this.createdDate_STR = createdDate_STR;
        this.isSchedulerBatch = isSchedulerBatch;
    }
   
    //Call this constructor from Schedule Batch class.
    public PEAC_ContractShareBatch(Boolean isSchedulerBatch) {
        this.isSchedulerBatch = isSchedulerBatch;
    }
    //Share contracts based on Dealer Accounts.
    public PEAC_ContractShareBatch(List<Id> dealerAccountsList) {
        this.dealerAccountIdList = dealerAccountsList; 
        
    }
    /**************************************************************************************************************
    @Author:Rajesh Kumar(LTIMindtree)
    @Description: This method will execute the scheduler
    @User Story:DP-1585
    @Created Date:February-20-2025    
    @Param:SchedulableContext
	@Return:None
    **************************************************************************************************************/

    public void execute(SchedulableContext sc){
        Database.ExecuteBatch(new PEAC_ContractShareBatch(True),Integer.ValueOf(Label.PEAC_Contract_Share_Batch_Size));
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

        dealerAccountIdList.addAll(sDPUserAccountIDMap.values());
        System.debug(LoggingLevel.ERROR, 'dealerAccountIdList....'+dealerAccountIdList);
        String dealerIdsString = '\'' + String.join(dealerAccountIdList, '\',\'') + '\'';
        
        theQuery = 'SELECT Id, Dealer_Name__c, Dealer_User__c, Dealer_User__r.IsActive, OwnerId FROM Contract__c WHERE Dealer_Name__c IN ('
                    + dealerIdsString + ') ';
        
        if(isCalledFromContract){
            theQuery = 'SELECT Id, Dealer_Name__c, Dealer_User__c, Dealer_User__r.IsActive, OwnerId FROM Contract__c WHERE ID IN: contractIDSet';
        }
        if(isSchedulerBatch)
        {
            theQuery +=' AND CreatedDate = '+ createdDate_STR  ;        
       
        }
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
            userMap = new Map<Id, User>([SELECT Id, Contact.AccountId FROM User WHERE IsActive = True AND IsPrmSuperUser = true AND Contact.AccountId IN:dealerAccountIdList ]);

            addDealerSuperUser(userMap);
            /*childAccountMap = PEAC_ContractShareHelperBatch.getDealerChildAccounts(dealerAccountIdList);
            for(Id childDealer : childAccountMap.keySet())
            {
              //  dealerAccountIdList.addall(childAccountMap.get(childDealer));
            }*/
            
        }
        
       
        
        //Check for dealer Account id list is empty or not
        if(dealerAccountIdList.isEmpty())
        {
            for(Account dealerAccount :[SELECT Id, IsPartner FROM Account WHERE IsPartner = True ]){
                dealerAccountIdList.add(dealerAccount.Id);// add dealer account id into list
            }
        }
        //Check for user and account id map is empty or not
        if(sDPUserAccountIDMap.isEmpty()){
            //Get all super users and their associated account ids
            userMap = new Map<Id, User>([SELECT Id, Contact.AccountId FROM User WHERE IsActive = True AND IsPrmSuperUser = true ]);
        }
        else{
            //Get super users with specified user id
            userMap = new Map<Id, User>([SELECT Id, Contact.AccountId FROM User WHERE IsActive = True AND IsPrmSuperUser = true AND ID IN:sDPUserAccountIDMap.keySet() ]);
        }
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
        Set<Id> dealerIdSet = new Set<Id>();
        try {
            List<Contract__Share> contractShareList = new List<Contract__Share>();
            for(sObject objR : scopeList) {
                Contract__c contr = (Contract__c)objR;
                dealerIdSet.add(contr.Dealer_Name__c);
            }
            PEAC_ContractShareHelperBatch.getParentDealers(dealerIdSet);
            dealerSuperUserIdMap = PEAC_ContractShareHelperBatch.dealerSuperUserIdMap;
            system.debug(LoggingLevel.ERROR, 'dealerSuperUserIdMap.......'+dealerSuperUserIdMap);
            for(sObject obj : scopeList) {
                Contract__c contractRec = (Contract__c)obj;
                //Check for contract dealer user is not null and active
                contractUserIDMap.put(contractRec.id,new Set<Id>());
                if(contractRec.Dealer_User__c !=Null && contractRec.Dealer_User__r.IsActive && contractRec.Dealer_User__c != contractRec.OwnerId)
                {
                    //Pass the below parameters in the method and add contract__share into list
                    contractShareList.add(PEAC_ContractShareHelperBatch.contractShare(contractRec.id, contractRec.Dealer_User__c,editAccess,contractRowCause));
                    contractUserIDMap.get(contractRec.id).add(contractRec.Dealer_User__c) ;// add contract id and dealer user into map
                }
               
                for(Id userId : sDPUserAccountIDMap.keySet()){
                    //Check for user id which is already a contract dealer user and contract owner
                    if(!contractUserIDMap.get(contractRec.id).contains(userId) && sDPUserAccountIDMap.get(userId) == contractRec.Dealer_Name__c && contractRec.OwnerId !=userId ){
                        //Pass the below parameters in the method and add contract__share into list
                        contractShareList.add(PEAC_ContractShareHelperBatch.contractShare(contractRec.id, userId,editAccess,contractRowCause));
                        contractUserIDMap.get(contractRec.id).add(userId) ;// add contract id and dealer user into map
                    
                }
                
            }
                if(dealerSuperUserIdMap.get(contractRec.Dealer_Name__c)!=null)
                {
                    for(Id parentUserId: dealerSuperUserIdMap.get(contractRec.Dealer_Name__c)){
                        //Check for user id which is already a contract dealer user and contract owner
                        if(!contractUserIDMap.get(contractRec.id).contains(parentUserId) && parentUserId != contractRec.Dealer_User__c && contractRec.OwnerId !=parentUserId){
                          //Pass the below parameters in the method and add contract__share into list
                          contractShareList.add(PEAC_ContractShareHelperBatch.contractShare(contractRec.id, parentUserId,editAccess,contractRowCause));
                          contractUserIDMap.get(contractRec.id).add(parentUserId) ;// add contract id and dealer user into map
                          system.debug(LoggingLevel.Error, 'parentUserId....'+parentUserId+'Count...'+contractShareList.size());
           
                        }  
                          /*for (Id dealerID: childAccountMap.keySet()) {
                
                            for (Id childDealerId : childAccountMap.get(dealerID)) {
                                if ( !contractUserIDMap.get(contractRec.id).contains(parentUserId) && childDealerId == contractRec.Dealer_Name__c) {
                                    //Pass the below parameters in the method and add contract__share into list
                                    contractShareList.add(contractShare(contractRec.id, parentUserId,editAccess,contractRowCause));
                          
                                }
                            }
                        }*/
                    }
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
            allErrors.add('Dealer Id...'+dealerIdSet+ '\r\n'+ ' \r\n' + ex.getMessage()+ ' \r\n' );
                           
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

    public void finish(Database.BatchableContext BC) {
        if(!allErrors.isEmpty()){
            String serializedMap = String.join(allErrors, '. \r\n');
            MARLIN_IntegrationLog.addLog ('PEAC_ContractShareBatch', BC.getJobId(), 'Error', '', serializedMap.left(131071),
                'Error', 'Error encountered while trying to give access to the Dealer Users described in the Response_Message__c field, shareObject: ' + 'Contract__Share');
            MARLIN_IntegrationLog.insertLogs();
            System.enqueueJob(new SL_CollectionAssignmentQ('dl-salesforcesupport@peacsolutions.com', 'Error Summary shareObject: ' + 'Contract__Share', serializedMap));
        }
    }
        
}
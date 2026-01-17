/********************************************************************************************************************
@Author:Rajesh Kumar(LTIMindtree)
@Description: This class is responsilbe for sharing the related list of Contract records with the 
            associated super dealer user.
@User Story:DP-1585
@Created Date:February-20-2025 	    
*********************************************************************************************************************/

public without sharing class PEAC_ContractShareHelperBatch {
    Public static Map<Id,Set<Id>> dealerSuperUserIdMap = new Map<Id,Set<Id>>();
    /**************************************************************************************************************
    @Author:Rajesh Kumar(LTIMindtree)
    @Description: This method is being called from Contract share batch class to get parent super users.
    @User Story:DP-1585
    @Created Date:March-13-2025    
    @Param: Set of dealer ids
	@Return:None
    **************************************************************************************************************/

    public static void getParentDealers(Set<Id> dealerIdSet)
    {
        dealerSuperUserIdMap = new Map<Id,Set<Id>>();
        //We can go upto five level up
        List<ExternalAccountHierarchy> externalAccountList = [SELECT Id,accountid,parentId,name,
                                                            parent.parentId, parent.parent.parentId,parent.parent.parent.parentId,parent.accountid,
                                                            parent.parent.accountid,parent.parent.parent.accountid,parent.parent.parent.parent.accountid 
                                                            FROM ExternalAccountHierarchy WHERE (accountID IN:dealerIdSet OR parentId IN:dealerIdSet) AND IsActive = True];
        
        Map<Id,Set<Id>> parentChildAccountMap = new Map<Id,Set<Id>>();//stroe child dealer with all parent ids
        Set<Id> parentChildDealerId = new Set<Id>();// store all dealer ids including parent
        if(!externalAccountList.isEmpty())
        {
            for(ExternalAccountHierarchy acc:externalAccountList)
            {
                if(!parentChildAccountMap.containsKey(acc.accountid))
                {
                    parentChildAccountMap.put(acc.accountid, new Set<Id>());  
                }
                parentChildDealerId.add(acc.accountid);
                //check 5 level up parents
                if (acc.parentId!=null  && acc.parent.parentId!=null && acc.parent.parent.parentId!=null && acc.parent.parent.parent.parentId!=null) {
                    parentChildAccountMap.get(acc.accountid).add(acc.parent.accountid);  
                    parentChildAccountMap.get(acc.accountid).add(acc.parent.parent.accountid);
                    parentChildAccountMap.get(acc.accountid).add(acc.parent.parent.parent.accountid);  
                    parentChildAccountMap.get(acc.accountid).add(acc.parent.parent.parent.parent.accountid);  
                    
                }
                //check 4 level up parents
                else if(acc.parentId!=null  && acc.parent.parentId!=null && acc.parent.parent.parentId!= null)
                {
                    parentChildAccountMap.get(acc.accountid).add(acc.parent.accountid);  
                    parentChildAccountMap.get(acc.accountid).add(acc.parent.parent.accountid);
                    parentChildAccountMap.get(acc.accountid).add(acc.parent.parent.parent.accountid);  
                   
                }
                //check 2 level up parents
                else if(acc.parentId!=null  && acc.parent.parentId!=null )
                {
                    parentChildAccountMap.get(acc.accountid).add(acc.parent.accountid);  
                    parentChildAccountMap.get(acc.accountid).add(acc.parent.parent.accountid);
                     
                }
                //check 1 level up parents
                else if(acc.parentId!=null){
                    parentChildAccountMap.get(acc.accountid).add(acc.parent.accountid);  
                    
                }
                parentChildDealerId.addAll(parentChildAccountMap.get(acc.accountid));
            }
            getParentSuperUsers(parentChildDealerId, parentChildAccountMap);
        }
    }
    /**************************************************************************************************************
    @Author:Rajesh Kumar(LTIMindtree)
    @Description: This method is being called from Contract share batch class to get parent super users.
    @User Story:DP-1585
    @Created Date:March-13-2025    
    @Param: Set of dealer ids and parent child account ids
	@Return:Map of dealer id and set of super partner user ids
    **************************************************************************************************************/
    public static Map<Id,Set<Id>>  getParentSuperUsers(Set<Id> parentChildDealerId, Map<Id,Set<Id>> parentChildAccountMap){
        //Get all super users and their associated account ids
        Map<Id, User>  userMap = new Map<Id, User>([SELECT Id, Contact.AccountId FROM User WHERE IsActive = True AND IsPrmSuperUser = true AND Contact.AccountId IN:parentChildDealerId]);
        dealerSuperUserIdMap = new Map<Id,Set<Id>>();
        System.debug(LoggingLevel.ERROR, 'userMapHelper....'+userMap);
        Map<Id,Set<Id>> accountUserIdMap = new Map<Id,Set<Id>>();
        for(user superDuser: userMap.values()){
           if(!accountUserIdMap.containsKey(superDuser.Contact.AccountId))
            {
                accountUserIdMap.put( superDuser.Contact.AccountId, New Set<Id>());
            }
            accountUserIdMap.get(superDuser.Contact.AccountId).add(superDuser.Id);

        }
        
        
        for (Id dealerId: parentChildAccountMap.keySet()) {
            dealerSuperUserIdMap.put(dealerId, new set<id>());
            if(accountUserIdMap.get(dealerId) !=null) 
            {
                dealerSuperUserIdMap.get(dealerId).addAll(accountUserIdMap.get(dealerId));
            }                   
               
            if(!parentChildAccountMap.get(dealerId).isEmpty())
            {
                for(Id childDealerId: parentChildAccountMap.get(dealerId))
                {
                    if(accountUserIdMap.ContainsKey(childDealerId)){
                       dealerSuperUserIdMap.get(dealerId).AddAll(accountUserIdMap.get(childDealerId));
                    }
                    
                } 
            }
            system.debug('dealerSuperUserIdMapInside....'+ dealerSuperUserIdMap);
        }

        system.debug('dealerSuperUserIdMap....'+ dealerSuperUserIdMap);
        return dealerSuperUserIdMap;
        
        
    }
    /**************************************************************************************************************
    @Author:Rajesh Kumar(LTIMindtree)
    @Description:This method is being called from Contract share batch class to child accounts.
    @User Story:DP-1585
    @Created Date:March-13-2025    
    @Param:List of dealer ids
	@Return:Map of parent id and set of child account ids 
    **************************************************************************************************************/

    
    public static Map<Id,Set<Id>> getDealerChildAccounts(List<Id> allDealerIdsList){
        Map<Id,Set<Id>> childAccountMap = new Map<Id,Set<Id>>();
        List<ExternalAccountHierarchy> externalAccountList = [SELECT Id,accountid,parentId,name ,
                (SELECT ID, accountid,(SELECT ID,accountid FROM ExternalAccountHierarchies) 
                FROM ExternalAccountHierarchies )
                FROM ExternalAccountHierarchy  WHERE accountId IN:allDealerIdsList AND IsActive = True];
        for(ExternalAccountHierarchy externaAccount: externalAccountList)
        {
            if(!childAccountMap.containskey(externaAccount.accountid))
            {
                childAccountMap.put(externaAccount.accountid, new Set<Id>());
            }
            
            for(ExternalAccountHierarchy childAccount: externaAccount.ExternalAccountHierarchies)
            {
                childAccountMap.get(externaAccount.accountid).add(childAccount.accountid);
        
                for(ExternalAccountHierarchy childOfChildAccount: childAccount.ExternalAccountHierarchies)
                {
                childAccountMap.get(externaAccount.accountid).add(childOfChildAccount.accountid);
            
                }
            }
        }
        system.debug('childAccountMap....'+childAccountMap);
        return childAccountMap;
    }
    /**************************************************************************************************************
    @Author:Rajesh Kumar(LTIMindtree)
    @Description: This method is being called from Contract share batch class to get parent super users.
    @User Story:DP-1585
    @Created Date:March-13-2025    
    @Param: Set of dealer ids
	@Return:None
    **************************************************************************************************************/
    public static void getExternalAccounts(Map<Id,Id> oldExternalIdWithAccountMap)
    {
        List<ExternalAccountHierarchy> externalAccountList = [SELECT Id,accountid,parentId,name,
        parent.parentId, parent.parent.parentId,parent.parent.parent.parentId,parent.accountid,
        parent.parent.accountid,parent.parent.parent.accountid,parent.parent.parent.parent.accountid 
        FROM ExternalAccountHierarchy WHERE ID IN:oldExternalIdWithAccountMap.Values() AND IsActive = True];
        
        system.debug('externalAccountList....'+ externalAccountList.size()+externalAccountList);
        Map<Id,Set<Id>> parentChildAccountMap = new Map<Id,Set<Id>>();
        Set<Id> parentChildDealerId = new Set<Id>();
        
        for(ExternalAccountHierarchy acc:externalAccountList)
        {
            if(!parentChildAccountMap.containsKey(acc.parentId))
            {
                parentChildAccountMap.put(acc.Id, new Set<Id>());  
            }
            parentChildDealerId.add(acc.accountid);
            if (acc.parentId!=null  && acc.parent.parentId!=null && acc.parent.parent.parentId!=null && acc.parent.parent.parent.parentId!=null) {
                parentChildAccountMap.get(acc.Id).add(acc.parent.accountid);  
                parentChildAccountMap.get(acc.Id).add(acc.parent.parent.accountid);
                parentChildAccountMap.get(acc.Id).add(acc.parent.parent.parent.accountid);  
                parentChildAccountMap.get(acc.Id).add(acc.parent.parent.parent.parent.accountid);  
                
            }
            else if (acc.parentId!=null  && acc.parent.parentId!=null && acc.parent.parent.parentId!= null)
            {
                parentChildAccountMap.get(acc.Id).add(acc.parent.accountid);  
                parentChildAccountMap.get(acc.Id).add(acc.parent.parent.accountid);
                parentChildAccountMap.get(acc.Id).add(acc.parent.parent.parent.accountid);  
                
            }
            else if(acc.parentId!=null  && acc.parent.parentId!=null )
            {
                parentChildAccountMap.get(acc.Id).add(acc.parent.accountid);  
                parentChildAccountMap.get(acc.Id).add(acc.parent.parent.accountid);
                    
            }
            else if(acc.parentId!=null){
                parentChildAccountMap.get(acc.Id).add(acc.parent.accountid);  
                
            }
            parentChildDealerId.addAll(parentChildAccountMap.get(acc.Id));
        }
        getParentExternalSuperUsers(parentChildDealerId, parentChildAccountMap);
            
    }
    /**************************************************************************************************************
    @Author:Rajesh Kumar(LTIMindtree)
    @Description: This method is being to get parent super partner users.
    @User Story:DP-1585
    @Created Date:March-13-2025    
    @Param: Set of dealer ids
	@Return:None
    **************************************************************************************************************/
    
    public static void getParentExternalSuperUsers(Set<Id> parentChildDealerId, Map<Id,Set<Id>> parentChildAccountMap){
        //Get all super users and their associated account ids
        Map<Id, User>  userMap = new Map<Id, User>([SELECT Id, Contact.AccountId FROM User WHERE IsActive = True AND IsPrmSuperUser = true AND Contact.AccountId IN:parentChildDealerId]);
        dealerSuperUserIdMap = new Map<Id,Set<Id>>();
        Map<Id,Set<Id>> accountUserIdMap = new Map<Id,Set<Id>>();
        for(user superDuser: userMap.values()){
        if(!accountUserIdMap.containsKey(superDuser.Contact.AccountId))
            {
                accountUserIdMap.put( superDuser.Contact.AccountId, New Set<Id>());
            }
            accountUserIdMap.get(superDuser.Contact.AccountId).add(superDuser.Id);

        }
        for (Id dealerId: parentChildAccountMap.keySet()) {
            dealerSuperUserIdMap.put(dealerId, new set<id>());
            for(Id sUser: accountUserIdMap.keySet()){
                if(accountUserIdMap.get(sUser) !=null)
                {
                    for(Id dealerAccountId: accountUserIdMap.get(sUser)){
                        dealerSuperUserIdMap.get(dealerId).add(dealerAccountId);  
                    }
                }
            }
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

    public static Contract__Share contractShare(Id parentId, Id userOrGroupId,String accessLevel, String rowCause)
    {
        Contract__Share accountShare = new Contract__Share();
        accountShare.ParentId = parentId;
        accountShare.AccessLevel = accessLevel;  
        accountShare.RowCause =  rowCause;
        accountShare.UserOrGroupId = userOrGroupId;
        return accountShare;
    }
}
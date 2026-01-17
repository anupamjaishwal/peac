public without sharing class SL_DPSharingRecalcBatch implements Database.Batchable<SObject>, Database.Stateful {
    String shareObject = 'Contract__Share';
    List<String> dealerAccountIds = new List<String>();
    Boolean isToFixSharing = false;
    Map<String, set<String>> superUserIdsByDealerId = new Map<String, set<String>>();
    Set<Id> allUserIds = new Set<Id>();
    List<String> allErrors = new List<String>();
    List<SObject> remainingToUpsert = new List<SObject>();
    
    public SL_DPSharingRecalcBatch(String shareObject, List<String> dealerAccountIds) {
        this.shareObject = shareObject;
        this.dealerAccountIds = dealerAccountIds;
    }
    public SL_DPSharingRecalcBatch(String shareObject, Boolean isToFixSharing) {
        this.shareObject = shareObject;
        this.isToFixSharing = isToFixSharing;
    }
    public SL_DPSharingRecalcBatch(List<SObject> remainingToUpsert, String shareObject){
        this.remainingToUpsert = remainingToUpsert;
        this.shareObject = shareObject;
    }

    public Database.querylocator start(Database.BatchableContext BC){
        String theQuery = '';
        if(isToFixSharing){
            dealerAccountIds = SL_DPPermissions.findMissingSharesByCount(shareObject);
        }
        if(dealerAccountIds.size() == 0){
            theQuery = 'SELECT Id FROM Contract__Share WHERE Id = null';
            insertRemainingShares();
        }else{
            String idsString = '\'';
            Integer queryLimit = Limits.getLimitQueryRows() - Limits.getQueryRows() - (shareObject == 'AccountShare'? 5000: 0);
            for(User newUser : [SELECT Id, Contact.AccountId, IsPrmSuperUser FROM User WHERE IsActive = true 
                AND Contact.AccountId IN:dealerAccountIds LIMIT :queryLimit]){
                if(newUser.IsPrmSuperUser){
                    if(superUserIdsByDealerId.containsKey(newUser.Contact.AccountId)){
                        set<String> tempset = superUserIdsByDealerId.get(newUser.Contact.AccountId);
                        tempset.add(newUser.Id);
                        superUserIdsByDealerId.put(newUser.Contact.AccountId, tempset);
                    } else{
                        superUserIdsByDealerId.put(newUser.Contact.AccountId, new set<String>{newUser.Id});
                    }
                }
                allUserIds.add(newUser.Id);
            }
            switch on shareObject {
                when 'Account', 'Contract__c', 'Opportunity' {
                    idsString += String.join(dealerAccountIds, '\',\'') + '\'';
                }
                when 'User' {
                    Map<Id, Id> parentByChildDealerId = SL_DPPermissions.getParentByChildDealerAccId();
                    List<String> childDealerIds = new List<String>();
                    for(String childId :parentByChildDealerId.keySet()){
                        String parentId = parentByChildDealerId.get(childId);
                        if(dealerAccountIds.contains(parentId)){
                            childDealerIds.add(childId);
                        }
                    }
                    idsString += String.join(childDealerIds, '\',\'') + '\'';
                }
                when else {
                    idsString += String.join(allUserIds, '\',\'') + '\'';
                }
            }
            switch on shareObject {
                when 'AccountShare' {
                    List<String> customerAccountIds = new List<String>();
                    List<AggregateResult> customerResults = [SELECT count(Id), Customer__c customerId
                        FROM Contract__c WHERE Customer__c != null AND Dealer_Name__c IN :dealerAccountIds
                        GROUP BY Customer__c LIMIT 5000];
                    for(AggregateResult customerResult :customerResults){
                        customerAccountIds.add(String.valueOf(customerResult.get('customerId')));
                    }
                    idsString = '\'' + String.join(customerAccountIds, '\',\'') + '\'';
                    theQuery = 'SELECT Id, AccountId, UserOrGroupId, RowCause, AccountAccessLevel '
                        + 'FROM AccountShare WHERE RowCause = \'Manual\' AND AccountAccessLevel = \'Edit\' '
                        + 'AND UserOrGroup.IsActive = true AND AccountId IN ('
                        + idsString + ')';
                }
                when 'Contract__Share' {
                    theQuery = 'SELECT Id, ParentId, UserOrGroupId, RowCause, Parent.Dealer_Name__c, Parent.Dealer_User__c '
                        + 'FROM Contract__Share WHERE RowCause = \'Dealer_Contract_Sharing__c\' AND AccessLevel = \'Edit\' '
                        + 'AND UserOrGroup.IsActive = true AND UserOrGroupId IN ('
                        + idsString + ')';
                }
                when 'OpportunityShare' {
                    theQuery = 'SELECT Id, OpportunityId, OpportunityAccessLevel, UserOrGroupId, RowCause, '
                        + 'Opportunity.Dealer_Account__c, Opportunity.Dealer_User__c '
                        + 'FROM OpportunityShare WHERE RowCause = \'Manual\' AND OpportunityAccessLevel = \'Edit\' '
                        + 'AND UserOrGroup.IsActive = true AND UserOrGroupId IN ('
                        + idsString + ')';
                }
                when 'UserShare' {
                    theQuery = 'SELECT Id, UserId, UserAccessLevel, UserOrGroupId, RowCause, '
                        + 'User.Contact.AccountId '
                        + 'FROM UserShare WHERE RowCause = \'Manual\' AND UserAccessLevel = \'Read\' '
                        + 'AND UserOrGroup.IsActive = true AND User.Contact.Account.IsPartner = true AND UserOrGroupId IN ('
                        + idsString + ')';
                }
                when 'Account' {
                    theQuery = 'SELECT Id, Dealer_Name__c, Dealer_User__c, Dealer_User__r.IsActive, Customer__c, Customer__r.OwnerId '
                        + 'FROM Contract__c WHERE Customer__c != null AND Dealer_Name__c IN ('
                        + idsString + ') ORDER BY Customer__c'; 
                }
                when 'Contract__c' {
                    theQuery = 'SELECT Id, Dealer_Name__c, Dealer_User__c, Dealer_User__r.IsActive, OwnerId FROM Contract__c WHERE Dealer_Name__c IN ('
                        + idsString/*.substringBefore(',\'')*/ + ')'; 
                }
                when 'Opportunity' {
                    theQuery = 'SELECT Id, OwnerId, Dealer_Account__r.Name, Dealer_User__c, Dealer_User__r.IsActive, Name FROM Opportunity WHERE Dealer_Account__c IN ('
                        + idsString + ')'; 
                }
                when 'User' {
                    theQuery = 'SELECT Id, Contact.AccountId FROM User WHERE IsPortalEnabled = true AND IsActive = true AND Contact.AccountId IN ('
                        + idsString + ')'; 
                }
            }
        }
        return Database.getQueryLocator(theQuery);
    }
    public void execute(Database.BatchableContext BC, List<SObject> scope){
        switch on shareObject {
            when 'AccountShare', 'Contract__Share', 'OpportunityShare', 'UserShare' {
                recalculateDeleteShares(scope);
            }
            when 'Account', 'Contract__c', 'Opportunity', 'User' {
                recalculateInsertShares(scope);
            }
        }   
    }
    public void finish(Database.BatchableContext BC){
        Map<String, String> step2ByStep1 = new Map<String, String>{'AccountShare' => 'Account',
         'Contract__Share' => 'Contract__c', 'OpportunityShare' => 'Opportunity', 'UserShare' => 'User'};
        switch on shareObject {
            when 'AccountShare', 'Contract__Share', 'OpportunityShare', 'UserShare' {
                if(isToFixSharing){
                    Database.executeBatch(new SL_DPSharingRecalcBatch(step2ByStep1.get(shareObject), isToFixSharing));
                }else{
                    Database.executeBatch(new SL_DPSharingRecalcBatch(step2ByStep1.get(shareObject), dealerAccountIds));
                }
            }
            when 'Account', 'Contract__c', 'Opportunity', 'User' {
                if(allErrors.size() > 0){
                    String serializedMap = String.join(allErrors, '. \r\n');
                    MARLIN_IntegrationLog.addLog ('DP Sharing Recalculation Batch', BC.getJobId(), 'Error', '', serializedMap.left(131071),
                        'Error', 'Error encountered while trying to give access to the Dealer Users described in the Response_Message__c field, shareObject: ' + shareObject);
                    MARLIN_IntegrationLog.insertLogs();
                    System.enqueueJob(new SL_CollectionAssignmentQ('dl-salesforcesupport@peacsolutions.com', 'Error Summary shareObject: ' + shareObject, serializedMap));
                }
                System.debug('remainingToUpsert: ' + remainingToUpsert);
                System.debug('size on finish:' + remainingToUpsert.size());
                if(remainingToUpsert.size() > 0){
                    Database.executeBatch(new SL_DPSharingRecalcBatch(remainingToUpsert, shareObject));
                }
            }
        }
    }

    @TestVisible
    void recalculateDeleteShares(List<SObject> scope){
        List<SObject> sharesToDelete = new List<SObject>();
        Set<Id> userIds = new Set<Id>();
        for(SObject obj : scope){
            userIds.add((Id)obj.get('UserOrGroupId'));
        }
        Map<Id, User> users = new Map<Id, User>([SELECT Id, IsPrmSuperUser, Contact.AccountId
            FROM User WHERE IsActive = true AND isPortalEnabled = true AND Id IN :userIds]);
        for(SObject obj : scope){
            Object userId = obj.get('UserOrGroupId');
            User theUser = users.get((Id)userId);
            if(theUser != null){
                switch on shareObject {
                    when 'Contract__Share', 'OpportunityShare' {
                        Id dealerId = shareObject == 'Contract__Share'? ((Contract__Share)obj).Parent.Dealer_Name__c: 
                            ((OpportunityShare)obj).Opportunity.Dealer_Account__c;
                        Id dealerUserId = shareObject == 'Contract__Share'? ((Contract__Share)obj).Parent.Dealer_User__c: 
                            ((OpportunityShare)obj).Opportunity.Dealer_User__c;
                        if(!theUser.IsPrmSuperUser && dealerUserId != (Id)userId){
                            sharesToDelete.add(obj);
                        }else if(theUser.IsPrmSuperUser && dealerId != theUser.Contact.AccountId){
                            sharesToDelete.add(obj);
                        }
                    }
                    when 'UserShare' {
                        Id dealerId = SL_DPPermissions.getParentByChildDealerAccId().get(((UserShare)obj).User.Contact.AccountId);
                        if(dealerId == null){
                            sharesToDelete.add(obj);
                        }
                    }
                    when else {
                        if(!theUser.IsPrmSuperUser){
                            sharesToDelete.add(obj);
                        }
                    }
                }
            }else{
                sharesToDelete.add(obj);
            }
        }
        if(sharesToDelete.size() > 0){
            List<List<SObject>> bigDeleteList = splitDMLList(sharesToDelete);
            for(List<SObject> actualSharesToDelete: bigDeleteList){
                if(actualSharesToDelete.size() > 0){
                    delete actualSharesToDelete;
                }
            }
        }
    }

    @TestVisible
    void recalculateInsertShares(List<SObject> scope){
        Set<String> sharingKeys = new Set<String>();
        Set<Id> allSharedIds = new Set<Id>();
        Set<Id> currentDealerIds = new Set<Id>();
        Integer existingShareRecordsLimit = System.Limits.getLimitQueryRows() - System.Limits.getQueryRows();
        switch on shareObject {
            when 'Account' {
                for(AccountShare customerShareWithSuperUser : [SELECT Id, AccountId, UserOrGroupId 
                    FROM AccountShare 
                    WHERE UserOrGroupId IN :allUserIds AND UserOrGroup.IsActive = true
                    AND RowCause = 'Manual' AND AccountAccessLevel = 'Edit'
                    ORDER BY LastModifiedDate DESC LIMIT :existingShareRecordsLimit]){
                    sharingKeys.add(String.valueOf(customerShareWithSuperUser.AccountId)+String.valueOf(customerShareWithSuperUser.UserOrGroupId));
                }
                List<AccountShare> customerAccountShares = new List<AccountShare>();
                for(SObject obj : scope){
                    Contract__c theContract = (Contract__c)obj;
                    Account theCustomer = theContract.Customer__r;
                    if(theContract.Dealer_User__c != null && theCustomer.OwnerId != theContract.Dealer_User__c
                        && theContract.Dealer_User__r.IsActive
                        && !(allSharedIds.contains(theCustomer.Id) && allUserIds.contains(theContract.Dealer_User__c))
                        && !sharingKeys.contains(String.valueOf(theCustomer.Id) + String.valueOf(theContract.Dealer_User__c))){
                        AccountShare dealerUserShare = new AccountShare();
                        dealerUserShare.AccountId = theCustomer.Id;
                        dealerUserShare.AccountAccessLevel = 'Edit';
                        dealerUserShare.OpportunityAccessLevel = 'None';
                        dealerUserShare.CaseAccessLevel = 'None';
                        dealerUserShare.RowCause = 'Manual';
                        dealerUserShare.UserOrGroupId = theContract.Dealer_User__c;
                        dealerUserShare.Id = null;
                        customerAccountShares.add(dealerUserShare);
                        allUserIds.add(theContract.Dealer_User__c);
                    }
                    Set<String> dealerUserIds = superUserIdsByDealerId.get(theContract.Dealer_Name__c);
                    if(dealerUserIds != null){
                        for(String dealerUserId : dealerUserIds){
                            AccountShare shareToSuperUser = new AccountShare();
                            if(theCustomer.OwnerId != dealerUserId
                                && !(allSharedIds.contains(theCustomer.Id) && allUserIds.contains(dealerUserId))
                                && !sharingKeys.contains(String.valueOf(theCustomer.Id) + String.valueOf(dealerUserId))){
                                shareToSuperUser.AccountId = theCustomer.Id;
                                shareToSuperUser.AccountAccessLevel = 'Edit';
                                shareToSuperUser.OpportunityAccessLevel = 'None';
                                shareToSuperUser.CaseAccessLevel = 'None';
                                shareToSuperUser.RowCause = 'Manual';
                                shareToSuperUser.UserOrGroupId = dealerUserId;
                                shareToSuperUser.Id = null;
                                customerAccountShares.add(shareToSuperUser);
                                allUserIds.add(dealerUserId);
                            }
                        }
                    }
                    allSharedIds.add(theCustomer.Id);
                }
                if(customerAccountShares.size() > 0){
                    List<List<SObject>> bigInsertList = splitDMLList(customerAccountShares);
                    allErrors = bigUpsert(bigInsertList, true, allErrors, remainingToUpsert);
                }
            }
            when 'Contract__c' {
                for(SObject obj: scope){
                    Contract__c theContract = (Contract__c)obj;
                    currentDealerIds.add(theContract.Dealer_Name__c);
                }
                for(Contract__Share contractShareWithSuperUser : [SELECT Id, ParentId, UserOrGroupId
                    FROM Contract__Share 
                    WHERE Parent.Dealer_Name__c IN :currentDealerIds AND UserOrGroupId IN :allUserIds 
                    AND UserOrGroup.IsActive = true AND RowCause = 'Dealer_Contract_Sharing__c' AND AccessLevel = 'Edit'
                    ORDER BY LastModifiedDate DESC LIMIT :existingShareRecordsLimit]){
                    sharingKeys.add(String.valueOf(contractShareWithSuperUser.ParentId)+String.valueOf(contractShareWithSuperUser.UserOrGroupId));
                }
                List<Contract__Share> contractshareLst = new List<Contract__Share>();
                for(SObject obj : scope){
                    Contract__c theContract = (Contract__c)obj;
                    if(theContract.Dealer_User__c != null && theContract.OwnerId != theContract.Dealer_User__c
                        && theContract.Dealer_User__r.IsActive
                        && !sharingKeys.contains(String.valueOf(theContract.Id) + String.valueOf(theContract.Dealer_User__c))){
                        Contract__Share dealerUserShare = new Contract__Share();
                        dealerUserShare.ParentId = theContract.Id;
                        dealerUserShare.AccessLevel = 'Edit';                  
                        dealerUserShare.RowCause = 'Dealer_Contract_Sharing__c';
                        dealerUserShare.UserOrGroupId = theContract.Dealer_User__c;
                        contractshareLst.add(dealerUserShare);
                    }
                    Set<String> acctUserIds = superUserIdsByDealerId.get(theContract.Dealer_Name__c);
                    if(acctUserIds != null){
                        for(String conAccnt : acctUserIds){
                            Contract__Share contrctShare = new Contract__Share();
                            if(theContract.OwnerId != conAccnt
                            && !sharingKeys.contains(String.valueOf(theContract.Id) + String.valueOf(conAccnt))){
                                contrctShare.ParentId = theContract.Id;
                                contrctShare.AccessLevel = 'Edit';                  
                                contrctShare.RowCause = 'Dealer_Contract_Sharing__c';
                                contrctShare.UserOrGroupId = conAccnt;
                                contractshareLst.add(contrctShare);
                            }
                        }
                    }
                }
                if(contractshareLst.size() > 0){
                    List<List<SObject>> bigInsertList = splitDMLList(contractshareLst);
                    allErrors = bigUpsert(bigInsertList, true, allErrors, remainingToUpsert);
                }
            }
            when 'Opportunity' {
                for(SObject obj: scope){
                    Opportunity opty = (Opportunity)obj;
                    currentDealerIds.add(opty.Dealer_Account__c);
                }
                for(OpportunityShare oppShareWithSuperUser : [SELECT Id, OpportunityId, UserOrGroupId 
                    FROM OpportunityShare 
                    WHERE Opportunity.Dealer_Account__c IN :currentDealerIds AND UserOrGroupId IN :allUserIds
                    AND UserOrGroup.IsActive = true AND RowCause = 'Manual' AND OpportunityAccessLevel = 'Edit'
                    ORDER BY LastModifiedDate DESC LIMIT :existingShareRecordsLimit]){
                    sharingKeys.add(String.valueOf(oppShareWithSuperUser.OpportunityId)+String.valueOf(oppShareWithSuperUser.UserOrGroupId));
                }
                List<OpportunityShare> optyshareLst = new List<OpportunityShare>();
                for(SObject obj : scope){
                    Opportunity opty = (Opportunity)obj;
                    if(opty.Dealer_User__c != null && opty.OwnerId != opty.Dealer_User__c
                        && opty.Dealer_User__r.IsActive
                        && !sharingKeys.contains(String.valueOf(opty.Id) + String.valueOf(opty.Dealer_User__c))){
                        OpportunityShare dealerUserShare = new OpportunityShare();
                        dealerUserShare.OpportunityId = opty.Id;
                        dealerUserShare.OpportunityAccessLevel = 'Edit';                  
                        dealerUserShare.RowCause = 'Manual';
                        dealerUserShare.UserOrGroupId = opty.Dealer_User__c;
                        if(dealerUserShare.Id == null){
                            optyshareLst.add(dealerUserShare);
                        }
                    }
                    Set<String> acctUserIds = superUserIdsByDealerId.get(opty.Dealer_Account__c);
                    if(acctUserIds != null){
                        for(String optyAccnt : acctUserIds){
                            if (opty.OwnerId != optyAccnt
                            && !sharingKeys.contains(String.valueOf(opty.Id) + String.valueOf(optyAccnt))){
                                OpportunityShare OptyShare = new OpportunityShare();
                                OptyShare.OpportunityId = opty.Id;
                                OptyShare.OpportunityAccessLevel = 'Edit';                  
                                OptyShare.RowCause = 'Manual';
                                OptyShare.UserOrGroupId = optyAccnt;
                                if(OptyShare.Id == null){
                                    optyshareLst.add(OptyShare);
                                }
                            }
                        }
                    }
                }
                if(optyshareLst.size() > 0){
                    List<List<SObject>> bigInsertList = splitDMLList(optyshareLst);
                    allErrors = bigUpsert(bigInsertList, true, allErrors, remainingToUpsert);
                }
            }
            when 'User' {// DP-1921 Misael Romero
                Map<Id, Id> parentByChildDealerId = SL_DPPermissions.getParentByChildDealerAccId();
                Set<Id> childDealerIds = new Set<Id>();
                for(SObject obj: scope){
                    User childUser = (User)obj;
                    childDealerIds.add(childUser.Contact.AccountId);
                    Id parentDealerId = parentByChildDealerId.get(childUser.Contact.AccountId);
                    if(parentDealerId != null){
                        currentDealerIds.add(parentDealerId);
                    }
                }
                Map<Id, List<Id>> adminUsersByAccountId = new Map<Id, List<Id>>();
                for(User theUser : [SELECT Id, Contact.AccountId
                FROM User WHERE IsPortalEnabled = true AND IsActive = true AND Contact.AccountId IN :currentDealerIds
                ORDER BY LastModifiedDate DESC LIMIT :existingShareRecordsLimit]){
                    List<Id> adminUserIds = adminUsersByAccountId.get(theUser.Contact.AccountId) ?? new List<Id>();
                    adminUserIds.add(theUser.Id);
                    adminUsersByAccountId.put(theUser.Contact.AccountId, adminUserIds);
                }
                existingShareRecordsLimit = System.Limits.getLimitQueryRows() - System.Limits.getQueryRows();
                for(UserShare childUserShare : [SELECT Id, UserId, User.Contact.AccountId, UserOrGroupId 
                    FROM UserShare 
                    WHERE User.Contact.AccountId IN :childDealerIds AND UserOrGroupId IN :allUserIds
                    AND UserOrGroup.IsActive = true AND RowCause = 'Manual' AND UserAccessLevel = 'Read'
                    ORDER BY LastModifiedDate DESC LIMIT :existingShareRecordsLimit]){
                    sharingKeys.add(String.valueOf(childUserShare.UserId)+String.valueOf(childUserShare.UserOrGroupId));
                }
                List<UserShare> userShareList = new List<UserShare>();
                for(SObject obj : scope){
                    User childUser = (User)obj;
                    Id parentDealerId = parentByChildDealerId.get(childUser.Contact.AccountId);
                    if(parentDealerId != null){
                        List<Id> adminUserIds = adminUsersByAccountId.get(parentDealerId)?? new List<Id>();
                        for(Id adminUserId : adminUserIds){
                            if(!sharingKeys.contains(String.valueOf(childUser.Id) + String.valueOf(adminUserId))){
                                UserShare shareToUser = new UserShare(UserAccessLevel = 'Read',
                                    RowCause = 'Manual', UserId = childUser.Id, UserOrGroupId = adminUserId);
                                userShareList.add(shareToUser);
                            }
                        }
                    }
                }
                if(userShareList.size() > 0){
                    List<List<SObject>> bigInsertList = splitDMLList(userShareList);
                    allErrors = bigUpsert(bigInsertList, true, allErrors, remainingToUpsert);
                }
            }
        }
    }

    public void insertRemainingShares(){
        if(remainingToUpsert.size() > 0){
            List<List<SObject>> bigInsertList = splitDMLList(remainingToUpsert);
            List<List<SObject>> insertListInstance2 = new List<List<SObject>>();
            for(List<SObject> anInsertList : bigInsertList){
                insertListInstance2.add(anInsertList.deepClone(false, false, false));
            }
            remainingToUpsert.clear();
            allErrors = bigUpsert(insertListInstance2, true, allErrors, remainingToUpsert);
        }
    }

    public static List<List<SObject>> splitDMLList(List<SObject> allTheRecords){
        List<List<SObject>> bigDMLList = new List<List<SObject>>();
        Integer limitDmlRows = System.Limits.getLimitDmlRows();
        if(allTheRecords.size() > 0 && allTheRecords.size() < limitDmlRows){
            bigDMLList.add(allTheRecords);
        }else{
            for(Integer i = 0; i < System.Limits.getLimitDmlStatements(); i++){
                List<SObject> partialList = new List<SObject>();
                for(Integer j = 0; j < limitDmlRows; j++){
                    Integer originalListIndex = (i * limitDmlRows) + j;
                    if(originalListIndex < allTheRecords.size()){
                        partialList.add(allTheRecords[originalListIndex]);
                    }else{
                        break;
                    }
                }
                bigDMLList.add(partialList);
            }
        }
        return bigDMLList;
    }

    public static List<String> bigUpsert(List<List<SObject>> bigInsertList, Boolean isInsert, List<String> allErrors){
        return bigUpsert(bigInsertList, isInsert, allErrors, new List<SObject>());
    }

    public static List<String> bigUpsert(List<List<SObject>> bigInsertList, Boolean isInsert, List<String> allErrors,
    List<SObject> remainingToUpsert){
        List<SObject> actualRecordsToUpsert = bigInsertList[0];
        if(actualRecordsToUpsert.size() > 0){
            List<Database.SaveResult> results = null;
            if(isInsert){
                results = Database.insert(actualRecordsToUpsert, false);
            }else{
                results = Database.update(actualRecordsToUpsert, false);
            }
            for(Database.SaveResult aResult :results){
                if(isNearCpuLimit() || isNearHeapLimit()){
                    break;
                }else{
                    if(!aResult.isSuccess()){
                        Database.Error[] errors = aResult.getErrors();
                        if(errors[0].getStatusCode() != StatusCode.DUPLICATE_VALUE && errors[0].getStatusCode() != StatusCode.INVALID_FIELD_FOR_INSERT_UPDATE){
                            allErrors.add(errors[0].getStatusCode() + ' \r\n' + errors[0].getMessage()+ ' \r\n' + errors[0].getFields().toString());
                        }
                    }
                }
            }
        }
        if(bigInsertList.size() > 1){
            List<SObject> recordsBeyondLimit = bigInsertList[1];
            allErrors.add('In order to not hit the limit of DML rows, the below records were not processed:\r\n' + recordsBeyondLimit.toString());
            if(!isNearHeapLimit() && remainingToUpsert != null && recordsBeyondLimit.size() > 0){
                remainingToUpsert.addAll(recordsBeyondLimit);
            }
        }
        System.debug('remainingToUpsert After bigInsert:' + remainingToUpsert);
        System.debug('size After bigInsert:' + remainingToUpsert.size());
        return allErrors;
    }

    public static Boolean isNearCpuLimit(){
        Integer remainingCpuTime = System.Limits.getLimitCpuTime() - System.Limits.getCpuTime();
        return remainingCpuTime < System.Limits.getLimitCpuTime() / 5;
    }

    public static Boolean isNearHeapLimit(){
        Integer remainingHeap = System.Limits.getLimitHeapSize() - System.Limits.getHeapSize();
        return remainingHeap < System.Limits.getLimitHeapSize() / 5;
    }
}
public with sharing class TC_AccountTriggerHandler extends SL_Trigger.baseHandler  {
    private Set<Id> accountIds = new Set<Id>();
    private Map<Id, List<String>> fieldsChangedById = new Map<Id, List<String>>();
    Set<Id> checklistIds = new Set<Id>();
    User currentUser = new User();
    Map<Id, User> owners = new Map<Id, User>();
    Map<Id, RecordType> recordTypes = new Map<Id, RecordType>();
    Map<Id, AccountContactRelation> primaryContacts = new Map<Id, AccountContactRelation>();
    Map<Id, List<Contract__c>> contracts = new Map<Id, List<Contract__c>>();
    Map<Id, List<Opportunity>> opportunities = new Map<Id, List<Opportunity>>();
    Map<Id, List<Opportunity>> dealeropportunities = new Map<Id, List<Opportunity>>();
    Map<Id, List<TC_Origination__Checklist__c>> checklists = new Map<Id, List<TC_Origination__Checklist__c>>();
    Map<Id, List<TC_Origination__Checklist_Item_with_Attachments__c>> checklistItems = new Map<Id, List<TC_Origination__Checklist_Item_with_Attachments__c>>();
    Id endUserId;
	    public static boolean accountRecursiveCheck = false;

    //PG 11/11/2021 - Added the refactored methods
    public override void beforeInsert(List<SObject> newList){
        TC_UpdateChildDealerAccounts.categorize(null, null, false, true, false);
        TC_UpdateHiddenRTField.updateHiddenRTField(null, (List<Account>) newList);
        TC_SetTransactionLimit.setTransactionLimit(null, (List<Account>) newList);
        
        SL_InfoleaseUtils.isRecursive = true;
        for(SObject obj : newList){
            getLookupMaps(obj);
        }
        getInfoFromOthers(new Map<Id, SObject>());
        TC_AutoAssignEndUserAndDealerAcc.doAction((List<Account>) newList, this.currentUser);// SAL-5468 Misael Romero
        TC_UpdateLastUpdateField.currentuser = this.currentUser;
        TC_UpdateLastUpdateField.updateLastUpdatedField(null, (List<Account>) newList);
        TC_RequiredPrimaryContact.requiredPrimaryContact(null, (List<Account>) newList,
            currentUser.Profile.Name, this.recordTypes, this.primaryContacts);
        TC_AutoSetPortfolioThresholds.autoSetPortfolioThresholds(null, (List<Account>) newList, this.owners);
        TC_UpdateReviewForNull.updateReviewForNull((List<Account>) newList);

        beforeChangesToSelf(newList, true);
        //SAL-5019
        PEAC_ManufacturerNumberClass.updateManucturerNumber((List<Account>) newList);
    }

    public override void beforeUpdate(Map<Id, SObject> oldMap, Map<Id, SObject> newMap){
        TC_UpdateChildDealerAccounts.categorize((Map<Id, Account>)newMap, (Map<Id, Account>)oldMap, false, false, true);
        TC_DealerPrimaryContactValidation.validateDealerPrimaryContact((Map<Id, Account>)newMap, (Map<Id, Account>)oldMap);
        TC_DealerEmailageValidation.validateDealerPrimaryContactEmailage((Map<Id, Account>)newMap, (Map<Id, Account>)oldMap);
        TC_SetPrimaryContactEmailString.setDealerPrimaryContactEmailString((Map<Id, Account>)newMap, (Map<Id, Account>)oldMap);
        //PG 11/11/2021 - Added the refactored methods
        TC_NewDealerRampupNotification.newDealerRampupNotification((Map<Id, Account>)oldMap, (Map<Id, Account>)newMap);
        // end PG
        TC_SetTransactionLimit.setTransactionLimit((Map<Id, Account>)oldMap, (Map<Id, Account>)newMap);
        checkUpdatedFields(oldMap, newMap);
        List<SObject> newList = new List<SObject>();
        for(SObject obj : newMap.values()){
            getLookupMaps(obj);
            newList.add(obj);
        }
        getInfoFromOthers(newMap);
        TC_AccountGetMostRecentOpp.doAction((Map<Id, Account>)newMap, (Map<Id, Account>)oldMap, true, false, this.opportunities);// SAL-5468 Misael Romero
        TC_UpdateLastUpdateField.currentuser = this.currentUser;
        TC_UpdateLastUpdateField.updateLastUpdatedField((Map<Id, Account>)oldMap, (Map<Id, Account>)newMap);
        TC_RequiredPrimaryContact.requiredPrimaryContact((Map<Id, Account>)oldMap, (Map<Id, Account>)newMap,
            currentUser.Profile.Name, this.recordTypes, this.primaryContacts);
        TC_AutoSetPortfolioThresholds.autoSetPortfolioThresholds((Map<Id, Account>)oldMap, (Map<Id, Account>)newMap, this.owners);
        TC_UpdateReviewForNull.updateReviewForNull((Map<Id, Account>)newMap);
        TC_SetReviewTrackingField.setReviewTrackingField ((Map<Id, Account>)oldMap, (Map<Id, Account>)newMap);
        beforeChangesToSelf(newList, false);
    }
    
    public override void afterInsert(Map<Id, SObject> newMap){
        TC_UpdateChildDealerAccounts.categorize((Map<Id, Account>)newMap, null, true, true, false);
        TC_CreateSurveillanceOnWatchList.createSurveillanceOnWatchList(null, (Map<Id, Account>)newMap);
        TC_ThresholdReachedCreateSurv.thresholdReachedCreateSurv(null, (Map<Id, Account>)newMap);
        SL_InfoleaseUtils.isRecursive = true;
        for(SObject obj : newMap.values()){
            getLookupMaps(obj);
        }
        getInfoFromOthers(newMap);
        afterChangesToOthers(newMap, true);
        //Rajesh-Create CCID for end user and franchisee accounts
        //PEAC_AutoCCIDNumber.createCCID(newMap);
    }

    public override void afterUpdate(Map<Id, SObject> oldMap, Map<Id, SObject> newMap){
        TC_UpdateChildDealerAccounts.categorize((Map<Id, Account>)newMap, (Map<Id, Account>)oldMap, true, false, true);
        TC_AccountGetMostRecentOpp.doAction((Map<Id, Account>)newMap, (Map<Id, Account>)oldMap, false, true, null);
        TC_AutoCreateDealerSurveillance.autoCreateDealerSurveillance((Map<Id, Account>)oldMap, (Map<Id, Account>)newMap);
        TC_CreateSurveillanceOnWatchList.createSurveillanceOnWatchList((Map<Id, Account>)oldMap, (Map<Id, Account>)newMap);
        TC_UpdateOppVerbalStips.updateOppVerbalStips((Map<Id, Account>)oldMap, (Map<Id, Account>)newMap);
        TC_ThresholdReachedCreateSurv.thresholdReachedCreateSurv((Map<Id, Account>)oldMap, (Map<Id, Account>)newMap);
       //TC_DealerFundingLimit.updateFundingLimit((Map<Id, Account>)oldMap, (Map<Id, Account>)newMap);
        //push to Bridgeware to Sync with Infolease
        if(!SL_InfoleaseUtils.isRecursive && !System.isFuture() && !System.isBatch()){
            SL_InfoleaseUtils.isRecursive = true;
            Map <Id, Account> oldMapAccount = new Map <Id, Account>();
            Map <Id, Account> newMapAccount = new Map <Id, Account>();
            for (SObject theObj : oldMap.values()){
                oldMapAccount.put(theObj.Id, (Account)theObj);
                newMapAccount.put(theObj.Id, ((Account)newMap.get(theObj.Id)));
            }
            SL_InfoleaseCustomerController.updateAccount(oldMapAccount, newMapAccount);
        }
        if(!TC_AccountTriggerHandler.accountRecursiveCheck && newMap != null && oldMap != null) {
            TC_AccountTriggerHandler.accountRecursiveCheck = true;
            Map<Id,Set<Id>> accWithOppIdMap = new Map<Id, Set<Id>>();
            //SAL-5468
           // for(Id accountId : newMap.keySet()){
                //List<Opportunity> customerOpps = this.opportunities.get(accountId);
                //if(customerOpps != null){
                    for(Opportunity gr :  [select Id, AccountId from Opportunity where AccountId IN :newMap.keySet() AND Loan_Record_Type__c = true]){
                        //if(gr.Loan_Record_Type__c){
                            if(!accWithOppIdMap.containskey(gr.AccountId)) {
                                accWithOppIdMap.put(gr.AccountId,new Set<Id>{gr.Id});
                            } else {
                                Set<Id> oppIdSet = accWithOppIdMap.get(gr.AccountId);
                                oppIdSet.add(gr.Id);
                                accWithOppIdMap.put(gr.AccountId,oppIdSet);
                            }
                       // }
                    }
               // }
           // }
            
        FieldChangeTracker.TrackerWrapper trackerDetails = new FieldChangeTracker.TrackerWrapper();
        trackerDetails.newRecordMap = newMap;
        trackerDetails.oldRecordMap =  oldMap;
        trackerDetails.recordIdWithOppIdsMap = accWithOppIdMap;
        trackerDetails.objectApiName = 'Account';
        FieldChangeTracker.trackDetails(trackerDetails);
        }
      /*   if(!newMap.isEmpty() && !oldMap.isEmpty()) {
            FieldChangeTracker.TrackerWrapper trackerDetails = new FieldChangeTracker.TrackerWrapper();
            trackerDetails.newRecordMap = newMap;
            trackerDetails.oldRecordMap = oldMap;
            trackerDetails.objectApiName = 'Account';
            FieldChangeTracker.trackDetails(trackerDetails);
        } */


        checkUpdatedFields(oldMap, newMap);
        for(SObject obj : newMap.values()){
            getLookupMaps(obj);
        }
        getInfoFromOthers(newMap);
        afterChangesToOthers(newMap, false);
    }
    //end PG

    private void checkUpdatedFields(Map<Id, SObject> oldMap, Map<Id, SObject> newMap){
        endUserId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('End User Account').getRecordTypeId();
        List<String> fieldsToCheck = new List<String>();
        if(Trigger.isBefore){
            fieldsToCheck = new List<String>{'Account_Branch__c', 'Discount_for_Upgrade_to_Keep__c', 'DM_Review_Status__c', 
            'Review_For__c'};
        }else{
            fieldsToCheck = new List<String>{'Active_Insurance__c', 'DM_Review_Status__c', 'IF_Decision_Status__c', 'Multiples__c', 
            'Name', 'OwnerId', 'Private_Label_Documents__c', 'Review_For__c'};
        }
        for(Id accountId :newMap.keySet()){
            Account account = (Account)newMap.get(accountId);
            Account oldAccount = (Account)oldMap.get(accountId);
            SL_TriggerUtil.findChangedFields(accountId, account, oldAccount, fieldsChangedById, fieldsToCheck);
        }
    }

    private void getLookupMaps(SObject obj){
        Account theAccount = (Account)obj;
        if(theAccount.Id != null){
            this.accountIds.add(theAccount.Id);
            this.contracts.put(theAccount.Id, new List<Contract__c>());
            this.opportunities.put(theAccount.Id, new List<Opportunity>());
            this.dealeropportunities.put(theAccount.Id, new List<Opportunity>());
            this.checklists.put(theAccount.Id, new List<TC_Origination__Checklist__c>());
        }
        if(theAccount.OwnerId != null){
            this.owners.put(theAccount.OwnerId, new User());
        }
        if(theAccount.RecordTypeId != null){
            this.recordTypes.put(theAccount.RecordTypeId, new RecordType());
        }
    }
    
    private void getInfoFromOthers(Map<Id, SObject> newMap){
        if(accountIds.size() > 0){
            for(Account related :[SELECT Id, Owner.Name, Owner.Email, Owner.Vendor_Team__c, Owner.Profile.Name, 
                    RecordType.Name,
                    (SELECT Id, Status__c, Insurance__c, Customer__c, Dealer_Name__c, Dealer_User__r.Contact.AccountId FROM Customer_Contracts__r),
                    (SELECT Id, Roles, ContactId FROM AccountContactRelations),
                    (SELECT Id, Name, Application__c, Application_Status__c, Private_Label_Documents__c, Loan_Record_Type__c 
                    FROM Opportunities ORDER BY CreatedDate DESC),
                    (SELECT Id, Name, Private_Label_Documents__c, Dealer_Account__c,Application_Status__c, StageName 
                    FROM OpportunitiesDealerAcc__r WHERE Application_Status__c !='Booked' AND Application_Status__c != 'Cancelled' AND StageName != 'Lost'),
                    (SELECT Id, Name FROM TC_Origination__Checklists__r)
                FROM Account
                WHERE Id IN :accountIds]){
                owners.put(related.OwnerId, related.Owner);
                if(related.RecordTypeId != null){
                    recordTypes.put(related.RecordTypeId, related.RecordType);
                }
                List<Contract__c> relatedCustomerContracts = new List<Contract__c>();
                for(Contract__c contractWithInfo : related.Customer_Contracts__r){
                    relatedCustomerContracts.add(contractWithInfo);
                }
                this.contracts.put(related.Id, relatedCustomerContracts);
                for(AccountContactRelation relatedContact: related.AccountContactRelations){
                    if(relatedContact.Roles == 'Primary Contact'){
                        this.primaryContacts.put(related.Id, relatedContact);
                        break;
                    }
                }
                List<Opportunity> relatedOpps = new List<Opportunity>();
                for(Opportunity opp : related.Opportunities){
                    relatedOpps.add(opp);
                }
                this.opportunities.put(related.Id, relatedOpps);
                List<Opportunity> relatedDealerOpps = new List<Opportunity>();
                for(Opportunity opp : related.OpportunitiesDealerAcc__r){
                        relatedDealerOpps.add(opp);
                    }                    
                this.dealeropportunities.put(related.Id, relatedDealerOpps);
                List<TC_Origination__Checklist__c> relatedChecklists = new List<TC_Origination__Checklist__c>();
                for(TC_Origination__Checklist__c theChecklist : related.TC_Origination__Checklists__r){
                    relatedChecklists.add(theChecklist);
                    this.checklistIds.add(theChecklist.Id);
                }
                this.checklists.put(related.Id, relatedChecklists);
                

            }
            
        }
        Set<Id> userIdsToSearch = new Set<Id>();
        userIdsToSearch.add(System.UserInfo.getUserId());
        userIdsToSearch.addAll(owners.keySet());
        if(Trigger.isBefore){
            for(User foundUser : [SELECT Id, Name, Email, Vendor_Team__c, Profile.Name FROM User 
               WHERE Id IN :userIdsToSearch]){
                if(foundUser.Id == System.UserInfo.getUserId()){
                    this.currentUser = foundUser;
                }
                if(owners.size() > 0 && newMap.size() == 0){
                    owners.put(foundUser.Id, foundUser);
                }
            }
        }
        if(recordTypes.size() > 0 && SL_TriggerUtil.checkForMissingInfo(recordTypes.values())){
            recordTypes.putAll([SELECT Id, Name FROM RecordType WHERE Id IN :recordTypes.keySet()]);
        }
        if(Trigger.isBefore && this.checklistIds.size() > 0){
            for(TC_Origination__Checklist_Item_with_Attachments__c cliwa : [SELECT Id, Name, TC_Origination__Checklist__c FROM TC_Origination__Checklist_Item_with_Attachments__c 
                WHERE TC_Origination__Checklist__c IN :this.checklistIds]){
                List<TC_Origination__Checklist_Item_with_Attachments__c> itemsByCheckList = this.checklistItems.get(cliwa.TC_Origination__Checklist__c);
                if(itemsByCheckList == null){
                    itemsByCheckList = new List<TC_Origination__Checklist_Item_with_Attachments__c>();
                }
                itemsByCheckList.add(cliwa);
                this.checklistItems.put(cliwa.TC_Origination__Checklist__c, itemsByCheckList);
            }
        }
    }

    private void beforeChangesToSelf(List<SObject> newList, Boolean isNew){
        endUserId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('End User Account').getRecordTypeId();
        for(SObject obj : newList){
            Account theAccount = (Account)obj;
            //TC_UpdateHiddenRTField
            String recordTypeName = recordTypes.get(theAccount.RecordTypeId) != null? recordTypes.get(theAccount.RecordTypeId).Name: '';
            recordTypeName = recordTypeName != null? recordTypeName: '';
            if(theAccount.ParentId == null && !TC_RecursiveTriggerHelper.avoidUpdateChildDealerRecursion) {
                theAccount.Update_Child_Records__c = true;
            }
            theAccount.Account_Record_Type_Custom__c = recordTypeName.containsIgnoreCase('Dealer')? 'Dealer Account' : recordTypeName;
            if(isNew){
                switch on currentUser.Vendor_Team__c {
                    when 'DLG'{
                        if(theAccount.RecordTypeId == endUserId){
                            theAccount.Account_Branch__c = 'Direct - End User';
                        }else{
                            theAccount.Account_Branch__c = 'NJ Retail'; // API name instead of visible Value
                        }
                    }
                    when 'HC' {
                        theAccount.Account_Branch__c = 'Healthcare Division'; // API name instead of visible Value
                    }
                    when 'IFP' {
                        theAccount.Account_Branch__c = 'IFP - Indirect Funding Pl';
                    }
                    when 'OEG' {
                        theAccount.Account_Branch__c = 'Office Equip Group-OEG';
                    }
                    when 'OEG NC' {
                        theAccount.Account_Branch__c = 'OEG Non-Copier';
                    }
                    when 'SNAP' {
                        theAccount.Account_Branch__c = 'SNAP (National Accounts)';
                    }
                    when 'CTIF' {
                        theAccount.Account_Branch__c = 'CT&I Field';
                    }
                    when null {
                        theAccount.Account_Branch__c = null;
                    }
                }
            }
            validateFloorplanLineAmount(theAccount);
            List<String> fieldsChanged = fieldsChangedById.get(TheAccount.Id);
            dealerGDSFormerFlow(theAccount, fieldsChanged, recordTypeName, true);
            addStipsForApprovalEmail(theAccount);
            setDefaultDiscount(theAccount, isNew, fieldsChanged);
        }
    }

    private void afterChangesToOthers(Map<Id, SObject> newMap, Boolean isNewAccount){
        Map<Id, Contract__c> contractsToUpdate = new Map<Id, Contract__c>();
        List<Id> accountsToEmail = new List<Id>();
        Map<Id, Opportunity> opportunitiesToUpdate = new Map<Id, Opportunity>();
        Set<Id> accountIdsPLD = new Set<Id>();
        Map<String, String> usersToNotifyByAcc = new Map<String, String>();
        List<GDS_Action__e> gdsActionsToPublish = new List<GDS_Action__e>();
        Set<Id> dealerAccountsToShare = new Set<Id>();
        Set<Id> dealerSharesToUser = new Set<Id>();
        for(SObject obj : newMap.values()){
            Account account = (Account)obj;
            String recordTypeName = recordTypes.get(account.RecordTypeId) != null? recordTypes.get(account.RecordTypeId).Name: '';
            recordTypeName = recordTypeName != null? recordTypeName: '';
            List<String> fieldsChanged = fieldsChangedById.get(account.Id);
            if(((fieldsChanged != null && fieldsChanged.contains('Active_Insurance__c'))
                || isNewAccount)
                || (fieldsChanged != null && fieldsChanged.contains('Multiples__c'))){
                for(Contract__c contract : this.contracts.get(account.Id)){
                    if(!contract.Status__c.contains('Disposed')){
                        // SL-2805 Misael Romero
                        // contract.Collection_Group__c = !account.Multiples__c? '': 'Multiples';
                        // contractsToUpdate.put(contract.Id, contract);
                        if(contract.Insurance__c != account.Active_Insurance__c){
                            contract.Insurance__c = account.Active_Insurance__c;
                            contractsToUpdate.put(contract.Id, contract);
                        }
                        
                    }
                }
            }
            if(fieldsChanged != null && fieldsChanged.contains('Name')){
                List<String> approvedStatus = new List<String>{'Automatically Approved', 'Manually Approved', 'Approved'};
                Boolean hasApprovedOpps = false;
                for(Opportunity opp : this.opportunities.get(account.Id)){
                    if(approvedStatus.contains(opp.Application_Status__c)){
                        hasApprovedOpps = true;
                        break;
                    }
                }
                if(hasApprovedOpps){
                    accountsToEmail.add(account.Id);
                }
            }
            if(isNewAccount || (fieldsChanged != null && fieldsChanged.contains('Private_Label_Documents__c'))){
                for(Opportunity opp : this.dealeropportunities.get(account.Id)){
                    if(opp.Private_Label_Documents__c != account.Private_Label_Documents__c){
                        accountIdsPLD.add(account.Id);
                    }
                
                }
            }
            if(account.OwnerId != null && fieldsChanged != null && fieldsChanged.contains('IF_Decision_Status__c')){
                usersToNotifyByAcc.put(account.Id, account.OwnerId);
            }
            GDS_Action__e gdsAction = dealerGDSFormerFlow(account, fieldsChanged, recordTypeName, false);
            if(gdsAction != null){
                gdsActionsToPublish.add(gdsAction);
            }
            dealerAccountsToShare = updateDPSharing(account, fieldsChanged, this.contracts, dealerAccountsToShare, dealerSharesToUser);
        }
        update contractsToUpdate.values();
        if(accountIdsPLD.size() > 0){
            System.enqueueJob(new SL_UpdatePrivateLabelDocQ(accountIdsPLD));
        }
        // SL-2684
        // if(fieldsChanged != null && fieldsChanged.contains('Multiples__c')){
        //     SL_ContractTriggerHandler.callCollectionAssignment();
        // }
        if(accountsToEmail.size() > 0){
            System.enqueueJob(new SL_PostApprovalEmailQ(accountsToEmail));
        }
        if(usersToNotifyByAcc.values().size() > 0){
            List<Id> accountsIFDecision = new List<Id>();
            CustomNotificationType notificationType = [SELECT Id, DeveloperName 
                FROM CustomNotificationType WHERE DeveloperName='IF_Decision_Status_Updated'];
            for(String accountId : usersToNotifyByAcc.keySet()){
                Messaging.CustomNotification notification = new Messaging.CustomNotification();
                notification.setTitle('IF Decision Status Updated');
                notification.setBody('Click to review The Dealer');
                notification.setNotificationTypeId(notificationType.Id);
                notification.setTargetId(accountId);
                notification.send(new Set<String>{usersToNotifyByAcc.get(accountId)});
                accountsIFDecision.add(accountId);
            }
            System.enqueueJob(new SL_AccountTriggerEmailsQ(accountsIFDecision, 'IF_Decision_Status_Updated'));
        }
        if(gdsActionsToPublish.size() > 0){
            System.EventBus.publish(gdsActionsToPublish);
        }
        if(dealerAccountsToShare.size() > 0){
            System.enqueueJob(new SL_UserAccountShareQ('AccountShare', new List<Id>(dealerAccountsToShare)));
        }
        if(dealerSharesToUser.size() > 0){
            System.enqueueJob(new SL_UserAccountShareQ('dealerAccountShare', new List<Id>(dealerSharesToUser)));
        }
    }

    private void validateFloorplanLineAmount(Account theAccount){
        if(theAccount.IF_Floorplan_Line_Amount__c != null && theAccount.IF_Floorplan_Line_Amount__c < 9.2){
            theAccount.IF_Floorplan_Line_Amount__c.addError('The value for IF Floorplan Line Amount needs to be at least 9.20');
        }
    }

    private GDS_Action__e dealerGDSFormerFlow(Account theAccount, List<String> fieldsChanged, String recordTypeName, Boolean isBefore){
        GDS_Action__e gdsActionToCreate = null;
        if(recordTypeName.contains('Dealer')
            && fieldsChanged != null && (fieldsChanged.contains('DM_Review_Status__c') || fieldsChanged.contains('Review_For__c'))
            && theAccount.DM_Review_Status__c == 'Submitted for Review'
            && (theAccount.Review_For__c.contains('Approval') || theAccount.Review_For__c.contains('Predelivery')
            || theAccount.Review_For__c.contains('Inventory Finance'))){
            if(isBefore){
                theAccount.Submitted_By__c = this.currentUser.Id;
            }else{
                if(String.isBlank(theAccount.Dealer_Number__c)){
                    gdsActionToCreate = new GDS_Action__e(Action__c = Label.TC_GDS_Get_Dealer_InfoLease, Record_Id__c = theAccount.Id);
                }else{
                    gdsActionToCreate = new GDS_Action__e(Action__c = Label.TC_GDS_Get_Dealer, Record_Id__c = theAccount.Id);
                }
            }
        }
        return gdsActionToCreate;
    }

    void addStipsForApprovalEmail(Account theAccount){
        String stipsToEmail = '';
        List<TC_Origination__Checklist__c> accountChecklists = this.checklists.get(theAccount.Id);
        if(accountChecklists != null){
            for(TC_Origination__Checklist__c theChecklist : accountChecklists){
                for(TC_Origination__Checklist_Item_with_Attachments__c cliwa : this.checklistItems.get(theChecklist.Id)){
                    stipsToEmail += ', \r\n' + cliwa.Name;
                }
            }
        }
        
        theAccount.Stips_for_Approval_Email__c = stipsToEmail.removeStart(', \r\n').left(255);
    }

    Set<Id> updateDPSharing(Account theAccount, List<String> fieldsChanged, Map<Id, List<Contract__c>> contracts, 
    Set<Id> dealerAccountsToShare, Set<Id> dealerSharesToUser){
        if(fieldsChanged != null && fieldsChanged.contains('OwnerId')){
            for(Contract__c customerContract : contracts.get(theAccount.Id)){
                if(customerContract.Dealer_Name__c != null){
                    dealerAccountsToShare.add(customerContract.Dealer_Name__c);
                }else if(customerContract.Dealer_User__c != null && customerContract.Dealer_User__r.Contact != null
                && customerContract.Dealer_User__r.Contact.AccountId != null){
                    dealerAccountsToShare.add(customerContract.Dealer_User__r.Contact.AccountId);
                }
            }
            if(theAccount.IsPartner){
                dealerSharesToUser.add(theAccount.Id);
            }
        }
        return dealerAccountsToShare;
    }

    void setDefaultDiscount(Account theAccount, Boolean isNew, List<String> fieldsChanged){
        Boolean changedBranch = fieldsChanged != null && fieldsChanged.contains('Account_Branch__c');
        Boolean changedDiscount = fieldsChanged != null && fieldsChanged.contains('Discount_for_Upgrade_to_Keep__c');
        if((isNew || changedBranch) && theAccount.Account_Branch__c == 'Office Equip Group-OEG' && !changedDiscount){
            theAccount.Discount_for_Upgrade_to_Keep__c = '3.000';
        }
    }
}
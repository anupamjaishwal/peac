public with sharing class SL_UserTriggerHandler extends SL_Trigger.baseHandler {
    private Set<Id> UserIds = new Set<Id>();
    Map<Id, Contact> contacts = new Map<Id, Contact>();
    Map<Id, UserRole> userRoles = new Map<Id, UserRole>();
    Map<Id, Profile> profiles = new Map<Id, Profile>();
    Map<Id, List<PermissionSetAssignment>> permissionSetsAssigned = new Map<Id, List<PermissionSetAssignment>>();
    private Map<Id, List<String>> fieldsChangedById = new Map<Id, List<String>>();
    private SL_SharingCustomRecord shareRecords;

    public override void beforeInsert(List<SObject> newList){
        List<User> theList = new List<User>();
        for(SObject theObject :newList){
            getLookupMaps(theObject);
            theList.add((User)theObject);
        }
        beforeChangesToSelf(theList, true);
    }
    public override void beforeUpdate(Map<Id, SObject> oldMap, Map<Id, SObject> newMap){
        List<User> theList = new List<User>();
        for(SObject theObject :newMap.values()){
            getLookupMaps(theObject);
            theList.add((User)theObject);
            user oldUser = (user)oldMap.get(theObject.Id);
            user newUser = (user)newMap.get(theObject.Id);
           system.debug('@89::'+newUser.IsPrmSuperUser+'---'+oldUser.IsPrmSuperUser); 
        }
        // checkUpdatedFields(oldMap, newMap);
        beforeChangesToSelf(theList, false);
    }
    public override void afterInsert(Map<Id, SObject> newMap){
        for(SObject theObject :newMap.values()){
            getLookupMaps(theObject);
        }
        afterChangesToRelated(newMap, null, true);

        // had to comment the below because I need to run test classes, please team if we need all of the portal users to see Account records where
        // Type = 'M', please see the sharing rule Dealer_Users_access_to_Manufacturers it is under Account, 
        // that gives access without the need of a batchable process, please discuss it with the team.

        //Share Manufacturer accounts with portal users
        //PEAC_ManufacturerSharingClass.shareManufacturerAccounts(newMap,new Map<id,Account>(), PEAC_ConstantClass.READ_ACCESS);
    }
    public override void afterUpdate(Map<Id, SObject> oldMap, Map<Id, SObject> newMap){
        List<User> theList = new List<User>();
        for(SObject theObject :newMap.values()){
            getLookupMaps(theObject);
            theList.add((User)theObject);
            user oldUser = (user)oldMap.get(theObject.Id);
            user newUser = (user)newMap.get(theObject.Id);
        
        }
        checkUpdatedFields(oldMap, newMap);
        afterChangesToRelated(newMap, oldMap, false);
        
        // had to comment this because I need to run test classes, please team if we need all of the portal users to see Account records where
        // Type = 'M', please see the sharing rule Dealer_Users_access_to_Manufacturers it is under Account, 
        // that gives access without the need of a batchable process, please discuss it with the team.
    //   PEAC_ManufacturerSharingClass.shareManufacturersWithPUsers(newMap, oldMap , PEAC_ConstantClass.READ_ACCESS);
    }

    private void getLookupMaps(SObject obj){
        User theUser = (User)obj;
        if(theUser.ContactId != null){
            this.contacts.put(theUser.ContactId, new Contact());
        }
        if(theUser.UserRoleId != null){
            this.userRoles.put(theUser.UserRoleId, new UserRole());
        }
        if(theUser.ProfileId != null){
            this.profiles.put(theUser.ProfileId, new Profile());
        }
        if(theUser.Id != null){
            this.UserIds.add(theUser.Id); 
            this.permissionSetsAssigned.put(theUser.Id, new List<PermissionSetAssignment>());          
        }
    }

    private void checkUpdatedFields(Map<Id, SObject> oldMap, Map<Id, SObject> newMap){
        List<String> fieldsToCheck = null;
        if(Trigger.isBefore){
            fieldsToCheck = new List<String>{/*'UserRoleId'*/};
        } else{// isAfter
            fieldsToCheck = new List<String>{'IsActive', 'UserRoleId'};
        } 
        for(Id userId :newMap.keySet()){
            User newUser = (User)newMap.get(userId);
            User oldUser = (User)oldMap.get(userId);
            SL_TriggerUtil.findChangedFields(userId, newUser, oldUser, fieldsChangedById, fieldsToCheck);
        }
    }

    private void getInfoFromOthers(){
        if(UserIds.size() > 0){
            for(User related : [SELECT Id, Contact.Account.Account_Dealer_Program__c, UserRole.Name, Profile.Name, 
                (SELECT id, PermissionSet.Name FROM PermissionSetAssignments) FROM User WHERE Id IN:UserIds]){
                system.debug('related.ContactId:'+related.ContactId);
                system.debug('related.Contact:'+related.Contact);
                if(this.contacts.get(related.ContactId) != null){
                    this.contacts.put(related.ContactId, related.Contact);
                }
                if(this.userRoles.get(related.UserRoleId) != null){
                    this.userRoles.put(related.UserRoleId, related.UserRole);
                }
                if(this.profiles.get(related.ProfileId) != null){
                    this.profiles.put(related.ProfileId, related.Profile);
                }
                List<PermissionSetAssignment> relatedPermissionSets = new List<PermissionSetAssignment>();
                for(PermissionSetAssignment thePSA: related.PermissionSetAssignments){
                    relatedPermissionSets.add(thePSA);
                }
                this.permissionSetsAssigned.get(related.Id).addAll(relatedPermissionSets);
            }
        }
        if(Trigger.isBefore && this.contacts.size() > 0 && SL_TriggerUtil.checkForMissingInfo(this.contacts.values())){
            this.contacts.putAll([SELECT Id, Account.Account_Dealer_Program__c FROM Contact WHERE Id IN :this.contacts.keySet()]);
        }
        if(Trigger.isAfter && this.userRoles.size() > 0 && SL_TriggerUtil.checkForMissingInfo(this.userRoles.values())){
            this.userRoles.putAll([SELECT Id, Name FROM UserRole WHERE Id IN :this.userRoles.keySet()]);
        }
        if(Trigger.isAfter && this.profiles.size() > 0 && SL_TriggerUtil.checkForMissingInfo(this.profiles.values())){
            this.profiles.putAll([SELECT Id, Name FROM Profile WHERE Id IN :this.profiles.keySet()]);
        }
    }

    private void beforeChangesToSelf(List<User> newList, Boolean isNew){
        ORE__c OrgExceptions = ORE__c.getInstance(System.UserInfo.getUserId());
        getInfoFromOthers();
        for(User theUser :newList){
            Contact userContact = this.contacts.get(theUser.ContactId);
            if(userContact != null && (isNew || theUser.Dealer__c != String.valueOf(userContact.AccountId))){
                theUser.Dealer__c = userContact.AccountId;
            }
            theUser.SuperUser__c = theUser.IsPrmSuperUser;
        }
        
        
    }
    
    private void afterChangesToRelated(Map<Id, SObject> newMap, Map<Id, sObject> oldUSers, Boolean isNew){
        List<Contact> updateContacts = new List<Contact>();
        ORE__c OrgExceptions = ORE__c.getInstance(System.UserInfo.getUserId());
        getInfoFromOthers();
        Set<Id> dealerAccounts = new Set<Id>();
        for(Contact partnerContact :this.contacts.values()){
          if(partnerContact != null){
            dealerAccounts.add(partnerContact.AccountId);
          }
        }
        Map<Id, List<Id>> adminUsersByAccountId = new Map<Id, List<Id>>();
        List<AccountShare> sharesToInsert = new List<AccountShare>();
        List<AccountShare> sharestoDelete = new List<AccountShare>();
        List<AccountShare> sharestoDeleteForReal = new List<AccountShare>();
        List<UserShare> userSharesToInsert = new List<UserShare>();
        List<UserShare> userSharesToDelete = new List<UserShare>();
        List<UserShare> userSharesToDeleteForReal = new List<UserShare>();
        // DP-1616 Misael Romero
        // List<TC_Origination__Checklist__Share> checklistSharesToInsert = new List<TC_Origination__Checklist__Share>();
        // List<TC_Origination__Checklist__Share> checklistSharesToDelete = new List<TC_Origination__Checklist__Share>();
        // List<TC_Origination__Checklist__Share> checklistSharesToDeleteForReal = new List<TC_Origination__Checklist__Share>();
        List<String> dealerAccountIds = new List<String>();
        Map<String, List<Id>> userIdsByGroup = new Map<String, List<Id>>();
        List<Id> userIdsToUngroup = new List<Id>();
        Map<Id,Id> userWithAccountIdMap = new Map<Id,Id>();
        Map<Id,Id> removeUserWithAccountIdMap = new Map<Id,Id>();
        for(SObject obj :newMap.values()){
            User theUser = (User)obj;
            Contact userContact = this.contacts.get(theUser.ContactId);
            UserRole theRole = this.userRoles.get(theUser.UserRoleId);
            Profile theProfile = this.profiles.get(theUser.ProfileId);
            List<String> fieldsChanged = fieldsChangedById.get(theUser.Id);
            User oldUser ;// modified by Rajesh(Mindtree)
            if(!isNew){
                oldUser = (User)oldUSers.get(theUser.Id);// modified by Rajesh(Mindtree)
                if(userContact != null && oldUser.Receive_Notifications__c <> theUser.Receive_Notifications__c){
                    userContact.Receive_All_Notifications__c = theUser.Receive_Notifications__c;
                    updateContacts.add(userContact);
                }
                if(theUser.IsPrmSuperUser != oldUser.IsPrmSuperUser){
                    if(userContact != null && userContact.AccountId != null 
                        && !dealerAccountIds.contains(userContact.AccountId)){
                        dealerAccountIds.add(String.valueOf(userContact.AccountId));
                    }
                }
            }
            //Added by Rajesh(Mindtree)
            if((isNew || (!isNew && theUser.IsPrmSuperUser != oldUser.IsPrmSuperUser)) && userContact != null && userContact.AccountId != null && theUser.IsPrmSuperUser)
            {
                userWithAccountIdMap.put(theUser.Id,userContact.AccountId);
            }
            //Added by Rajesh(Mindtree)
            if(!isNew && oldUser != null && theUser.IsPrmSuperUser != oldUser.IsPrmSuperUser && !theUser.IsPrmSuperUser && userContact != null && userContact.AccountId != null)
            {
                removeUserWithAccountIdMap.put(theUser.Id,userContact.AccountId);
            }
            
            //End
            if(userContact != null && userContact.AccountId != null && theUser.isPortalEnabled){
                Boolean isAdmin = SL_DPPermissions.isDealerAdminUser(theUser, theRole, permissionSetsAssigned, userContact, adminUsersByAccountId);
                AccountShare shareToUser = SL_DPPermissions.getPartnerAccountShare(theUser, userContact);
                if(theUser.IsActive && isAdmin){
                    sharesToInsert.add(shareToUser);
                }else{
                    sharestoDelete.add(shareToUser);
                }
                if(theUser.IsActive && theRole != null && theProfile != null 
                && (theRole.Name.containsIgnoreCase('Partner Executive') || theRole.Name.containsIgnoreCase('Partner Manager'))){
                    Boolean isXbs = userContact.Account.Account_Dealer_Program__c != null && (userContact.Account.Account_Dealer_Program__c.contains('XBS'));
                    if(theProfile.Name.containsIgnoreCase('OEG Dealer') || theProfile.Name.containsIgnoreCase('CT&I Dealer') || theProfile.Name.containsIgnoreCase('HC Dealer')){
                            // if(theProfile.Name.containsIgnoreCase('OEG Dealer')){ // according to DP-1222 it should only be OEG Dealer I don't know who added the other profiles
                        String groupDevName = isXbs? 'OEG_Dealer_Manager': 'Non_XBS_OEG_Dealer_Manager';
                        userIdsByGroup = addUserToGroup(groupDevName, theUser.Id, userIdsByGroup);
                    }
                    if(theRole.Name.containsIgnoreCase('Partner Executive')){
                        userIdsByGroup = addUserToGroup('Dealer_Admins', theUser.Id, userIdsByGroup);
                    }
                }else{
                    if(fieldsChanged != null && fieldsChanged.contains('UserRoleId')){
                        userIdsToUngroup.add(theUser.Id);
                    }
                }
            }
            removeInactiveDealerUser(theUser, isNew, fieldsChanged);
        }
        for(AccountShare accountShareWithUser : [SELECT Id, AccountId, UserOrGroupId, AccountAccessLevel, RowCause FROM AccountShare 
            WHERE AccountId IN :dealerAccounts AND UserOrGroupId IN :newMap.keySet()]){
            SL_SharingCustomRecord.checkAddOrRemove(accountShareWithUser, sharesToInsert, sharestoDelete, sharestoDeleteForReal,
                'AccountId', 'Manual', 'AccountAccessLevel', 'Edit');
        }
        if(adminUsersByAccountId.keySet().size() > 0){
            Map<Id, Id> parentByChildDealerAccId = new Map<Id, Id>();
            for(ExternalAccountHierarchy childAccountHierarchy : [SELECT Id, AccountId, Parent.AccountId
                FROM ExternalAccountHierarchy WHERE IsActive = true AND AccountId != null AND Parent.AccountId IN :adminUsersByAccountId.keySet()]){
                    parentByChildDealerAccId.put(childAccountHierarchy.AccountId, childAccountHierarchy.Parent.AccountId);
            }
            Set<Id> allChildIds = new Set<Id>();
            Set<Id> allAdminIds = new Set<Id>();
            for(User childDealerUser : [SELECT Id, Name, FirstName, LastName, ContactId, Contact.AccountId
                FROM User WHERE IsPortalEnabled = true AND Contact.AccountId IN :parentByChildDealerAccId.keySet()]){
                if(childDealerUser.Contact != null && childDealerUser.Contact.AccountId != null){
                    for(Id adminUserId : adminUsersByAccountId.get(parentByChildDealerAccId.get(childDealerUser.Contact.AccountId))){
                        UserShare shareToUser = new UserShare(UserAccessLevel = 'Read',
                        RowCause = 'Manual', UserId = childDealerUser.Id, UserOrGroupId = adminUserId);
                        Boolean isDelete = false;// cannot check the permissionSetAssignment before and after as of now
                        if(isDelete){
                            userSharesToDelete.add(shareToUser);
                        }else{
                            userSharesToInsert.add(shareToUser);
                        }
                        allChildIds.add(childDealerUser.Id);
                        allAdminIds.add(adminUserId);
                    }
                }
            }
            for(UserShare userShareWithAdminUser : [SELECT Id, UserId, UserOrGroupId, UserAccessLevel, RowCause FROM UserShare 
                WHERE UserId IN :allChildIds AND UserOrGroupId IN :allAdminIds]){
                SL_SharingCustomRecord.checkAddOrRemove(userShareWithAdminUser, userSharesToInsert, userSharesToDelete, userSharesToDeleteForReal,
                    'UserId', 'Manual', 'UserAccessLevel', 'Read');
            }
        }
        if(sharesToInsert.size() > 0 || sharestoDeleteForReal.size() > 0
            || userSharesToInsert.size() > 0 || userSharesToDeleteForReal.size() > 0){
            System.enqueueJob(new SL_UserAccountShareQ(sharesToInsert, sharestoDeleteForReal, userSharesToInsert, userSharesToDeleteForReal));
        }
        system.debug('updateContacts:'+updateContacts);
        if(updateContacts.size() > 0) update updateContacts;
        
        if(dealerAccountIds.size() > 0){
           // Commentted the below code by Rajesh(Mindtree)
            //System.enqueueJob(new SL_UserAccountShareQ('Contract__Share', dealerAccountIds));
            System.enqueueJob(new SL_UserAccountShareQ('OpportunityShare', dealerAccountIds));
        }
        if(userIdsByGroup.values().size() > 0 || userIdsToUngroup.size() > 0){
            System.enqueueJob(new SL_UserAccountShareQ(userIdsByGroup, userIdsToUngroup));
        }
        //Added by Rajesh(Mindtree)
        if(!userWithAccountIdMap.isEmpty())
        {
            PEAC_SuperUsersContractShareBatch batchJob = New PEAC_SuperUsersContractShareBatch(userWithAccountIdMap);
            Database.executeBatch(batchJob, Integer.ValueOf(Label.PEAC_Contract_SUser_Sharing)); 
        }
        //Added by Rajesh(Mindtree)
        if(!removeUserWithAccountIdMap.isEmpty())
        {
            PEAC_RemoveContractShareBatch removeBatchJob = New PEAC_RemoveContractShareBatch(removeUserWithAccountIdMap,  'User');
            Database.executeBatch(removeBatchJob, Integer.ValueOf(Label.PEAC_Contract_SUser_Sharing)); 
        }
        
        //End
    }
	

    public static Map<String, List<Id>> addUserToGroup(String groupDevName, Id userId, Map<String, List<Id>> userIdsByGroup){
        List<Id> memberIds = userIdsByGroup.get(groupDevName);
        if(memberIds == null){
            memberIds = new List<Id>();
        }
        memberIds.add(userId);
        userIdsByGroup.put(groupDevName, memberIds);
        return userIdsByGroup;
    }

    private static void removeInactiveDealerUser(User theUser, Boolean isNew, List<String> fieldsChanged){
        if(!isNew && fieldsChanged != null && fieldsChanged.contains('IsActive') && !theUser.IsActive){
            List<AsyncApexJob> alreadyScheduled = [SELECT Id, CronTrigger.CronJobDetail.Name, ApexClass.Name, CronTrigger.PreviousFireTime, cronTrigger.NextFireTime
            FROM AsyncApexJob
            WHERE CronTrigger.NextFireTime != null AND ApexClass.Name = 'SL_DPRemoveInactiveUsers'];
            if(alreadyScheduled.size() == 0){
                Date scheduledDay = Date.today();
                Datetime theTimeofDay = Datetime.now();
                if(theTimeofDay.hour() >= 3){
                    scheduledDay = Date.today().addDays(1);
                }
                String cronExp = '0 0 3 ' + scheduledDay.day() + ' ' + scheduledDay.month() + ' '
                    + '? ' + scheduledDay.year();
                System.schedule('SL DP Remove inactive Users' + String.valueOf(scheduledDay), cronExp, new SL_DPRemoveInactiveUsers());
            }
        }

    }
}
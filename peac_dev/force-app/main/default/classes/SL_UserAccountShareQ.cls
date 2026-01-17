public without sharing class SL_UserAccountShareQ implements Queueable {
    List<AccountShare> sharesToInsert = new List<AccountShare>();
    List<AccountShare> sharestoDelete = new List<AccountShare>();
    List<UserShare> userSharesToInsert = new List<UserShare>();
    List<UserShare> userSharesToDelete = new List<UserShare>();
    // DP-1616 Misael Romero
    // List<TC_Origination__Checklist__Share> checklistSharesToInsert = new List<TC_Origination__Checklist__Share>();
    // List<TC_Origination__Checklist__Share> checklistSharesToDelete = new List<TC_Origination__Checklist__Share>();
    String shareObject = '';
    List<String> dealerAccountIds = new List<String>();
    Boolean isToFixSharing = false;
    Map<String, List<Id>> userIdsByGroup = new Map<String, List<Id>>();
    List<Id> userIdsToUngroup = new List<Id>();
    List<SObject> remainingToUpsert = new List<SObject>();
    List<String> allErrors = new List<String>();

    public SL_UserAccountShareQ(List<AccountShare> sharesToInsert, List<AccountShare> sharestoDelete, 
        List<UserShare> userSharesToInsert, List<UserShare> userSharesToDelete) {
        this.sharesToInsert = sharesToInsert;
        this.sharestoDelete = sharestoDelete;
        this.userSharesToInsert = userSharesToInsert;
        this.userSharesToDelete = userSharesToDelete;
    }
    public SL_UserAccountShareQ(String shareObject, List<String> dealerAccountIds) {
        this.shareObject = shareObject;
        this.dealerAccountIds = dealerAccountIds;
    }
    public SL_UserAccountShareQ(String shareObject) {
        this.shareObject = shareObject;
        this.isToFixSharing = true;
    }

    public SL_UserAccountShareQ(Map<String, List<Id>> userIdsByGroup, List<Id> userIdsToUngroup){
        this.userIdsByGroup = userIdsByGroup;
        this.userIdsToUngroup = userIdsToUngroup;
    }

    public void execute(QueueableContext context) {
        if(sharesToInsert.size() > 0){
            callBigUpsert(sharesToInsert, true, 'AccountShare', context);
        }
        if(sharestoDelete.size() > 0){
            delete sharestoDelete;
        }
        if(userSharesToInsert.size() > 0){
            callBigUpsert(userSharesToInsert, true, 'UserShare', context);
        }
        if(userSharesToDelete.size() > 0){
            delete userSharesToDelete;
        }
        
        if(dealerAccountIds.size() > 0){
            if(shareObject == 'dealerAccountShare'){
                shareDealerAccountToSuperUsers(context);
            }else{
            Database.executeBatch(new SL_DPSharingRecalcBatch(shareObject, dealerAccountIds));
            }
        }
        if(isToFixSharing){
            Database.executeBatch(new SL_DPSharingRecalcBatch(shareObject, isToFixSharing));
        }
        if(userIdsByGroup.values().size() > 0 || userIdsToUngroup.size() > 0){
            List<String> DealerAdminGroups = new List<String>{'Dealer_Admins', 'Non_XBS_OEG_Dealer_Manager', 'OEG_Dealer_Manager'};
            Set<Id> allUserIds = new Set<Id>();
            List<GroupMember> membersToDelete = new List<GroupMember>();
            List<GroupMember> membersToInsert = new List<GroupMember>();
            for(List<Id> groupedIds :userIdsByGroup.values()){
                allUserIds.addAll(groupedIds);
            }
            allUserIds.addAll(userIdsToUngroup);
            List<Group> adminGroupList = [SELECT Id, DeveloperName FROM Group WHERE DeveloperName In :DealerAdminGroups];
            Map<String, Id> groupIdsByDevName = new Map<String, Id>();
            For(Group DealerGroup:adminGroupList){
                groupIdsByDevName.put(DealerGroup.DeveloperName, DealerGroup.Id);
            }
            Map<String, GroupMember> currentMemberships = new Map<String, GroupMember>();
            for(GroupMember currentMembership :[SELECT Id, UserOrGroup.UserRole.Name, UserOrGroup.Profile.Name, UserOrGroupId, Group.DeveloperName
                FROM GroupMember 
                WHERE UserOrGroup.IsPortalEnabled = true AND Group.DeveloperName IN :DealerAdminGroups AND UserOrGroupId IN :allUserIds]){
                if(userIdsToUngroup.contains(currentMembership.UserOrGroupId)
                && (currentMembership.UserOrGroup.UserRole == null || !(currentMembership.UserOrGroup.UserRole.Name.containsIgnoreCase('Partner Executive')
                || currentMembership.UserOrGroup.UserRole.Name.containsIgnoreCase('Partner Manager')))){
                    membersToDelete.add(currentMembership);
                }
                currentMemberships.put(currentMembership.Group.DeveloperName + currentMembership.UserOrGroupId, currentMembership);
            }
            for(String groupDevName :userIdsByGroup.keySet()){
                List<Id> groupUserIds = userIdsByGroup.get(groupDevName);
                if(groupUserIds != null){
                    for(Id userId :groupUserIds){
                        if(currentMemberships.get(groupDevName + userId) == null){
                            membersToInsert.add(new GroupMember(GroupId = groupIdsByDevName.get(groupDevName), UserOrGroupId = userId));
                        }
                    }
                }
            }
            if(membersToDelete.size() > 0){
                List<Database.DeleteResult> deletionResults = Database.delete(membersToDelete, false);
                System.debug('deletionResults: ' + deletionResults);
            }
            if(membersToInsert.size() > 0){
                List<Database.SaveResult> insertionResults = Database.insert(membersToInsert, false);
                System.debug('insertionResults: ' + insertionResults);
            }
        }
    }
    // DP-1601 Misael Romero
    void shareDealerAccountToSuperUsers(QueueableContext context){
        Map<Id, List<Id>> adminUsersByAccountId = new Map<Id, List<Id>>();
        for(User partnerUser :[SELECT Id, IsPrmSuperUser, Contact.Account.Account_Dealer_Program__c, 
        UserRole.Name, Profile.Name, (SELECT id, PermissionSet.Name FROM PermissionSetAssignments) 
        FROM User WHERE IsPortalEnabled = true AND IsActive = true AND Contact.AccountId = :dealerAccountIds]){
            UserRole theRole = partnerUser.UserRole;
            Contact userContact = partnerUser.Contact;
            Map<Id, List<PermissionSetAssignment>> permissionSetsAssigned = new Map<Id, List<PermissionSetAssignment>>();
            List<PermissionSetAssignment> relatedPermissionSets = new List<PermissionSetAssignment>();
            for(PermissionSetAssignment thePSA: partnerUser.PermissionSetAssignments){
                relatedPermissionSets.add(thePSA);
            }
            permissionSetsAssigned.put(partnerUser.Id, relatedPermissionSets);
            Boolean isAdmin = SL_DPPermissions.isDealerAdminUser(partnerUser, theRole, permissionSetsAssigned, userContact, adminUsersByAccountId);
            if(isAdmin){
                sharesToInsert.add(SL_DPPermissions.getPartnerAccountShare(partnerUser, userContact));
            }
        }
        if(sharesToInsert.size() > 0){
            callBigUpsert(sharesToInsert, true, 'AccountShare', context);
        }
    }
    // DP-1921 Misael Romero
    public void callBigUpsert(List<SObject> allRecords, Boolean isInsert, String shareObject, QueueableContext context){
        List<List<SObject>> bigInsertList = SL_DPSharingRecalcBatch.splitDMLList(allRecords);
        allErrors = SL_DPSharingRecalcBatch.bigUpsert(bigInsertList, isInsert, allErrors, remainingToUpsert);
        if(allErrors.size() > 0){
            String serializedMap = String.join(allErrors, '. \r\n');
            // MARLIN_IntegrationLog.addLog ('DP Sharing Recalculation Batch', context.getJobId(), 'Error', '', serializedMap.left(131071),
            //     'Error', 'Error encountered while trying to give access to the Dealer Users described in the Response_Message__c field, shareObject: ' + shareObject);
            // MARLIN_IntegrationLog.insertLogs();
            system.debug('serializedMap errors: ' + serializedMap);
            // System.enqueueJob(new SL_CollectionAssignmentQ('misael.romero@silverlinecrm.com', 'Error Summary shareObject: ' + shareObject, serializedMap));
        }
        if(remainingToUpsert.size() > 0){
            Database.executeBatch(new SL_DPSharingRecalcBatch(remainingToUpsert, shareObject));
        }
    }
}
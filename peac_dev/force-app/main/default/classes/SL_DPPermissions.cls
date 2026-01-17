public without sharing class SL_DPPermissions {
    public static Map<Id, User> allPortalUsers2 = new Map<Id, User>();
    public static Map<Id, Id> parentByChildDealerAccId = new Map<Id, Id>();

    public static void checkDealerAdminShares(){
        String coverageHelp = 'a';
        coverageHelp = 'b';
        coverageHelp = 'c';
        coverageHelp = 'd';
        coverageHelp = 'e';
        // DP-1646 Misael Romero
        System.enqueueJob(new SL_UserAccountShareQ('AccountShare'));
        System.enqueueJob(new SL_UserAccountShareQ('Contract__Share'));
        System.enqueueJob(new SL_UserAccountShareQ('OpportunityShare'));
        // DP-1921 Misael Romero
        System.enqueueJob(new SL_UserAccountShareQ('UserShare'));        
    }

    public static List<String> findMissingSharesByCount(String shareObject){
        return findMissingSharesByCount(shareObject, '');
    }
    public static List<String> findMissingSharesByCount(String shareObject, String dealerIdToCheck){
        List<String> shareObjectsToInsert = new List<String>{'Account', 'Contract__c', 'Opportunity', 'User'};
        Boolean isToInsert = shareObjectsToInsert.contains(shareObject);
        List<String> missingSharesDealerIds = new List<String>();
        Map<String, SL_DPPermissions.DealerStats> statsByDealerId = new Map<String, SL_DPPermissions.DealerStats>();
        Integer queryRowsLimit = 5000;
        List<AggregateResult> userResults = [SELECT Contact.AccountId dealerId, IsPrmSuperUser isSuper, count(Id) totalUsers
            FROM User WHERE IsPortalEnabled = true AND IsActive = true
            GROUP BY Contact.AccountId, IsPrmSuperUser LIMIT :queryRowsLimit];
        for(AggregateResult userResult :userResults){
            String dealerId = String.valueOf(userResult.get('dealerId'));
            SL_DPPermissions.DealerStats thisDealerStats = statsByDealerId.get(dealerId) ?? new SL_DPPermissions.DealerStats();
            if(Boolean.valueOf(userResult.get('isSuper'))){
                thisDealerStats.totalSuperUsers = Integer.valueOf(userResult.get('totalUsers'));
            }else{
                thisDealerStats.totalMereUsers = Integer.valueOf(userResult.get('totalUsers'));
            }
            statsByDealerId.put(String.valueOf(userResult.get('dealerId')), thisDealerStats);
            if(String.isnotBlank(dealerIdToCheck) && dealerIdToCheck == String.valueOf(userResult.get('dealerId'))){
                system.debug('checkedSuperUsers: ' + thisDealerStats);
            }
        }
        allPortalUsers2 = new Map<Id, User>([SELECT Id, Contact.AccountId, IsPrmSuperUser 
            FROM User WHERE IsActive = true AND IsPortalEnabled  = true LIMIT 20000]);
        String shareQuery = '';
        String targetQuery = '';
        String ownerIsPartnerQuery = '';
        switch on shareObject {
            when 'AccountShare','Account' {
                shareQuery = 'SELECT Parent.Dealer_Name__c dealerId, UserOrGroupId superUserId, Parent.Customer__c customerId, count(Id) shareTotal '
                    + ' FROM Contract__Share WHERE Parent.Dealer_Name__r.IsPartner = true AND UserOrGroup.IsActive = true '
                    + ' AND RowCause = \'Dealer_Contract_Sharing__c\' AND AccessLevel = \'Edit\' AND Parent.Customer__c != null '
                    + ' GROUP BY Parent.Dealer_Name__c, UserOrGroupId, Parent.Customer__c ORDER BY Parent.Dealer_Name__c, UserOrGroupId LIMIT ' + String.valueOf(queryRowsLimit);
                targetQuery = 'SELECT Dealer_Name__c dealerId,  Customer__c customerId, count(Id) totalRecords '
                    + ' FROM Contract__c WHERE Dealer_Name__r.IsPartner = true AND Customer__c != null '
                    + ' GROUP BY Dealer_Name__c, Customer__c LIMIT ' + String.valueOf(queryRowsLimit);
                ownerIsPartnerQuery = 'SELECT OwnerId, COUNT(Id) totalRecords '
                    + ' FROM Account WHERE OwnerId IN :portalUserIds '
                    + ' GROUP BY OwnerId LIMIT ' + String.valueOf(queryRowsLimit);
            }
            when 'Contract__Share','Contract__c' {
                shareQuery = 'SELECT Parent.Dealer_Name__c dealerId, UserOrGroupId superUserId, count(Id) shareTotal '
                    + ' FROM Contract__Share WHERE Parent.Dealer_Name__r.IsPartner = true AND UserOrGroup.IsActive = true '
                    + ' AND RowCause = \'Dealer_Contract_Sharing__c\' AND AccessLevel = \'Edit\' '
                    + ' GROUP BY Parent.Dealer_Name__c, UserOrGroupId ORDER BY Parent.Dealer_Name__c, UserOrGroupId LIMIT ' + String.valueOf(queryRowsLimit);
                targetQuery = 'SELECT Dealer_Name__c dealerId,  count(Id) totalRecords '
                    + ' FROM Contract__c WHERE Dealer_Name__r.IsPartner = true '
                    + ' GROUP BY Dealer_Name__c LIMIT ' + String.valueOf(queryRowsLimit);
                ownerIsPartnerQuery = 'SELECT OwnerId,  count(Id) totalRecords '
                    + ' FROM Contract__c WHERE Dealer_Name__r.IsPartner = true '
                    + ' AND OwnerId IN :portalUserIds '
                    + ' GROUP BY OwnerId LIMIT ' + String.valueOf(queryRowsLimit);
            }
            when 'OpportunityShare','Opportunity' {
                shareQuery = 'SELECT Opportunity.Dealer_Account__c dealerId,  count(Id) shareTotal '
                    + ' FROM OpportunityShare WHERE Opportunity.Dealer_Account__r.IsPartner = true AND UserOrGroup.IsActive = true '
                    + ' AND RowCause = \'Manual\' AND OpportunityAccessLevel = \'Edit\' '
                    + ' GROUP BY Opportunity.Dealer_Account__c LIMIT ' + String.valueOf(queryRowsLimit);
                targetQuery = 'SELECT Dealer_Account__c dealerId,  count(Id) totalRecords '
                    + ' FROM Opportunity WHERE Dealer_Account__r.IsPartner = true '
                    + ' GROUP BY Dealer_Account__c LIMIT ' + String.valueOf(queryRowsLimit);
                ownerIsPartnerQuery = 'SELECT OwnerId, count(Id) totalRecords '
                    + ' FROM Opportunity WHERE Dealer_Account__r.IsPartner = true '
                    + ' AND OwnerId IN :portalUserIds '
                    + ' GROUP BY OwnerId LIMIT ' + String.valueOf(queryRowsLimit);
            }
            when 'UserShare','User' {
                shareQuery = 'SELECT User.Contact.AccountId dealerId,  count(Id) shareTotal '
                    + ' FROM UserShare WHERE User.Contact.Account.IsPartner = true AND UserOrGroup.IsActive = true '
                    + ' AND RowCause = \'Manual\' AND UserAccessLevel = \'Read\' '
                    + ' GROUP BY User.Contact.AccountId LIMIT ' + String.valueOf(queryRowsLimit);
                targetQuery = 'SELECT Contact.AccountId dealerId,  count(Id) totalRecords '
                    + ' FROM User WHERE IsPortalEnabled = true AND IsActive = true AND Contact.Account.IsPartner = true '
                    + ' GROUP BY Contact.AccountId LIMIT ' + String.valueOf(queryRowsLimit);
                ownerIsPartnerQuery = '';
            }
        }
        if(shareObject.contains('User')){
            getParentByChildDealerAccId();
        }
        statsByDealerId = countTotalsInTarget(targetQuery, statsByDealerId, shareObject, dealerIdToCheck);
        statsByDealerId = countTotalsInShare(shareQuery, statsByDealerId, shareObject, dealerIdToCheck, isToInsert);
        if(ownerIsPartnerQuery != ''){
            statsByDealerId = countTotalsOwner(ownerIsPartnerQuery, statsByDealerId, shareObject, true, dealerIdToCheck);
        }
        Map<String, SL_DPPermissions.DealerStats> missingDealersStats = new Map<String, SL_DPPermissions.DealerStats>();
        Map<String, SL_DPPermissions.DealerStats> dealersWithMereUsers = new Map<String, SL_DPPermissions.DealerStats>();
        for(String dealerId : statsByDealerId.keySet()){
            SL_DPPermissions.DealerStats thisDealerStats = statsByDealerId.get(dealerId);
            if(shareObject.contains('User')){
                thisDealerStats.totalSuperUsers += thisDealerStats.totalMereUsers;
            }
            Integer expectedShareTotal = thisDealerStats.totalRecords * thisDealerStats.totalSuperUsers - thisDealerStats.totalSuperOwners;
            if(isToInsert){
                if(thisDealerStats.shareTotal < expectedShareTotal){
                    missingSharesDealerIds.add(dealerId);
                }
            }else{
                if(thisDealerStats.totalRecords > 0 && thisDealerStats.totalSuperUsers > 0
                && thisDealerStats.shareTotal > expectedShareTotal){
                    missingSharesDealerIds.add(dealerId);
                }
            }
            if(!missingSharesDealerIds.contains(dealerId) && !String.isBlank(thisDealerStats.oddSharingUserId)){
                missingSharesDealerIds.add(dealerId);
            }
            if(missingSharesDealerIds.contains(dealerId)){
                missingDealersStats.put(dealerId, thisDealerStats);
            }
            if(thisDealerStats.totalMereUsers > 0){
                dealersWithMereUsers.put(dealerId, thisDealerStats);
            }
            if(String.isnotBlank(dealerIdToCheck) && dealerIdToCheck == dealerId){
                system.debug('final veredict: ' + thisDealerStats);
                System.debug('multiplication result: '+ (thisDealerStats.totalRecords * thisDealerStats.totalSuperUsers));
            }
        }
        if(isToInsert && !shareObject.contains('User')){
            missingSharesDealerIds = findMissingShareMereUsers(dealersWithMereUsers, queryRowsLimit, missingSharesDealerIds, shareObject, dealerIdToCheck, isToInsert);
        }
        System.debug('total of missingShare Dealer Ids: ' + missingSharesDealerIds.size());
        System.debug('missingDealersStats: ' + missingDealersStats);
        allPortalUsers2.clear();
        return missingSharesDealerIds;
    }

    public static List<String> findMissingShareMereUsers(Map<String, SL_DPPermissions.DealerStats> dealersWithMereUsers, Integer queryRowsLimit,
    List<String> missingSharesDealerIds, String shareObject, String dealerIdToCheck, Boolean isToInsert){
        String shareQuery = '';
        String targetQuery = '';
        String ownerIsPartnerQuery = '';
        switch on shareObject {
            when 'AccountShare','Account' {
                shareQuery = 'SELECT Parent.Dealer_Name__c dealerId, UserOrGroupId superUserId, Parent.Customer__c customerId, count(Id) shareTotal '
                    + ' FROM Contract__Share WHERE Parent.Dealer_Name__r.IsPartner = true '
                    + ' AND RowCause = \'Dealer_Contract_Sharing__c\' AND AccessLevel = \'Edit\' AND Parent.Customer__c != null AND Parent.Dealer_User__c != null '
                    + ' AND Parent.Dealer_User__r.IsPrmSuperUser = false AND Parent.Dealer_User__r.IsActive = true '
                    + ' GROUP BY Parent.Dealer_Name__c, UserOrGroupId, Parent.Customer__c ORDER BY Parent.Dealer_Name__c, UserOrGroupId LIMIT ' + String.valueOf(queryRowsLimit);
                targetQuery = 'SELECT Dealer_Name__c dealerId,  Customer__c customerId, count(Id) totalRecords '
                    + ' FROM Contract__c WHERE Dealer_Name__r.IsPartner = true AND Customer__c != null AND Dealer_User__c != null '
                    + ' AND Dealer_User__r.IsPrmSuperUser = false AND Dealer_User__r.IsActive = true '
                    + ' GROUP BY Dealer_Name__c, Customer__c LIMIT ' + String.valueOf(queryRowsLimit);
                ownerIsPartnerQuery = 'SELECT OwnerId, COUNT(Id) totalRecords '
                    + ' FROM Account WHERE OwnerId IN :portalUserIds '
                    + ' GROUP BY OwnerId LIMIT ' + String.valueOf(queryRowsLimit);
            }
            when 'Contract__Share','Contract__c' {
                shareQuery = 'SELECT Parent.Dealer_Name__c dealerId, UserOrGroupId superUserId, count(Id) shareTotal '
                    + ' FROM Contract__Share WHERE Parent.Dealer_Name__r.IsPartner = true '
                    + ' AND RowCause = \'Dealer_Contract_Sharing__c\' AND AccessLevel = \'Edit\' AND Parent.Dealer_User__c != null '
                    + ' AND Parent.Dealer_User__r.IsPrmSuperUser = false AND Parent.Dealer_User__r.IsActive = true '
                    + ' GROUP BY Parent.Dealer_Name__c, UserOrGroupId ORDER BY Parent.Dealer_Name__c, UserOrGroupId LIMIT ' + String.valueOf(queryRowsLimit);
                targetQuery = 'SELECT Dealer_Name__c dealerId,  count(Id) totalRecords '
                    + ' FROM Contract__c WHERE Dealer_Name__r.IsPartner = true AND Dealer_User__c != null '
                    + ' AND Dealer_User__r.IsPrmSuperUser = false AND Dealer_User__r.IsActive = true '
                    + ' GROUP BY Dealer_Name__c LIMIT ' + String.valueOf(queryRowsLimit);
                ownerIsPartnerQuery = 'SELECT OwnerId,  count(Id) totalRecords '
                    + ' FROM Contract__c WHERE Dealer_Name__r.IsPartner = true AND Dealer_User__c != null '
                    + ' AND Dealer_User__r.IsPrmSuperUser = false AND Dealer_User__r.IsActive = true AND OwnerId IN :portalUserIds '
                    + ' GROUP BY OwnerId LIMIT ' + String.valueOf(queryRowsLimit);
            }
            when 'OpportunityShare','Opportunity' {
                shareQuery = 'SELECT Opportunity.Dealer_Account__c dealerId,  count(Id) shareTotal '
                    + ' FROM OpportunityShare WHERE Opportunity.Dealer_Account__r.IsPartner = true '
                    + ' AND RowCause = \'Manual\' AND OpportunityAccessLevel = \'Edit\' AND Opportunity.Dealer_User__c != null '
                    + ' AND Opportunity.Dealer_User__r.IsPrmSuperUser = false AND Opportunity.Dealer_User__r.IsActive = true '
                    + ' GROUP BY Opportunity.Dealer_Account__c LIMIT ' + String.valueOf(queryRowsLimit);
                targetQuery = 'SELECT Dealer_Account__c dealerId,  count(Id) totalRecords '
                    + ' FROM Opportunity WHERE Dealer_Account__r.IsPartner = true AND Dealer_User__c != null '
                    + ' AND Dealer_User__r.IsPrmSuperUser = false AND Dealer_User__r.IsActive = true '
                    + ' GROUP BY Dealer_Account__c LIMIT ' + String.valueOf(queryRowsLimit);
                ownerIsPartnerQuery = 'SELECT OwnerId, count(Id) totalRecords '
                    + ' FROM Opportunity WHERE Dealer_Account__r.IsPartner = true AND Dealer_User__c != null '
                    + ' AND Dealer_User__r.IsPrmSuperUser = false AND Dealer_User__r.IsActive = true AND OwnerId IN :portalUserIds '
                    + ' GROUP BY OwnerId LIMIT ' + String.valueOf(queryRowsLimit);
            }
        }
        dealersWithMereUsers = countTotalsInTarget(targetQuery, dealersWithMereUsers, shareObject, dealerIdToCheck);
        for(SL_DPPermissions.DealerStats dealerStat : dealersWithMereUsers.values()){
            dealerStat.shareTotal = 0;
        }
        dealersWithMereUsers = countTotalsInShare(shareQuery, dealersWithMereUsers, shareObject, dealerIdToCheck, isToInsert);
        dealersWithMereUsers = countTotalsOwner(ownerIsPartnerQuery, dealersWithMereUsers, shareObject, false, dealerIdToCheck);
        Map<String, SL_DPPermissions.DealerStats> missingDealersStats = new Map<String, SL_DPPermissions.DealerStats>();
        for(String dealerId : dealersWithMereUsers.keySet()){
            SL_DPPermissions.DealerStats thisDealerStats = dealersWithMereUsers.get(dealerId);
            if(thisDealerStats.totalRecords > 0 && thisDealerStats.shareTotal > 0
                && thisDealerStats.shareTotal < thisDealerStats.totalRecords - thisDealerStats.totalMereOwners + (thisDealerStats.totalRecords * thisDealerStats.totalSuperUsers)){
                missingSharesDealerIds.add(dealerId);
            }
            if(missingSharesDealerIds.contains(dealerId)){
                missingDealersStats.put(dealerId, thisDealerStats);
            }
            if(String.isnotBlank(dealerIdToCheck) && dealerIdToCheck == dealerId){
                system.debug('mere users final veredict: ' + thisDealerStats);
            }
        }
        System.debug('mere users missingDealersStats: ' + missingDealersStats);
        return missingSharesDealerIds;
    }

    static Map<String, SL_DPPermissions.DealerStats> countTotalsInTarget(String targetQuery, Map<String, SL_DPPermissions.DealerStats> statsByDealerId, String shareObject,
    String dealerIdToCheck){
        List<AggregateResult> targetResults = Database.query(targetQuery);
        for(AggregateResult targetResult :targetResults){
            String dealerId = String.valueOf(targetResult.get('dealerId'));
            if(shareObject.contains('User')){
                dealerId = parentByChildDealerAccId.get(dealerId);
            }
            SL_DPPermissions.DealerStats thisDealerStats = statsByDealerId.get(dealerId) ?? new SL_DPPermissions.DealerStats();
            if(shareObject.contains('Account')){
                thisDealerStats.totalRecords++;
            }else{
                if(shareObject.contains('User')){
                    thisDealerStats.totalRecords += Integer.valueOf(targetResult.get('totalRecords'));
                }else{
                    thisDealerStats.totalRecords = Integer.valueOf(targetResult.get('totalRecords'));
                }
            }
            statsByDealerId.put(dealerId, thisDealerStats);
            if(String.isnotBlank(dealerIdToCheck) && dealerIdToCheck == String.valueOf(targetResult.get('dealerId'))){
                system.debug('checkedtargetRecords: ' + thisDealerStats);
            }
        }
        return statsByDealerId;
    }

    static Map<String, SL_DPPermissions.DealerStats> countTotalsInShare(String shareQuery, Map<String, SL_DPPermissions.DealerStats> statsByDealerId, String shareObject,
    String dealerIdToCheck, Boolean isToInsert){
        List<AggregateResult> shareResults = Database.query(shareQuery);
        for(AggregateResult shareResult :shareResults){
            String dealerId = String.valueOf(shareResult.get('dealerId'));
            if(shareObject.contains('User')){
                dealerId = parentByChildDealerAccId.get(dealerId);
            }
            SL_DPPermissions.DealerStats thisDealerStats = statsByDealerId.get(dealerId) ?? new SL_DPPermissions.DealerStats();
            Integer sharePerUser = Integer.valueOf(shareResult.get('shareTotal'));
            if(shareObject.contains('Contract__')){
                if(isToInsert){
                    if(thisDealerStats.totalRecords > 0 && sharePerUser < thisDealerStats.totalRecords){
                        thisDealerStats.oddSharingUserId = String.valueOf(shareResult.get('superUserId'));
                    }
                }else{
                    if(thisDealerStats.totalRecords > 0 && sharePerUser > thisDealerStats.totalRecords){
                        thisDealerStats.oddSharingUserId = String.valueOf(shareResult.get('superUserId'));
                    }
                }
            }
            if(shareObject.contains('Account')){
                thisDealerStats.shareTotal++;
            }else{
                thisDealerStats.shareTotal += sharePerUser;    
            }
            statsByDealerId.put(dealerId, thisDealerStats);
            if(String.isnotBlank(dealerIdToCheck) && dealerIdToCheck == dealerId){
                system.debug('checkedShares: ' + thisDealerStats);
            }
        }
        return statsByDealerId;
    }

    static Map<String, SL_DPPermissions.DealerStats> countTotalsOwner(String ownerQuery, Map<String, SL_DPPermissions.DealerStats> statsByDealerId, String shareObject,
    Boolean isSuper, String dealerIdToCheck){
        Set<Id> portalUserIds = allPortalUsers2.keySet();
        List<AggregateResult> targetResults = Database.query(ownerQuery);
        for(AggregateResult targetResult :targetResults){
            User theOwner = allPortalUsers2.get((Id)targetResult.get('OwnerId'));
            String dealerId = String.valueOf(theOwner.Contact.AccountId);
            SL_DPPermissions.DealerStats thisDealerStats = statsByDealerId.get(dealerId) ?? new SL_DPPermissions.DealerStats();
            Integer totalPartnerAsOwners = 0;
            totalPartnerAsOwners = Integer.valueOf(targetResult.get('totalRecords'));
            if(isSuper && theOwner.IsPrmSuperUser){
                thisDealerStats.totalSuperOwners += totalPartnerAsOwners;
            }else{
                if(!isSuper && !theOwner.IsPrmSuperUser){
                    thisDealerStats.totalMereOwners += totalPartnerAsOwners;
                }
            }
            statsByDealerId.put(dealerId, thisDealerStats);
            if(String.isnotBlank(dealerIdToCheck) && dealerIdToCheck == dealerId){
                system.debug('checkedOwnerRecords: ' + thisDealerStats);
            }
        }
        return statsByDealerId;
    }

    public static Map<Id, Id> getParentByChildDealerAccId(){
        if(parentByChildDealerAccId.keySet().size() == 0){
            for(ExternalAccountHierarchy childAccountHierarchy : [SELECT Id, AccountId, Parent.AccountId
            FROM ExternalAccountHierarchy WHERE IsActive = true AND AccountId != null AND Parent.AccountId != null]){
                parentByChildDealerAccId.put(childAccountHierarchy.AccountId, childAccountHierarchy.Parent.AccountId);
            }
        }
        return parentByChildDealerAccId;
    }

    public static Boolean isDealerAdminUser(User theUser, UserRole theRole, Map<Id, List<PermissionSetAssignment>> permissionSetsAssigned, 
    Contact userContact, Map<Id, List<Id>> adminUsersByAccountId){
        Boolean isAdmin = theUser.IsPrmSuperUser || (theRole != null && theRole.Name.containsIgnoreCase('Partner Executive'));
        if(!isAdmin){
            for(PermissionSetAssignment thePSA: permissionSetsAssigned.get(theUser.Id)){
                if(thePSA.PermissionSet.Name == 'Dealer_Delegated_Admin' || thePSA.PermissionSet.Name == 'Login_Users_Dealer_Delegated_Admin'){
                    isAdmin = true;
                    List<Id> adminUserIds = adminUsersByAccountId.get(userContact.AccountId);
                    if(adminUserIds == null){
                        adminUserIds = new List<Id>();
                    }
                    adminUserIds.add(theUser.Id);
                    adminUsersByAccountId.put(userContact.AccountId, adminUserIds);
                    break;
                }
            }
        }
        return isAdmin;
    }

    public static AccountShare getPartnerAccountShare(User theUser, Contact userContact){
        return new AccountShare(AccountAccessLevel = 'Edit', OpportunityAccessLevel = 'Edit', CaseAccessLevel = 'Read',
                    RowCause = 'Manual', AccountId = userContact.AccountId, UserOrGroupId = theUser.Id);
    }

    public class DealerStats {
        public Integer shareTotal = 0;
        public Integer totalRecords = 0;
        public Integer totalSuperUsers = 0;
        public Integer totalMereUsers = 0;
        public Integer totalSuperOwners = 0;
        public Integer totalMereOwners = 0;
        public String oddSharingUserId;
    }
}
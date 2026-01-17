public without sharing class SL_DealerPortalCAOppInfo {
    @invocableMethod(label='Share Opp with User')
    public static List<Opportunity> shareOppWithUser(List<Opportunity> opportunities){
        Opportunity theOpportunity = opportunities[0];
        Id userId = System.UserInfo.getUserId();
        Boolean isEditable = false;
        List<SObject> sharesWithUser = [SELECT Id, OpportunityAccessLevel, RowCause FROM OpportunityShare 
            WHERE OpportunityId = :theOpportunity.Id AND UserOrGroupId = :userId];
        isEditable = checkSharedWithUser('Opportunity', sharesWithUser);
        // if(sharesWithUser.size() > 0){
        //     for(OpportunityShare accShare :sharesWithUser){
        //         if(accShare.OpportunityAccessLevel == 'Edit' || accShare.OpportunityAccessLevel == 'All'){
        //             isEditable = true;
        //         }
        //     }
        // }
        system.debug('System.UserInfo.getUserId(): ' + System.UserInfo.getUserId());
        system.debug('sharesWithUser: ' + sharesWithUser);
        system.debug('userId: ' + userId);
        if(!isEditable && theOpportunity.Id != null){
            insert new OpportunityShare(OpportunityAccessLevel = 'Edit',
                RowCause = 'Manual', OpportunityId = theOpportunity.Id, UserOrGroupId = userId);
        }
        
        Id samUserId = [SELECT Id, Dealer_Account__r.SAM__c FROM Opportunity WHERE Id = :theOpportunity.Id][0].Dealer_Account__r.SAM__c;
        sharesWithUser = [SELECT Id, UserAccessLevel, RowCause FROM UserShare 
            WHERE UserId = :samUserId AND UserOrGroupId = :userId];
        isEditable = checkSharedWithUser('User', sharesWithUser);
        if(!isEditable && samUserId != null){
            insert new UserShare(UserAccessLevel = 'Edit',
                RowCause = 'Manual', UserId = samUserId, UserOrGroupId = userId);
        }
        return new List<Opportunity>{theOpportunity};
    }

    public static Boolean checkSharedWithUser(String SObjectAPIName, List<SObject> sharesWithUser){
        Boolean isEditable = false;
        if(sharesWithUser.size() > 0){
            for(SObject accShare :sharesWithUser){
                if(accShare.get(SObjectAPIName + 'AccessLevel') == 'Edit'
                || accShare.get(SObjectAPIName + 'AccessLevel') == 'All'){
                    isEditable = true;
                }
            }
        }
        return isEditable;
    }
}
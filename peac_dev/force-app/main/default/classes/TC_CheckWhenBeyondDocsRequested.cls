public class TC_CheckWhenBeyondDocsRequested {
public static void checkWhenBeyondDocsRequested(Map <Id, Opportunity> oldMap,Map<Id, Opportunity> newMap) {
        Set<Id> oppIdSet = new Set<Id>();
        for (Opportunity opp : newMap.values()) {
            if (!opp.Loan_Record_Type__c && opp.StageName != 'Docs Requested' && opp.Probability > 75.0 && opp.Branch__c == 'Commercial Vehicle Group') {
                oppIdSet.add(opp.Id);
            }
        }
        
        List<Asset__c> assetList = new List<Asset__c>();
        if (!oppIdSet.isEmpty()) {
            assetList = new List<Asset__c>([
                SELECT Id, Owner_Operator__c, Opportunity__c
                FROM Asset__c
                WHERE Opportunity__c IN: oppIdSet
            ]);
        }
        
        Map<Id, List<Asset__c>> oppIdAssetMap = new Map<Id, List<Asset__c>>();
        for (Asset__c asset : assetList) {
            if (oppIdAssetMap.containsKey(asset.Opportunity__c)) {
                oppIdAssetMap.get(asset.Opportunity__c).add(asset);
            } else {
                oppIdAssetMap.put(asset.Opportunity__c, new List<Asset__c>{asset});
            }
        }
        
        for (Id oppId : oppIdSet) {
            Boolean throwError = false;
            throwError = newMap.get(oppId).Pricing_Level__c == null || newMap.get(oppId).Lessor__c != 405;
            if (!throwError) {
                List<Profile> profileList = new List<Profile>([SELECT Id, Name FROM Profile WHERE Id=:userinfo.getProfileId()]);
                String userProfileName = profileList[0].Name;
                if (userProfileName != 'Credit Manager') {
                    Boolean assetOwnerOperatorBoolean = false;
                    if (oppIdAssetMap.containsKey(oppId)) {
                        for (Asset__c asset : oppIdAssetMap.get(oppId)) {
                            assetOwnerOperatorBoolean = assetOwnerOperatorBoolean || (asset.Owner_Operator__c != 'No');
                        }
                    }
                    throwError = throwError || assetOwnerOperatorBoolean;
                }
            }
            if (throwError) {
                newMap.get(oppId).addError('If Branch = Commercial Vehicle Group and Opportunity is moving beyond Docs Requested, all' +
                                           ' Asset\'s Owner Operator must equal No (if not a Credit Manager), Lessor Code must equal 405' +
                                           ' and Pricing Level must be non-blank.');
            }
        }
    }
}
public class PEAC_OpportunityTriggerHelper {
    //SAL-5800 : Update Region Code for eplus Opportunity based on the credit branch
    //Check branch type is changed && only need this for lease
    public static void updateEplusOppRegion(List<Opportunity> newList, Map<Id, Opportunity> oldMap) {
        
        Map<String, String> branchTeamToRegionMap = new Map<String, String>();
        for (Branch_Region_Mapping__mdt mapping : [SELECT Branch__c, Region__c
                                                   FROM Branch_Region_Mapping__mdt
                                                   WHERE Branch__c != null AND Region__c != null]) {
                                                       branchTeamToRegionMap.put(mapping.Branch__c, mapping.Region__c);
                                                   }
        
        if(!branchTeamToRegionMap.isEmpty()){
            for (Opportunity opty : newList) {
                if ((oldMap == null || (oldMap.containsKey(opty.Id) && opty.Branch__c != oldMap.get(opty.Id).Branch__c)) &&
                    !String.isBlank(opty.Branch__c) && 
                    PEAC_ConstantClass.OPPORTUNITY_ORIGINATING_BUSINESS_VA_PEAC.equals(opty.Originating_Business__c) &&
                    !System.Label.Loan_Opportunity_Record_Types.contains(opty.RecordTypeId)) {
                        if (branchTeamToRegionMap.containsKey(opty.Branch__c) && branchTeamToRegionMap.get(opty.Branch__c) != null) {
                            opty.Region__c = branchTeamToRegionMap.get(opty.Branch__c);
                        }
                    }
            }
        }
    }
    
    //SAL-5801 : Update LessorCode Code for eplus Opportunity based on the Document Template
    public static void updateEplusOppLessorCode(List<Opportunity> newList, Map<Id, Opportunity> oldMap) {
        Map<String, Decimal> documenttemplateLessorMap = new Map<String, Decimal>();
        for (Document_Template_Lessor_Map__mdt mapping : [SELECT Document_Template__c, Lessor__c 
                                                          FROM Document_Template_Lessor_Map__mdt 
                                                          WHERE Document_Template__c != null AND Lessor__c != null]) {
                                                              documenttemplateLessorMap.put(mapping.Document_Template__c, mapping.Lessor__c);
                                                          }
        
        for (Opportunity opty : newList) {
            if(PEAC_ConstantClass.OPPORTUNITY_ORIGINATING_BUSINESS_VA_PEAC.equals(opty.Originating_Business__c)){
                if ((oldMap == null || (oldMap.containsKey(opty.Id) && opty.Opportunity_Document_Template__c != oldMap.get(opty.Id).Opportunity_Document_Template__c)) &&
                    !String.isBlank(opty.Opportunity_Document_Template__c) && 
                    documenttemplateLessorMap.containsKey(opty.Opportunity_Document_Template__c) &&
                    documenttemplateLessorMap.get(opty.Opportunity_Document_Template__c) != null) {
                        opty.Lessor__c = documenttemplateLessorMap.get(opty.Opportunity_Document_Template__c);
                    }    
            }
        }
    }
    
    //SAL-5802 : Update Branch on Account
    /*public static void updateAccountBranchForVaPeacOpp(List<Opportunity> newList, Map<Id, Opportunity> oldMap) {
Set<Id> accountIds = new Set<Id>();
for (Opportunity opty : newList) {
if ((oldMap == null || opty.Originating_Business__c != oldMap.get(opty.Id).Originating_Business__c) && 
opty.AccountId != null){
accountIds.add(opty.AccountId);
}
}
if (!accountIds.isEmpty()) {
System.enqueueJob(new PEAC_AccountBranchUpdateQueueable(accountIds));
}
}*/
    /*
    public static void validationCheckOnResidualAmount(List<Opportunity> newList, Map<Id, Opportunity> oldMap) {
        
        Set<Id> oppIds = new Set<Id>();
        Map<Id, Opportunity> newById = new Map<Id, Opportunity>();
        
        for (Opportunity o : newList) {
            Opportunity oldO = oldMap.get(o.Id);
            if (oldO != null && o.StageName == 'Booking' && oldO.StageName != 'Booking' && o.Purchase_Options__c == 'FMV') {
                oppIds.add(o.Id);
                newById.put(o.Id, o);
            }
        }
        if (oppIds.isEmpty()) return;    
        for (Opportunity oppQ : [
            SELECT Id,
            (SELECT Name, Residual_Amount__c FROM Assets__r)
            FROM Opportunity
            WHERE Id IN :oppIds]) {
                
                List<Asset__c> assets = oppQ.Assets__r;
                
                if (assets == null || assets.isEmpty()) {
                    newById.get(oppQ.Id).addError('Booking blocked: No related Assets found for FMV opportunity.');
                    continue;
                }    
                List<String> bad = new List<String>();
                for (Asset__c a : assets)
                    if (a.Residual_Amount__c == null || a.Residual_Amount__c <= 1)
                    bad.add(a.Name + ' (Residual=' + String.valueOf(a.Residual_Amount__c) + ')');
                
                if (!bad.isEmpty())
                    newById.get(oppQ.Id).addError(
                        'Booking blocked: Residual Amount must be > 1 for all Assets when Purchase Option = FMV. Fix: ' +
                        String.join(bad, ', ')
                    );
            }
    }  */

    /** SAL-5830 
     * Detects Lease Rate Factor changes and collects Opportunity IDs. 
     * Calls an asynchronous service to update related Assets' rent calculations.
     */
    public static void validateOpportunityLeaseRateFactorChange(List<Opportunity> newList, Map<Id, Opportunity> oldMap){
        Set<Id> oppIds = new Set<Id>();
        for(Opportunity opp : newList){
            Opportunity oldOpp = oldMap.get(opp.Id);
            if(opp.Soft_Lease_Rate_Factor__c != oldOpp.Soft_Lease_Rate_Factor__c ||
               opp.Hard_Lease_Rate_Factor__c != oldOpp.Hard_Lease_Rate_Factor__c){
                   oppIds.add(opp.Id);
               }
        }
        if(!oppIds.isEmpty()){
            PEAC_LeaseCalculationService.updateAssetsFromOpportunityAsync(oppIds);
        }
    }   
}
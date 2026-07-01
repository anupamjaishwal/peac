/************************************************************************************************************************
 @Description: Trigger the T Value calculation when app is approved
 @Author: Rajesh Kumar(LTM)
 @Created Date: 05/19/2026
 @User Story: SAL-7197
 ************************************************************************************************************************/

public class PEAC_PricingAPICall {
    /**************************************************************************************************************
    @Author:Rajesh Kumar(LTM)
    @Description: This method will be called from TC_OpportunityTriggerHandler to Trigger the T Value
					calculation when app is approved
    @User Story:SAL-7197	 
    @Param:New Map of opportunity id with record and old map of opportunity id with record 
    @Created Date:05/19/2026   
    **************************************************************************************************************/
    public static void tValuePricing(Map<Id, Opportunity> newOppsMap,Map<Id, Opportunity> oldOppsMap) {
        // 1. Collect Opps that JUST moved into Proposal stage
        Set<Id> movedToProposalSet = new Set<Id>();

        for (Opportunity newOpp : newOppsMap.values()) {
            Opportunity oldOpp = oldOppsMap.get(newOpp.Id);
			
            if (newOpp.StageName == PEAC_ConstantClass.OPPORTUNITY_STAGENAME_PROPOSAL && oldOpp != null && !newOpp.Loan_Record_Type__c && oldOpp.StageName != newOpp.StageName ) 
            {
                movedToProposalSet.add(newOpp.Id);
            }
        }

        if (movedToProposalSet.isEmpty()) {
            return;
        }

        // 2. Find existing TValue Quotes for these Opps
        Set<Id> oppsWithQuotesSet = new Set<Id>();

        for (tval__TValue_Quote__c quote : [
            SELECT tval__Opportunity__c
            FROM tval__TValue_Quote__c
            WHERE tval__Opportunity__c IN :movedToProposalSet
        ]) {
            oppsWithQuotesSet.add(quote.tval__Opportunity__c);
        }

        // 3. Only Opps WITHOUT TValue Quotes should be priced
        Set<Id> oppsNeedingPricingSet = movedToProposalSet.clone();
        oppsNeedingPricingSet.removeAll(oppsWithQuotesSet);
		
        if (!oppsNeedingPricingSet.isEmpty()) {
            for(Id oppId:oppsNeedingPricingSet)
            {
                NT_CalculatePricingController.validateAndRunPricing(oppId);
            }
            
        }
    }
}
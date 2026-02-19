trigger TC_OppBeneficialOwnerTrigger  on Opportunity_Beneficial_Owner__c (after insert) {
    if (Trigger.isInsert && Trigger.isAfter) {
        TC_OppBeneficialOwnerTriggerHelper.createBeneficialOwners (Trigger.newMap);
    }
}
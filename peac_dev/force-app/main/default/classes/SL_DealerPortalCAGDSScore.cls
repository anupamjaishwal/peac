public without sharing class SL_DealerPortalCAGDSScore {
    @invocableMethod(label='Submit App for GDS Score')
    public static List<Opportunity> submitAppForGDSScore(List<Opportunity> opportunities){
        Opportunity theOpportunity = opportunities[0];
        // Integer personalGuarantors =[SELECT COUNT() FROM Guarantor__c WHERE Opportunity__c =:theOpportunity.Id];
        // if(personalGuarantors > 0){
            System.enqueueJob(new SL_DealerPortalCreateAppQ('callDwhAndAutoPgApi', theOpportunity, false));
        // }else{
        //     System.enqueueJob(new SL_DealerPortalCreateAppQ('lastUpdateToApp', theOpportunity, true));
        // }
        return new List<Opportunity>{theOpportunity};
    }
}
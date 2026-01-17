//date: 5/22/21
// SAL-3089
    public with sharing class TC_OpportunityCustomerTypeDefault{

    // B2B and MarlinNet Apps default the CustomerType = NEW in the Scoring API webservice request sent to GDS
    public static void doAction(Map <Id, Opportunity> oldMap, Map <Id, Opportunity> newMap, List<Opportunity> newList, Boolean isUpdate) {

        List<Opportunity> opps;

        if(newMap != null){
            opps = newMap.values();
        }
        if(newList != null){
            opps = newList;
        }
       

        for (Opportunity opp : opps) {

            String portalUserId = opp.Portal_User_Id__c;

            if (!isUpdate) { 
                if (portalUserId <> null && portalUserId <> 'SF-' && portalUserId <> 'UDA-' && portalUserId <> 'PUDA-') {
                    opp.CustomerType__c = 'NEW';
                }
            } else if (isUpdate) {
                if (portalUserId<> null && portalUserId <> 'SF-' && portalUserId <> 'UDA-' && portalUserId <> 'PUDA-' && oldMap <> null && oldMap?.get(opp.Id)?.Portal_User_Id__c <> portalUserId) {
                    opp.CustomerType__c = 'NEW';
                }
            }
        }
    }

}
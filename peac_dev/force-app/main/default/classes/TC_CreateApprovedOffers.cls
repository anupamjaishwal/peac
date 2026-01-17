public class TC_CreateApprovedOffers {
  public static void createApprovedOffers(Map<Id, Opportunity> oldMap, List<Opportunity> newList) {

        if (TC_RecursiveTriggerHelper.createApprovedOffers) return;

        Set<Id> oppIds = new Set<Id>();
        List<Opportunity> opps = new List<Opportunity>();
        //Set<Id> setPortalOppsNoOffer = new Set<Id>();

        for (Opportunity opp : newList) {
            // https://marlinbusiness.atlassian.net/browse/SAL-1748
            //System.debug(opp.StageName);
            //System.debug(opp.Credit_Risk_Grade__c);
            //System.debug(opp.Loan_Record_Type__c);
            //System.debug(opp.Equipment_Cost__c);
            //System.debug(opp.Purchase_Options__c);
            //System.debug(opp.Lessor__c);
            //System.debug(opp.StageName != oldMap.get(opp.Id).StageName);
            //System.debug(opp.Equipment_Cost__c != oldMap.get(opp.Id).Equipment_Cost__c);
            //System.debug(opp.Purchase_Options__c != oldMap.get(opp.Id).Purchase_Options__c);
            //System.debug((opp.Lessor__c == 421 || opp.Lessor__c == 422 || opp.Lessor__c == 423 || opp.Lessor__c == 424));

            if (criteriaToCreateOffer(opp, oldMap)) {
              //System.debug('add to opps list: ' + opp);
              oppIds.add(opp.Id);
              opps.add(opp);
            }/*else if(isPortalOpp(opp) && opp.StageName == 'Proposal' && !System.isFuture()){
              setPortalOppsNoOffer.add(opp.Id);
            }*/
        }
        //System.debug('Opps Size:' + opps.size());
//        delete [SELECT Id FROM EF_Approved_Offers__c WHERE Opportunity__c IN :oppIds AND RecordType.Name = 'System'];

        if (!opps.isEmpty()){
          TC_RecursiveTriggerHelper.createApprovedOffers = true;
          TC_RateCardRules.createApprovedOffers(opps);
        }
        /*removed the asset trigger is updating multiple times the opp so this will be triggered multiple times.
        else if(!setPortalOppsNoOffer.isEmpty()){
          //Jonathan Munguia added to publish event to be consumed by the SL_DPOffer lwc.
          for(Id oppId :setPortalOppsNoOffer){
            dispatchEventResult('Criteria to Create Offer not matching', 'Success', oppId);
          }
        }*/
    }

  public static void setOfferMadeByDealer(Map<Id, Opportunity> oldMap, List<Opportunity> newList) {
    for (Opportunity opp : newList) {
      if (criteriaToCreateOffer(opp, oldMap) && opp.Dealer_User__c != null) {
        opp.Offer_Made_By__c = 'Dealer';
      }
    }
  }

  private static Boolean criteriaToCreateOffer(Opportunity opp, Map<Id, Opportunity> oldMap){
    return (
            opp.StageName == 'Proposal'
            && (String.isNotEmpty(opp.Credit_Risk_Grade__c)
              || (opp.Lessor__c == 421 || opp.Lessor__c == 422 || opp.Lessor__c == 423 || opp.Lessor__c == 424)
              || isPortalOpp(opp)
            )
            && !opp.Loan_Record_Type__c
            && (opp.StageName != oldMap.get(opp.Id).StageName
              || opp.Equipment_Cost__c != oldMap.get(opp.Id).Equipment_Cost__c
              || (opp.Purchase_Options__c != oldMap.get(opp.Id).Purchase_Options__c)
              || opp.Terms__c != oldMap.get(opp.Id).Terms__c
              || isPortalOpp(opp) && opp.Required_Adv_Payments__c != oldMap.get(opp.Id).Required_Adv_Payments__c)
          );
  }

  public static Boolean isPortalOpp(Opportunity opp){
    return ( opp.Portal_User_ID__c != null && opp.Portal_User_ID__c.containsIgnoreCase('DP-') );
  }

  /*public static void dispatchEventResult(String message, String status, String recordId){
    EventBus.publish( new SL_BW_Integration_Status__e(Message__c = message, Status__c = status, Record_Id__c = recordId));
  }*/
}
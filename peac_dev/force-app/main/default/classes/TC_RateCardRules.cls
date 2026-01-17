public without sharing class TC_RateCardRules {
  private static String FMV_VALUE = 'FMV';

    public static void createApprovedOffers(List<Opportunity> opps) {
      // Rajesh (LTIMindtree)
        if(!system.isBatch()){
          for (Opportunity opp : opps){
       
            createApprovedOffers(opp.Id);
          }  
        }
        
    }

    @Future
    private static void createApprovedOffers(Id objId){
      delete [SELECT Id FROM EF_Approved_Offers__c WHERE Opportunity__c = :objId AND RecordType.Name = 'System'];
      Opportunity opp = [SELECT Id, Terms__c, Max_Term_Approved__c, Purchase_Options__c, Dealer_Account__c, Dealer_User__c, Portal_User_ID__c FROM Opportunity WHERE Id = :objId];

      TCRE.RuleEngine rateCardRE = new TCRE.RuleEngine();
      Set<Id> objIds = new Set<Id>();
      objIds.add(objId);

      rateCardRE.logicObjectIds = objIds;
      rateCardRE.ruleObjectType = 'RateCard__c';
      rateCardRE.TestRuleConditions();

      system.debug('-----------------Rate Card Entry Criteria RESULTS--------------');
      system.debug(rateCardRE.RuleResults);

      Set<Id> trueRateCardIds = new Set<Id>();
      for(Map<Id, Boolean> rule : rateCardRE.RuleResults.values()){
          for(Id ruleId : rule.keySet()){
              if(rule.get(ruleId) == TRUE){
                  trueRateCardIds.add(ruleId);
              }
          }
      }

      system.debug('trueRateCardIds = '  + trueRateCardIds);
    //DP-153 This class must be refactored TBD, updated to include Residual field and Limit the creation of Offers for the single Term chosen on the opp.

      if(trueRateCardIds.size() > 0){
          Set<Id> ruleConfigIds = new Set<Id>();

          for (Rate_Card_Row__c rcr : [SELECT Row_Criteria__c FROM Rate_Card_Row__c WHERE Rate_Card__r.Entry_Criteria__c IN :trueRateCardIds])
              ruleConfigIds.add(rcr.Row_Criteria__c);

          TCRE.RuleEngine rateRowRE = new TCRE.RuleEngine();
          rateRowRE.logicObjectIds = objIds;
          rateRowRE.ruleConfigIds = ruleConfigIds;
          rateRowRE.ruleObjectType = 'Rate_Card_Row__c';
          rateRowRE.TestRuleConditions();

          system.debug('-----------------Rate Card Row Criteria RESULTS--------------');
          system.debug(rateRowRE.RuleResults);

          //find the TRUE row rule
          Set<Id> trueRowIds = new Set<Id>();
          for(Map<Id, Boolean> rule : rateRowRE.RuleResults.values()){
              for(Id ruleId : rule.keySet()){
                  if(rule.get(ruleId) == TRUE){
                      system.debug('TRUE ROW ruleId = '  + ruleId);
                      trueRowIds.add(ruleId);
                  }
              }
          }

          Decimal minEquipmentCost;
          Decimal maxEquipmentCost;

          List<TCRE__Rule_Condition__c> ruleConditions = [Select Id, TCRE__Value__c, TCRE__Operator__c FROM TCRE__Rule_Condition__c WHERE TCRE__Rule_Config__c IN :trueRowIds];

          for (TCRE__Rule_Condition__c ruleCondition : ruleConditions) {
              if (ruleCondition.TCRE__Operator__c == '>') {
                  try {
                      minEquipmentCost = Decimal.valueOf(ruleCondition.TCRE__Value__c);
                  } catch (Exception e) {
                      // Leave null.
                  }
              }

              if (ruleCondition.TCRE__Operator__c == '<=') {
                  try {
                      maxEquipmentCost = Decimal.valueOf(ruleCondition.TCRE__Value__c);
                  } catch (Exception e) {
                      // Leave null.
                  }
              }
          }

          ruleConfigIds = new Set<Id>();

          for (Rate_Card_Column__c rcc : [SELECT Column_Criteria__c FROM Rate_Card_Column__c WHERE Rate_Card__r.Entry_Criteria__c IN :trueRateCardIds])
              ruleConfigIds.add(rcc.Column_Criteria__c);

          TCRE.RuleEngine rateColRE = new TCRE.RuleEngine();
          rateColRE.logicObjectIds = objIds;
          rateColRE.ruleConfigIds = ruleConfigIds;
          rateColRE.ruleObjectType = 'Rate_Card_Column__c';
          rateColRE.TestRuleConditions();

          system.debug('-----------------Rate Card Column Criteria RESULTS--------------');
          system.debug(rateColRE.RuleResults);

          //find the TRUE column rule
          Set<Id> trueColIds = new Set<Id>();
          for(Map<Id, Boolean> rule : rateColRE.RuleResults.values()){
              for(Id ruleId : rule.keySet()){
                  if(rule.get(ruleId) == TRUE){
                      system.debug('TRUE Col ruleId = '  + ruleId);
                      trueColIds.add(ruleId);
                  }
              }
          }

          List<Rate_Card_Rate__c> rates = [
                  SELECT Id, Rate__c, Rate_Card_Column__r.Name
                  FROM Rate_Card_Rate__c
                  WHERE Rate_Card_Row__r.Row_Criteria__c IN :trueRowIds
                  AND Rate_Card_Column__r.Column_Criteria__c IN :trueColIds
          ];

          system.debug('Rates results = ' + rates);

          List<Rate_Card_Rate__c> ratesAllTerms = [
                  SELECT Id, Rate__c, Rate_Card_Column__r.Name, Rate_Card_Column__r.Residual__c
                  FROM Rate_Card_Rate__c
                  WHERE Rate_Card_Row__r.Row_Criteria__c IN :trueRowIds
                  ORDER BY Rate_Card_Column__r.Order__c
          ];

          List<EF_Approved_Offers__c> offers = new List<EF_Approved_Offers__c>();

          //Just create offers for the specified Term, we have to create only offers with the same Term for Portal opps.
          if (rates.size() == 0 && (opp.Dealer_User__c == null && opp.Dealer_Account__c == null)) {
              system.debug('-------------------- TERM NOT FOUND --------------------------');

              Decimal lowTermRate = 0;
              Decimal highTermRate = 0;
              Integer extraMonths = 0;
              
              Decimal lowestTerm;
              Decimal highestTerm;

              for (Rate_Card_Rate__c rcr : ratesAllTerms) {
                  Integer term;

                  try {
                      term = Integer.valueOf(rcr.Rate_Card_Column__r.Name);
                  } catch (Exception e) {
                      // Leave null.
                  }
                  
                  // keep track of highest and lowest terms
                  if (highestTerm == null || Integer.valueOf(rcr.Rate_Card_Column__r.Name) > highestTerm) highestTerm = Integer.valueOf(rcr.Rate_Card_Column__r.Name);
        if (lowestTerm == null || Integer.valueOf(rcr.Rate_Card_Column__r.Name) > lowestTerm) lowestTerm = Integer.valueOf(rcr.Rate_Card_Column__r.Name);
                  
                  if (highTermRate == 0 || opp.Terms__c > Integer.valueOf(rcr.Rate_Card_Column__r.Name)) {
                      highTermRate = rcr.Rate__c;

                      try {
                          extraMonths = Integer.valueOf(opp.Terms__c) - term;
                      } catch (Exception e) {
                          // Leave null.
                      }
                  }

                  if (lowTermRate == 0 && opp.Terms__c < term)
                      lowTermRate = rcr.Rate__c;
              }

              if (lowestTerm >= opp.Terms__c && highestTerm <= opp.Terms__c) {
                  offers.add(new EF_Approved_Offers__c(Opportunity__c = objId,
                      Term_in_Months__c = opp.Terms__c,
                      RecordTypeId = Schema.SObjectType.EF_Approved_Offers__c.getRecordTypeInfosByName().get('System').getRecordTypeId(),
                      Yield__c = TC_Rate.interpolate(highTermRate, lowTermRate, extraMonths),
                      Min_Equipment_Cost__c = minEquipmentCost,
                      Max_Equipment_Cost__c = maxEquipmentCost
              ));
              }

              
          }

          for (Rate_Card_Rate__c rcr : ratesAllTerms) {
              Integer term;

              try {
                  term = Integer.valueOf(rcr.Rate_Card_Column__r.Name);
              } catch (Exception e) {
                  // Leave null.
              }
              if( (
                    (term <= opp.Max_Term_Approved__c || opp.Max_Term_Approved__c == null) && 
                    !TC_CreateApprovedOffers.isPortalOpp(opp)
                  )  ||
                  (
                    term == opp.Terms__c && TC_CreateApprovedOffers.isPortalOpp(opp)
                  )
                ){
                  offers.add(new EF_Approved_Offers__c(Opportunity__c = objId,
                          Term_in_Months__c = term,
                          RecordTypeId = Schema.SObjectType.EF_Approved_Offers__c.getRecordTypeInfosByName().get('System').getRecordTypeId(),
                          Yield__c = rcr.Rate__c,
                          Min_Equipment_Cost__c = minEquipmentCost,
                          Max_Equipment_Cost__c = maxEquipmentCost,
                          //DP-153 Mapping Residual value only for Rates FMV.
                          Residual__c = opp.Purchase_Options__c == FMV_VALUE ? rcr.Rate_Card_Column__r.Residual__c : null,
                          Is_Selected_Offer__c = opp.Dealer_User__c != null ? true : false
                  ));
              }
          }
		insert offers;
        /*String resultMessage = 'EF Offer Future Method.';
        String status = 'Success';
        try {
          insert offers;
        }catch (Exception e) {
          resultMessage = 'An error occurred: ' + e.getMessage();
          status = 'Error';
          System.debug(resultMessage);
        }

        if(TC_CreateApprovedOffers.isPortalOpp(opp)){
          TC_CreateApprovedOffers.dispatchEventResult(resultMessage, status, opp.Id);
        }*/
      }
  }

  
}
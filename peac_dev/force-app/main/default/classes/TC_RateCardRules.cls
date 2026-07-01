public without sharing class TC_RateCardRules {
  private static String FMV_VALUE = 'FMV';

    public static void createApprovedOffers(List<Opportunity> opps) {
        //Rajesh (LTIMindtree)
        
          for (Opportunity opp : opps){
            if(!System.isBatch() && !System.isFuture()){
            createApprovedOffers(opp.Id);
            }else{
                synchronouslyCreateOffers(opp.Id);
            }
          }  
        
        
    }
    // DP-2093 Misael Romero
    public static void synchronouslyCreateOffers(Id objId){
      delete [SELECT Id FROM EF_Approved_Offers__c WHERE Opportunity__c = :objId AND RecordType.Name = 'System'];
        Opportunity opp = [SELECT Id, Terms__c, Lessor__c, Risk_Based_Pricing__c,  Max_Term_Approved__c, Purchase_Options__c, Dealer_Account__c, Dealer_User__c, Portal_User_ID__c FROM Opportunity WHERE Id = :objId];

      SL_RuleEngine rateCardRE = new SL_RuleEngine();// SAL-6028 Misael Romero
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

          SL_RuleEngine rateRowRE = new SL_RuleEngine();// SAL-6028 Misael Romero
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

          SL_RuleEngine rateColRE = new SL_RuleEngine();// SAL-6028 Misael Romero
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
                        (opp.Risk_Based_Pricing__c || opp.Lessor__c == 421 || opp.Lessor__c == 422 || opp.Lessor__c == 423 || opp.Lessor__c == 424)
                        //!opp.Portal_User_ID__c != null && opp.Portal_User_ID__c.containsIgnoreCase('DP-')
                  )  ||
                  (
                    term == opp.Terms__c && TC_CreateApprovedOffers.isPortalOpp(opp)
                  )
                ){
                     
                     Boolean selectedOffer = false;   
                     if(opp.Portal_User_ID__c == 'DP-'){
                        if(opp.Dealer_User__c != null) selectedOffer = true;
                     }
                     else{
                         if(opp.Portal_User_ID__c != 'SF-'){
                            selectedOffer = true;
                         }
                     }

                  offers.add(new EF_Approved_Offers__c(Opportunity__c = objId,
                          Term_in_Months__c = term,
                          RecordTypeId = Schema.SObjectType.EF_Approved_Offers__c.getRecordTypeInfosByName().get('System').getRecordTypeId(),
                          Yield__c = rcr.Rate__c,
                          Min_Equipment_Cost__c = minEquipmentCost,
                          Max_Equipment_Cost__c = maxEquipmentCost,
                          //DP-153 Mapping Residual value only for Rates FMV.
                          Residual__c = opp.Purchase_Options__c == FMV_VALUE ? rcr.Rate_Card_Column__r.Residual__c : null,
                            Is_Selected_Offer__c = selectedOffer
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

    @Future
    public static void createApprovedOffers(Id objId){
      synchronouslyCreateOffers(objId);
    }

  
        public static String rewriteLogic(String logic, Map<Integer, Integer> reindexMap, Set<Integer> deletedPositions) {
        // Tokenize: split into runs of digits vs everything else
        List<String> tokens = new List<String>();
        String current = '';
        Boolean inNum = false;

        for (Integer i = 0; i < logic.length(); i++) {
            String ch = logic.substring(i, i + 1);
            Boolean isDigit = (ch >= '0' && ch <= '9');
            if (isDigit != inNum) {
                if (current != '') tokens.add(current);
                current = ch;
                inNum = isDigit;
            } else {
                current += ch;
            }
        }
        if (current != '') tokens.add(current);

        // Replace number tokens; collect which ones are deleted so we can clean
        // up their adjacent AND/OR connectors in a second pass.
        List<String> replaced = new List<String>();
        for (String tok : tokens) {
            if (tok.isNumeric()) {
                Integer oldN = Integer.valueOf(tok);
                if (deletedPositions.contains(oldN)) {
                    replaced.add('__DELETED__');
                } else if (reindexMap.containsKey(oldN)) {
                    replaced.add(String.valueOf(reindexMap.get(oldN)));
                } else {
                    replaced.add(tok); // unchanged (shouldn't happen in a healthy config)
                }
            } else {
                replaced.add(tok);
            }
        }

        // Join back and clean up orphaned AND/OR operators left by deleted numbers.
        // All regex matches use (?i) flag to handle lowercase and/or/AND/OR.
        String result = String.join(replaced, '');

        // Remove deleted number with its following operator (e.g. "3 AND ", "3 and ", "3 OR ")
        result = result.replaceAll('(?i)__DELETED__\\s+(AND|OR)\\s+', '');
        // Remove deleted number with its preceding operator (e.g. " AND 3", " and 3", " OR 3")
        result = result.replaceAll('(?i)\\s+(AND|OR)\\s+__DELETED__', '');
        // Any lone __DELETED__ still remaining (e.g. only element inside parens)
        result = result.replaceAll('__DELETED__', '');

        // Clean up parens that now contain only operators/spaces (e.g. "( or or )", "( and )")
        // Loop because cleaning one layer may expose another
        String prev = '';
        while (prev != result) {
            prev = result;
            result = result.replaceAll('(?i)\\(\\s*(and\\s+|or\\s+|\\s)*\\)', '');
        }

        // Clean up leading/trailing AND|OR left at the start or end of the full string
        result = result.replaceAll('(?i)^\\s*(AND|OR)\\s+', '');
        result = result.replaceAll('(?i)\\s+(AND|OR)\\s*$', '');

        // Collapse multiple spaces
        result = result.replaceAll('\\s{2,}', ' ').trim();

        return result;
    }
  
}
/**
 * Created by trohweder on 12/16/20.
 */

public with sharing class TC_PossibleOffers {

    private static Map <String, Double> deferralMapping = new Map <String, Double> {'30 days' => 1, '60 days' => 2, '90 days' => 3};

    public static List<PossibleOffer> generatePossibleOffers(Id oppId){

        System.debug('TC_PossibleOffers.generatePossibleOffers');

        Opportunity opp = [SELECT Id, Equipment_Cost__c, Risk_Based_Pricing__c, Credit_Risk_Grade__c, Lessor__c, Points__c, Deferral_Payments__c FROM Opportunity WHERE Id = :oppId];
        System.debug('?>?>?>'+opp);
        TCRE.RuleEngine rateCardRE = new TCRE.RuleEngine();
        Set<Id> objIds = new Set<Id>();
        objIds.add(oppId);

        rateCardRE.logicObjectIds = objIds;
        rateCardRE.ruleObjectType = 'RateCard__c';
        rateCardRE.testRuleConditions();

        System.debug('-----------------Rate Card Entry Criteria RESULTS--------------');
        System.debug(rateCardRE.ruleResults);

        Set<Id> trueRateCardIds = new Set<Id>();
        for (Map<Id, Boolean> rule : rateCardRE.ruleResults.values()) {
            for (Id ruleId : rule.keySet()) {
                if (rule.get(ruleId) == true) {
                    trueRateCardIds.add(ruleId);
                }
            }
        }

        System.debug('trueRateCardIds = ' + trueRateCardIds);

        if (opp.Equipment_Cost__c != null){

            if (trueRateCardIds.size() > 0) {
                Set<Id> ruleConfigIds = new Set<Id>();

                for (Rate_Card_Row__c rcr : [SELECT Row_Criteria__c FROM Rate_Card_Row__c WHERE Rate_Card__r.Entry_Criteria__c IN :trueRateCardIds]){
                    ruleConfigIds.add(rcr.Row_Criteria__c);
                }

                TCRE.RuleEngine rateRowRE = new TCRE.RuleEngine();
                rateRowRE.logicObjectIds = objIds;
                rateRowRE.ruleConfigIds = ruleConfigIds;
                rateRowRE.ruleObjectType = 'Rate_Card_Row__c';
              rateRowRE.testRuleConditions();

                System.debug('-----------------Rate Card Row Criteria RESULTS--------------');
                System.debug(rateRowRE.ruleResults);

                //find the TRUE row rule
                Set<Id> trueRowIds = new Set<Id>();
                for (Map<Id, Boolean> rule : rateRowRE.ruleResults.values()) {
                    for (Id ruleId : rule.keySet()) {
                        if (rule.get(ruleId) == true) {
                            System.debug('TRUE ROW ruleId = ' + ruleId);
                            trueRowIds.add(ruleId);
                        }
                    }
                }

                Decimal minEquipmentCost;
                Decimal maxEquipmentCost;

                List<TCRE__Rule_Condition__c> ruleConditions = [SELECT Id, TCRE__Value__c, TCRE__Operator__c FROM TCRE__Rule_Condition__c WHERE TCRE__Rule_Config__c IN :trueRowIds];

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

                for (Rate_Card_Column__c rcc : [SELECT Column_Criteria__c FROM Rate_Card_Column__c WHERE Rate_Card__r.Entry_Criteria__c IN :trueRateCardIds]){
                    ruleConfigIds.add(rcc.Column_Criteria__c);
                }

                TCRE.RuleEngine rateColRE = new TCRE.RuleEngine();
                rateColRE.logicObjectIds = objIds;
                rateColRE.ruleConfigIds = ruleConfigIds;
                rateColRE.ruleObjectType = 'Rate_Card_Column__c';
                rateColRE.testRuleConditions();

                System.debug('-----------------Rate Card Column Criteria RESULTS--------------');
                System.debug(rateColRE.ruleResults);

                //find the TRUE column rule
                Set<Id> trueColIds = new Set<Id>();
                for (Map<Id, Boolean> rule : rateColRE.ruleResults.values()) {
                    for (Id ruleId : rule.keySet()) {
                        if (rule.get(ruleId) == true) {
                            System.debug('TRUE Col ruleId = ' + ruleId);
                            trueColIds.add(ruleId);
                        }
                    }
                }

                List<Rate_Card_Rate__c> ratesAllTerms = [
                        SELECT Id, Rate__c, Rate_Card_Column__r.Name
                        FROM Rate_Card_Rate__c
                        WHERE Rate_Card_Row__r.Row_Criteria__c IN :trueRowIds
                        ORDER BY Rate_Card_Column__r.Order__c
                ];

                System.debug('Possible rates: ' + ratesAllTerms);

                List<PossibleOffer> offers = new List<PossibleOffer>();

                System.debug('ratesAllTerms' + ratesAllTerms);

                for (Rate_Card_Rate__c rcr : ratesAllTerms) {
                    Integer term;

                    try {
                        term = Integer.valueOf(rcr.Rate_Card_Column__r.Name);
                    } catch (Exception e) {
                        // Leave null.
                    }

                    System.debug('term: ' + term);
                    System.debug('Equip Cost: ' + opp.Equipment_Cost__c);
                    System.debug('Points: ' + opp.Points__c);
                    System.debug('Rate: ' + rcr.Rate__c);
                    System.debug('Deferral: ' + opp.Deferral_Payments__c != null ? opp.Deferral_Payments__c : 'null');

                    Decimal points = opp.Points__c != null ? opp.Points__c : 0;
                    System.debug('points: ' + points);

                    offers.add(new PossibleOffer(term,rcr.Rate__c, opp.Equipment_Cost__c, points, opp.Deferral_Payments__c));
                }
                System.debug('offers: ' + offers);

                return offers;
            }
            System.debug('No True Rate Cards');
        }

        return null;
    }

    // SAL-2602 generate possible offers from an opportunity in memory
    public static List<PossibleOffer> generatePossibleOffersFromOpp(Opportunity opp) {

        System.debug ('TC_PossibleOffers.generatePossibleOffersFromOpp');

        Formula.recalculateFormulas(new List<Opportunity>{opp});

        TCRE.RuleEngine re = new TCRE.RuleEngine();
        re.logicObjects = new List<Opportunity>();
        re.logicObjects.add(opp);
        re.logicObjectType = 'Opportunity';
        re.logicObjectUId = 'Id';
        re.ruleObjectType = 'RateCard__c';

       re.testRuleConditions();

        System.debug('-----------------Rate Card Entry Criteria RESULTS--------------');
        System.debug(re.ruleResultsStr);

        Set<Id> trueRateCardIds = new Set<Id>();
        for (Map<Id, Boolean> rule : re.ruleResultsStr.values()) {
            for (Id ruleId : rule.keySet()) {
                if (rule.get(ruleId) == true) {
                    trueRateCardIds.add(ruleId);
                }
            }
        }

        System.debug('trueRateCardIds = ' + trueRateCardIds);

        if (opp.Equipment_Cost__c != null){

            if (trueRateCardIds.size() > 0) {
                Set<Id> ruleConfigIds = new Set<Id>();

                for (Rate_Card_Row__c rcr : [SELECT Row_Criteria__c FROM Rate_Card_Row__c WHERE Rate_Card__r.Entry_Criteria__c IN :trueRateCardIds]){
                    ruleConfigIds.add(rcr.Row_Criteria__c);
                }

                TCRE.RuleEngine rateRowRE = new TCRE.RuleEngine();
                rateRowRE.logicObjects = new List<Opportunity>();
                rateRowRE.logicObjects.add(opp);
                rateRowRE.logicObjectType = 'Opportunity';
                rateRowRE.logicObjectUId = 'Id';
                rateRowRE.ruleConfigIds = ruleConfigIds;
                rateRowRE.ruleObjectType = 'Rate_Card_Row__c';
               rateRowRE.testRuleConditions();

                System.debug('-----------------Rate Card Row Criteria RESULTS--------------');
                System.debug(rateRowRE.ruleResultsStr);

                //find the TRUE row rule
                Set<Id> trueRowIds = new Set<Id>();
                for (Map<Id, Boolean> rule : rateRowRE.ruleResultsStr.values()) {
                    for (Id ruleId : rule.keySet()) {
                        if (rule.get(ruleId) == true) {
                            System.debug('TRUE ROW ruleId = ' + ruleId);
                            trueRowIds.add(ruleId);
                        }
                    }
                }

                Decimal minEquipmentCost;
                Decimal maxEquipmentCost;

                List<TCRE__Rule_Condition__c> ruleConditions = [SELECT Id, TCRE__Value__c, TCRE__Operator__c FROM TCRE__Rule_Condition__c WHERE TCRE__Rule_Config__c IN :trueRowIds];

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

                for (Rate_Card_Column__c rcc : [SELECT Column_Criteria__c FROM Rate_Card_Column__c WHERE Rate_Card__r.Entry_Criteria__c IN :trueRateCardIds]){
                    ruleConfigIds.add(rcc.Column_Criteria__c);
                }

                TCRE.RuleEngine rateColRE = new TCRE.RuleEngine();
                rateColRE.logicObjects = new List<Opportunity>();
                rateColRE.logicObjects.add(opp);
                rateColRE.logicObjectType = 'Opportunity';
                rateColRE.logicObjectUId = 'Id';
                rateColRE.ruleConfigIds = ruleConfigIds;
                rateColRE.ruleObjectType = 'Rate_Card_Column__c';
                rateColRE.testRuleConditions();

                System.debug('-----------------Rate Card Column Criteria RESULTS--------------');
                System.debug(rateColRE.ruleResults);

                //find the TRUE column rule
                Set<Id> trueColIds = new Set<Id>();
                for (Map<Id, Boolean> rule : rateColRE.ruleResults.values()) {
                    for (Id ruleId : rule.keySet()) {
                        if (rule.get(ruleId) == true) {
                            System.debug('TRUE Col ruleId = ' + ruleId);
                            trueColIds.add(ruleId);
                        }
                    }
                }

                List<Rate_Card_Rate__c> ratesAllTerms = [
                        SELECT Id, Rate__c, Rate_Card_Column__r.Name
                        FROM Rate_Card_Rate__c
                        WHERE Rate_Card_Row__r.Row_Criteria__c IN :trueRowIds
                        ORDER BY Rate_Card_Column__r.Order__c
                ];

                System.debug('Possible rates: ' + ratesAllTerms);

                List<PossibleOffer> offers = new List<PossibleOffer>();

                System.debug('ratesAllTerms' + ratesAllTerms);

                for (Rate_Card_Rate__c rcr : ratesAllTerms) {
                    Integer term;

                    try {
                        term = Integer.valueOf(rcr.Rate_Card_Column__r.Name);
                    } catch (Exception e) {
                        // Leave null.
                    }

                    System.debug('term: ' + term);
                    System.debug('Equip Cost: ' + opp.Equipment_Cost__c);
                    System.debug('Points: ' + opp.Points__c);
                    System.debug('Rate: ' + rcr.Rate__c);
                    System.debug('Deferral: ' + opp.Deferral_Payments__c != null ? opp.Deferral_Payments__c : 'null');

                    Decimal points = opp.Points__c != null ? opp.Points__c : 0;
                    System.debug('points: ' + points);

                    offers.add(new PossibleOffer(term,rcr.Rate__c, opp.Equipment_Cost__c, points, opp.Deferral_Payments__c));
                }
                System.debug('offers: ' + offers);

                return offers;
            }
            System.debug('No True Rate Cards');
        }

        return null;
    }

    public class PossibleOffer{
        //This class is meant to be an object that can be returned showing possible offers on an Opportunity
        @AuraEnabled
        public Integer Term;
        @AuraEnabled
        public Double Yield;
        @AuraEnabled
        public Decimal MonthlyPayment;
        @AuraEnabled
        public Decimal EquipmentCost;
        @AuraEnabled
        public Decimal Points;
        @AuraEnabled
        public Decimal RateFactor;
        
        
        public PossibleOffer(Integer term, Decimal yield, Decimal equipmentCost, Decimal points, String deferralString){
            //Constructor of PossibleOffer object that will calculate the payment and rate factor of possible offers
            this.Term = term;
            this.Yield = yield;
            this.EquipmentCost = equipmentCost;
            this.Points = points;
            Double deferral = deferralString != null ? TC_PossibleOffers.deferralMapping.get (deferralString) : 0;
            this.RateFactor = Decimal.valueOf(Math.pow((1+this.Yield/100/12),deferral)*(this.Yield/100/12)/(1-Math.pow((1+(this.Yield/100/12)),-this.Term))).setScale(8);
            this.MonthlyPayment = (this.EquipmentCost*(1+this.Points/100)*this.RateFactor).setScale(2);

        }

    }
}
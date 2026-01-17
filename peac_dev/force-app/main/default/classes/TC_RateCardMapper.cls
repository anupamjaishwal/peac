/** @author : Northteq Consulting, Inc.
 * @date : 10/30/20
 * @description: Mapper class
 *
 */
public with sharing class TC_RateCardMapper {

    /**
     * Map the request bean account fields
     *
     * @param acc the parent account of the rate cards
     * @param req the request bean containing account fields
     */
    public static void mapAccountFields(Account acc, TC_RateCardRequestBean req) {

        acc.Account_Months_In_Business__c = req.timeInBusiness;
    }

    /**
     * Map the request bean opportunity fields
     *
     * @param opp the parent opportunity of the rate cards
     * @param req the request bean containing opportunity fields
     */
    public static void mapOpportunityFields(Opportunity opp, TC_RateCardRequestBean req) {

        opp.Credit_Risk_Grade__c = req.riskGrade;
        opp.Equipment_Cost__c = req.equipmentCost;
        opp.RBP_Webservice__c = req.riskBasedPricing;
    }

    /**
     * Map the rate card fields to the response bean given a list of possible offers
     *
     * @param possibleOffers a list of possible offers (rate cards)
     * @return a response bean
     */
    public static TC_RateCardResponseBean mapRateCardFields(List<TC_PossibleOffers.PossibleOffer> possibleOffers) {

        TC_RateCardResponseBean bean = new TC_RateCardResponseBean();

        if (possibleOffers <> null) {
            for (TC_PossibleOffers.PossibleOffer offer : possibleOffers) {
                TC_RateCardResponseBean.Response rc = new TC_RateCardResponseBean.Response();
                rc.yield = offer.Yield;
                rc.term = offer.Term;
                bean.rows.add(rc);
            }
        }

        return bean;
    }
}
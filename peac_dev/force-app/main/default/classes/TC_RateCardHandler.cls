/** @author : Northteq Consulting, Inc.
 * @date : 10/30/20
 * @description: Handles the process of generating rate cards
 *
 */
public with sharing class TC_RateCardHandler {

    public static TC_RateCardResponseBean findRateCards(TC_RateCardRequestBean req) {

        // Create a dummy opportunity that persists only in memory
        Account acc = [SELECT Id, Name FROM Account WHERE Name = 'STATIC ACCOUNT FOR RATE CARDS'];
        Opportunity opp = TC_SobjectRecordFactory.createOpportunity(acc);
        TC_RateCardMapper.mapOpportunityFields(opp, req);

        // Generate the possible offers from the dummy opportunity and return them as rate cards
        List<TC_PossibleOffers.PossibleOffer> possibleOffers = TC_PossibleOffers.generatePossibleOffersFromOpp(opp);
        TC_RateCardResponseBean resp = TC_RateCardMapper.mapRateCardFields(possibleOffers);

        return resp;
    }
}
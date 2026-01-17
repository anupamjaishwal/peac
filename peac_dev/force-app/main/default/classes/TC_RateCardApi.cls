/** @author : Northteq Consulting, Inc.
 * @date : 10/27/20
 * @description: SAL-1830 New Webservice For Digital Portal Access to Rate Cards (GC)
 *
 * 1. Take as entered criteria a JSON-structured format that will return a set of rate cards that match with
 * the given criteria.
 * 2. For each entered criteria, match to a given rate card *using the existing rules engine* as if an
 * opportunity of the same criteria were doing so
 * 3. Return a rate card with those values.
 *
    JSON request format:
    {
    "Branch": <STRING> ,
    "Risk Grade": <STRING> ,
    "Equipment Cost":NUMBER ,
    "Time In Business":NUMBER,
    .Other Fields Needed?
    }

    Sample request:
    {
    "Branch": "Retail" ,
    "Risk Grade": "B2" ,
    "Equipment Cost":43455.76,
    "Time In Business":NULL
    }

    JSON response format:
    { rows: [
    "Term":NUMBER,
    "Yield":NUMBER ]
    }

    Sample response:
    {
    "rows" : [
    { "Term": 24,
    "Yield": 16.50 },
    { "Term": 36,
    "Yield": 14.40},
    { "Term": 39,
    "Yield": 13.78 },
    { "Term": 48,
    "Yield": 13.15 },
    { "Term": 60,
    "Yield": 12.05 } ]
    }
 *
 * POST Endpoint: https://marlin--uat1.my.salesforce.com/services/apexrest/getRateCards
 *
 * Entry criteria for generating rate cards:

    Stage = Proposal
    On stage change
    Or Equipment cost change
    Or purchase options change for lessor = 421 to 424

    Rate card generation is done asynchronously
 *
 */
@RestResource(UrlMapping='/getRateCards/*')
global with sharing class TC_RateCardApi {

    @HttpPost
    global static void findRateCards() {

        RestRequest request = RestContext.request;

        TC_RateCardRequestBean req = (TC_RateCardRequestBean) JSON.deserialize(request.requestBody.toString(), TC_RateCardRequestBean.class);

        TC_RateCardResponseBean resp = TC_RateCardHandler.findRateCards(req);

        RestResponse response = RestContext.response;
        if (response == null) {
            response = new RestResponse();
            RestContext.response = response;
        }
        response.responseBody = Blob.valueOf(JSON.serialize(resp));
        response.statusCode = 200;
    }
}
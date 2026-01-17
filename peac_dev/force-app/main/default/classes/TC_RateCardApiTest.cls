/** @author : Northteq Consulting, Inc.
 * @date : 10/27/20
 * @description: SAL-1830 New Webservice For Digital Portal Access to Rate Cards (GC)
 *
 * Test class for TC_RateCardApi
 */

@IsTest
private class TC_RateCardApiTest {

    @TestSetup
    static void setup() {

        String username = 'standardusertest123@northteq.com';

        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        User u = new User(Alias = 'testuser', Email = 'sfdc@northteq.com', EmailEncodingKey='UTF-8',
                LastName = 'testing', FirstName = 'user', LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US', ProfileId = p.Id, TimeZoneSidKey = 'America/Los_Angeles',
                Username = username, Doc_Fee_Exception_Approver__c = true);
        insert u;
        
        Account acc = new Account (Name = 'STATIC ACCOUNT FOR RATE CARDS',
                RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Franchisee Account').getRecordTypeId(),
                Business_Address__c = 'test', Business_City__c = 'test', Business_State__c = 'MN', Business_Zip__c = '11111');
        insert acc;
    }

    @IsTest
    static void testFindRateCards() {

        User u = [SELECT Id FROM User WHERE Username = 'standardusertest123@northteq.com'];

        System.runAs(u) {

            RestRequest request = new RestRequest();
            request.requestURI = Url.getOrgDomainUrl().toExternalForm() + '/services/apexrest/getRateCards';
            request.httpMethod = 'POST';
            request.addHeader('Content-Type', 'application/json');

            String body = '{' +
                    '"Branch":"Direct - End User",' +
                    '"RiskGrade":"B2",' +
                    '"EquipmentCost":43455.76,' +
                    '"TimeInBusiness":5,' +
                    '"RiskBasedPricing":true' +
                    '}';

            request.requestBody = Blob.valueOf(body);
            RestContext.request = request;

            TC_RateCardApi.findRateCards();

            System.debug('testCreateRateCards response: ' + RestContext.response);
        }
    }

    @IsTest
    static void testRateCardMapper() {

        User u = [SELECT Id FROM User WHERE Username = 'standardusertest123@northteq.com'];

        System.runAs(u) {

            Test.startTest();

            TC_RateCardRequestBean bean = new TC_RateCardRequestBean();
            bean.branch = 'Direct - End User';
            bean.riskGrade = 'B2';
            bean.equipmentCost = 43455.76;
            bean.timeInBusiness = 5;
            bean.riskBasedPricing = true;

            Account acc = TC_SobjectRecordFactory.createAccount(bean);
            TC_RateCardMapper.mapAccountFields(acc, bean);
            insert acc;

            Opportunity opp = TC_SobjectRecordFactory.createOpportunity(acc);
            TC_RateCardMapper.mapOpportunityFields(opp, bean);
            insert opp;

            Test.stopTest();

            List<TC_PossibleOffers.PossibleOffer> rateCards = TC_PossibleOffers.generatePossibleOffersFromOpp(opp);
            TC_RateCardResponseBean resp = TC_RateCardMapper.mapRateCardFields(rateCards);
            System.debug('testRateCardMapper response: ' + JSON.serialize(resp));
        }
    }

    @IsTest
    static void testRequestBean() {
        TC_RateCardRequestBean bean = new TC_RateCardRequestBean();
    }

    @IsTest
    static void testMapRateCardFields() {

        List<TC_PossibleOffers.PossibleOffer> possibleOffers = new List<TC_PossibleOffers.PossibleOffer>();
        possibleOffers.add(new TC_PossibleOffers.PossibleOffer(24,16,50000,36,null));
        TC_RateCardMapper.mapRateCardFields(possibleOffers);
    }
}
@isTest
public with sharing class SL_DnBCalloutTest {
    @isTest
    public static void companyTypeaheadSearch() {
        SL_SCTestData.createDnBCredentials();
        String result1 = '';
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new dnBMock());
        SL_DnBCallout.accessToken = 'expiredForTesting';
        SL_DnBCallout.callSearch('Zeltiq', '');
        result1 = SL_DnBCallout.accessToken;
        SL_DnBCallout.callSearch('Zeltiq', '');
        SL_DnBCallout.callSearch('Zeltiq', 'cookieToken1');
        Test.stopTest();
        System.Assert.isFalse(result1 == '', 'accessToken was not assigned.');
    }
    
    @isTest
    public static void phoneSearch(){
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new dnBMock());
        String testRes = SL_DnBCallout.searchPhone('000000000');
        Test.stopTest();
    }

    public class dnBMock implements HttpCalloutMock {

        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setHeader('Content-Type', 'application/json');
            if(req.getHeader('Authorization') == 'Bearer cookieToken1'){
                res.setStatusCode(501);
            }else{
                res.setStatusCode(200);
            }
            if(req.getEndpoint().contains('v2/token')){
                res.setBody('{"access_token":"55os9OJ8390gtuQwy70761ste1vI","expiresIn":86400}');
            }else{
                if(req.getEndpoint().contains('v1/search/typeahead?searchTerm=')){
                    res.setBody('{"transactionDetail": {"transactionID": "rrt-0162cf1552a826c4b-d-ea-22079-118379925-23",'
                        + '"transactionTimestamp": "2023-07-21T14:52:22.657Z","inLanguage": "en-US","serviceVersion": "1"'
                        + '},"inquiryDetail": {"countryISOAlpha2Code": "US","searchTerm": "Zeltiq"},"candidatesReturnedQuantity": 10,'
                        + '"candidatesMatchedQuantity": 12,"searchCandidates": [{"displaySequence": 1,"organization": {'
                        + '"duns": "809152916","dunsControlStatus": {"isOutOfBusiness": false},"primaryName": "Zeltiq Aesthetics, Inc.",'
                        + '"primaryAddress": {"addressCountry": {"isoAlpha2Code": "US"},"streetAddress": {"line1": "4410 Rosewood Dr"'
                        + '},"addressLocality": {"name": "Pleasanton"},"addressRegion": {"name": "California"},"postalCode": "94588-3050"'
                        + '},"corporateLinkage": {"isBranch": false,"globalUltimate": {"duns": "078458370","primaryName": "Abbvie Inc."'
                        + '}},"financials": [{"yearlyRevenue": [{"value": 1.64845015E8,"currency": "USD"}]}],"tradeStyleNames": ['
                        + '{"name": "CoolSculpting","priority": 1}],"primaryIndustryCodes": [{"usSicV4": "3841",'
                        + '"usSicV4Description": "Mfg surgical/medical instruments"}]}}]}');
                }else{
                    if(req.getEndpoint().contains('v1/search/criteria')){
                        res.setBody('{"searchCandidates": [{"organization": {"telephone": [{ "telephoneNumber": "9046486350", "isdCode": "1" }]}}]}');
                    }
                }
            }
            
            return res;
        }
    }
    
        @isTest
    public static void CCANSearch(){
        SL_SCTestData.createAccountAndContracts(1, 1);
        
        Account acc = [SELECT Id, CCAN__c FROM Account LIMIT 1];
        
        Test.startTest();
		List<Account> ccanAcc = SL_DnBCallout.searchByCCAN(acc.CCAN__c);
        Test.stopTest();
        
		System.Assert(ccanAcc.size() > 0, 'Account not found.');

    }
}
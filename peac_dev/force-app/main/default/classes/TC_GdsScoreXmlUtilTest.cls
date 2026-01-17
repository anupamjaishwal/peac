@isTest
public class TC_GdsScoreXmlUtilTest {
@isTest 
    public static void runTest(){
        TC_GDSScoreReqRespBean bean=TestDataFactory.createGDSScoreReqResBean();
        Account acc = TestDataFactory.createTestAccount();
        Opportunity opp = TestDataFactory.createTestOpp(acc.Id);
        Test.startTest();
        bean.opp = opp;
        TC_GdsScoreXmlUtil.serializeMatchingNode(bean);
        TC_GdsScoreXmlUtil.serializeRequest(bean);
        
        String body=TestDataFactory.createGDSScoreReqResXMLResponse();
        
        TC_GdsScoreXmlUtil.deSerializeResponse(bean, body);
        System.assertEquals('12345',bean.company1.EBFILENUMBER__c);
        Test.stopTest();
    }
}
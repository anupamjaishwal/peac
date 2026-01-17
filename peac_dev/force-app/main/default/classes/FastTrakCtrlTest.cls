@isTest
public class FastTrakCtrlTest {

    //// Start: Test class to cover codcoverage for decommision(SAL-4149) class-By Raja Sirivella
   static testmethod void test1(){
        Test.startTest();

       FastTrakCtrl cs = new FastTrakCtrl();
       cs.FastTrakCtrl('test');

        Test.stopTest();
    }
}
  ////End by:Raja Sirivella


// From here old code 


    /*private class RestMock implements HttpCalloutMock {

        public HTTPResponse respond(HTTPRequest req) {
            String fullJson = 'your Json Response';

            HTTPResponse res = new HTTPResponse();
            res.setHeader('Content-Type', 'text/json');
            res.setBody(fullJson);
            res.setStatusCode(200);
            return res;
        }
    }
    static testmethod void test1(){
        Test.setMock(HttpCalloutMock.class, new RestMock());
        Test.startTest();
        FastTrakCtrl.makeCallout('sfdc@northteq.com','0033J00000JUlnWQAT','4444470','1111117');
        Test.stopTest();
    }
} */
@isTest
private class BriteVerifyAPITest {
     @isTest static void testCallout() {
        // Set mock callout class 
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        BriteVerifyResponse responseBean = BriteVerifyAPI.verifyEmail('test@test.com');
    }
}
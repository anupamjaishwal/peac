@isTest public class TC_LeadConversionSettingsServiceTest {
	
    static testmethod void autoLeadConversionTest () {

        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('LeadMappingMockTest');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'text/xml');
        mock.setHeader('SOAPAction', 'test');
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, mock);
        TC_LeadMappingToCustMetadata.updateMetadata ();
        Test.stopTest();
    }
}
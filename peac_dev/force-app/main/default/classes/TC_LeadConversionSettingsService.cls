public class TC_LeadConversionSettingsService {
	
    public static List <TC_LeadConversionSetting> sendLeadConversionSettingsRequest () {
        List <StaticResource> sr = new List <StaticResource> ([SELECT Id, Body FROM StaticResource WHERE Name = 'LeadConversionRequestXML']);
        String xmlBody = '';
        if (!sr.isEmpty()) {
            xmlBody = sr[0].Body.toString();
        }
        
        xmlBody = xmlBody.replace('iiiii', getSessionIdFromVFPage ());
        HttpRequest httpReq = new HttpRequest ();
        httpReq.setMethod ('POST');
        httpReq.setHeader ('Content-Type', 'text/xml');
        httpReq.setEndpoint (Label.Standard_Lead_Mapping_Soap_Endpoint); // make custom setting
        httpReq.setBody (xmlBody);
        // need to throw any value into the soap action for some reason
        httpReq.setHeader ('SOAPAction', 'test');

        HttpResponse httpResp = new HttpResponse ();
        Http http = new Http ();
        
        try {
            httpResp = http.send (httpReq);
        } catch (Exception e) {
            System.debug ('Error during request: ' + e);
        }
        
        List <TC_LeadConversionSetting> cSettings = new List <TC_LeadConversionSetting> ();
        
        try {
            cSettings = TC_LeadConversionSettingsMapper.parseResponse (httpResp.getBody());
        } catch (Exception e) {
            System.debug ('Error during response parse: ' + e);
        }
        System.debug ('xxxxx cSettings:' + cSettings);
        return cSettings;
    }
    
    // cant get session id from async context
    public static String getSessionIdFromVFPage () {
        if (Test.isRunningTest()) {
            return 'test';
        } else {
            String content = Page.TC_SessionId.getContent().toString();
            Integer s = content.indexOf('Start_Of_Session_Id') + 'Start_Of_Session_Id'.length(), e = content.indexOf('End_Of_Session_Id');
        	return content.substring(s, e);
        }
        
        
    }
}
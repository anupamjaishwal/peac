/////////////////////////////////////////////
public with sharing class xctDataClass {
    @future(callout=true)
    public static void makeCallout(String resourceName, String Id, String status, String xmlContent) {
    
        List<String> fillers = new String[]{resourceName, Id, status, xmlContent};
        System.debug( String.format('Called: makeCallout({0},{1},{2},{3})', fillers) );
        
        xmlContent = xmlContent.escapeJava();
        
        SLIntegration__c settings = SLIntegration__c.getInstance('SLINTEGRATE');
        String siteID = '';
        String endpoint = '';
        String authorization = '';
        String certName = '';
        siteID = '';
        endpoint = '';
        authorization = '';
        certName = '';
       
        try
        {
            siteID      = settings.SLSiteID__c;
        }
        catch(Exception e){}
        try
        {
            endpoint = settings.SLIntegrationEndpoint__c + resourceName;    
        }
        catch(Exception e){}
        try
        {
            authorization = settings.SLAuthorization__c;    
        }
        catch(Exception e){}
        try
        {
            certName = settings.CertName__c;    
        }
        catch(Exception e){}
        
        if ( !String.isBlank(siteID) && siteID != '' ) {
        
            Integer Retry = 8;
        
            while ( Retry > 0) {
            
                HttpRequest request = new HttpRequest();
                if ( !String.isBlank(certName) && certName != '' ) {
                    request.setClientCertificateName(certName);
                }

                request.setMethod('POST');
                request.setHeader('Authorization','Basic ' + authorization);
                request.setHeader('SiteID',siteID);
                
                // Set the endpoint URL.
                request.setEndPoint(endpoint);
        
                request.setBody('{"itemType":"'+resourceName+'","itemID":"'+Id+ '","status":"' + status + '","xmlContent":"' + xmlContent+ '"}');
                // request.setCompressed(true);
                
            
                HttpResponse response; 
                try {
                   // Send the HTTP request and get the response.
                        System.debug('Header: ' + request.toString());
                  response = new HTTP().send(request);
                   
                   System.debug('creatLog0 ');
                   if ( response.getStatusCode() == 200) { 
                       Retry = 0; 
                       // Log the XML content
                       xctSLLogging.creatLog('makeCallout', resourceName, Id, request.getBody(), response.getBody());
                      }
                   else {
                       // Log the XML content
                       System.debug('Request: ' + request.getBody());
                        System.debug('Response: ' + response.toString());                  
                       xctSLLogging.creatLog('makeCallout', resourceName, Id, request.getBody(), response.toString());
                       }
                   System.debug('creatLog1 ' + string.valueof(Retry));
                   
                   
                }  catch(Exception e) {
                
                   System.debug('creatLog2 ');
                   if (!Test.isRunningTest()) {
                       xctSLLogging.creatLog('makeCallout', resourceName, Id, request.getBody(), 'Callout error:('+ e + ')');
                       Retry -= 1;
                   }
                   else {
                       Retry = -1;
                   }
                   System.debug('creatLog3 ' + string.valueof(Retry));
                  
                }
                
            }
        }
        else {
            System.debug('Calls turned off: ' + xmlContent);
        }
        
    }
   
}
/////////////////////////////////////////////
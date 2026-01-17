@isTest
public class xct_Solomon {
    @isTest static void xctSolomonBaseTest() {
        System.debug ('<<<<< xctDataClassTest');
        // Test data setup
        
        // Perform test
        Test.startTest();
            System.debug ('<<<<< right before xctDataClass.makeCallout');
                SLIntegration__c SLI = new SLIntegration__c(Name='SLINTEGRATE',SLSiteID__c='TEST', SLAuthorization__c='QVBJS0VZMTpBRTRFM0Q0MEJFRTU0NjA0QUI0QTgzRkFGQzMzRjJDQg==', SLIntegrationEndpoint__c='https://dsliis.asu-nvg.com/ctIntegrator/api/integration/ctQueue/');
                insert SLI;
                xctDataClass.makeCallout('SFDATA', 'DUMMYID', 'TEST', 'XMLContentField');
            System.debug ('<<<<< right afterCall');
            System.debug ('<<<<< right before xctSLLogging.creatLog');
                xctSLLogging.creatLog('makeCallout', 'SFDATA', 'TEST', 'TEST');
            System.debug ('<<<<< right afterCall');
            
            System.debug ('<<<<< right before sf2SLLogs');
                 SF2SLLog__c obj = new SF2SLLog__c(CreateDate__c=System.today(), LogType__c='TEST');
                 insert obj;
        
                 PageReference pageRef = Page.SF2SLLog1;
                 Test.setCurrentPage(pageRef);
                 ApexPages.StandardController sc = new ApexPages.StandardController(obj);
                 xctSF2SLLogs testPlan = new xctSF2SLLogs(sc);
                 testPlan.clearSF2SLLogs();
                
                     System.debug ('<<<<< right afterCall');
           
        Test.stopTest();
       
    }
    
}
public class TC_TrustPilotAPI {
	
    // called from trigger, bulkified
    public static void generateInvitations (Set <Id> oppIds) {

        TC_TrustPilotService service = new TC_TrustPilotService ();
        List <Opportunity> updateList = new List <Opportunity> ();
        service.loadAccessToken();
        
        List <TC_TrustPilotInvRequestBean> reqBeans = TC_TrustPilotInvMapper.createRequests (oppIds);

        for (TC_TrustPilotInvRequestBean reqBean : reqBeans) {
            String url = service.generateInvitation(reqBean);
            if (url != null) updateList.add (new Opportunity (Id = reqBean.oppId, Trustpilot__c = url));
        }
        
        if (!updateList.isEmpty ()) update updateList;
        MARLIN_IntegrationLog.insertLogs ();
    }
    
    
      public static void generateInvitationsForDocsIn (Set <Id> oppIds) {

        TC_TrustPilotService service = new TC_TrustPilotService ();
        List <Opportunity> updateList = new List <Opportunity> ();
        service.loadAccessToken();
        
        List <TC_TrustPilotInvRequestBean> reqBeans = TC_TrustPilotInvMapper.createRequests (oppIds);

        for (TC_TrustPilotInvRequestBean reqBean : reqBeans) {
            String url = service.generateInvitation(reqBean);
            if (url != null) updateList.add (new Opportunity (Id = reqBean.oppId, Dealer_Trustpilot_Link__c = url));
        }
        
        if (!updateList.isEmpty ()) update updateList;
        MARLIN_IntegrationLog.insertLogs ();
    }
    
    // incase for use for one offs
    public static void generateInvitation (Id oppId) {
        generateInvitations (new Set <Id> {oppId});
    }
    
    // incase for use for one offs
    public static void generateInvitationForDocsIn (Id oppId) {
        generateInvitationsForDocsIn (new Set <Id> {oppId}); 
    }
    
}
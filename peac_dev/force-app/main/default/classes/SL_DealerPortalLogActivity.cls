public without sharing class SL_DealerPortalLogActivity {

    @invocableMethod(label='Save Dealer Portal Activity')
    public static void saveActivityLogDP(List<FlowInput> inputs){
        FlowInput input = inputs[0];
        List<String> fromEventStream = new List<String>{'Export Report'};
        Map<String,String> currentSession = null;
        String si = null;
        Id userId = null;
        if(!fromEventStream.contains(input.actionType)){
            if(!Test.isRunningTest() && !System.isQueueable()){
                currentSession = Auth.SessionManagement.getCurrentSession();
            }
            si = currentSession?.get('SessionId');
            userId = currentSession?.get('UsersId');
        }else{
            userId = input.actualU;
        }
        // Dealer_Portal_Activity__c dpa = new Dealer_Portal_Activity__c();
        User delegatedUser;

        Boolean isDe = false;
        List<AuthSession> aSession;
        if((currentSession != null && currentSession.get('LoginHistoryId')==null)
        || (currentSession == null && input.loginHistoryId == null)){
            isDe=true;
        }
        List<User> ul = [SELECT Id, Name, AccountId FROM User WHERE Id = :userId];
        User realUser = ul.size() == 1? ul[0]: new User();
        if(isDe){ 
            // Map<Id, Dealer_Portal_Activity__c> du = new Map<Id, Dealer_Portal_Activity__c>();
            if(si != null){
                aSession = [SELECT Id, CreatedDate, LastModifiedDate, ParentId, Users.Name
                    FROM AuthSession
                    WHERE Id = :si LIMIT 1];
            }else{
                aSession = [SELECT Id, CreatedDate, LastModifiedDate, ParentId, Users.Name
                    FROM AuthSession
                    WHERE UsersId = :userId AND ParentId != null AND LoginHistoryId = null ORDER BY CreatedDate DESC LIMIT 10];
            }
            if(aSession.size() > 0){
                aSession = [SELECT Id, CreatedDate, LastModifiedDate, ParentId, Users.Name
                    FROM AuthSession
                    WHERE  Id = :aSession[0].ParentId LIMIT 1];
            }
            if(aSession.size() == 1){
                delegatedUser = aSession[0].Users;
            }       
        }
        // if(delegatedUser != null)dpa.Delegated_User__c = delegatedUser.Id;
        // dpa.Session_Key__c = si;
        // dpa.Type__c = input.actionType;

        // switch on input.actionType {
        //     when 'Create Application' {
        //         Opportunity opp = [SELECT Id, Name FROM Opportunity WHERE Id = :input.recordId];
        //         dpa.Opportunity__c = opp.Id;
        //         dpa.Details__c = 'Application ' + opp.Name + ' created';
        //     }
        //     when 'Create Buyouts' {
        //         Contract__c con = [SELECT ID, NAME FROM Contract__c WHERE ID = :input.recordId];
        //         dpa.Contract__c = con.Id;
        //         dpa.Details__c = 'Buyouts generated for ' + con.Name;
        //     }
        //     when 'Export Report' {
        //         dpa.Details__c = input.details;
        //         dpa.Session_Key__c = input.sessionKey != null? input.sessionKey: si;
        //     }
        //     when 'Generate Documents' {
        //         Opportunity opp = [SELECT Id, Name FROM Opportunity WHERE Id = :input.recordId];
        //         dpa.Opportunity__c = opp.Id;
        //         dpa.Details__c = 'Documents Generated for Application ' + opp.Name;
        //     }
        //     when 'Upload Meter Reads' {
        //         dpa.Details__c = 'Meter Reads Uploaded for dealer Number ' + input.recordId;
        //     }
        // }
        // dpa.User__c = userId;
        // dpa.Dealer_Account__c = realUser.AccountId;
        
        // insert dpa;
    }

    public class FlowInput{

        @InvocableVariable
        public String actionType;
        @InvocableVariable
        public String recordId;
        @InvocableVariable
        public String details;
        @InvocableVariable
        public String sessionKey;
        @InvocableVariable
        public String delegated;
        @InvocableVariable
        public String actualU;
        @InvocableVariable
        public String loginHistoryId;
    }

    @AuraEnabled
    public static void runFromLWC(String actionType, String recordId) {
        FlowInput input = new FlowInput();
        input.actionType = actionType;
        input.recordId = recordId;

        // reutilizas la lógica
        saveActivityLogDP(new List<FlowInput>{ input });
    }
}
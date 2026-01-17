public class TC_DocsOut {
    public static void docsOut (Map <Id, Opportunity> oldMap, Map <Id, Opportunity> newMap) {
            
        for (Opportunity opp : newMap.values()) {
            if ((opp.Opportunity_CurrentUser_Profile__c == 'CMS' || opp.Opportunity_CurrentUser_Profile__c == 'User MarlinDocusign')
                && opp.Docs_Out__c != null && oldMap.get (opp.Id).Docs_Out__c == null) {
                    opp.StageName = 'Docs Out';
            }
        }
    }
}
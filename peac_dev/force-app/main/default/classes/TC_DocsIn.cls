public class TC_DocsIn {
    public static void docsIn (Map <Id, Opportunity> oldMap, Map <Id, Opportunity> newMap) {
        for (Opportunity opp : newMap.values()) {
            if ((opp.Opportunity_CurrentUser_Profile__c == 'CMS' || opp.Opportunity_CurrentUser_Profile__c == 'User MarlinDocusign')
                && opp.Docs_In__c != null && oldMap.get (opp.Id).Docs_In__c == null) {
                opp.StageName = 'Docs In';
            }
        }
    }
}
/**
 * Created by andrewmayer on 8/24/20.
 */

public inherited sharing class TC_ChecklistDao extends TC_DaoAbstract{

    public List <TC_Origination__Checklist__c> queryChecklistOnOppsByApiName (Set <Id> oppIds, String checklistApiName) {
        if (oppIds.isEmpty() || String.isBlank(checklistApiName)) return null;
        String query = TC_DataUtility.createSelectAllQueryString ('TC_Origination__Checklist__c', ' TC_Origination__Opportunity__c IN :oppIds AND Checklist_Template_Name__c = :checklistApiName', null);
        return Database.query (query);
    }
}
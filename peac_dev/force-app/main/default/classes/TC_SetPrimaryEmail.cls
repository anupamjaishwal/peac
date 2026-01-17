/*
Setting Opportunity primary contact email and Primary contact name based on opportunity casecenter and Portal app completed. 
*/
public class TC_SetPrimaryEmail {
public static void setPrimaryEmail (Map <Id, Opportunity> oldMap, Map <Id, Opportunity> newMap, Map<Id, List<OpportunityContactRole>> contactRoles){
        // SAL-323
        Set <Id> oppIds = new Set <Id> ();
        for (Opportunity opp : newMap.values()){
            if (opp.CaseCenter__c != null && (oldMap.get (opp.Id).CaseCenter__c  == null || (opp.Portal_App_Completed__c && !oldMap.get (opp.Id).Portal_App_Completed__c))) {
                oppIds.add (opp.Id);
            }
        }

        // SAL-2641 Setting the primary contact name here as well due to a loan notification bug (it doesn't get set right away)
        if (!oppIds.isEmpty()){
            
            for (Id oppId : oppIds) {
                String email = '';
                String name = '';
                for (OpportunityContactRole ocr : contactRoles.get(oppId)) {
                    if (email == '' && (ocr.IsPrimary || ocr.Role == 'Primary Contact')) email = ocr.Contact.Email;
                    if (name == '' && (ocr.IsPrimary || ocr.Role == 'Primary Contact')) name = ocr.Contact.Name;
                }
                newMap.get (oppId).Primary_Contact_Email__c = email;
                newMap.get (oppId).Primary_Contact_Name__c = name;
            }
        }
    }
}
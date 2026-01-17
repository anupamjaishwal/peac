public class TC_SetBillingPrimaryContactInfo {
public static void setBillingPrimaryContactInfo (Map <Id, Opportunity> oldMap, Map <Id, Opportunity> newMap,
    Map<Id, List<OpportunityContactRole>> contactRoles) {
        
        
        Set <Id> oppIds = new Set <Id> ();
        
        for (Opportunity opp : newMap.values ()) {
            if (opp.StageName != oldMap.get (opp.Id).StageName || (opp.Ready_to_Doc__c != oldMap.get (opp.Id).Ready_to_Doc__c  && opp.Ready_to_Doc__c == 'Yes')) {
                oppIds.add (opp.Id);
            }
            //updateList.add (new Opportunity (Id = ));
        }
        
        if (!oppIds.isEmpty()) {
            
            
            // List <Opportunity> oppsWithContactRoles = new List <Opportunity> ([SELECT ID, (SELECT ID, Role, ContactId, IsPrimary FROM OpportunityContactRoles ORDER BY CreatedDate ASC) FROM Opportunity WHERE Id IN :oppIds]);
            List <Opportunity> updateList = new List <Opportunity> ();
            
            for (Id oppId : oppIds) {
                Opportunity opp = newMap.get(oppId);
                List<OpportunityContactRole> contactRolesPerOpp = contactRoles.get(opp.Id);
                if (contactRolesPerOpp != null) {
                    
                    Id primary = null;
                    Id billing = null;
                    
                    for (OpportunityContactRole ocr : contactRolesPerOpp) {
                        
                        if ((ocr.Role == 'Primary Contact' || ocr.IsPrimary) && primary == null) {
                            primary = ocr.ContactId;
                        }
                        if (ocr.Role == 'Billing Contact' && billing == null) {
                            billing = ocr.ContactId;
                        }
                        if(primary != null && billing != null){
                            break;
                        }
                    }
                    opp.Primary_Contact__c = primary;
                    opp.Billing_Contact__c = billing;
                    
                } else {
                    opp.Primary_Contact__c = null;
                    opp.Billing_Contact__c = null;
                }
            }
        }
        
        
    }
}
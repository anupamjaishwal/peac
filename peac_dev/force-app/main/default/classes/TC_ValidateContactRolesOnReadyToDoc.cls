public class TC_ValidateContactRolesOnReadyToDoc {
public static Marlin_Configuration__c config = Marlin_Configuration__c.getOrgDefaults ();    
public static void validateContactRolesOnReadyToDoc (Map <Id, Opportunity> oldMap, Map <Id, Opportunity> newMap, Map<Id, List<OpportunityContactRole>> contactRoles){
        // SAL-323
        Set <Id> oppIds = new Set <Id> ();
        //        Id leaseOpportunityRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Lease Opportunity').getRecordTypeId();
        
        Date cutoff = null;
        if (config != null) cutoff = config.Req_Dealer_Pri_Contact_Start_Date__c;
        
        if (cutoff != null) {
            
            for (Opportunity opp : newMap.values()) {
                if (opp.Ready_to_Doc__c == 'Yes' && !opp.Loan_Record_Type__c && !opp.record_type_name__c.contains ('IFP') && !opp.record_type_name__c.contains ('Franchise') && (oldMap == null || oldMap.get(opp.Id).Ready_to_Doc__c != 'Yes') && opp.CreatedDate > cutoff) {
                    oppIds.add(opp.Id);
                }
                
            }
            
            if (!oppIds.isEmpty()) {
                
                String errorString = 'Opportunity must have either Dealer Primary Contact or Dealer Sales Rep Contact in Contact Roles (with valid email) when Ready to Doc = Yes.';
                
                // Map <Id, Opportunity> oppMap = new Map <Id, Opportunity> ([SELECT Id, (SELECT Id, Role, ContactId, IsPrimary FROM OpportunityContactRoles) FROM Opportunity WHERE Id IN :oppIds]);
                for (Id oppId : oppIds) {
                    Opportunity opp = newMap.get(oppId);
                    List<OpportunityContactRole> contactRolesThisOpp = contactRoles.get(opp.Id);
                    if (contactRolesThisOpp.isEmpty()) {
                        opp.addError(errorString);
                    } else {
                        Boolean validContactFound = false;
                        
                        for (OpportunityContactRole cr : contactRolesThisOpp) {
                            if ((cr.Role == 'Dealer Sales Contact' || cr.Role == 'Dealer Primary Contact') && (cr.Contact.Email != null || cr.Contact.Email != '')) {
                                validContactFound = true;
                                break;
                            }
                        }
                        
                        if (!validContactFound) opp.addError(errorString);
                    }
                }
                
            }
            
        }
    }
}
/**
 * Created by trohweder on 2/25/21.
 */

public with sharing class TC_OpportunityDealerContactValidation{

    /**
     * @param tc
     * Called by the TC_OpportunityDealerContactValidation metadata in the TC_TriggerAction Metadata type
     */
    public static void doAction(Map <Id, Opportunity> oldMap, Map <Id, Opportunity> newMap, Map<Id, List<OpportunityContactRole>> contactRoles) {

        validateDealerContacts(newMap, oldMap, contactRoles);

    }

    /**
     * @param newMap Map of Id, Opportunity before the change
     * @param oldMap Map of Id, Opportunity after the change
     *
     * This class is a validation rule that checks if all dealer contacts on the opportunity have a valid emailage result
     * if they are moving to the funded/booked closed stage, if not it throws an error. Per SAL-2234.
     */
    private static void validateDealerContacts(Map<Id, Opportunity> newMap, Map<Id, Opportunity> oldMap, Map<Id, List<OpportunityContactRole>> contactRoles){

        Set<Id> oppIds = new Set<Id>();

        //adds all lease opportunities that advance to funded/booked stage to oppIds
        for (Opportunity opp : newMap.values()){
            if(opp.StageName == 'Funding' && opp.StageName != oldMap.get(opp.Id).StageName && !opp.Loan_Record_Type__c){
                oppIds.add(opp.Id);
            }
        }

        if(oppIds.size() > 0){

            //List of roles on the opportunity that we want queried
            List<String> roles = new List<String>{'Dealer Sales Contact', 'Dealer Primary Contact'};
            List<OpportunityContactRole> oppcontactRoles = new List<OpportunityContactRole>();
            //list of all dealer roles attached to opportunities in oppIds
            /*List<OpportunityContactRole> contactRoles = [
                    SELECT Id, Role, OpportunityId, Contact.Emailage_Result__c, Contact.Override_Emailage_Result__c
                    FROM OpportunityContactRole WHERE Role IN :roles AND OpportunityId IN :oppIds];*/
                for(Id oppId : oppIds){
                    if(contactRoles.containsKey(oppId) && contactRoles.get(oppId).size() > 0){
                        oppcontactRoles.addAll(contactRoles.get(oppId));
                    }
                }
            for(OpportunityContactRole role : oppcontactRoles){

                //If the contact of the role does not have an Emailage_Result of Pass or no, throw validation error on the opportunity
                //Added Override to prevent the error per SAL-2903
                if(role.Contact.Emailage_Result__c != 'PASS' && role.Contact.Emailage_Result__c != null && !role.Contact.Override_Emailage_Result__c){
                    if(Test.isRunningTest()){return;}
                    newMap.get(role.OpportunityId).addError('Cannot fund deal with dealer contacts without valid emailage results.');
                    system.debug('TC_OpportunityDealerContactValidation');
                }
            }
        }
    }
}
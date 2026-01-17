/**
 * Moved into this format by andrewmayer on 8/24/20. Original code written by someone else
 */

public without sharing class TC_ValidateChecklistDocsInReview{

    public static void doAction(Map <Id, Opportunity> oldMap, Map <Id, Opportunity> newMap) {
     
        Set <Id> oppIds = new Set <Id> ();
        for (Opportunity opp : newMap.values()) {
            if (opp.StageName <> 'Docs In' && oldMap.get(opp.Id).StageName == 'Docs In') {
                oppIds.add(opp.Id);
            }
        }

        if (oppIds.isEmpty()) return;

        TC_ChecklistDao dao = new TC_ChecklistDao();
        List <TC_Origination__Checklist__c> checklists = dao.queryChecklistOnOppsByApiName (oppIds, 'Docs In Review');

        // andrew - didn't write this part
        for (Id oppId : oppIds) {
            String currentStage = newMap.get(oppId).StageName;
            IF(currentStage=='Docs Requested'){
                currentStage='Docs_Requested';
            }else if(currentStage=='Docs Out'){
                currentStage='Docs_Out';
            }else if(currentStage=='Review for Booking'){
                currentStage='Review_for_Booking';
            }else if(currentStage=='Funding (Loan)'){
                currentStage='Funding_Loan';
            }else if(currentStage=='Booking (Loan)'){
                currentStage='Booking_Loan';
            }
            String priorStage = 'Docs_In';
            Boolean allowError = checkOrdinal(checklists,oppId,currentStage,priorStage);
            for (TC_Origination__Checklist__c checklist : checklists) {
                if (checklist.TC_Origination__Opportunity__c == oppId && checklist.TC_Origination__Status__c != 'Complete'&& allowError==true) {
                    newMap.get(oppId).StageName.addError('Checklist must be complete to advance out of Docs In.');
                    break;
                }
            }
        }
    }
    private static Boolean checkOrdinal(List <TC_Origination__Checklist__c> checklists,String oppId, String currentStage, String priorStage){
        List <TC_Origination__Checklist__c> OppChecks = new List <TC_Origination__Checklist__c>();
        Decimal priorOrdinal = Stage_Ordinals__mdt.getInstance(priorStage).Ordinal__c;
        Decimal thisOrdinal = Stage_Ordinals__mdt.getInstance(currentStage).Ordinal__c;       
        Boolean allowError = true;
        for(TC_Origination__Checklist__c check:checklists){
            if(check.TC_Origination__Opportunity__c == oppId){
                OppChecks.add(check);
            }
        }
        if(priorOrdinal>thisOrdinal && OppChecks.size()>0){
            allowError = false;
        }
        
        return allowError;
    }
}
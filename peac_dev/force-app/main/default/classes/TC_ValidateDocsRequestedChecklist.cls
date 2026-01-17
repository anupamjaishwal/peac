/**
 * Moved into this format by andrewmayer on 8/24/20. Original code written by someone else
 */

public without sharing class TC_ValidateDocsRequestedChecklist{


    public static void doAction(Map <Id, Opportunity> oldMap, Map <Id, Opportunity> newMap) {


        Set <Id> advancedFromDocsRequestedIds = new Set <Id> ();

        for (Opportunity opp : newMap.values()) {
            if (opp.StageName <> 'Docs Requested' && oldMap.get(opp.Id).StageName == 'Docs Requested') {
                advancedFromDocsRequestedIds.add(opp.Id);
            }
        }

        if (advancedFromDocsRequestedIds.isEmpty()) return;

        TC_ChecklistDao dao = new TC_ChecklistDao();
        List <TC_Origination__Checklist__c> checklists = dao.queryChecklistOnOppsByApiName (advancedFromDocsRequestedIds, 'Docs Requested');

        // andrew - didn't write this next part

        for (Id oppId : advancedFromDocsRequestedIds) {
            String currentStage = newMap.get(oppId).StageName;
            IF(currentStage=='Docs In'){
                currentStage='Docs_In';
            }else if(currentStage=='Docs Out'){
                currentStage='Docs_Out';
            }
            String priorStage = 'Docs_Requested';
            Boolean allowError = checkOrdinal(checklists,oppId,currentStage,priorStage);
            for (TC_Origination__Checklist__c checklist : checklists) {
                

                if (checklist.TC_Origination__Opportunity__c == oppId && checklist.TC_Origination__Status__c != 'Complete'&& allowError==true) {

                    newMap.get(oppId).StageName.addError('Docs Requested checklist must be completed before advancing.');
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
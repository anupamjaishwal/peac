/**************************************************************************************************************
@Author: Chalapati Murru (LTIMindtree)
@Description: This class is used to run validations before the Opportuntiy save.
@User Story: SAL-7102 Expo: Opportunity Validation
@Created Date: 12-May-2026
**************************************************************************************************************/
public class PEAC_OpportunityValidationUtil {
    
    public static void readyToDocValidationError(List<Opportunity> newList, Map<Id,Opportunity> oldMap) {
        ORE__c oreSetting = ORE__c.getInstance();
        Id loanOppRecTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Funding_Stream_Opportunity').getRecordTypeId();
        
        for (Opportunity newOpp : newList) {
            Opportunity oldOpp = oldMap.get(newOpp.Id);
            Boolean isStageChanged = oldOpp != null && newOpp.StageName != oldOpp.StageName;
            Boolean isReadyToDocChanged = oldOpp != null && newOpp.Ready_to_Doc__c != oldOpp.Ready_to_Doc__c;
            
            Boolean stageOrReadyToDocCondition = (isStageChanged && newOpp.StageName == PEAC_ConstantClass.OPPORTUNITY_STATUS_DOCS_REQUESTED && newOpp.Ready_to_Doc__c == 'Yes')
                || (isReadyToDocChanged && newOpp.Ready_to_Doc__c == 'Yes');
            
            Boolean validationTriggered = newOpp.Loan_Record_Type__c == false && oreSetting.Bypass__c == false && oreSetting.StageBypass__c == false &&
                newOpp.RecordTypeId != loanOppRecTypeId && stageOrReadyToDocCondition && String.isBlank(newOpp.Opportunity_Document_Template__c) && newOpp.Docs_Requested__c != null && newOpp.Docs_Requested__c.date() >= Date.newInstance(2018, 9, 10);
            
            if(validationTriggered){
                newOpp.addError('Please Enter "Document Template"');
            }
        }
    }
}
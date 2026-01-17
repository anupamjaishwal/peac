/**
 * Created by trohweder on 10/5/20.
 */

public with sharing class TC_LeadOutcomeChange implements TC_TriggerActionI{

    public static void updateLeadOutcome(Map <Id, Lead> leadOldMap, Map <Id, Lead> leadNewMap){

        try{

            User loanPortal = [SELECT Id FROM User WHERE Name = 'loan portal'];

            System.debug('*******TC_LeadOutcomeChange************');
            for (Id key : leadNewMap.keySet()){
                if(leadNewMap.get(key).Lead_Outcome__c != 'Warm Transfer Approved' ||
                        leadNewMap.get(key).Lead_Outcome__c != 'Warm Transfer Booked'){
                    System.debug(leadNewMap.get(key).Status + ' '+ leadOldMap.get(key).Status);
                    if(leadNewMap.get(key).Status != leadOldMap.get(key).Status &&
                            leadNewMap.get(key).Status == 'Closed - Converted'){
                        if (leadNewMap.get(key).Opportunity_Record_ID__c != null){
                            leadNewMap.get(key).Lead_Outcome__c = 'Digital Auto Converted';
                        }
                        else if (leadNewMap.get(key).Opportunity_Record_ID__c == null &&
                                leadNewMap.get(key).CreatedById != loanPortal.Id){
                            leadNewMap.get(key).Lead_Outcome__c = 'Warm Transfer Converted';
                        }
                        System.debug(leadNewMap.get(key).Lead_Outcome__c);
                    }
                }

            }

        }
        catch (Exception e){
            System.debug(e.getMessage());
        }

    }


    public void doAction(TC_TriggerContext tc) {
        if (tc.isBefore() && tc.isUpdate()) {

            Map<Id, Lead> leadNewMap = (Map<Id, Lead>) tc.getNewMap();
            Map<Id, Lead> leadOldMap = (Map<Id, Lead>) tc.getOldMap();
            updateLeadOutcome(leadOldMap,leadNewMap);
        }
    }
}
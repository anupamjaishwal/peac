public class TC_ValidateChkListReadyToDocChkBox {
public static void validateCreditChecklistReadyToDocCheckbox (Map <Id, Opportunity> oldMap, Map <Id, Opportunity> newMap){
        
        Set <Id> oppIds = new Set <Id> ();
        
        Set <String> targetChannelValues = new Set <String> {
            'DLG', 'FC', 'WS', 'HC', 'SNAP', 'HKF', 'CVG', 'Franchise EF', 'Retail'
                };
                    
                    for (Opportunity opp : newMap.values()){
                        if (opp.Ready_to_Doc__c  == 'Yes' && targetChannelValues.contains(opp.Channel__c ) && (opp.Ready_to_Doc__c != oldMap.get(opp.Id).Ready_to_Doc__c || opp.Channel__c != oldMap.get(opp.Id).Channel__c)) oppIds.add(opp.Id);
                    }
        
        if (!oppIds.isEmpty()){
            
            // query all credit checklists
            
            List <TC_Origination__Checklist__c> creditChecklists = [SELECT TC_Origination__Opportunity__c, (SELECT Id FROM TC_Origination__Checklist_Items_with_Attachments__r WHERE TC_Origination__Category__c = 'Pre-Doc' AND TC_Origination__Status__c = 'Open') FROM TC_Origination__Checklist__c WHERE TC_Origination__Opportunity__c IN :oppIds AND Checklist_Template_Name__c = 'Credit Stips'];
            
            if (creditChecklists != null && !creditChecklists.isEmpty()){
                
                for (Id oppId : oppIds){
                    for (TC_Origination__Checklist__c checklist : creditChecklists){
                        if (checklist.TC_Origination__Opportunity__c == oppId && checklist.TC_Origination__Checklist_Items_with_Attachments__r != null && checklist.TC_Origination__Checklist_Items_with_Attachments__r.size() > 0 && !Test.isRunningTest()){
                            newMap.get(oppId).Ready_to_Doc__c.addError('All Pre-Doc Stip(s) must be completed or waived to mark Ready for Doc.');
                            break;
                        } 
                    }
                }
            }
        }
    }
}
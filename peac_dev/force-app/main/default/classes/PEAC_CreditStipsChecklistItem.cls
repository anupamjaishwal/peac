/********************************************************************************************************************
@Author:Vinod Rathod(LTIMindtree)
@Description: This class identifies removed stipulations from the Opportunity object and deletes related Checklist Items
under the 'Credit Stips' checklist.
@User Story:SAL-4872
@Created Date:April-01-2025 	    
*********************************************************************************************************************/
public class PEAC_CreditStipsChecklistItem {
    public static void deleteRemovedChecklistItem(Map<Id, Opportunity> oldMap, Map<Id, Opportunity> newMap) {
        
        Set<Id> relevantOpportunityIds = new Set<Id>(); 
        Map<Id, Set<String>> removedStipulationsMap = new Map<Id, Set<String>>(); // Store removed values per Opportunity
        
        // Opportunities where Stipulations has changed
        for (Id oppId : newMap.keySet()) {
            
            // Convert multi-select picklist values into Sets
            Set<String> oldStipulationsValues = new Set<String>();
            Set<String> newStipulationsValues = new Set<String>();
            
            if (oldMap.get(oppId).Stipulations__c != null) {
                oldStipulationsValues.addAll(oldMap.get(oppId).Stipulations__c.split(';'));
            }
            if (newMap.get(oppId).Stipulations__c != null) {
                newStipulationsValues.addAll(newMap.get(oppId).Stipulations__c.split(';'));
            }
            // If new Stipulations values is null, delete all related checklist items
            if(newMap.get(oppId).Stipulations__c == null) {
                relevantOpportunityIds.add(oppId);
                removedStipulationsMap.put(oppId, oldStipulationsValues);
                continue; 
            }
            
            // Find removed values (present in old but not in new)
            Set<String> removedStipulationsValues = new Set<String>(oldStipulationsValues);
            removedStipulationsValues.removeAll(newStipulationsValues);
            
            if (!removedStipulationsValues.isEmpty()) {
                relevantOpportunityIds.add(oppId);
                removedStipulationsMap.put(oppId, removedStipulationsValues);
            }
        }
        
        if(!removedStipulationsMap.isEmpty()){
            deleteChecklistItemsForRemovedStipulations(removedStipulationsMap);
        }
    }
    
    /**************************************************************************************************************
@Author:Vinod Rathod(LTIMindtree)
@Description:  Method to query and delete checklist items based on removed stipulations.
@User Story:SAL-4872
@Created Date:April-01-2025     
@Param: removedStipulationsMap - Map of Opportunity Ids to Set of removed Stipulation names

**************************************************************************************************************/
    private static void deleteChecklistItemsForRemovedStipulations(Map<Id, Set<String>> removedStipulationsMap){
        
        // Query all checklist items 
        List<TC_Origination__Checklist_Item_with_Attachments__c> checklistItemsToDelete = new List<TC_Origination__Checklist_Item_with_Attachments__c>();
        
        List<TC_Origination__Checklist_Item_with_Attachments__c> allChecklistItems = [
            SELECT Id, TC_Origination__API_Name__c, TC_Origination__Checklist_s_Opportunity__c
            FROM TC_Origination__Checklist_Item_with_Attachments__c
            WHERE TC_Origination__Checklist__r.Name = 'Credit Stips'
            AND TC_Origination__Is_Complete__c = FALSE
            AND Item_Waived_or_Cleared__c = FALSE
            AND TC_Origination__Checklist_s_Opportunity__c IN :removedStipulationsMap.keySet()
        ];
        
        //Group checklist items by Opportunity
        if(!allChecklistItems.isEmpty()){
        for (TC_Origination__Checklist_Item_with_Attachments__c item : allChecklistItems) {
            if(removedStipulationsMap.get(item.TC_Origination__Checklist_s_Opportunity__c) != Null &&
               removedStipulationsMap.containsKey(item.TC_Origination__Checklist_s_Opportunity__c) &&
               removedStipulationsMap.get(item.TC_Origination__Checklist_s_Opportunity__c).contains(item.TC_Origination__API_Name__c)){
                   
                   checklistItemsToDelete.add(item);
                   
               }
        }
        }
        System.debug('### Checklist Item to be deleted: '+ checklistItemsToDelete);
        
        // Delete checklist items in bulk
        if (!checklistItemsToDelete.isEmpty()) {
            delete checklistItemsToDelete;
        }
        
    }
}
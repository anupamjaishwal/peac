/** @author : Northteq Consulting, Inc.
 * @date : 11/23/20
 * @description: SAL-2133 Validation rule to check if all checklist items have been cleared before advancing the stage
 *
 */
public with sharing class TC_StageToClearValidation{

    public static void doAction(Map <Id, Opportunity> oldMap, Map <Id, Opportunity> newMap, 
    Map<Id, List<TC_Origination__Checklist_Item_with_Attachments__c>> checklistItemsAttachments, Set<Id> oppsAdvancedStageName) {
        // SAL-5426 Misael Romero
        for (Opportunity opp : newMap.values()) {

            List<String> incompleteItems = new List<String>();

            if (oppsAdvancedStageName.contains(opp.Id) && checklistItemsAttachments.get(opp.Id) <> null) {
                for (TC_Origination__Checklist_Item_with_Attachments__c item : checklistItemsAttachments.get(opp.Id)) {
                    // Is this item done by the stage we're trying to advance from?
                    if (item.TC_Origination__Included__c && !item.TC_Origination__Is_Complete__c && item.TC_Origination__Stage_to_Clear__c <> null 
                    && oldMap.get(opp.Id).StageName.contains(item.TC_Origination__Stage_to_Clear__c)) {
                        incompleteItems.add(item.Name);
                    }
                }
            }

            // If there are incomplete items, display an error
            if (incompleteItems.size() > 0) {
                opp.addError('These checklist items must be cleared before advancing the stage: ' + String.join(incompleteItems, ','));
            }
        }
    }
}
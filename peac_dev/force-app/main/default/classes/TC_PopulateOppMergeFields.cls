/** @author : Tamarack Consulting, Inc.
 * @date : 5/18/20
 * @description: 
 *
 */
public class TC_PopulateOppMergeFields {

    @InvocableMethod
    public static void populateOppMergeFields(List<Id> oppIds) {

        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>([SELECT Id FROM Opportunity WHERE Id IN :oppIds]);

        if (oppMap.size() > 0) {

            // Get included credit stips checklist items
            //Added Loan Credit Stips for SAL-2423
            List<TC_Origination__Checklist_Item_with_Attachments__c> checklistItems = [
                    SELECT Id, Name, TC_Origination__Checklist_s_Opportunity__c, TC_Origination__Internal_External__c
                    FROM TC_Origination__Checklist_Item_with_Attachments__c
                    WHERE TC_Origination__Checklist__c IN (
                            SELECT Id
                            FROM TC_Origination__Checklist__c
                            WHERE (Name = 'Credit Stips' OR Name = 'Loan Credit Stips')
                            AND TC_Origination__Opportunity__c IN :oppMap.values()
                    )
                    AND TC_Origination__Included__c = TRUE
                    AND TC_Origination__Is_Complete__c = FALSE
            ];
            System.debug('checklistItems: ' + checklistItems);

            Map<Id, List<TC_Origination__Checklist_Item_with_Attachments__c>> checklistItemsMap = new Map<Id, List<TC_Origination__Checklist_Item_with_Attachments__c>>();
            for (Opportunity opp : oppMap.values()) {
                if (checklistItemsMap.get(opp.Id) == null) {
                    checklistItemsMap.put(opp.Id, new List<TC_Origination__Checklist_Item_with_Attachments__c>());
                }
                for (TC_Origination__Checklist_Item_with_Attachments__c item : checklistItems) {
                    if (item.TC_Origination__Checklist_s_Opportunity__c == opp.Id) {
                        checklistItemsMap.get(opp.Id).add(item);
                    }
                }

                // Build the checklist items string
                //Added the setting of the external checklist item string for SAL-2432
                List<String> checklistItemStrings = new List<String>();
                List<String> externalChecklistItemStrings = new List<String>();
                for (TC_Origination__Checklist_Item_with_Attachments__c item : checklistItemsMap.get(opp.Id)) {
                    checklistItemStrings.add(item.Name);
                    if(item.TC_Origination__Internal_External__c == 'External'){
                        externalChecklistItemStrings.add(item.Name);
                    }
                }
                System.debug('checklistItemStrings: ' + checklistItemStrings);
                opp.Stips_for_Approval_Email__c = String.join(checklistItemStrings, '\n');
                System.debug('externalChecklistItemStrings: ' + externalChecklistItemStrings);
                opp.External_Stips_for_Approval_Email__c = String.join(externalChecklistItemStrings, '\n');
                System.debug('opp.Stips_for_Approval_Email__c: ' + opp.Stips_for_Approval_Email__c);
            }

            update oppMap.values();
        }
    }
}
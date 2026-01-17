public class TC_PopulateOpenExternalStips {
    public static boolean recCheck = false;
public static void populateOpenExternalStips(Map<Id, Opportunity> oldMap,Map<Id, Opportunity> newMap){
            //start recursive check
            if(recCheck){
                return;
            }
            else{
                recCheck = true;
            }
            //end recursive check, make sure SOQL query only runs once
        List<TC_Origination__Checklist_Item_with_Attachments__c> checklistItems = [
                    SELECT Id, Name, TC_Origination__Checklist_s_Opportunity__c, TC_Origination__Internal_External__c
                    FROM TC_Origination__Checklist_Item_with_Attachments__c
                    WHERE TC_Origination__Checklist__c IN (
                            SELECT Id
                            FROM TC_Origination__Checklist__c
                            WHERE TC_Origination__Opportunity__c IN :newMap.values()
                    )
                    AND TC_Origination__Included__c = TRUE
                    AND TC_Origination__Is_Complete__c = FALSE
            ];
        Map<Id, List<TC_Origination__Checklist_Item_with_Attachments__c>> checklistItemsMap = new Map<Id, List<TC_Origination__Checklist_Item_with_Attachments__c>>();
        for (Opportunity opp : newMap.values()) {
                if (checklistItemsMap.get(opp.Id) == null) {
                    checklistItemsMap.put(opp.Id, new List<TC_Origination__Checklist_Item_with_Attachments__c>());
                }
                for (TC_Origination__Checklist_Item_with_Attachments__c item : checklistItems) {
                    if (item.TC_Origination__Checklist_s_Opportunity__c == opp.Id) {
                        checklistItemsMap.get(opp.Id).add(item);
                    }
                }

                List<String> externalChecklistItemStrings = new List<String>();
                for (TC_Origination__Checklist_Item_with_Attachments__c item : checklistItemsMap.get(opp.Id)) {
                    if(item.TC_Origination__Internal_External__c == 'External'){
                        externalChecklistItemStrings.add(item.Name);
                    }
                }
                opp.Open_External_Stips__c = String.join(externalChecklistItemStrings, '\n');
            }
    }
}
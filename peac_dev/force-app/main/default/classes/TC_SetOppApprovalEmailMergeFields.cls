public class TC_SetOppApprovalEmailMergeFields {
    public static void setOppApprovalEmailMergeFields(Opportunity opp, List<String> fieldsChanged, Map<Id, Guarantor__c> guarantors) {
        
        if ((opp.Application_Status__c == 'Manually Approved' || opp.Application_Status__c == 'Automatically Approved')
                    && fieldsChanged != null && fieldsChanged.contains('Application_Status__c')) {
            List<String> pgNames = new List<String>();
            for (Guarantor__c theGuarantor : guarantors.values()) {
                if (theGuarantor.Opportunity__c == opp.Id && theGuarantor.Type__c == 'Personal Guarantor') {
                    pgNames.add(theGuarantor.Contact_Name__c);
                }
            }
            opp.PGs_for_Approval_Email__c = (pgNames.size() > 0) ? String.join(pgNames, '\n') : '0';
        }
    

                //old just kept as reference
        // Map <Id, Opportunity> newNewMap = new Map <Id, Opportunity>();
        // for (Opportunity opp : newMap.values()) {
        //     if ((opp.Application_Status__c == 'Manually Approved' || opp.Application_Status__c == 'Automatically Approved')
        //         && opp.Application_Status__c <> oldMap.get(opp.Id).Application_Status__c) {
        //             if (newNewMap.get(opp.Id) == null) {
        //                 newNewMap.put(opp.Id, opp);
        //             }
        //         }
        // }
        
        // if (newNewMap.size() > 0) {
            
        //     List<Guarantor__c> pgs = new List<Guarantor__c>([
        //         SELECT Opportunity__c,
        //         Contact_Name__c
        //         FROM Guarantor__c
        //         WHERE Opportunity__c IN :newNewMap.values()
        //         AND Type__c = 'Personal Guarantor'
        //     ]);
        //     System.debug('pgs: ' + pgs);
            
            // THIS HAS BEEN REPLACED BY TC_PopulateOppMergeFields
            // Get the checklist items for all new/updated opportunities
            // List<TC_Origination__Checklist_Item_with_Attachments__c> checklistItems = new List<TC_Origination__Checklist_Item_with_Attachments__c>([
            //     SELECT Id,
            //     Name,
            //     TC_Origination__Checklist_s_Opportunity__c
            //     FROM TC_Origination__Checklist_Item_with_Attachments__c
            //     WHERE TC_Origination__Checklist__c IN (
            //         SELECT Id
            //         FROM TC_Origination__Checklist__c
            //         WHERE Name = 'Credit Stips'
            //         AND TC_Origination__Opportunity__c IN :newNewMap.values()
            //     )
            //     AND TC_Origination__Included__c = TRUE
            //     AND TC_Origination__Is_Complete__c = FALSE
            // ]);
            // System.debug('checklistItems: ' + checklistItems);
            
            // Map<Id, List<TC_Origination__Checklist_Item_with_Attachments__c>> checklistItemsMap = new Map<Id, List<TC_Origination__Checklist_Item_with_Attachments__c>>();
            // for (Opportunity opp : newNewMap.values()) {
                
            //     // Build the PGs name string
            //     List<String> pgNames = new List<String>();
            //     for (Guarantor__c pg : pgs) {
            //         if (pg.Opportunity__c == opp.Id) {
            //             pgNames.add(pg.Contact_Name__c);
            //         }
            //     }
            //     opp.PGs_for_Approval_Email__c = (pgNames.size() > 0) ? String.join(pgNames, '\n') : '0';
                
                // // Organize the checklist items by opportunity
                // if (checklistItemsMap.get(opp.Id) == null) {
                //     checklistItemsMap.put(opp.Id, new List<TC_Origination__Checklist_Item_with_Attachments__c>());
                // }
                // for (TC_Origination__Checklist_Item_with_Attachments__c item : checklistItems) {
                //     if (item.TC_Origination__Checklist_s_Opportunity__c == opp.Id) {
                //         checklistItemsMap.get(opp.Id).add(item);
                //     }
                // }
                
                // // Build the checklist items string
                // List<String> checklistItemStrings = new List<String>();
                // for (TC_Origination__Checklist_Item_with_Attachments__c item : checklistItemsMap.get(opp.Id)) {
                //     checklistItemStrings.add(item.Name);
                // }
                // System.debug('checklistItemStrings: ' + checklistItemStrings);
                // //                opp.Stips_for_Approval_Email__c = String.join(checklistItemStrings, '\n'); THIS HAS BEEN REPLACED BY TC_PopulateOppMergeFields
                // System.debug('opp.Stips_for_Approval_Email__c: ' + opp.Stips_for_Approval_Email__c);
        //     }
        // }
    }
    
}
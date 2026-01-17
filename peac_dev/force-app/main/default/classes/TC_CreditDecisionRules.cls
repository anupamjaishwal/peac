/** @author : Tamarack Consulting, Inc.
 * @date : 12/27/19
 * @description: Stores the rules used for credit decision
 *
 */
public with sharing class TC_CreditDecisionRules {

    /* Stores all Chatter posts for these rules, used at the end in bulk insert */
    public static List<FeedItem> chatterPosts {get; set;}

    /**
     * CDR-001 Update fields based on Lessor (SAL-1020)
     * @description: Sets fields based on the selected Lessor__c field
     * @param oppMap The opportunity records on which to update fields
     */
    public static void updateFieldsBasedOnLessor(Map <Id, Opportunity> oppMap) {

        Set <Id> oppIdsForChecklistItems = new Set <Id> ();

        for (Opportunity opp : oppMap.values()) {

            if (opp.Region__c <> null) {
                /* If there are 150 MLC Syndications, then set the region to Marlin Leasing, else set it to MBB */
                opp.Region__c = (opp.Lessor__c == 150 || opp.Lessor__c == 170 || (opp.Lessor__c > 399 && opp.Lessor__c < 500)) ? '000' : '001';
                try {
                    chatterPosts.add(createChatterPost(opp.Id, opp.Name, 'Set Region to ' + opp.Region__c));
                } catch (NullPointerException e) {
                    System.debug(LoggingLevel.ERROR, e.getMessage());
                }
            }
            if(opp.Lessor__c == 170) {
                   opp.Remit_to_Window__c = '0001';
               
            }

            /* If the Lessor value is applicable, check the Auto ACH Required box on the Credit Stips checklist */
            if (opp.Lessor__c == 421 || opp.Lessor__c == 422 || opp.Lessor__c == 423 || opp.Lessor__c == 432 || opp.Lessor__c == 021) {
                /* Get the Auto ACH Required checkbox from this opportunity's Credit Stips checklist */
                opp.Stipulations__c = 'Auto ACH Required';
                try {
                    chatterPosts.add(createChatterPost(opp.Id, opp.Name, 'Set Stipulations to ' + opp.Stipulations__c));
                } catch (NullPointerException e) {
                    System.debug(LoggingLevel.ERROR, e.getMessage());
                }
                oppIdsForChecklistItems.add(opp.Id);
            }
        }

        if (!oppIdsForChecklistItems.isEmpty()) {
            List <TC_Origination__Checklist_Item_with_Attachments__c> autoAchRequired = [
                    SELECT Id,
                            TC_Origination__Primary_Reviewer__c,
                            TC_Origination__Checklist__r.TC_Origination__Opportunity__c
                    FROM TC_Origination__Checklist_Item_with_Attachments__c
                    WHERE TC_Origination__Checklist__r.TC_Origination__Opportunity__c IN :oppIdsForChecklistItems
                    AND TC_Origination__Checklist__r.Name = 'Credit Stips'
                    AND TC_Origination__API_Name__c = 'Auto ACH Required'
            ];

            if (!autoAchRequired.isEmpty()) {
                List <TC_Origination__Checklist_Item_with_Attachments__c> targetItems = new List <TC_Origination__Checklist_Item_with_Attachments__c> ();

                for (TC_Origination__Checklist_Item_with_Attachments__c item : autoAchRequired) {
                    /* Verify the checkbox is unchecked before checking it */
                    if (!item.TC_Origination__Primary_Reviewer__c) {
                        targetItems.add(new TC_Origination__Checklist_Item_with_Attachments__c(
                                Id = item.Id,
                                TC_Origination__Primary_Reviewer__c = true));
                    }
                }

                /* Update Auto ACH Required checkboxes */
                if (!targetItems.isEmpty()) {
                    for (TC_Origination__Checklist_Item_with_Attachments__c item : targetItems) {
                        try {
                            chatterPosts.add(createChatterPost(item.TC_Origination__Checklist__r.TC_Origination__Opportunity__c,
                                    item.TC_Origination__Checklist__r.TC_Origination__Opportunity__r.Name,
                                    'Auto ACH Required was checked on the Credit Stips checklist'));
                        } catch (NullPointerException e) {
                            System.debug(LoggingLevel.ERROR, e.getMessage());
                        }
                    }
                    update targetItems;
                }
            }
        }
    }

    /**
     * CDR-004 ACH Guarantee Form (SAL-1023)
     * @description Sets the Stipulations picklist to ACH Guarantee Form
     * @param opps The map of opportunities on which to set Stipulations field
     */
    public static void setStipulationsToAchGuaranteeForm(Map<Id, Opportunity> opps) {

        for (Opportunity opp : opps.values()) {
            if ((opp.Lessor__c == 421 || opp.Lessor__c == 422 || opp.Lessor__c == 423 || opp.Lessor__c == 424 ||
                    opp.Lessor__c == 432 || opp.Lessor__c == 021) && opp.Decision_Status__c == 'Approved' &&
                    opp.SIC_Code__c == '8661' && opp.Opportunity_Marlin_Score__c == null) {
                opp.Stipulations__c = 'ACH Guarantee Form';
                try {
                    chatterPosts.add(createChatterPost(opp.Id, opp.Name, 'Set the Stipulations picklist to ACH Guarantee Form'));
                } catch (NullPointerException e) {
                    System.debug(LoggingLevel.ERROR, e.getMessage());
                }
            }
        }
    }

    /**
     * CDR-007 Set Facility (SAL-1028)
     * @description Sets the facility code based on SFP Tier 2 Status or Program Type, then checks the Email Required
     * item on the Credit Stips checklist
     * @param oldMap The old version of each opportunity
     * @param newMap The new version of each opportunity
     */
    public static void setFacility(Map<Id, Opportunity> oldMap, Map<Id, Opportunity> newMap) {

        Set<Id> oppIdsForChecklistItems = new Set<Id>();

        for (Opportunity opp : newMap.values()) {

            /* Checks if the SFP Tier 2 Status or Program Type has changed */
            if (opp.SFP_Tier_2_Status__c <> oldMap.get(opp.Id).SFP_Tier_2_Status__c && opp.Program_Type__c <> oldMap.get(opp.Id).Program_Type__c) {

                /* Entry criteria for SFP Tier 2 Status */
                if (opp.SFP_Tier_2_Status__c == 'Approved' || opp.SFP_Tier_2_Status__c == 'More Info') {
                    opp.Facility_Code__c = 'VARADERO';
                } else if (opp.SFP_Tier_2_Status__c == 'Rejected') {
                    opp.Facility_Code__c = null;
                }

                /* Entry criteria for Program Type */
                if (opp.Program_Type__c == 'Hold for Sale') {
                    opp.Facility_Code__c = 'CVG Syndication';
                } else if (opp.Program_Type__c == 'On Balance Sheet Funding' || opp.Program_Type__c == 'SFP Tier 2') {
                    oppIdsForChecklistItems.add(opp.Id);
                }
            }
        }

        if (!oppIdsForChecklistItems.isEmpty()) {
            /* Get 'Email Required' checkboxes */
            List <TC_Origination__Checklist_Item_with_Attachments__c> emailRequired = [
                    SELECT Id,
                            TC_Origination__Primary_Reviewer__c,
                            TC_Origination__Checklist__r.TC_Origination__Opportunity__c
                    FROM TC_Origination__Checklist_Item_with_Attachments__c
                    WHERE TC_Origination__Checklist__r.TC_Origination__Opportunity__c IN :oppIdsForChecklistItems
                    AND TC_Origination__Checklist__r.Name = 'Credit Stips'
                    AND TC_Origination__API_Name__c = 'Email Required'
            ];

            if (!emailRequired.isEmpty()) {
                List <TC_Origination__Checklist_Item_with_Attachments__c> targetItems = new List <TC_Origination__Checklist_Item_with_Attachments__c> ();

                /* Verify the checkboxes is unchecked before checking it */
                for (TC_Origination__Checklist_Item_with_Attachments__c item : emailRequired) {
                    if (!item.TC_Origination__Primary_Reviewer__c) {
                        targetItems.add(new TC_Origination__Checklist_Item_with_Attachments__c(
                                Id = item.Id,
                                TC_Origination__Primary_Reviewer__c = true));
                    }
                }

                /* Update Email Required checkboxes */
                if (!targetItems.isEmpty()) {
                    for (TC_Origination__Checklist_Item_with_Attachments__c item : targetItems) {
                        chatterPosts.add(createChatterPost(item.TC_Origination__Checklist__r.TC_Origination__Opportunity__c,
                                item.TC_Origination__Checklist__r.TC_Origination__Opportunity__r.Name,
                                'Email Required was checked on the Credit Stips checklist'));
                    }
                    update targetItems;
                }
            }
        }
    }

    /**
     * @description Helper method that creates a Chatter feed item
     * @param oppId The ID of the opportunity record to post to
     * @param title The title of the post (e.g. the opportunity name)
     * @param body The message of the post
     * @return The FeedItem that can be added to a list of feed items
     */
    public static FeedItem createChatterPost(Id oppId, String title, String body) {
        FeedItem post = new FeedItem();
        post.ParentId = oppId;
        post.Title = title;
        post.Type = 'TextPost';
        post.Body = body;
        return post;
    }

    /**
     * @description Helper method for bulk-inserting Chatter feed items
     * @param feedItems The list of Chatter feed items to be inserted
     */
    public static void uploadChatterPosts(List<FeedItem> feedItems) {
        insert feedItems;
    }

    /**
     * CDR-003 setNumberOfPaymentsField (SAL-1022)
     * @description IF existing Max_Term_Approved__c = NULL, SET of_Payments__c = Terms__c
     */
    public static void setNumberOfPaymentsField (Map<Id, Opportunity> oldMap, Map<Id, Opportunity> newMap){

        for (Opportunity opp : newMap.values()){
            // Check if Max Term Approved is null, and if either that value changed or the stage changed.
            if (opp.Max_Term_Approved__c == null && (oldMap == null || oldMap.get(opp.Id).Max_Term_Approved__c != null || oldMap.get(opp.Id).StageName != opp.StageName)){
                opp.of_Payments__c = opp.Terms__c;
                chatterPosts.add(createChatterPost(opp.Id, opp.Name, '# of Payments set equal to Terms.'));
            }
        }
    }

    /**
    * CDR-003 setOFACRequiredField (SAL-1022)
    * @description IF OFAC_Override__c = True, SET OFAC_Required__c = True
    */
    public static void setOFACRequiredField (Map<Id, Opportunity> oldMap, Map<Id, Opportunity> newMap) {

        for (Opportunity opp : newMap.values()){
            if (opp.OFAC_Override__c && (oldMap == null || !oldMap.get(opp.Id).OFAC_Override__c) || oldMap.get(opp.Id).StageName != opp.StageName){
                opp.OFAC_Required__c = 'True';
                chatterPosts.add(createChatterPost(opp.Id, opp.Name, 'OFAC Required set to True.'));
            }
        }
    }

    /**
    * CDR-002 setProgramType (SAL-1021)
    * @description Sets Program Type based on Lessor and SFP Tier 2 Status.
    */
    public static void setProgramType (Map <Id, Opportunity> oldMap, Map <Id, Opportunity> newMap) {

        Set <Decimal> targetLessorCodes = new Set <Decimal> {421, 423, 201};

        for (Opportunity opp : newMap.values()){
            if (opp.Lessor__c != null && targetLessorCodes.contains(opp.Lessor__c)) {
                opp.Program_Type__c = '1100';
                chatterPosts.add(createChatterPost(opp.Id, opp.Name, 'Program Type set to 1100.'));
            } else if (opp.SFP_Tier_2_Status__c == 'Approved' || opp.SFP_Tier_2_Status__c == 'More Info'){
                opp.Program_Type__c = '1200';
                chatterPosts.add(createChatterPost(opp.Id, opp.Name, 'Program Type set to 1200.'));
            } else if (opp.SFP_Tier_2_Status__c == 'Rejected'){
                opp.Program_Type__c = null;
                chatterPosts.add(createChatterPost(opp.Id, opp.Name, 'Program Type set to null.'));
            }
        }
    }

    /**
    * CDR-010 SIC 8661 settings (SAL-1032)
    * @description IF OFAC_Override__c = True, SET OFAC_Required__c = True
    */
    public static void setSIC8661Settings (Map <Id, Opportunity> oldMap, Map <Id, Opportunity> newMap) {

        for (Opportunity opp : newMap.values()){
            if (opp.Decision_Status__c == 'A' && opp.SIC_Code__c == '8661' && opp.Opportunity_Marlin_Score__c == null){
                opp.SFP_Model__c = true;
                opp.Required_Adv_Payments__c = 2;
                opp.Lessor__c = 421;
                chatterPosts.add(createChatterPost(opp.Id, opp.Name, 'SIC 8661 settings applied.'));
            }
        }
    }

    /**
     * CDR-008 Set Owner Operator (SAL-1026)
     * @description: Sets Owner_Operator__c field based on Opportunity fields
     * @param oldMap Map of old opportunity records from trigger
     * @param newMap Map of new opportunity records from trigger
     */
    public static void setOwnerOperatorField (Map<Id, Opportunity> oldMap, Map<Id, Opportunity> newMap) {
        if (TC_RecursiveTriggerHelper.populateOwnerOpportunity)
            return;
        else {
            TC_RecursiveTriggerHelper.populateOwnerOpportunity = true;
            TC_RecursiveTriggerHelper.populateEquipmentAddress = true;
        }

        Set<Id> ooOppIds = new Set<Id> ();
        Set<Id> oppIds = new Set<Id> ();

        for (Opportunity opp : newMap.values()) {
            if (oldMap == null || oldMap.get(opp.Id).Branch__c != opp.Branch__c) {
                if (opp.Branch__c == 'TFG-Transportation Financ')
                    ooOppIds.add (opp.Id);

                oppIds.add (opp.Id);
            }
        }

        List <Dealer__c> dealers = [SELECT Id,
                Opportunity__c
        FROM Dealer__c
        WHERE Primary_Dealer__c = true
        AND Dealer__r.Dealer_Number__c = '855331.7237'
        AND Opportunity__c IN :ooOppIds];

        ooOppIds = new Set<Id> ();

        for (Dealer__c d : dealers) {
            ooOppIds.add (d.Opportunity__c);
        }

        Set<Id> assetIds = new Set<Id> ();

        for (Asset__c a : [SELECT Id FROM Asset__c WHERE Is_Titled__c = true AND Opportunity__c IN :ooOppIds])
            assetIds.add (a.Id);

        List <Asset__c> assets = [SELECT Id
        FROM Asset__c
        WHERE Opportunity__c IN :oppIds];

        for (Asset__c a : assets) {
            if (assetIds.contains (a.Id))
                a.Owner_Operator__c = null;
            else
                a.Owner_Operator__c = 'No';
        }

        if (!assets.isEmpty()) update assets;
    }

}
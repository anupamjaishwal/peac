/*
	Andrew Mayer
	Description:
	When a Originals or tracking for originals checklist item is created under a Docs In review checklist. Auto include it
	if (Total Equipment Cost > 100,000 AND Document_Delivery_Method__c = ‘PDF’) OR (Equip_Code_1 CONTAINS ‘Title’
	AND Broker.Exclude Originals Stipulation Requirement != TRUE)

	Additional Notes:
	Bandita said there can only be one broker, so grabbing the first one

	JIRA:
	https://marlinbusiness.atlassian.net/browse/SAL-1688

	Operations:
	Before Insert

	Queries: 2
	DMLS: 0
	
	Test Class: none yet
*/
public class TC_AutoIncludeDocsInReviewOriginalsStip implements TC_TriggerActionI {
    
    private Map <Id, Boolean> oppBrokerExcludesStipRequirement;
	
    public void doAction (TC_TriggerContext tc) {
        
        List <TC_Origination__Checklist_Item_with_Attachments__c > newList = (List <TC_Origination__Checklist_Item_with_Attachments__c  >) tc.getNewList ();
        
        Set <Id> checklists = new Set <Id> ();
        List <TC_Origination__Checklist_Item_with_Attachments__c> items = new List <TC_Origination__Checklist_Item_with_Attachments__c> ();
        
        for (TC_Origination__Checklist_Item_with_Attachments__c item : newList) {
            if (item.TC_Origination__API_Name__c == 'Originals or tracking for originals') {
                checklists.add (item.TC_Origination__Checklist__c);
                items.add (item);
            } 
        }
        
        if (checklists.isEmpty ()) return;
        
        Map <Id, Id> checklistOppMap = new Map <Id, Id> ();
        
        for (TC_Origination__Checklist__c checklist : [SELECT Id, TC_Origination__Opportunity__c FROM TC_Origination__Checklist__c WHERE Id IN :checklists]) {
            checklistOppMap.put (checklist.Id, checklist.TC_Origination__Opportunity__c);
        }
        
        oppBrokerExcludesStipRequirement = new Map <Id, Boolean> ();
        
        Map <Id, Opportunity> oppMap = new Map <Id, Opportunity> ([SELECT Id, Equipment_Cost__c, Document_Delivery_Method__c, Equip_Code1__c, (SELECT Id, Account__r.Exclude_Originals_Stipulation_Requiremen__c FROM Brokers1__r ORDER BY CreatedDate ASC LIMIT 1) FROM Opportunity WHERE Id IN :checklistOppMap.values()]);
        
        for (Opportunity opp : oppMap.values ()) {
            if (!opp.Brokers1__r.isEmpty ()){
                oppBrokerExcludesStipRequirement.put (opp.Id, opp.Brokers1__r[0].Account__r.Exclude_Originals_Stipulation_Requiremen__c);
            }
        }
        
        for (TC_Origination__Checklist_Item_with_Attachments__c item : items) {
            item.TC_Origination__Included__c = requireStip (oppMap.get (checklistOppMap.get (item.TC_Origination__Checklist__c)));
        }
    }

    // require stip if (equipment cost over 100000 and ddm = pdf) or (equipment code is titled and broker not excluded)
    private Boolean requireStip (Opportunity opp) {
        return (opp.Equipment_Cost__c > 100000 && opp.Document_Delivery_Method__c == 'PDF') || (!String.isBlank (opp.Equip_Code1__c) && opp.Equip_Code1__c.containsIgnoreCase ('titled') && (oppBrokerExcludesStipRequirement.isEmpty () || !oppBrokerExcludesStipRequirement.get (opp.Id)));
    }
}
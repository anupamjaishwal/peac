/** @author : Tamarack Consulting, Inc.
 * @date : 12/27/19
 * @description: Handles all the credit decision rules
 *
 */
public with sharing class TC_CreditDecision {

    public static void runRules(Map<Id, Opportunity> oldMap, Map<Id, Opportunity> newMap) {

        if (TC_RecursiveTriggerHelper.cdrRules) return;

        System.debug ('JJJJJ start credit decision rules');

        System.debug('newMap: ' + newMap);

        Set<Id> filterIds = new Set<Id>();
        Set<Id> loanFilterIds = new Set<Id>();

        for (Opportunity opp : newMap.values()) {
            // Entry criteria requires that the stage is Decision and the opportunity is a lease
            if ((opp.StageName == 'Decision' || (opp.StageName == 'Proposal' && opp.StageName <> oldMap.get(opp.Id).StageName)) 
                && opp.Last_Date_Scorex_Retrieved__c <> null && !opp.Loan_Record_Type__c) {
                	filterIds.add(opp.Id);
                	if (oldMap.get(opp.Id).Last_Date_Scorex_Retrieved__c == null ) {
                    	gdsHasRunFirstTime.put(opp.Id, true);
                	}
            }

            if((opp.Application_Status__c == 'More Info'|| opp.Application_Status__c == 'Automatically Approved' || opp.Application_Status__c == 'Manually Approved' || opp.Application_Status__c == 'Approved' ) && opp.Application_Status__c <> oldMap.get(opp.Id).Application_Status__c && opp.Loan_Record_Type__c) {
                	loanFilterIds.add(opp.Id);
                    gdsHasRunFirstTime.put(opp.Id, true);
            }

        }


        relatedRecords relatedRecordsWrapper = new relatedRecords();

        if (!filterIds.isEmpty()) {
            
            
            /*
             * platform event workaround
			ORE__c ore = ORE__c.getInstance(Userinfo.getProfileId());
            if (ore == null) ore = new ORE__c();
            ore.GDS_Validation_Bypass__c = true;
            upsert ore;
            
            ORE__c ore2 = ORE__c.getOrgDefaults ();
            ore2.GDS_Validation_Bypass__c = true;
            upsert ore2;*/
            
            // TC_CDR014: Exception made, to be executed in after trigger because of recursive conflicts between
            // updating Opportunity & Accounts
            // TC_CDR018: Removed TC_CDR018 (identical logic in TC_CDR012). TC_CDR018Asset still executed in after
            // trigger because of recursive conflicts between Opportunity & Assets
            List <String> rules = new List <String> {
                    'TC_CDR002'
                    , 'TC_CDR003'
                    
                    , 'TC_CDR005'
                    //, 'TC_CDR006' Commented out for later release - related to SFP2
                    , 'TC_CDR007'
                    //, 'TC_CDR010' https://marlinbusiness.atlassian.net/browse/SAL-103l2; Marlin wanted removed from this release.
                    //, 'TC_CDR011' https://marlinbusiness.atlassian.net/browse/SAL-3214: 
                    , 'TC_CDR012'
                    , 'TC_CDR019'
                    , 'TC_CDR020'
                    , 'TC_CDR001' // SAL-2622 Moved 001 to later in the flow, since it relys on lessor changes from 004 - Causing ACH Required to not update
                    , 'TC_CDR004'
            };
            for (String ruleStr : rules) {
                Type ruleType = Type.forName(ruleStr);
                TC_CDRInterface ruleImpl = (TC_CDRInterface) ruleType.newInstance();
                ruleImpl.runRule(oldMap, newMap, filterIds, relatedRecordsWrapper);
            }
           

            // Now, DML all related records from relatedRecordsWrapper
            update relatedRecordsWrapper.relatedContactMap.values();
            update relatedRecordsWrapper.relatedAssetMap.values();
            update relatedRecordsWrapper.relatedDealerMap.values();
            update relatedRecordsWrapper.relatedAccountMap.values();
            update relatedRecordsWrapper.relatedChecklistItemMap.values();
            if (!Test.isRunningTest()) TC_ChatterHelper.sendToChatter(relatedRecordsWrapper.relatedChatterMap);

            TC_RecursiveTriggerHelper.cdrRules = true;
        }


        if (!loanFilterIds.isEmpty()) {
            List <String> rules = new List <String> {
                    'TC_CDR020'
            };
            for (String ruleStr : rules) {
                Type ruleType = Type.forName(ruleStr);
                TC_CDRInterface ruleImpl = (TC_CDRInterface) ruleType.newInstance();
                ruleImpl.runRule(oldMap, newMap, loanFilterIds, relatedRecordsWrapper);
            }
           
            TC_RecursiveTriggerHelper.cdrRules = true;
        }

    }

    public static void runRules(Map<Id, Dealer__c> oldMap, Map<Id, Dealer__c> newMap) {
        Map <Id, Opportunity> oldMapSubset = null;
        Map <Id, Opportunity> newMapSubset = new Map <Id, Opportunity> ();
        Set <Id> oppIds = new Set <Id> ();

        for (Dealer__c d : newMap.values()) {
            if (d.Primary_Dealer__c == true && (oldMap == null || oldMap.get(d.Id).Primary_Dealer__c == false || oldMap.get(d.Id).Dealer__c != d.Dealer__c))
                oppIds.add(d.Opportunity__c);
        }

        for (Opportunity opp : [SELECT StageName, Loan_Record_Type__c, Branch__c FROM Opportunity WHERE Id IN :oppIds]) {
            /* Entry criteria requires that the stage is Decision and the opportunity is a lease */
            if (opp.StageName == 'Decision' && !opp.Loan_Record_Type__c)
                newMapSubset.put(opp.Id, opp);
        }

        if (!newMapSubset.isEmpty()){
            /* Run credit decision rules below */
            TC_CreditDecisionRules.setOwnerOperatorField(oldMapSubset, newMapSubset); /* CDR-008 */
        }
    }

    public static void runRules(Map<Id, Asset__c> newAssets, Boolean isNew, Map<Id, List<String>> fieldsChangedById, Map<Id, Opportunity> opps) {
        Map <Id, Opportunity> oldMapSubset = null;
        Map <Id, Opportunity> newMapSubset = new Map <Id, Opportunity> ();
        for(Asset__c newAsset : newAssets.values()){
            List<String> fieldsChanged = fieldsChangedById.get(newAsset.Id);
            Boolean changedIsTitled = fieldsChanged != null && fieldsChanged.contains('Is_Titled__c');
            if(isNew || changedIsTitled){
                Opportunity opp = opps.get(newAsset.Opportunity__c);
                if(opp != null && opp.StageName == 'Decision' && !opp.Loan_Record_Type__c && opp.Last_Date_Scorex_Retrieved__c <> null){
                    newMapSubset.put(opp.Id, opp);
                }
            }
        }
        // for (Asset__c a : newMap.values()) {
        //     if (oldMap == null || oldMap.get(a.Id).Is_Titled__c != a.Is_Titled__c)
        //         oppIds.add(a.Opportunity__c);
        // }
        // for (Opportunity opp : [SELECT StageName, Loan_Record_Type__c, Branch__c, Last_Date_Scorex_Retrieved__c FROM Opportunity WHERE Id IN :oppIds]) {
            /* Entry criteria requires that the stage is Decision and the opportunity is a lease */
            // if (opp.StageName == 'Decision' && !opp.Loan_Record_Type__c && opp.Last_Date_Scorex_Retrieved__c <> null)
            //     newMapSubset.put(opp.Id, opp);
        //}
        if (!newMapSubset.isEmpty()){
            /* Run credit decision rules below */
            TC_CreditDecisionRules.setOwnerOperatorField(oldMapSubset, newMapSubset); /* CDR-008 */
        }
    }

    public class RelatedRecords {

        public Map<Id, Contact> relatedContactMap;
        public Map<Id, Asset__c> relatedAssetMap;
        public Map<Id, Dealer__c> relatedDealerMap;
        public Map<Id, TC_Origination__Checklist_Item_with_Attachments__c> relatedChecklistItemMap;
        public Map<Id, List<String>> relatedChatterMap;
        public Map<Id, Account> relatedAccountMap;

        public RelatedRecords() {
            this.relatedContactMap = new Map<Id, Contact>();
            this.relatedAssetMap = new Map<Id, Asset__c>();
            this.relatedDealerMap = new Map<Id, Dealer__c>();
            this.relatedChecklistItemMap = new Map<Id, TC_Origination__Checklist_Item_with_Attachments__c>();
            this.relatedChatterMap = new Map<Id, List<String>>();
            this.relatedAccountMap = new Map<Id, Account>();
        }

    }

    public static Map<Id, Boolean> gdsHasRunFirstTime = new Map<Id, Boolean>();

    public static Boolean gdsRanFirstTime(Id recordId) {
        if (gdsHasRunFirstTime.get(recordId) != null && gdsHasRunFirstTime.get(recordId))  {
            return true;
        } else {
            return false;
        }
    }

}
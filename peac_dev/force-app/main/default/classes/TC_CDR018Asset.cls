/**
 * Created by tamarack on 1/17/20.
 */

public with sharing class TC_CDR018Asset {

    /**
     * CDR-018 Set CVG Requirements
     * @description:
     * If Opportunity.Branch__c = Commercial Vehicle Group, set Lessor Code = 405. (Handled in CDR-012)
     * IF Opportunity.Lessor Code = 405
     *      Update  all related Asset__c.Owner_Operator__c = "No"
     *
     * Validation Rule:
     * IF (Opportunity.Lessor Code = 405)
     *      Asset.Owner_Operator__c must be “No”
     *      Opportunity.Branch__c must be Commercial Vehicle Group (and vice versa)
     *      Opportunity.Pricing_Level__c field must be non-blank to move beyond Docs Requested
     * @param oldMap Map of old records from opportunity trigger
     * @param newMap Map of new records from opportunity trigger
     * @param filterIds Set of relevant opp Ids from opportunity trigger
     * @param relatedRecordsWrapper Wrapper object of related records to DML at end of CDRs
     */

    public static void runRule(Map<Id, Opportunity> newMap) {

        Set<Id> filterIds = new Set<Id>();
        for (Opportunity opp : newMap.values()) {
            if (opp.StageName == 'Decision' && opp.Last_Date_Scorex_Retrieved__c <> null && !opp.Loan_Record_Type__c) {
                filterIds.add(opp.Id);
            }
        }

        Set<Id> filter018Ids = new Set<Id>();
        for (Id oppId : filterIds) {
            if (newMap.get(oppId).Lessor__c == 405) {
                if (newMap.get(oppId).Branch__c == 'Commercial Vehicle Group') {
                    filter018Ids.add(oppId);
                }
            }
        }

        List<Asset__c> assetList = new List<Asset__c>();
        if (!filter018Ids.isEmpty()) {
            assetList = new List<Asset__c>([
                    SELECT Id, Owner_Operator__c
                    FROM Asset__c
                    WHERE Opportunity__c IN: filter018Ids
            ]);
        }

        for (Asset__c asset : assetList) {
            asset.Owner_Operator__c = 'No';
        }

        update assetList;

    }

}
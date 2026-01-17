/**
 * Created by tamarack on 1/9/20.
 */

public with sharing class TC_CDR014 {

    /**
     * CDR-014 Update Months in Business Fields (SAL-1046)
     * @description: https://marlinbusiness.atlassian.net/browse/SAL-1046
     * @param oldMap Map of old records from opportunity trigger
     * @param newMap Map of new records from opportunity trigger
     */

    public static void runRule(Map<Id, Opportunity> oldMap, Map<Id, Opportunity> newMap) {


        Set<Id> filterIds = new Set<Id>();
        for (Opportunity opp : newMap.values()) {
            if (opp.StageName == 'Decision' && opp.Last_Date_Scorex_Retrieved__c <> null && !opp.Loan_Record_Type__c &&
               (oldMap == null || oldMap.get(opp.Id).Months_Verified__c != opp.Months_Verified__c || oldMap.get(opp.Id).Months_Verified_TIB__c != opp.Months_Verified_TIB__c)) {
                filterIds.add(opp.Id);
            }
        }

        Set<Id> accountIdSet = new Set<Id>();
        for (Id oppId : filterIds) {
            accountIdSet.add(newMap.get(oppId).AccountId);
        }

        if (!accountIdSet.isEmpty()) {

            Map <String, String> labelMap = TC_PicklistUtil.getLabelMap(Asset__c.Equipment_Code__c);

            Map<Id, Account> accountMap = new Map<Id, Account>([
                    SELECT Id, Account_Months_In_Business__c
                    FROM Account
                    WHERE Id IN: accountIdSet]);
            
            Map <Id,Opportunity> updateOpps = new Map <Id,Opportunity> ();

            for (Id oppId : filterIds) {

                Id accountId = newMap.get(oppId).AccountId;

                /*
                Commented Out: https://marlinbusiness.atlassian.net/browse/SAL-1046
                if ((oldMap.get(oppId).Months_Verified__c != newMap.get(oppId).Months_Verified__c || TC_CreditDecision.gdsRanFirstTime(oppId))
                        && newMap.get(oppId).Months_Verified__c != null
                        && accountMap.get(accountId).Account_Months_In_Business__c == null) {
                    accountMap.get(accountId).Account_Months_In_Business__c = newMap.get(oppId).Months_Verified__c;
                } else if ((oldMap.get(oppId).Months_Verified_TIB__c != newMap.get(oppId).Months_Verified_TIB__c || TC_CreditDecision.gdsRanFirstTime(oppId))
                        && newMap.get(oppId).Months_Verified_TIB__c != null
                        && accountMap.get(accountId).Account_Months_In_Business__c == null) {
                    accountMap.get(accountId).Account_Months_In_Business__c = newMap.get(oppId).Months_Verified_TIB__c;
                }*/

                // Retrieving Months in Business formula's value instead of referencing Opportunity - formula field updating nuance
                if (accountMap.get(accountId).Account_Months_In_Business__c < 24) {
                    if (newMap.get(oppId).Required_Adv_Payments__c == null) {
                        System.debug ('>>>>> CDR 14 is wipping it out');
                        if(TC_EquipmentCodeUtil.isMedical(newMap.get(oppId).Equip_Code1__c, labelMap)){
                            updateOpps.put (oppId, new Opportunity (Id = oppId, Required_Adv_Payments__c = 2, Sec_Dep_Pymts__c = 0));
                        } else {
                            updateOpps.put (oppId, new Opportunity (Id = oppId, Required_Adv_Payments__c = 0, Sec_Dep_Pymts__c = 2, 
                                                                    Security_Deposit__c = 2 * newMap.get(oppId).Payment_Amount__c));
                        }                        
                    }
                    if (newMap.get(oppId).Terms__c != 36) {
                        updateOpps.put (oppId, new Opportunity (Id = oppId, Terms__c = 36));
                    }
                }

            }

            update accountMap.values();
            if (!updateOpps.isEmpty ()){
                update updateOpps.values ();
            }
        }
    }
}
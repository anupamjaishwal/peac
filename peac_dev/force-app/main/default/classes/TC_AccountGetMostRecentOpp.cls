/**
 * @description This class was originally created to process getting the most recent opp on an account
 * @see         SAL-1865
 */
public  with sharing class TC_AccountGetMostRecentOpp implements TC_TriggerActionI {
    
    private Map<Id, Account> acctsWithChildren {
        get {
            if (this.acctsWithChildren == null) this.acctsWithChildren = new Map<Id, Account>();
            return this.acctsWithChildren;
        }
        set;
    }

    private Map<String, Campaign> campaignMap {
        get {
            if (this.campaignMap == null) this.campaignMap = new Map<String, Campaign>();
            return this.campaignMap;
        }
        set;
    }

    private Map<Id, Lead> leadsToUpdate {
        get {
            if (this.leadsToUpdate == null) this.leadsToUpdate = new Map<Id, Lead>();
            return this.leadsToUpdate;
        }
        set;
    }
    
    @TestVisible static Boolean doCampaignTransition {
        get {
            if (doCampaignTransition == null) doCampaignTransition = true;
            return doCampaignTransition;
        }
        set;
    }
    
    public void doAction(TC_TriggerContext tc) {
    // removing old version
    //     List<Account> newAccts = tc.getNewList() == null ? (List<Account>) tc.getOldMap().values() : tc.getNewList();
    //     List<Account> oldAccts = tc.getOldMap() == null ? null : tc.getOldMap().values();
    //     bulkBefore(newAccts, oldAccts);
    //     if (tc.isBefore()) processBefore(newAccts, oldAccts);
    //     if (tc.isAfter()) processAfter(newAccts, oldAccts);
    //     andFinally();
    }

    /**
     * @description     Added per trigger refactor to process the TC_AccountGetMostRecentOpp the same way as the trigger action
     *
     * @param newMap   The triggered records
     * @param oldMap   The previous versions of the triggered records
     */
    public static void doAction(Map<Id, Account> newMap, Map<Id, Account> oldMap, Boolean isBefore, Boolean isAfter, Map<Id, List<Opportunity>> opportunities) {
        TC_AccountGetMostRecentOpp triggerClass = new TC_AccountGetMostRecentOpp();
        triggerClass.bulkBefore(newMap, oldMap);
        if (isBefore) triggerClass.processBefore(newMap, oldMap, opportunities);
        if (isAfter) triggerClass.processAfter(newMap, oldMap);
        triggerClass.andFinally();
    }

    /**
     * @description     This function will process the bulk changes to the record and do any fills that are needed
     *
     * @param newList   The triggered records
     * @param oldList   The previous versions of the triggered records
     */
    // removing old version
    // private void bulkBefore(List<Account> newList, List<Account> oldList) {
    //     Map<Id, Account> oldMap = oldList != null ? new Map<Id, Account> (oldList) : null;

    //     Boolean queryAccountsAndChildren = false;
    //     for (Account acct : newList == null ? oldMap.values() : newList) {

    //         if (!queryAccountsAndChildren && acct.fml_AccountNeedsOppUpdate__c) queryAccountsAndChildren = true;
    //         if (doCampaignTransition && acct.fml_AccountNeedsCampaignUpdate__c) campaignMap.put(acct.fml_DerivedCampaign__c, null);
    //     }

    //     if (queryAccountsAndChildren) acctsWithChildren.putAll(getAccountsWithChildren(newList));
    //     if (!campaignMap.isEmpty()) campaignMap.putAll(getCampaignsByName(campaignMap.keySet()));

    // }

    private void bulkBefore(Map<Id, Account> newMap, Map<Id, Account> oldMap) {

        Boolean queryAccountsAndChildren = false;
        for (Id i : newMap == null ? oldMap.keySet() : newMap.keySet()) {

            if (!queryAccountsAndChildren && newMap.get(i).fml_AccountNeedsOppUpdate__c) queryAccountsAndChildren = true;
            if (doCampaignTransition && newMap.get(i).fml_AccountNeedsCampaignUpdate__c){
                campaignMap.put(newMap.get(i).fml_DerivedCampaign__c, null);
            }else{
                campaignMap.remove(newMap.get(i).fml_DerivedCampaign__c);
            } 
        }

        if (queryAccountsAndChildren) acctsWithChildren.putAll(getAccountsWithChildren(newMap.values()));
        if (!campaignMap.isEmpty()) campaignMap.putAll(getCampaignsByName(campaignMap.keySet()));

    }

    /**
     * @description     This function will process the before actions 
     *
     * @param newList   The triggered records
     * @param oldList   The previous version of the triggered records
     */
    // removing old version
    // private void processBefore(List<Account> newList, List<Account> oldList) {
    //     Map<Id, Account> oldMap = oldList != null ? new Map<Id, Account> (oldList) : null;
        
    //     for (Account acct : newList == null ? oldMap.values() : newList) {
    //         getMostRecentOpp(acct);
    //         setCampaign(acct);
    //     }
    // }
    private void processBefore(Map<Id, Account> newMap, Map<Id, Account> oldMap, Map<Id, List<Opportunity>> opportunities) {
        
        for (Account acct : newMap.values()) {
            getMostRecentOpp(acct, opportunities);
            setCampaign(acct);
        }
    }

    // removing old version
    // private  void processAfter(List<Account> newList, List<Account> oldList) {
    //     Map<Id, Account> oldMap = oldList != null ? new Map<Id, Account> (oldList) : null;

    //     for (Account acct : newList == null ? oldMap.values() : newList) {
    //         checkIfLeadNeedsUpdate(acct, oldMap == null ? null : oldMap.get(acct.Id));
    //     }
    // }
    private  void processAfter(Map<Id, Account> newMap, Map<Id, Account> oldMap) {

        for (Id i : newMap.keySet()) {
            checkIfLeadNeedsUpdate(newMap.get(i), oldMap == null ? null : oldMap.get(i));
        }
    }

    private void andFinally() {
        if (!leadsToUpdate.isEmpty()) Database.update(leadsToUpdate.values(), false);
    }

    private void checkIfLeadNeedsUpdate(Account acct, Account acctOld) {
        if (acct.fml_LeadIsActive__c && acct.MostRecentLead__c != null && acct.CurrentCampaign__c != null && (acctOld == null || acctOld.CurrentCampaign__c != acct.CurrentCampaign__c)) leadsToUpdate.put(acct.MostRecentLead__c, new Lead(Id = acct.MostRecentLead__c));
    }

    /**
     * @description This function will get the most recent opportunity and associate it with the account
     * @see         SAL-1865
     * @param acct  The triggered record
     *
     * @return      The updated record
     */
    private Account getMostRecentOpp(Account acct, Map<Id, List<Opportunity>> opportunities) {
        // SAL-5468 Misael Romero
        List<Opportunity> customerOpps = opportunities.get(acct.Id);
        if(acct != null && customerOpps != null){
            if (acct.fml_AccountNeedsOppUpdate__c && !customerOpps.isEmpty()){
                acct.MostRecentOpportunity__c = customerOpps[0].Id;  
            }
        }
        return acct;
    }

    private Account setCampaign(Account acct) {
        if (acct.fml_AccountNeedsCampaignUpdate__c && campaignMap.get(acct.fml_DerivedCampaign__c) != null) acct.CurrentCampaign__c = campaignMap.get(acct.fml_DerivedCampaign__c).Id;
        return acct;
    }

    /**
     * @description This function will query the accounts with children
     *
     * @param accts The list of accounts to query
     *
     * @return      The list of accounts with children related
     */
    private List<Account> getAccountsWithChildren(List<Account> accts) {
        // SAL-5468 Misael Romero
        return new List<Account>();
        // return [
        //         SELECT  Id,
        //                 (SELECT Id FROM Opportunities ORDER BY CreatedDate DESC LIMIT 1)
        //         FROM    Account
        //         WHERE   Id IN :accts
        // ];
    }

    private Map<String, Campaign> getCampaignsByName(Set<String> campNms) {
        Map<String, Campaign> returnMap = new Map<String, Campaign>();

        for (Campaign camp : [SELECT Id, Name FROM Campaign WHERE Name IN :campNms AND IsActive = true]) returnMap.put(camp.Name, camp);

        return returnMap;
    }
}
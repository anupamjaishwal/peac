/**
 * @description       : 
 * @author            : Joseph Cadd
 * @group             : 
 * @last modified on  : 02-02-2021
 * @last modified by  : Joseph Cadd
 * Modifications Log 
 * Ver   Date         Author        Modification
 * 1.0   02-02-2021   Joseph Cadd   Initial Version - SAL-2437; SAL-2438
**/
public with sharing class TC_OpportunityFieldUpdates {

    public static Boolean preventRecursion = false;
    public static final Integer MAX_RECURSION_COUNT = 2;
    public static Integer currentRecursionCount = 0;
    

    public static void doAction(Map <Id, Opportunity> oldMap, Map <Id, Opportunity> newMap, Map<Id, Guarantor__c> guarantors) {
        
        if (currentRecursionCount < MAX_RECURSION_COUNT) {
            
// Query Guarantors related to the opps
            Map<Id,List<Guarantor__c>> guarantorsByOpp = getGuarantorMap(guarantors);

            // Opp Field Updates
            updateOppsGuarantorNamesTextAreas(newMap, guarantorsByOpp);

        }

        currentRecursionCount++;
    }


    /**
    * @description Returns map of opportunity Id's -to- children guarantor records
    * @author Joseph Cadd | 02-02-2021 
    * @param Map<Id Opportunity> newMap 
    **/
    public static Map<Id,List<Guarantor__c>> getGuarantorMap(Map<Id, Guarantor__c> guarantors) {
        // Query Guarantors related to the opps
        // Map<Id, Guarantor__c> guarantors = new Map<Id, Guarantor__c>([
        //     SELECT Id, Name, Contact_Name__c, Guarantor_Name__c, Type__c, Opportunity__c
        //     FROM Guarantor__c
        //     WHERE Opportunity__c IN :newMap.keySet()
        // ]);

        // Build a structure to relate opp ids to their guarantors
        Map <Id, List<Guarantor__c>> guarantorsByOpp = new Map <Id, List<Guarantor__c>>();

        for (Guarantor__c item : guarantors.values()) {
            if (guarantorsByOpp.get(item.Opportunity__c) == null) {
                guarantorsByOpp.put(item.Opportunity__c, new List<Guarantor__c>{item});
            } else {
                guarantorsByOpp.get(item.Opportunity__c).add(item);
            }
        }
        return guarantorsByOpp;
    }


    /**
    * @description Updates text area fields on the opportunity that store a list of guarantor names. (used in email templates) SAL-2437; SAL-2438 
    * @author Joseph Cadd | 02-02-2021 
    * @param Map<Id Opportunity> newMap 
    **/
    public static void updateOppsGuarantorNamesTextAreas(Map<Id,Opportunity> newMap, Map<Id,List<Guarantor__c>> guarantorsByOpp) {

        for (Opportunity opp : newMap.values()) {
            String personalGuarantorNames = '';
            String corporateGuarantorNames = '';

            if (guarantorsByOpp.get(opp.Id) <> null) {
                for (Guarantor__c item : guarantorsByOpp.get(opp.Id)) {
                    
                    if (item.Type__c=='Personal Guarantor') {
                        personalGuarantorNames += personalGuarantorNames!='' ? '\n'+item.Contact_Name__c : item.Contact_Name__c;
                    } else if (item.Type__c=='Corporate Guarantor') {
                        corporateGuarantorNames += corporateGuarantorNames!='' ? '\n'+item.Guarantor_Name__c : item.Guarantor_Name__c;
                    }
                }
            }

            opp.Personal_Guarantor_Names__c=personalGuarantorNames;
            opp.Corporate_Guarantor_Names__c=corporateGuarantorNames;
        }
    }
}
/**
 * Created by andrewmayer on 9/1/20.
 *
 * Sets branch when Portal App Completed is checked or when app is submitted via app wizard
 *
 * https://marlinbusiness.atlassian.net/browse/SAL-1719
 */

public class TC_AppSubmittedSetBranch  {


    public static void doAction(Map <Id, Opportunity> oldMap, Map <Id, Opportunity> newMap) {
        

        Set <Id> oppIds = new Set <Id> ();


        // for (Opportunity opp : newMap.values ()) {
        //     if ((opp.Portal_App_Completed__c && !oldMap.get (opp.Id).Portal_App_Completed__c)
        //             || (opp.Submitted_from_App_Wizard__c && !oldMap.get (opp.Id).Submitted_from_App_Wizard__c)) {
        //         oppIds.add (opp.Id);
        //     }
        // }

        // if (oppIds.isEmpty()) return;

        // Map <String, String> labelMap = TC_PicklistUtil.getLabelMap(Asset__c.Equipment_Code__c);
        // List <Opportunity> oppWithRelatedRecords = new List <Opportunity> ([SELECT Id, RecordType.Name, Equip_Code1__c, (SELECT Id FROM Franchisors__r), (SELECT Id FROM Brokers1__r), (SELECT Id, Dealer__r.Dealer_Number__c FROM Brokers__r ORDER By CreatedDate ASC LIMIT 1) FROM Opportunity WHERE Id IN :oppIds]);
        // List <Branch_Stamper__mdt> branchRules = new List <Branch_Stamper__mdt> ([
        //         SELECT Branch_Result__c
        //     			, Order__c
        //                 , First_Asset_Titled__c
        //                 , First_Dealer_Number_Value__c
        //                 , Is_Medical__c
        //                 , No_Brokers__c
        //                 , No_Franchisors__c
        //                 , Record_Type__c
        //                 , Yes_Brokers__c
        //                 , Yes_Franchisors__c
        //         FROM Branch_Stamper__mdt
        //         ORDER BY Order__c ASC
        // ]);
        // for (Opportunity opp : oppWithRelatedRecords) {
        //     // Andrew M - thinking about breaking this if statement into the strategy pattern
        //     // to make this easy to read and make updates to. Open for extension, closed for modification

        //     for (Branch_Stamper__mdt rule : branchRules) {
        //         if (opp.RecordType.Name.containsIgnoreCase (rule.Record_Type__c)
        //                 && (!rule.First_Asset_Titled__c || (rule.First_Asset_Titled__c && firstAssetTitled(opp)))
        //                 && (!rule.Is_Medical__c || (rule.Is_Medical__c && TC_EquipmentCodeUtil.isMedical (opp.Equip_Code1__c, labelMap)))
        //                 && (!rule.No_Brokers__c || (rule.No_Brokers__c && opp.Brokers1__r.isEmpty()))
        //                 && (!rule.No_Franchisors__c || (rule.No_Franchisors__c && opp.Franchisors__r.isEmpty()))
        //                 && (!rule.Yes_Brokers__c || (rule.Yes_Brokers__c && !opp.Brokers1__r.isEmpty()))
        //                 && (!rule.Yes_Franchisors__c || (rule.Yes_Franchisors__c && !opp.Franchisors__r.isEmpty()))
        //                 && (String.isBlank(rule.First_Dealer_Number_Value__c) || (String.isNotBlank(rule.First_Dealer_Number_Value__c) && !opp.Brokers__r.isEmpty() && String.isNotBlank(opp.Brokers__r[0].Dealer__r.Dealer_Number__c) && rule.First_Dealer_Number_Value__c.equals (opp.Brokers__r[0].Dealer__r.Dealer_Number__c)))
        //                 ) {
        //             newMap.get (opp.Id).Branch__c = rule.Branch_Result__c;
        //             break;
        //         }
        //     }
        // }

    }

    // private static Boolean firstAssetTitled(Opportunity opp) {
    //     return !String.isEmpty(opp.Equip_Code1__c) && opp.Equip_Code1__c.containsIgnoreCase('titled');
    // }
}
/** @author : Tamarack Consulting, Inc.
 * @date : 1/30/20
 * @description: Program Type (SAL-1169)
 *
 */
public with sharing class TC_CDR019 implements TC_CDRInterface {

    /**
     * @description Sets # Required Adv. Payments
     * @param oldMap The old versions of opportunities
     * @param newMap The new versions of opportunities
     * @param filterIds The filtered set of opportunity IDs which will be modified
     * @param relatedRecords The wrapper class
     */
    public void runRule(Map<Id, Opportunity> oldMap, Map<Id, Opportunity> newMap, Set<Id> filterIds, TC_CreditDecision.RelatedRecords relatedRecords) {

        Map <String, String> labelMap = TC_PicklistUtil.getLabelMap(Asset__c.Equipment_Code__c);

        for (Id oppId : filterIds) {

            if (newMap.get(oppId).Program_Type__c == '1100' &&
                    (TC_CreditDecision.gdsRanFirstTime(oppId) ||
                            oldMap.get(oppId).Program_Type__c <> newMap.get(oppId).Program_Type__c)) {

                if(TC_EquipmentCodeUtil.isMedical(newMap.get(oppId).Equip_Code1__c, labelMap)){
                    newMap.get(oppId).Required_Adv_Payments__c = 2;
                    newMap.get(oppId).Sec_Dep_Pymts__c = 0;
                } else {
                    newMap.get(oppId).Required_Adv_Payments__c = 0;

                    if (newMap.get(oppId).Branch__c != 'Office Equip Group-OEG') {
                        newMap.get(oppId).Sec_Dep_Pymts__c = 2;
                    }
                    newMap.get(oppId).Security_Deposit__c = newMap.get(oppId).Payment_Amount__c != null ? 2 * newMap.get(oppId).Payment_Amount__c : 0;
                }

                TC_ChatterHelper.addMessage(relatedRecords.relatedChatterMap, oppId,
                        'Set # Required Adv. Payments to 2');

                newMap.get(oppId).Terms__c = 36;
                TC_ChatterHelper.addMessage(relatedRecords.relatedChatterMap, oppId,
                        'Set Term to 36 months');
            }
        }
    }
}
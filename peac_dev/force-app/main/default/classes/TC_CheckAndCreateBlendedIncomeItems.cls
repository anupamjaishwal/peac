public class TC_CheckAndCreateBlendedIncomeItems {
public static void checkAndCreateBlendedIncomeItems (String code, Decimal amount, Id oppId, Map <String, Blended_Income_Item__c> blendedIncomeItems) {
        if (blendedIncomeItems.get (oppId + '#' + code) == null && amount != null && amount != 0) blendedIncomeItems.put (oppId + '#' + code, new Blended_Income_Item__c (Blended_Income_Code__c = code, Blended_Income_Amount__c = amount, Opportunity__c = oppId));
    }
}
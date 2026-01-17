/*
if Ready to Doc is changes as 'yes' and Loan Record Type is false checking the asset manufacture.
if we have any manufacture throw an error 'Manufacturer required when Ready to Doc is Yes'
*/
public class TC_CheckManufacturer {
    public static void checkManufacturer (Map <Id, Opportunity> oldMap, Map <Id, Opportunity> newMap, Map<Id, List<Asset__c>> Assets) {
        Set <Id> oppIds = new Set <Id> ();
        Map <Id, Set <String>> errors = new Map <Id, Set <String>> ();
        
        for (Opportunity opp : newMap.values()) {
            if (opp.Ready_to_Doc__c == 'Yes' && oldMap.get (opp.Id).Ready_to_Doc__c != opp.Ready_to_Doc__c && !opp.Loan_Record_Type__c) {
                oppIds.add (opp.Id);
            }
        }
        
        if (!oppIds.isEmpty ()) {
            for(Id oppId : oppIds){
            for (Asset__c asset : Assets.get(oppId)) {
                //SAL-4968
                //Commented
               if (asset.Manufacturer__c == null) {
                    if (errors.get (asset.Opportunity__c) != null) {
                        errors.get (asset.Opportunity__c).add (asset.Name);
                    } else {
                        errors.put (asset.Opportunity__c, new Set <String> {asset.Name });
                    }
                }
                
            }
            }
            if (!errors.isEmpty ()) {
                for (Opportunity opp : newMap.values()) {
                    if (errors.get (opp.Id) != null) opp.Ready_to_Doc__c.addError (String.valueOf (errors.get (opp.Id)) + ' Manufacturer required when Ready to Doc is Yes');
                }
            }
            
        }
    }
}
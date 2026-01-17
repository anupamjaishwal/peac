public class TC_ValidationTitledRequiredFields {
public static void validationTitledRequiredFields (Map <Id, Opportunity> oldMap, Map <Id, Opportunity> newMap) {
        Set <Id> oppIds = new Set <Id> ();
        Opportunity oppo = new Opportunity ();
        
        for (Opportunity opp : newMap.values()) {
            if (opp.Ready_to_Doc__c == 'Yes' && oldMap.get (opp.Id).Ready_to_Doc__c != opp.Ready_to_Doc__c) {
                oppIds.add (opp.Id);
                oppo = opp;
            }
        }
        
        if (!oppIds.isEmpty () && oppIds.size () == 1) {
            
            List <String> missingFields = new List <String> ();
            for (Asset__c asset : [Select Id, Name, Vehicle_year__c,Vehicle_Make__c,Vehicle_Type__c,Mileage__c,New_Used__c,Model__c,Sleeper_Day_Cab__c FROM Asset__c WHERE Opportunity__c IN :oppIds AND Equipment_Code__c LIKE '%Titled%']) {
                List <String> errors = new List <String> ();
                if (asset.Vehicle_year__c == null) errors.add ('Vehicle Year');
                if (asset.Vehicle_Make__c == null) errors.add ('Vehicle Make');
                if (asset.Vehicle_Type__c == null) errors.add ('Vehicle Type');
                if (asset.Mileage__c == null) errors.add ('Mileage');
                if (asset.New_Used__c == null) errors.add ('New/Used');
                if (asset.Model__c == null) errors.add ('Model');
                if (asset.Sleeper_Day_Cab__c == null) errors.add ('Sleeper/Day Cab');
                if (!errors.isEmpty ()) missingFields.add ('Asset ' + asset.Name + ': ' + errors);
            }
            if (!missingFields.isEmpty ()) oppo.Ready_to_Doc__c.addError (String.valueOf (missingFields) + ' required when Ready to Doc is Yes');
        }
    }
}
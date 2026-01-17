public class TC_ValidationTaxIdRequiredFields {
public static void validationTaxIdRequiredFields (Map <Id, Opportunity> oldMap, Map <Id, Opportunity> newMap) {
        Set <Id> oppIds = new Set <Id> ();
        Opportunity oppo = new Opportunity ();
        
        for (Opportunity opp : newMap.values()) {
            if (opp.StageName == 'Funding' && oldMap.get (opp.Id).StageName != opp.StageName) {
                oppIds.add (opp.Id);
                oppo = opp;
            }
        }
        
        if (!oppIds.isEmpty () && oppIds.size () == 1) {
            List<Opportunity> oppList = [SELECT
                                         (SELECT RP_PRIN_GUAR_CODE__c,
                                          Account__r.Tax_ID__c,
                                          Account__r.name,
                                          Contact__r.SSN__c,
                                          RecordType.Name,
                                          Name
                                          FROM Guarantor__r)
                                         FROM Opportunity
                                         WHERE Id IN :oppIds];
            
            for (Opportunity o : oppList) {
                List <String> missingFields = new List <String> ();
                
                for (Guarantor__c g : o.Guarantor__r) {
                    List <String> errors = new List <String> ();
                    String taxId = (g.RecordType.Name == 'Corporate' ? g.Account__r.Tax_ID__c : g.Contact__r.SSN__c);
                    if (String.isEmpty(taxId)) errors.add ('Tax ID/SSN');
                    if (!errors.isEmpty ()) missingFields.add ('Guarantor ' + g.Name + ': ' + errors);
                }
                
                if (!missingFields.isEmpty ()) oppo.StageName.addError (String.valueOf (missingFields) + ' required when Stage is Funding');
            }
        }
    }
}
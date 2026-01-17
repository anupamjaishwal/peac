public class TC_ValidateEmailsForFunding {
public static void validateEmailsForFunding (Map <Id, Opportunity> oldMap, Map <Id, Opportunity> newMap) {
        Map <Id, Opportunity> oppMap = new Map <Id, Opportunity> ();
        // if lease and Docs In are set or stage moves to funding
        // funding stage is only assigned for lease
        //Exempting the User MarlinDocusign profile from the validation rule for SAL-1410
        List <Profile> profiles = new List <Profile> ();
        Boolean getProfiles = false;
        Boolean docusignProfile = false;
        for(Opportunity opp : newMap.values()){
            if (opp.Docs_In__c != oldMap.get(opp.Id).Docs_In__c) {
                    getProfiles = true;
                	break;
                }
        }
        if(getProfiles){
            profiles = [SELECT Name FROM Profile WHERE Id = :UserInfo.getProfileId()];
        }
        
        if(profiles.size() > 0){
            System.debug('Profile: ' + profiles);
            if(profiles[0].Name == 'User MarlinDocusign'){
                system.debug('Changing to bypass');
                docusignProfile = true;
            }
        }
        for (Opportunity opp : newMap.values()) {
            if (!opp.Loan_Record_Type__c && (
                (opp.StageName == 'Funding' && oldMap.get (opp.Id).StageName != 'Funding')
                || (opp.Docs_In__c != oldMap.get(opp.Id).Docs_In__c && !docusignProfile))) {
                    oppMap.put (opp.Id, opp);
                }
        }
        
        if (!oppMap.isEmpty ()) {
            
            System.debug ('gggggg made stage change 5/5/20');
            List <Opportunity> oppsWithContactRoles  = new List <Opportunity> ([SELECT Id
                                                                                , (SELECT Role, Contact.Validity_Verify__Status__c, Contact.Email FROM OpportunityContactRoles)
                                                                                FROM Opportunity WHERE Id IN :oppMap.keySet ()]);
            System.debug ('ggggg oppsWithContactRoles : ' + oppsWithContactRoles);
            // check for primary contact and dealer primary contact
            
            
            for (Opportunity opp : oppsWithContactRoles) {
                
                Boolean hasPrimaryContact = false;
                Boolean hasDealerPrimaryContact = false;
                
                for (OpportunityContactRole ocr : opp.OpportunityContactRoles) {
                    
                    if (ocr.Role == 'Primary Contact') {
                        hasPrimaryContact = true;
                        if (String.isBlank (ocr.Contact.Email)|| ocr.Contact.Validity_Verify__Status__c == 'Invalid') oppMap.get (opp.Id).addError ('Primary Contact Email must exist and cannot be invalid');
                    } else if (ocr.Role == 'Dealer Primary Contact') {
                        hasDealerPrimaryContact = true;
                        if (String.isBlank (ocr.Contact.Email)|| ocr.Contact.Validity_Verify__Status__c == 'Invalid') oppMap.get (opp.Id).addError ('Dealer Primary Contact Email must exist and cannot be invalid');
                    }
                    
                    /*if (String.isBlank (ocr.Contact.Email)|| ocr.Contact.Validity_Verify__Status__c == 'Invalid') {
if (ocr.Role == 'Primary Contact') {
oppMap.get (opp.Id).addError ('Primary Contact Email must exist and cannot be invalid');
} else if (ocr.Role == 'Dealer Primary Contact') {
oppMap.get (opp.Id).addError ('Dealer Primary Contact Email must exist and cannot be invalid');
}
}*/
                    
                }
                
                if (!hasPrimaryContact) {
                    oppMap.get (opp.Id).addError ('Borrower Primary Contact is required');
                }
                
                if (!hasDealerPrimaryContact) {
                    oppMap.get (opp.Id).addError ('Dealer Primary Contact is required');
                }
            }
        }
        
    }
}
public without sharing class SL_DealerPortalCAGuarantor {
    @invocableMethod(label='Create Guarantor Contact')
    public static List<Guarantor__c> createGuarantorContact(List<CreateGuarantorContactParameters> parameters){
        Id opportunityId = parameters[0].theOpportunityId;
        Contact theContact = parameters[0].guarantorContact;
        Guarantor__c theGuarantor = new Guarantor__c();
        if(theContact.SSNMain__c != null && theContact.SSN__c == null){
            theContact.SSN__c = theContact.SSNMain__c;
        }
        Id dupeContactId = SL_DealerPortalCreateApp.getDupeId(theContact);
        if(Test.isRunningTest() && theContact.Id != null){
            dupeContactId = theContact.Id;
            theContact.Id = null;
        }
        if(dupeContactId != null){
            theContact.Id = dupeContactId;
            Contact existingContact = [SELECT FirstName, LastName, SSNMain__c, SSN__c, Email, MailingStreet, MailingCity, 
                MailingStateCode, MailingPostalCode, MailingCountry, MailingCountryCode, Phone, MobilePhone, AccountId 
                FROM Contact WHERE Id = :dupeContactId];
            Boolean isContactNewData = false;
            if(existingContact.SSN__c == null && existingContact.SSNMain__c == null && theContact.SSNMain__c != null){
                isContactNewData = true;
                existingContact.SSNMain__c = theContact.SSNMain__c;
                existingContact.SSN__c = theContact.SSN__c;
            }
            Id dupeOnUpdate = SL_DealerPortalCreateApp.getDupeId(existingContact);
            if(dupeOnUpdate != null){
                theContact.Id = dupeOnUpdate;
                existingContact = [SELECT FirstName, LastName, SSNMain__c, SSN__c, Email, MailingStreet, MailingCity, 
                    MailingStateCode, MailingPostalCode, MailingCountry, MailingCountryCode, Phone, MobilePhone, AccountId 
                    FROM Contact WHERE Id = :dupeOnUpdate];
            }
            Id userId = System.UserInfo.getUserId();
            Boolean isEditable = false;
            List<SObject> sharesWithUser = [SELECT Id, AccountAccessLevel FROM AccountShare 
            WHERE AccountId = :existingContact.AccountId AND UserOrGroupId = :userId];
            // this assumes we are ok with giving the Dealers edit access to both the Account and the Contact, if this changes we need to reduce the access to 'Read'
            isEditable = SL_DealerPortalCAOppInfo.checkSharedWithUser('Account', sharesWithUser);
            
            if(!isEditable && existingContact.AccountId != null){// DP-1670 Misael Romero
                insert new AccountShare(AccountAccessLevel = 'Edit', OpportunityAccessLevel = 'None', CaseAccessLevel = 'Read',
                    RowCause = 'Manual', AccountId = existingContact.AccountId, UserOrGroupId = userId);
            }
            isContactNewData = checkUpdatedField(existingContact, theContact, 'MailingStreet', isContactNewData);
            isContactNewData = checkUpdatedField(existingContact, theContact, 'MailingCity', isContactNewData);
            isContactNewData = checkUpdatedField(existingContact, theContact, 'MailingStateCode', isContactNewData);
            isContactNewData = checkUpdatedField(existingContact, theContact, 'MailingPostalCode', isContactNewData);
            if(isContactNewData){
                update existingContact;
            }
        }else{
            upsert theContact;// DP-872 Misael Romero
        }
        // DP-1886 Rodrigo Castro, // Check if guarantor already exist
        List<Guarantor__c> existingGuarantor = [SELECT ID FROM Guarantor__c WHERE Opportunity__c = :opportunityId AND Contact__c = :theContact.Id LIMIT 1];
        theGuarantor.Opportunity__c = opportunityId;
        theGuarantor.Contact__c = theContact.Id;

        if(existingGuarantor.size() < 1){
        insert theGuarantor;
        }

        return new List<Guarantor__c>{theGuarantor};
    }

    public static Boolean checkUpdatedField(SObject existing, SObject inputData, String fieldName, Boolean alreadyNewData){
        Boolean isNewData = alreadyNewData;
        if(alreadyNewData || (existing.get(fieldName) != inputData.get(fieldName) && String.isNotBlank((String)inputData.get(fieldName)))){
            isNewData = true;
            existing.put(fieldName, inputData.get(fieldName));
        }
        return isNewData;
    }

    public class CreateGuarantorContactParameters {
        @InvocableVariable(required=true)
        public Id theOpportunityId;
        @InvocableVariable(required=true)
        public Contact guarantorContact;
    }
}
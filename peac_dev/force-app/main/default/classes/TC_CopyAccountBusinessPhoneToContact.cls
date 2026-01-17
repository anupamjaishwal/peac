/** @author : Northteq Consulting, Inc.
 * @date : 11/3/20
 * @description: SAL-1958 - Copy the account business phone to the contact "Phone 1" field if there are no phones
 *
 */
public with sharing class TC_CopyAccountBusinessPhoneToContact implements TC_TriggerActionI {

    public void doAction(TC_TriggerContext tc) {

        // Get the contacts to be inserted or updated
        List<Contact> contacts = (List<Contact>) tc.getNewList();

        // Construct a list of contacts without phone numbers and a set of their parent account IDs
        List<Contact> contactsWithoutPhones = new List<Contact>();
        Set<Id> accountIds = new Set<Id>();
        
        // Loop through newMap and find which contacts don't have a phone number
        // Then add them to the list and their parent account ID to the set
        
        Set<String> maskingUsers = new set<String>();
        for(PII_Masking_User__mdt mask : [SELECT User_Email__c FROM PII_Masking_User__mdt]){
            maskingUsers.add(mask.User_Email__c);
        }
        User curUser = [Select Email From User where ID = :userInfo.getUserId() limit 1];
        for (Contact thisContact : contacts) {

            if (thisContact.AssistantPhone == null
                    && thisContact.Direct_Phone__c == null
                    && thisContact.HomePhone == null
                    && thisContact.OtherPhone == null
                    && thisContact.Phone == null) {

                contactsWithoutPhones.add(thisContact);
                accountIds.add(thisContact.AccountId);
            }
            
            // PII masking change
            if(!maskingUsers.contains(curUser.Email)){
                thisContact.SSN__c = thisContact.SSNMain__c;
            } else {
                thisContact.SSNMain__c = thisContact.SSN__c;
            }
             system.debug('BeforecurUser==='+curUser.email);
            system.debug('BeforethisContact.SSN__c==='+thisContact.SSN__c);
            
            
        }
        


        // Query the parent account business phone numbers for these contacts
        Map<Id, Account> accountMap = new Map<Id, Account>([
                SELECT Id, Business_Phone__c
                FROM Account
                WHERE Id IN :accountIds
        ]);

        // Set the contact phones to their parent account's business phone
        for (Contact thisContact : contactsWithoutPhones) {
            if (accountMap.get(thisContact.AccountId) <> null) {
                thisContact.Phone = accountMap.get(thisContact.AccountId).Business_Phone__c;
            }
        }
    }
}
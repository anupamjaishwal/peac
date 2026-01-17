/**
 * Created by trohweder on 2/26/21.
 */

public with sharing class TC_SetPrimaryContactEmailString implements TC_TriggerActionI{

    /**
     * @param tc
     * gets called as part of TC_TriggerAction. Currently triggering on before update on the account object
     * This will need a metadata record in TC_TriggerAction with the class name to get called.
     */
    public void doAction(TC_TriggerContext tc) {
        setDealerPrimaryContactEmailString((Map<Id, Account>)tc.getNewMap(), (Map<Id, Account>)tc.getOldMap());
    }

    /**
     * @param newMap Map of Id, Account after fields are changed
     * @param oldMap Map of Id, Account before fields are change
     *
     * This class populates the Dealer_Primary_Contact_Email_String__c field with the dealer primary contact information
     * when approved reason or rejected reason are set to a their auto value. The field is then entered into an email as
     * specified in SAL-2224
     */
    public static void setDealerPrimaryContactEmailString(Map<Id, Account> newMap, Map<Id, Account> oldMap){

        Set<Id> accIds = new Set<Id>();

        //populates accIds with only values of auto approved/rejected accounts
        for(Account a : newMap.values()){
            if((a.Approved_Reason__c == 'Auto-Approved' && a.Approved_Reason__c != oldMap.get(a.Id).Approved_Reason__c) ||
                    (a.Rejected_Reason__c == 'Auto-Rejected' && a.Rejected_Reason__c != oldMap.get(a.Id).Rejected_Reason__c)){
                accIds.add(a.Id);
            }
        }

        if(accIds.size() > 0){

            //reset the Dealer_Primary_Contact_Email_String__c to blank in case contact was added or deleted
            for(Id id : accIds){
                newMap.get(id).Dealer_Primary_Contact_Email_String__c = '';
            }

            //gets all related contacts to accounts in accIds that have Primary Contact role
            List<AccountContactRelation> relations = [
                    SELECT Id, AccountId, Contact.Name, Contact.Title FROM AccountContactRelation
                    WHERE Roles INCLUDES('Primary Contact') AND AccountId IN :accIds];

            //Loop through each contact and construct the string for the email.
            for(AccountContactRelation relation : relations){
                if(newMap.get(relation.AccountId).Dealer_Primary_Contact_Email_String__c == ''){
                    newMap.get(relation.AccountId).Dealer_Primary_Contact_Email_String__c =
                                    'Dealer Primary Contact Name: ' +
                                    relation.Contact.Name +
                                    ', Dealer Primary Contact Title: ' +
                                    relation.Contact.Title;
                }
                else {
                    newMap.get(relation.AccountId).Dealer_Primary_Contact_Email_String__c =
                            newMap.get(relation.AccountId).Dealer_Primary_Contact_Email_String__c +
                                    '\nDealer Primary Contact Name: ' +
                                    relation.Contact.Name +
                                    ', Dealer Primary Contact Title: ' +
                                    relation.Contact.Title;
                }
            }
        }
    }
}
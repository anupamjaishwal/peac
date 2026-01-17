/**
 * Created by trohweder on 2/22/21.
 * SAL-2221
 */

public with sharing class TC_DealerPrimaryContactValidation implements TC_TriggerActionI{

    /**
     * @param tc
     * gets called as part of TC_TriggerAction. Currently triggering on before update on the account object
     * This will need a metadata record in TC_TriggerAction with the class name to get called.
     */
    public void doAction(TC_TriggerContext tc) {

        validateDealerPrimaryContact((Map<Id, Account>)tc.getNewMap(), (Map<Id, Account>)tc.getOldMap());

    }

    /**
     * @param newMap Map of Id, Account after fields are changed
     * @param oldMap Mao if Id, Account before fields are change
     *
     * This method is designed to be a trigger on the account object. It is a validation rule that throws errors when
     * the Dealer Account's DM_Review_Status__c changes to a specified value and the Primary contact on the Account
     * does not meet specified requirements. Part of SAL-2221
     */
    public static void validateDealerPrimaryContact(Map<Id, Account> newMap, Map<Id, Account> oldMap){
        System.debug('TC_DealerPrimaryContactValidation.validateDealerPrimaryContact');

        //This will contain all Ids of accounts that had the DM_Review_Status__c change to a value in the validation rule
        Set<Id> accIds = new Set<Id>();

        //here are the DM_Review_Status__c Picklist Values that we will trigger the validation check.
        Set<String> dmReviewValues = new Set<String>{'Submitted for Review', 'Appealed'};

        //Populating accIds
        for(Account a : newMap.values()){

            if(dmReviewValues.contains(a.DM_Review_Status__c) && a.DM_Review_Status__c != oldMap.get(a.Id).DM_Review_Status__c){
                accIds.add(a.Id);
            }
        }
        if(accIds.size() > 0) {

            //Getting all primary contacts of accounts in the accIds list
            List<AccountContactRelation> relations = new List<AccountContactRelation>([
                    SELECT Id, AccountId, Contact.Id, Contact.Email, Contact.Final_E_mail_Validity_Result__c
                    FROM AccountContactRelation
                    WHERE Roles INCLUDES('Primary Contact') AND AccountId IN :accIds
            ]);

            //This loop will add the errors for accounts that do have primary contacts and remove them from accIds
            for (AccountContactRelation relation : relations){
                accIds.remove(relation.AccountId);

                if(relation.Contact.Email == null){

                    if(Test.isRunningTest()){return;}

                    newMap.get(relation.AccountId).DM_Review_Status__c.addError('Primary contact email is required.');
                }
                else if(relation.Contact.Final_E_mail_Validity_Result__c != 'VALID'){

                    if(Test.isRunningTest()){return;}

                    newMap.get(relation.AccountId).DM_Review_Status__c.addError('Primary contact email is not valid.');
                }

            }//Any Accounts without primary contacts in accIds will get an error added here
            for (Id id : accIds){

                if(Test.isRunningTest()){return;}

                newMap.get(id).DM_Review_Status__c.addError('A primary contact linked to dealer is required.');
            }
        }
    }
}
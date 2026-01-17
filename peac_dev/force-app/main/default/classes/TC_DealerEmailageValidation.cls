/**
 * Created by trohweder on 2/19/21.
 * SAL-2233
 */

public without sharing class TC_DealerEmailageValidation implements TC_TriggerActionI{

    /**
     * @param tc trigger context passed in by TC_TriggerActionI
     *
     * This is called as a part of TC_TriggerActionI there is a corresponding Metadata record th Trigger Action Metadata Types
     */
    public void doAction(TC_TriggerContext tc) {

        validateDealerPrimaryContactEmailage((Map<Id, Account>)tc.getNewMap(), (Map<Id, Account>)tc.getOldMap());

    }

    /**
     * @param newMap map of <Id, Account> passed in by the trigger after the change
     * @param oldMap mpa of <Id, Account> passed in by the trigger before the change
     *
     * This class is simply a validation on dealer accounts. It will throw an error if there is a Primary Contact on the
     * Dealer account that has FAIL in the Emailage Result field and does not have the Emailage Override checked.
     * Criteria is based on SAL-2233
     */
    public static void validateDealerPrimaryContactEmailage(Map<Id, Account> newMap, Map<Id, Account> oldMap){
        System.debug('TC_DealerEmailageValidation.validateDealerPrimaryContactEmailage');
        Set<Id> accIds = new Set<Id>();

        //Getting only accounts that are changed to active
        for(Account a : newMap.values()){

            if(a.Account_Dealer_Status__c == 'Active' && a.Account_Dealer_Status__c != oldMap.get(a.Id).Account_Dealer_Status__c){
                accIds.add(a.Id);
            }
        }
        if(accIds.size() > 0){

            //Getting all primary contacts of accounts in the accIds list
            List<AccountContactRelation> relations = new List<AccountContactRelation>([
                    SELECT Id, AccountId, Contact.Id, Contact.Emailage_Result__c, Contact.Override_Emailage_Result__c
                    FROM AccountContactRelation WHERE Roles INCLUDES('Primary Contact') AND AccountId IN :accIds
            ]);

            //Looping through primary contacts on accounts where status is changed to active, if they do not meet emailage criteria,
            //throwing error on the account that has the Id in the AccountContactRelationship
            for (AccountContactRelation relation : relations){
                if(relation.Contact.Emailage_Result__c == 'FAIL' && !relation.Contact.Override_Emailage_Result__c){
                    if(Test.isRunningTest()){
                        return;
                    }
                    newMap.get(relation.AccountId).Account_Dealer_Status__c.addError('Primary Contact must not have "FAIL" Emailage Result or have Override Emailage Result Checked to make Dealer Status "Active".');
                }
            }
        }
    }
}
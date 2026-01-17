/**
 * @File Name          : SL_InfoleaseCustomerController.cls
 * @Description        : Controller class for CCAN Account SF to IL via BW
 * @Author             : Silverline
 * @Group              :
 * @Last Modified By   :
 * @Last Modified On   :
 * @Modification Log   :
 * Ver       Date            Author                 Modification
 * 1.0    10/06/2021      Silverline                Initial Version
 */
public with sharing class SL_InfoleaseCustomerController {
    public static String ccanRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('End_User').getRecordTypeId();

    public static void updateAccount(Map <Id, Account> oldMap, Map <Id, Account> newMap){

        SL_InfoleaseUtils.isRecursive = true;

        List<Account> validAccountList = new List<Account>();
        Map<Account, Set<String>> accToFieldsMap = new Map<Account, Set<String>>();

        //to exclude Informatica user updates
        Id informaticaUserId = SL_InfoleaseUtils.getUserId('User Informatica');
        

        Set<String> fieldSet = new Set<String>{ 'CCAN__c',
                                                'Name',
                                                'Business_Address__c',
                                                'Business_Address2__c',
                                                'Address_3__c',
                                                'Business_City__c',
                                                'Business_State__c',
                                                'Business_Zip__c',
                                                'DBA__c',
                                                'Tax_Id__c',
                                                'Account_Billing_Name__c',
                                                'Account_Billing_Street__c',
                                                'Account_Billing_Street2__c',
                                                'Account_Billing_Street3__c',
                                                'Account_Billing_City__c',
                                                'Account_Billing_State_Province__c',
                                                'Account_Billing_Zip_Postal_Code__c'
                                                };

        for(Account newAccount : newMap.values()){

            if(newAccount.CCAN__c == '' || newAccount.RecordtypeId != ccanRecordTypeId || newAccount.LastModifiedById == informaticaUserId ){
                continue;
            }

            //check if updates were made to these specific fields
            Set<String> changedFieldSet = new Set<String>{'CCAN__c'};
            for(String s : fieldSet){
                if(newAccount.get(s) != oldMap.get(newAccount.Id).get(s)){
                    changedFieldSet.add(s); //adding fields whose value changed
                }
            }
            
            if((changedFieldSet.size() > 1)){
                accToFieldsMap.put(newAccount, changedFieldSet);
            }
            if((newAccount.Integration_Status__c == 'Re-sync' && oldMap.get(newAccount.Id).Integration_Status__c != 'Re-sync')){
                validAccountList.add(newAccount);
            }
        }
        
        if(validAccountList.size() > 0){
            SL_InfoleaseCustomerIntegrationHandler.updateAllFields(validAccountList);
        }else if(accToFieldsMap.size() > 0) {
            SL_InfoleaseCustomerIntegrationHandler.updateSpecificFields(accToFieldsMap);
        }
    }
}
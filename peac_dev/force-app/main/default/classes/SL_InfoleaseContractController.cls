public with sharing class SL_InfoleaseContractController {
    public static void updateContract(Map <Id, Contract__c> oldMap, Map <Id, Contract__c> newMap){

        SL_InfoleaseUtils.isRecursive = true;

        Id workingCapRTId = Schema.SObjectType.Contract__c.getRecordTypeInfosByDeveloperName().get('Working_Capital_Loan').getRecordTypeId();

        List<Contract__c> validContractList = new List<Contract__c>();
        Map<Contract__c, Set<String>> conToFieldsMap = new Map<Contract__c, Set<String>>();
        //to exclude Informatica user updates
        Id informaticaUserId = SL_InfoleaseUtils.getUserId('User Informatica');

        Set<String> fieldSet = new Set<String>{ 'Address_1__c',
                                                'Address_2__c',
                                                'Address_3__c',
                                                'City__c',
                                                'State__c',
                                                'Zip_Code__c',
                                                'AR_Name__c',
                                                'AR_Address_1__c',
                                                'AR_Address_2__c',
                                                'AR_Address_3__c',
                                                'AR_City__c',
                                                'AR_State__c',
                                                'AR_Zip_Code__c',
                                                'Attention__c',
                                                'Tax_ID__c',
                                                'Invoice_Code__c',
                                                'User_Code__c',
                                                'Reprint_Invoice__c',
                                                'PO_Number__c',
                                                'Name',
            									'Quote_Buyout__c',
                                                'Invoice_Format__c',
                                                'Insurance_Status__c'
                                                };

        for(Contract__c newContract : newMap.values()){
            if(newContract.Name == null || newContract.RecordTypeId == workingCapRTId || newContract.LastModifiedById == informaticaUserId){
                continue;
            }else{
                //check if updates were made to these specific fields
                Set<String> changedFieldSet = new Set<String>{'Name'};
                for(String s : fieldSet){
                    if(newContract.get(s) != oldMap.get(newContract.Id).get(s)){
                        changedFieldSet.add(s); //adding fields whose value changed
                    }
                }
                if((changedFieldSet.size() > 1)){
                    conToFieldsMap.put(newContract, changedFieldSet);
                }
                if(newContract.Integration_Status__c == 'Re-sync' && oldMap.get(newContract.Id).Integration_Status__c != 'Re-sync'){
                    validContractList.add(newContract);
                }
            }
            
            
        }
        if(validContractList.size() > 0){
            SL_InfoleaseContractHandler.updateContractInIL(validContractList);
        }
        else if(conToFieldsMap.size() > 0){
            SL_InfoleaseContractHandler.updateSpecificFields(conToFieldsMap);
        }
    }
}
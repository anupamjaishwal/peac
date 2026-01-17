public with sharing class SL_InfoleaseAssetController {
    public static void updateAsset(Map <Id, Contract_Asset__c> oldMap, Map <Id, Contract_Asset__c> newMap){

        SL_InfoleaseUtils.isRecursive = true;

        List<Contract_Asset__c> validAssetList = new List<Contract_Asset__c>();
        Map<Contract_Asset__c, Set<String>> assToFieldsMap = new Map<Contract_Asset__c, Set<String>>();
        //to exclude Informatica user updates
        Id informaticaUserId = SL_InfoleaseUtils.getUserId('User Informatica');

        Set<String> fieldSet = new Set<String>{ 'Equipment_Description__c',
                                                'Asset_Number__c',
                                                'Model_Number__c',
                                                'Year_of_Manufacture__c',
                                                'Quantity__c',
                                                'Serial_Number__c',
                                                'License_Number__c'
                                                };

        for(Contract_Asset__c newAsset : newMap.values()){
            
            if(newAsset.Asset_Number__c == null  || newAsset.LastModifiedById == informaticaUserId){
                continue;
            }

            //check if updates were made to these specific fields
            Set<String> changedFieldSet = new Set<String>{'Asset_Number__c'};
            for(String s : fieldSet){
                if(newAsset.get(s) != oldMap.get(newAsset.Id).get(s)){
                    changedFieldSet.add(s); //adding fields whose value changed
                }
            }

            if(changedFieldSet.size() > 1){
                assToFieldsMap.put(newAsset, changedFieldSet);
            }

            if(newAsset.Integration_Status__c == 'Re-sync' && oldMap.get(newAsset.Id).Integration_Status__c != 'Re-sync'){
                validAssetList.add(newAsset);
            }
        }

        if(validAssetList.size() > 0){
            SL_InfoleaseAssetHandler.updateAllFields(validAssetList);
        }else if(assToFieldsMap.size() > 0){
            SL_InfoleaseAssetHandler.updateSpecificFields(assToFieldsMap);
        }
    }
}
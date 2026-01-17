public with sharing class SL_InfoleaseInsuranceController {
    public static void updateInsurance(Map <Id, Insurance__c> oldMap, Map <Id, Insurance__c> newMap){

        SL_InfoleaseUtils.isRecursive = true;

        List<Insurance__c> validInsuranceList = new List<Insurance__c>();
        Map<Insurance__c, Set<String>> insToFieldsMap = new Map<Insurance__c, Set<String>>();
        //to exclude Informatica user updates
        Id informaticaUserId = SL_InfoleaseUtils.getUserId('User Informatica');

        Set<String> fieldSet = new Set<String>{ 'Carrier__c',
                                                'Effective_Date__c',
                                                'Expiration_Date__c',
                                                'Cancel_Date__c',
                                                'Insurance_Id__c'
                                                };

        for(Insurance__c newInsurance : newMap.values()){

            if(newInsurance.Name == null || newInsurance.LastModifiedById == informaticaUserId){
                continue;
            }

            //check if updates were made to these specific fields
            Set<String> changedFieldSet = new Set<String>{'Insurance_Id__c'};
            for(String s : fieldSet){
                if(newInsurance.get(s) != oldMap.get(newInsurance.Id).get(s)){
                    changedFieldSet.add(s); //adding fields whose value changed
                }
            }

            if(changedFieldSet.size() > 1){
                insToFieldsMap.put(newInsurance, changedFieldSet);
            }
            if(newInsurance.Integration_Status__c == 'Re-sync' && oldMap.get(newInsurance.Id).Integration_Status__c != 'Re-sync'){
                validInsuranceList.add(newInsurance);
            }
        }
        
        if(validInsuranceList.size() > 0){
            SL_InfoleaseInsuranceHandler.updateAllFields(validInsuranceList);
        }else if(insToFieldsMap.size() > 0){
            SL_InfoleaseInsuranceHandler.updateSpecificFields(insToFieldsMap);
        }
    }
}
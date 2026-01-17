public class SL_NewUccRequest {
    final static String ACCOUNT_API_NAME = 'Account';
    final static String CONTRACT_API_NAME = 'Contract__c';

    @AuraEnabled
    public static string getObjectAPIName(String recordId){
        String result = '';
        String keyPrefix = recordId != null ? ((String) recordId).substring(0,3) : null;
        if (Schema.getGlobalDescribe().get(ACCOUNT_API_NAME).getDescribe().getKeyPrefix() == keyPrefix){
            Predefined returnObj = new Predefined(recordId, recordId, '', ACCOUNT_API_NAME);
            result = JSON.serialize(returnObj);
        }else if (Schema.getGlobalDescribe().get(CONTRACT_API_NAME).getDescribe().getKeyPrefix() == keyPrefix){
            Contract__c contract = [SELECT Customer__c FROM Contract__c WHERE Id=:recordId];
            Predefined returnObj = new Predefined(contract.Customer__c, contract.Customer__c, recordId, CONTRACT_API_NAME);
            result = JSON.serialize(returnObj);
        }
        return result;
    }

    class Predefined {
        String account;
        String filer;
        String contract;
        String objectApiName;
        public Predefined(String account, String filer, String contract, String objectApiName){
            this.account = account;
            this.filer = filer;
            this.contract = contract;
            this.objectApiName = objectApiName;
        }
    }
}
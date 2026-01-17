public class showContractDocuments {
    
    @AuraEnabled
    public static string hubExecute(String methodName, List<String> methodParameters){
        String result = '';
        try {
            switch on methodName {
               
                when 'getContractAttachments'{
                    result = getContractAttachments(methodParameters[0]);
                }
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return result;
    }
    
    public static String getContractAttachments(String contractId){
        List<Contract_Attachment__c> contrAttachments = [SELECT Id, Name, Type__c, createdById FROM Contract_Attachment__c WHERE Contract__c = :contractId AND Type__C = 'LC - External'];
        return JSON.serialize(contrAttachments, true);
    }
}
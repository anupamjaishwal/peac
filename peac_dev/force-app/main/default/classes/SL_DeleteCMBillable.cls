public without sharing class SL_DeleteCMBillable {
    public Contract_Misc_Billable__c CMBillable;

    public SL_DeleteCMBillable(ApexPages.StandardController stdController) {
        CMBillable = (Contract_Misc_Billable__c)stdController.getRecord();
    }
    public Pagereference goBackNotDeleted(){
        return new PageReference('/'+ CMBillable.Id);
    }
    public Pagereference goToContract(){
        return new PageReference('/'+ CMBillable.Contract__c);
    }

    @AuraEnabled
    public static String deleteExternalFirst(String action, String recordId) {
        try {
            String result = 'failure';
            switch on action{
                when 'deleteExternal'{
                    result = deleteExternal(recordId);
                }
                when 'deleteInternal'{
                    result = deleteInternal(recordId);
                }
            }
            return result;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    static String deleteExternal(String recordId){
        Contract_Misc_Billable__c cmb = [SELECT Misc_Key__c, Contract__r.Infolease_Environment__c FROM Contract_Misc_Billable__c WHERE Id =:recordId];
        String miscBillableId = cmb.Misc_Key__c;
        Boolean isIL10 = TC_BWUtility.isIL10Record(cmb.Contract__r);
        String JsonResponse;
        if(isIL10){
            JsonResponse = '{"Response": {"Success": "false", "Errors": ["This action can only be performed in IL9"]}}';
        }else{
            JsonResponse = SL_SummaryAndDetail.deleteExternalCMBillable(miscBillableId);
        }
        return JsonResponse;
    }

    static String deleteInternal(String recordId){
        Contract_Misc_Billable__c toDelete = [SELECT Id, Contract__c FROM Contract_Misc_Billable__c WHERE Id =:recordId];
        delete toDelete;
        return '{"isSuccess": true, "contractId": "' + toDelete.Contract__c + '"}';
    }
}
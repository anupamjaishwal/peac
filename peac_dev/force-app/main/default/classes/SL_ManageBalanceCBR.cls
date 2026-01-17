public with sharing class SL_ManageBalanceCBR {
    @AuraEnabled(Cacheable = true)
    public static List<String> getMaxCBR() {
        Contract_Criteria__c criteriaSetting = [SELECT Maximum_Balance_CBR__c, Maximum_CBR_XBS_ADR__c FROM Contract_Criteria__c LIMIT 1];
        List<String> criterias = new List<String>();
        criterias.add(String.valueOf(criteriaSetting.Maximum_Balance_CBR__c));
        criterias.add(String.valueOf(criteriaSetting.Maximum_CBR_XBS_ADR__c));

        return criterias;
    }

    @AuraEnabled
    public static string hubExecute(String methodName, List<String> methodParameters){
        try {
            String result = '';
            switch on methodName {
                when 'checkPermission'{
                    result = checkPermission();
                }
                when 'saveMaxCBR'{
                    result = saveMaxCBR(methodParameters[0], methodParameters[1]);
                }
            }
            return result;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @testVisible
    static string checkPermission(){
        String result = 'false';
        List<String> collectionsManagerRoles = new List<String>{
            'Collections Manager',
            'Collections Supervisor',
            'System Admin',
            'VP of Collections'
        };
        List<UserRole> currentRole = [SELECT Id, Name FROM UserRole WHERE Id = :System.UserInfo.getUserRoleId()];
        if(currentRole.size() > 0 && collectionsManagerRoles.contains(currentRole[0].Name)){
            result = 'true';
        }
        return result;
    }

    @testVisible
    static String saveMaxCBR(String maximumBalanceCBR, String maximumBalanceCBR_XBS_ADR){
        String result = 'success';
        if(checkPermission() == 'true'){
            Contract_Criteria__c criteriaSetting = [SELECT Id, Maximum_Balance_CBR__c, Maximum_CBR_XBS_ADR__c FROM Contract_Criteria__c LIMIT 1];
            Decimal previousMax = criteriaSetting.Maximum_Balance_CBR__c;
            Decimal previousMax_XBS_ADR = criteriaSetting.Maximum_CBR_XBS_ADR__c;
            criteriaSetting.Maximum_Balance_CBR__c = Decimal.valueOf(maximumBalanceCBR);
            criteriaSetting.Maximum_CBR_XBS_ADR__c = Decimal.valueOf(maximumBalanceCBR_XBS_ADR);

            update criteriaSetting;
            System.enqueueJob(new SL_ManageBalanceCBRQ(previousMax, criteriaSetting.Maximum_Balance_CBR__c, previousMax_XBS_ADR, criteriaSetting.Maximum_CBR_XBS_ADR__c, false));
        }else{
            result = 'You don\'t have permission to change the Maximum Balance CBR, please contact your Administrator.';
        }
        return result;
    }
}
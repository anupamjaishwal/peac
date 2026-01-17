public without sharing class SL_RRManageMDTFuture {
    @AuraEnabled
    public static string hubExecuteFuture(String methodName, List<String> methodParameters){
        try {
            String result = '';
            switch on methodName {
                when 'deleteRRAssignees'{
                    result = deleteRRAssignees(methodParameters[0]);
                }
            }
            return result;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @testVisible
    static String deleteRRAssignees(String fullNamesList){
        List<String> fullNames = fullNamesList.split(',');
        SL_RRManageMDTFuture.callService(fullNames);
        return 'success';    
    }

    @Future(callout=true)
    public static void callService(List<String> fullNames){
        MetadataService.MetadataPort service = new MetadataService.MetadataPort();
        service.SessionHeader = new MetadataService.SessionHeader_element();
        service.SessionHeader.sessionId = UserInfo.getSessionId();
        if(!Test.isRunningTest()){
            List<MetadataService.DeleteResult> results = service.deleteMetadata('CustomMetadata', fullNames);
        }
    }
}
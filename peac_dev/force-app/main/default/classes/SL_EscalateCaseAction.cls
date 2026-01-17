public class SL_EscalateCaseAction {
    @AuraEnabled(cacheable=true)
    public static string getQueueId(){
        return [select Id from Group where Type = 'Queue' AND DeveloperNAME = 'Escalation_Queue'][0].Id;
    }    
}
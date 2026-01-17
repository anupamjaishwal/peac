public class OpportunityDocgenSender {
    public class NoDDPInfoException extends Exception { }
    
    @future(callout=true)
    public static void sendRequests(string oppId, string sessionId, string description) {
        system.debug('begin to get package');
        
        List<Loop__DDP__c> ddps = [SELECT Id, (SELECT Id FROM Loop__Custom_Integration_Options__r WHERE Name='DocGen Queue') FROM Loop__DDP__c WHERE Name='MarlinNet Docs'];
        Loop.loopMessage lm = new Loop.loopMessage();
        lm.sessionId = sessionId;
         system.debug('init request');
        lm.requests.add(new Loop.loopMessage.loopMessageRequest(
                oppId, // MAIN RECORD ID - SAME OBJECT AS THE DDP RECORD TYPE SPECIFIES
                ddps[0].Id,
                new Map<string, string>{
                    'deploy' => ddps[0].Loop__Custom_Integration_Options__r[0].Id
                    // THESE PARAMETERS ARE THE SAME AS THOSE FOUND IN OUR OUTBOUND MESSAGE DOCUMENTATION
                    // PLEASE REFERENCE THAT DOCUMENTATION FOR ADDITIONAL OPTIONS
                }
          ));
         system.debug('send request'); 
       lm.sendAllRequests();
          system.debug('end request'); 
		Opportunity opportunity = [select Id, Description from Opportunity where Id=:oppId];
        system.debug(description);
        system.debug(oppId);
        
        opportunity.Description = 'update by trigger:' + Datetime.now().format('**yyyy-MM-dd HH:mm:ss**');
        update opportunity;
         
    }
}
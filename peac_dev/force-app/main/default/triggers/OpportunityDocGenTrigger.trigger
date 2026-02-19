trigger OpportunityDocGenTrigger on Opportunity (after update) {
    if(DeactivateTriggers__c.getAll().get('OpportunityDocGenTrigger') != null && DeactivateTriggers__c.getAll().get('OpportunityDocGenTrigger').IsDeactived__c) return;
        
    for (Opportunity opp : Trigger.new) {
        if(opp.Description == '[JDR-Action:Generate PDF]' && opp.Description != Trigger.old[0].Description){
            OpportunityDocgenSender.sendRequests(opp.Id, '', Trigger.old[0].Description);
        }
        
        
       
    }

}
public with sharing class TC_LeadTriggerHelper {
    public static void afterUpdate (Map <Id, Lead> triggerOldMap, Map <Id, Lead> triggerNewMap) {
        
        Lead l = triggerOldMap.get (triggerNewMap.values() [0].Id);
        
        
        System.debug('@@@@@ TC_LeadTriggerHelper ISConverted: ' + l.IsConverted + ' AccountId: ' + l.ConvertedAccountId );
        TC_LeadConversion.attachExtraObjects(triggerOldMap, triggerNewMap);
    }
    
}
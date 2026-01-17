public class TC_GenerateTrustLink {
 public static void generateTrustLink(Map <Id, Opportunity> triggerNewMap, Map <Id, Opportunity> triggerOldMap){
        Set<Id> setOppIds = new Set<Id>();
        for(Opportunity opp : triggerNewMap.values()){
            if(opp.StageName == 'Docs In' && triggerOldMap.get(opp.Id).StageName != 'Docs In'){
                setOppIds.add(opp.Id);
            }
        }
        if(setOppIds.size() > 0){
            System.enqueueJob (new TC_TrustPilotQueueableDocsIn (setOppIds));
        }
        
    }
}
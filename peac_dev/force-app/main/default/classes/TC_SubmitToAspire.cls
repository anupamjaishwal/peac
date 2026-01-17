public class TC_SubmitToAspire {
 public static void submitToAspire(List <Opportunity> opps) {
        List <Opportunity> oppsToUpdate = new List<Opportunity>();
        for (Opportunity opp: opps) {
            if (opp.Auto_Submit_to_Aspire__c) {
                TC_SubmitToAspireByRecordId.submitToAspireByRecordId(opp.Id);
                oppsToUpdate.add(new Opportunity(Id = opp.Id, Auto_Submit_to_Aspire__c = false));
            }
        }
        
        if (oppsToUpdate != null && !oppsToUpdate.isEmpty())
            if (oppsToUpdate[0].getSObjectType().getDescribe().isUpdateable()) {
                //dml
                update oppsToUpdate;
            }  else {
                //throw new TC_OpportunityTriggerHelperException ('Insufficient Privileges on Object ' + oppsToUpdate[0].getSObjectType().getDescribe().getName());
            }
    }
}
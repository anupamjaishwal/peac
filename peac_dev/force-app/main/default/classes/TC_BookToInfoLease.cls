public class TC_BookToInfoLease {
public static void bookToInfoLease(List <Opportunity> opps) {
        List <Opportunity> oppsToUpdate = new List<Opportunity>();
        for (Opportunity opp: opps) {
            if (opp.Auto_Book_to_InfoLease__c) {
                TC_bookToInfoLeaseByRecordId.bookToInfoLeaseByRecordId(opp.Id);
                oppsToUpdate.add(new Opportunity(Id = opp.Id, Auto_Book_to_InfoLease__c = false));
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
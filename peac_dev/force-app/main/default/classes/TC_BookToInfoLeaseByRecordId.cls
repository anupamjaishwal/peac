public class TC_BookToInfoLeaseByRecordId {
public static void bookToInfoLeaseByRecordId(Id recordId) {
        List<InfoLease_Book_Request__e> ibrEvents = new List<InfoLease_Book_Request__e> ();
        ibrEvents.add(new InfoLease_Book_Request__e(Opportunity_Id__c = recordId));
        
        List<Database.SaveResult> results = EventBus.publish(ibrEvents);
        
        for (Database.SaveResult sr : results) {
            if (sr.isSuccess()) {
                System.debug('Successfully published event.');
            } else {
                for (Database.Error err : sr.getErrors()) {
                    System.debug('Error returned: ' +
                                 err.getStatusCode() +
                                 ' - ' +
                                 err.getMessage());
                }
            }
        }
    }
}
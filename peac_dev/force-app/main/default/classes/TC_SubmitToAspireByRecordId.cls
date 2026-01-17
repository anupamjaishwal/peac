public class TC_SubmitToAspireByRecordId {
  public static void submitToAspireByRecordId(Id recordId) {
        List<Aspire_Submit_Request__e> asrEvents = new List<Aspire_Submit_Request__e> ();
        asrEvents.add(new Aspire_Submit_Request__e(Opportunity_Id__c = recordId));
        
        List<Database.SaveResult> results = EventBus.publish(asrEvents);
        
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
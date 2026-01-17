public class TC_AutoNumberQueueable implements Queueable, Database.AllowsCallouts {
	Id oppId;
    
    public TC_AutoNumberQueueable (Id oppId) {
		this.oppId = oppId;        
    }
    
    public void execute(QueueableContext qc) {
        // opps without app ids already sent in
        TC_RetrieveAutoNumber.updateOppAppNumber (new Set <Id> {oppId});
        EventBus.publish(new GDS_Action__e (Action__c = Label.TC_Gds_Infolease, Record_Id__c = oppId));
    }
}
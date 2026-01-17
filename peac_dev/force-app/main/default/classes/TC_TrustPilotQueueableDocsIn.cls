public class TC_TrustPilotQueueableDocsIn  implements Queueable,Database.AllowsCallouts {
 
    Set <Id> oppIds;
    
    public TC_TrustPilotQueueableDocsIn (Set <Id> oppIds) {
        this.oppIds = oppIds;
    }
	public void execute(QueueableContext qc) {
        TC_TrustPilotAPI.generateInvitationsForDocsIn(oppIds); 
    }
}
public class TC_TrustPilotQueueable implements Queueable,Database.AllowsCallouts {
    
    Set <Id> oppIds;
    
    public TC_TrustPilotQueueable (Set <Id> oppIds) {
        this.oppIds = oppIds;
    }
	public void execute(QueueableContext qc) {
        TC_TrustPilotAPI.generateInvitations (oppIds);
    }
}
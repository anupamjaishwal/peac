public class TC_CreateCustomerInfoleaseQueueable implements Queueable, Database.AllowsCallouts{
    
    Id oppId;
    
    public TC_CreateCustomerInfoleaseQueueable (Id oppId) {
        this.oppId = oppId;
    }
    
    public void execute(QueueableContext qc) {
        TC_BookToInfoLeaseCtrl.sendPartiesToInfoLeaseFromProcess (oppId);
    }

}
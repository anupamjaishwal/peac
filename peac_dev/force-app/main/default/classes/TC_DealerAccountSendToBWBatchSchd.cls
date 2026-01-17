public class TC_DealerAccountSendToBWBatchSchd implements Schedulable{
	// this one should run after TC_DealerSuvAutoDeactivateBatchSchd
    public void execute(SchedulableContext sc) {
        Database.executebatch (new TC_DealerAccountSendToBWBatch (), 1);

    }
}
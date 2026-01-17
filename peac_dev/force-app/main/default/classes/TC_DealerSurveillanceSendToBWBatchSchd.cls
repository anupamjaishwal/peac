public class TC_DealerSurveillanceSendToBWBatchSchd implements Schedulable {
	public void execute(SchedulableContext sc){

        TC_DealerSurveillanceSendToBWBatch b = new TC_DealerSurveillanceSendToBWBatch();
        Database.executeBatch(b, 20);
    }
}
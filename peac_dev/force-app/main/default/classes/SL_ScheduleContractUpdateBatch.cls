public class SL_ScheduleContractUpdateBatch implements Schedulable {
    public void execute(SchedulableContext sc) {
        SL_ContractUpdateBatch batch = new SL_ContractUpdateBatch();
        Database.executeBatch(batch);
    }
}
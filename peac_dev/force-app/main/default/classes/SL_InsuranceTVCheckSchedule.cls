global class SL_InsuranceTVCheckSchedule implements Schedulable{
    public void execute(SchedulableContext ctx) {
        Database.executeBatch(new SL_InsuranceTVCheckBatch());
    }
}
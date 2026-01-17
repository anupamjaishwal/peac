@isTest
public class TestBatchToDeleteLeadsScheduler {
   @isTest static void executeTest(){
        SchedulableContext sc = null;
        BatchToDeleteLeadsScheduler tsc = new BatchToDeleteLeadsScheduler();
        tsc.execute(sc);
    }  
}
public class TC_DealerSuvAutoDeactivateBatchSchd implements Schedulable{

    public void execute(SchedulableContext sc) { 
        Database.executebatch (new TC_DealerSuvAutoDeactivateBatch (), 1);

    }
}
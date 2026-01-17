public class TC_AccountMarketPositionSchd implements Schedulable{

    public void execute(SchedulableContext sc) {
        Database.executebatch (new TC_AccountMarketPositionBatch (), 25);

    }
}
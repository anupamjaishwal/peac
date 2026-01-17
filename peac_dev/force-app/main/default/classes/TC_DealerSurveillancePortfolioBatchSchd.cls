public class TC_DealerSurveillancePortfolioBatchSchd implements Schedulable{
    public void execute(SchedulableContext sc){
 
        TC_DealerSurveillancePortfolioBatch b = new TC_DealerSurveillancePortfolioBatch();
        Database.executeBatch(b, 200);
    }

}
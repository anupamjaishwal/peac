/**
 * Created by corycafferty on 2019-07-23.
 */

public with sharing class TC_DealerSurveillanceBatchSchd implements Schedulable{
    public void execute(SchedulableContext sc){
 
        TC_DealerSurveillanceBatch b = new TC_DealerSurveillanceBatch();
        Database.executeBatch(b, 200);
    }
}
/**
 * Created by andrewmayer on 2/12/20.
 */

public with sharing class TC_AppStatusAutoCancelMoreInfoSchd implements Schedulable{
    public void execute(SchedulableContext sc) {
        Database.executebatch (new TC_AppStatusAutoCancelMoreInfoBatch (), 25);


    }

}
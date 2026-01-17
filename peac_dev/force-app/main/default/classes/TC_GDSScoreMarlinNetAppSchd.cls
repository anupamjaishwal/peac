/**
 * Created by andrewmayer on 2/12/20.
 */

public with sharing class TC_GDSScoreMarlinNetAppSchd implements Schedulable {
    public void execute(SchedulableContext sc) {

        // 1 opps at a time
        Database.executebatch (new TC_GDSScoreMarlinNetAppBatch (), 1);


    }
}
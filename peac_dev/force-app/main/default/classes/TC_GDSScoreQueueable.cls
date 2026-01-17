/**
 * Used to call out from a trigger context
 */

public with sharing class TC_GDSScoreQueueable implements Queueable, Database.AllowsCallouts {

    Id oppId;

    public TC_GDSScoreQueueable (Id oppId) {
        this.oppId = oppId;
    }
    public void execute(QueueableContext qc) {
        TC_GdsScoreApi.runGdsScore (oppId);
    }

}
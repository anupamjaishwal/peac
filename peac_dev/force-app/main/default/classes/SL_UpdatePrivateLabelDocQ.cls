public with sharing class SL_UpdatePrivateLabelDocQ implements Queueable {
    // Map<Id, Opportunity> opportunitiesToUpdate;
    Set<Id> accountIdsPLD;

    public SL_UpdatePrivateLabelDocQ(Set<Id> accountIdsPLD) {
        this.accountIdsPLD = accountIdsPLD;
    }

    public void execute(QueueableContext context) {
        // system.debug('oppZero.Private_Label_Documents__c: ' + this.opportunitiesToUpdate.values()[0].Private_Label_Documents__c);
        // Database.update(this.opportunitiesToUpdate.values(), true);
        Database.executeBatch(new SL_UpdatePrivateLabelDocBatch(this.accountIdsPLD), 50);
    }
}
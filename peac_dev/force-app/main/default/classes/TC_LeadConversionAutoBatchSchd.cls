public with sharing class TC_LeadConversionAutoBatchSchd implements Schedulable {
    public void execute(SchedulableContext sc) {
        // 1 lead at a time
        TC_LeadConversionAutoBatch b = new TC_LeadConversionAutoBatch ();
        Database.executebatch (b, 1);
    }
}
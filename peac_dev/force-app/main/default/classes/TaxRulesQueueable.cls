/**
 * @description       : This queueable class is used as a queueable wrapper to start multiple tax rules in a kind of multi-threading way. Only runs 1 record at a time then chains to the next record.
 * @author            : lvang@northteq.com
 * @group             :
 * @last modified on  : 02-06-2025
 * @last modified by  : lvang@northteq.com
 **/
public class TaxRulesQueueable implements Queueable {

    Set<Id> recordIds;
    Id parentId;
    public static Boolean running = false;

    public TaxRulesQueueable(Id parentId, Set<Id> recordIds) {
        this.parentId = parentId;
        this.recordIds = recordIds;
    }

    public void execute(QueueableContext context) {
        String error = 'Tax Matrix generated successfully.';
        String errorDetails;
        running = true;
        Id recordId;
        Map<String, Set<Id> > childRecordIds = new Map<String, Set<Id> >();
        if(this.recordIds != null && !this.recordIds.isEmpty()){
            recordId = this.recordIds.iterator().next();
            childRecordIds.put(recordId.getSobjectType().getDescribe().getName(), new Set<Id> {recordId});
        }
        try{
            TaxRules.generateTaxMatrix(this.parentId, childRecordIds);
            
            if(recordId != null) this.recordIds.remove(recordId);
            
            if (this.recordIds != null && !this.recordIds.isEmpty()) {
                System.enqueueJob(new TaxRulesQueueable(this.parentId, this.recordIds));
                return;
            }
        }catch(Exception e){
            error = 'Child record Id : ' + recordId + ' error:' +e.getMessage();
            errorDetails = e.getStackTraceString() + '';
            system.debug(error);
            System.debug(errorDetails);
        }

        TaxRules.updateParent(this.parentId, error, errorDetails);
    }
}
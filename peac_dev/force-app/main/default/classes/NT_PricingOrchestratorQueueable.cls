/**
 * @description Queueable wrapper for async pricing orchestration.
 *              Processes records one at a time and chains to next record.
 * @author Northteq
 */
public class NT_PricingOrchestratorQueueable implements Queueable, Database.AllowsCallouts {
    
    private Set<Id> recordIds;
    private String parentType;
    
    /**
     * @description Constructor
     * @param recordIds Set of record Ids to process
     * @param parentType The type of parent ('Opportunity' or 'Quote')
     */
    public NT_PricingOrchestratorQueueable(Set<Id> recordIds, String parentType) {
        this.recordIds = recordIds;
        this.parentType = parentType;
    }
    
    /**
     * @description Executes pricing for one record and chains to next
     * @param context The queueable context
     */
    public void execute(QueueableContext context) {
        if (recordIds == null || recordIds.isEmpty()) {
            return;
        }
        
        // Get the first record to process
        Id currentRecordId = recordIds.iterator().next();
        
        try {
            // Execute pricing orchestration
            NT_PricingOrchestrator orchestrator = new NT_PricingOrchestrator();
            orchestrator.executePricing(currentRecordId, parentType);
            
        } catch (Exception e) {
            // Create error pricing result
            NT_PricingResultService.createErrorResult(currentRecordId, parentType, e.getMessage());
            
            // Log the error
            try {
                MARLIN_IntegrationLog.addLog(
                    'Pricing Orchestrator',
                    currentRecordId,
                    'Error',
                    '',
                    '',
                    'QUEUEABLE_ERROR',
                    e.getMessage() + '\n' + e.getStackTraceString()
                );
                MARLIN_IntegrationLog.insertLogs();
            } catch (Exception logEx) {
                System.debug('Failed to log queueable error: ' + logEx.getMessage());
            }
        }
        
        // Remove processed record
        recordIds.remove(currentRecordId);
        
        // Chain to next record if more remain
        if (!recordIds.isEmpty() && Limits.getQueueableJobs() < Limits.getLimitQueueableJobs()) {
            System.enqueueJob(new NT_PricingOrchestratorQueueable(recordIds, parentType));
        }
    }
}
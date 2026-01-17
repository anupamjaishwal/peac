/************************************************************************************************************************
 @Description: Orchestration of Loan app to submit, rescore and submit from portal. Invoke the list of
                business process and orchestrate the callout.
 @Author: Rajesh Kumar(LTIMindtree)
 @Created Date: 06/16/2025
 ************************************************************************************************************************/

public with sharing class PEAC_GdsScoreLoanQueuable implements Queueable, Database.AllowsCallouts{
    String executionType;
    Id oppId;
    public PEAC_GdsScoreLoanQueuable(String executionType, Id oppId)
    {
        this.executionType = executionType;
        this.oppId = oppId;
    }
    
    public void execute(QueueableContext qc)
    {
        //Call GDS for final scoring/re scoring / Pull Bank details
        system.debug(LoggingLevel.Error, 'executionTypeGDS....'+executionType);
        if(PEAC_ConstantClass.actionCallTypeMap.ContainsKey(executionType))
        {
            PEAC_GDSScoreLoanAPI.callType = PEAC_ConstantClass.actionCallTypeMap.get(executionType);
        }
        string errorMessage = PEAC_GDSScoreLoanAPI.runGdsScore(oppId);
        if(errorMessage == '') {
            FieldChangeTracker.removeTrackedChanges(new List<string>{oppId});
        }
    }
}
/**
 * @Author: D Balakrishna (LTIMindtree)
 * @Description:  Trigger to stamp/capture fields on log record when a Buyout on Contract is created 	
 * @User Story: SL-2924
 * Created Date : 24 March 2026
 */
trigger PEAC_IL_Integration_LogsTrigger on IL_Integration_Logs__c (after insert) {
	PEAC_IL_Integration_LogsTriggerHandler.afterInsert(Trigger.new);
}
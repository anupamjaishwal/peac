/****************************************************************************************
* @Author       Sumedha G
* @Date         Aprl  19, 2017
* @Description  LPopulate VP data on opportunity for Docusign
*****************************************************************************************/

trigger populateVPData on Variable_Payment__c(before insert, before update, after insert, after update, after delete) {

if(trigger.isAfter)
{
    if(trigger.isInsert || trigger.isUpdate)
    {
        VariablePaymentTriggerHandler.populateVPdetailsonOpp(trigger.new);
    }
    
    if(trigger.isDelete)
    {
        VariablePaymentTriggerHandler.populateVPdetailsonOppdelete(trigger.old);
    }
}




}
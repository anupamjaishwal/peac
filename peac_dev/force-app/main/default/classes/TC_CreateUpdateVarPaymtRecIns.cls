public class TC_CreateUpdateVarPaymtRecIns {
public static void createUpdateVarialbePaymentRecordInsert(List <Opportunity> triggerNew){
        Set<String> setOppId = new Set<String>();
        for(Opportunity opp : triggerNew){
            if(opp.Deferral_Payments__c != 'None' && opp.Probability >= 75 ){
                setOppId.add(opp.Id);
            }
            
        }
        List<Variable_Payment__c> lstVariablePayments = new List<Variable_Payment__c>();
        for(Opportunity opp : [Select Id,Deferral_Periods__c, (Select Id,CreatedDate from Variable_Payments__r ORDER BY createddate DESC) from Opportunity where Id IN : setOppId]){
            Variable_Payment__c objVariablePayments = new Variable_Payment__c();
            if(opp.Variable_Payments__r.size() > 0){
                objVariablePayments.Id = opp.Variable_Payments__r[0].Id;
                objVariablePayments.of_payments__c = opp.Deferral_Periods__c;
                lstVariablePayments.add(objVariablePayments);
            }else{
                objVariablePayments.of_payments__c = opp.Deferral_Periods__c;
                objVariablePayments.Opportunity__c = opp.Id;
                objVariablePayments.Payment_Amount__c = 0.00;
                lstVariablePayments.add(objVariablePayments);
            }
            
        }
        upsert lstVariablePayments;
    }
}
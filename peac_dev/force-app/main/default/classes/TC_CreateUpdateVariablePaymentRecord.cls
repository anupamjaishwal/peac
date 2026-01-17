public class TC_CreateUpdateVariablePaymentRecord {
    public static void createUpdateVariablePaymentRecord(Opportunity opp, Map<Id, List<Variable_Payment__c>> variablePayments, List<String> fieldsChanged, List<Variable_Payment__c> lstVariablePayments){
        if(fieldsChanged != null && fieldsChanged.contains('Deferral_Payments__c') && opp.Deferral_Payments__c != 'None' && opp.Probability >= 75 ){
            List<Variable_Payment__c> oppVariablePayments = variablePayments.get(opp.Id);
            Variable_Payment__c objVariablePayments = new Variable_Payment__c();
            if(oppVariablePayments != null && oppVariablePayments.size() > 0){
                objVariablePayments.Id = oppVariablePayments[0].Id;
                objVariablePayments.of_payments__c = opp.Deferral_Periods__c;
            }else{
                objVariablePayments.of_payments__c = opp.Deferral_Periods__c;
                objVariablePayments.Opportunity__c = opp.Id;
                objVariablePayments.Payment_Amount__c = 0.00;
            }
            lstVariablePayments.add(objVariablePayments);
        }
    }

    // old just kept for reference
    // public static void createUpdateVariablePaymentRecord(List <Opportunity> triggerNew, Map<Id, opportunity> triggerOldMap){
    //     Set<String> setOppId = new Set<String>();
    //     for(Opportunity opp : triggerNew){
    //         if(opp.Deferral_Payments__c != triggerOldMap.get(opp.id).Deferral_Payments__c && opp.Deferral_Payments__c != 'None' && opp.Probability >= 75 ){
    //             setOppId.add(opp.Id);
    //         }
            
    //     }
    //     List<Variable_Payment__c> lstVariablePayments = new List<Variable_Payment__c>();
    //     for(Opportunity opp : [Select Id,Deferral_Periods__c, (Select Id,CreatedDate from Variable_Payments__r ORDER BY createddate DESC) from Opportunity where Id IN : setOppId]){
    //         Variable_Payment__c objVariablePayments = new Variable_Payment__c();
    //         if(opp.Variable_Payments__r.size() > 0){
    //             objVariablePayments.Id = opp.Variable_Payments__r[0].Id;
    //             objVariablePayments.of_payments__c = opp.Deferral_Periods__c;
    //             lstVariablePayments.add(objVariablePayments);
    //         }else{
    //             objVariablePayments.of_payments__c = opp.Deferral_Periods__c;
    //             objVariablePayments.Opportunity__c = opp.Id;
    //             objVariablePayments.Payment_Amount__c = 0.00;
    //             lstVariablePayments.add(objVariablePayments);
    //         }
            
    //     }
    //     upsert lstVariablePayments;
    // }
}
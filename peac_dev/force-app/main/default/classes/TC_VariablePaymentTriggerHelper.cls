public class TC_VariablePaymentTriggerHelper {
    public static void updateGrossContractOnOpp (Map <Id, Variable_Payment__c> oldMap, Map <Id, Variable_Payment__c> newMap) {
		Set <Id> oppIds = new Set <Id> ();
        
        if (newMap != null) {
            for (Variable_Payment__c vp : newMap.values ()) {
                if (oldMap == null || vp.Payment_Amount__c != oldMap.get (vp.Id).Payment_Amount__c || vp.of_payments__c != oldMap.get (vp.Id).of_payments__c) {
                    oppIds.add (vp.Opportunity__c );
                }
            }
        } else {
            for (Variable_Payment__c vp : oldMap.values ()) {
                oppIds.add (vp.Opportunity__c );
            }
        }
        
        if (!oppIds.isEmpty ()) {
            List <Opportunity> updateList = new List <Opportunity> ();
            for (Opportunity opp : [SELECT Id, Gross_Contract__c, Equipment_Cost__c , (SELECT Id, Total__c, of_payments__c, Payment_Amount__c FROM Variable_Payments__r) FROM Opportunity WHERE Id IN :oppIds AND Variable_Payment__c = true]) {
                Decimal numOfPayments = 0;
                Decimal sumPaymentAmount = 0;
                for (Variable_Payment__c vp : opp.Variable_Payments__r) {
                    if (vp.of_payments__c != null) numOfPayments += vp.of_payments__c ;
                    if (vp.of_payments__c != null && vp.Payment_Amount__c != null) sumPaymentAmount += vp.of_payments__c * vp.Payment_Amount__c;
                }
                updateList.add (new Opportunity (Id = opp.Id, Gross_Contract__c = sumPaymentAmount, Variable_Payments_of_Payments__c = numOfPayments, Gross_Finance__c = sumPaymentAmount - (opp.Equipment_Cost__c != null ? opp.Equipment_Cost__c : 0)));
            }
            
            if (!updateList.isEmpty ()) update updateList;
        }
    }
    
    public static void updateVariablePaymentCheckBoxOnOpp(List<Variable_Payment__c> lstNewVP){
        Set<String> setOppId = new Set<String>();
        for(Variable_Payment__c objVariablePayment : lstNewVP){
            setOppId.add(objVariablePayment.Opportunity__c);
        }
        Map<Id, Opportunity> mapIdTOOpp  = new Map<Id, Opportunity>();
        for(Opportunity opp : [Select Id,Variable_Payment__c from Opportunity where Id IN : setOppId ]) {
            mapIdTOOpp.put(opp.id, opp);
        }       
        
        Map<Id, Opportunity> mapOpportunityToUpdate = new Map<Id, Opportunity>();
        
        for(Variable_Payment__c objVariablePayment : lstNewVP){
            if(String.isNotBlank(objVariablePayment.Opportunity__c)){
                if(!mapIdTOOpp.get(objVariablePayment.Opportunity__c).Variable_Payment__c){
                    Opportunity objOpp = new Opportunity();
                    objOpp.Id = objVariablePayment.Opportunity__c;
                    objOpp.Variable_Payment__c = true;
                    mapOpportunityToUpdate.put(objVariablePayment.Opportunity__c, objOpp);
                }
               
            }
        }
        
		update mapOpportunityToUpdate.values();    
        updateFirstPaymentOnOpportunity(mapOpportunityToUpdate.values());
    }
    
    public static void updateVariablePaymentCheckBoxOnOppDelete(List<Variable_Payment__c> lstOldVP){
        
        Set<String> setOppId = new Set<String>();
        for(Variable_Payment__c objVp : lstOldVP)
        {
            if(String.isNotBlank(objVp.Opportunity__c)){
                setOppId.add(objVp.Opportunity__c);
            }
        }
        List<Opportunity> lstOpportunityToUpdate = new List<Opportunity>();
        for(Opportunity objOpp : [Select Id,Variable_Payment__c, (Select Id from Variable_Payments__r) from Opportunity where Id IN : setOppId]){
            
            if(objOpp.Variable_Payments__r.size() > 0){
                if(!objOpp.Variable_Payment__c){
                    objOpp.Variable_Payment__c = true;
                }
            }
            else{
                if(objOpp.Variable_Payment__c){
                    objOpp.Variable_Payment__c = false;
                }
            }
            lstOpportunityToUpdate.add(objOpp);
        }
        
        if(lstOpportunityToUpdate.size() > 0){
            update lstOpportunityToUpdate;
        }
        
        updateFirstPaymentOnOpportunity(lstOpportunityToUpdate);
    }
    
    public static void updateFirstPaymentOnOpportunity(List<Opportunity> lstOpportunityNew){
        Set<String> setOppId = new Set<String>();
        
        for(Opportunity opp : lstOpportunityNew){
            setOppId.add(opp.id);
        }
        List<Opportunity> lstOpportunityToUpdate = new List<Opportunity>();
        for(Opportunity objOpp : [Select Id, (Select Id, Total__c, Payment_Amount__c from Variable_Payments__r ORDER BY Createddate ASC limit 1) from Opportunity where ID IN : setOppId]){
            
            if(objOpp.Variable_Payments__r.size() > 0){
                objOpp.First_Payment_Amount__c = objOpp.Variable_Payments__r[0].Payment_Amount__c;
                lstOpportunityToUpdate.add(objOpp);
            }
        }
        
        if(!lstOpportunityToUpdate.isEmpty()){
            update lstOpportunityToUpdate;
        }
        
    }
}
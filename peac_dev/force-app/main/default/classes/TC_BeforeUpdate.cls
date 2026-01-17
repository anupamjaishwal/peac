public class TC_BeforeUpdate {
  public static void beforeUpdate(Map <Id, Opportunity> triggerNewMap, Map <Id, Opportunity> triggerOldMap) {
        Set <Id> oppIds = new Set <Id> ();
        
        for (Opportunity opp : triggerNewMap.values ()) {
            if (triggerOldMap.get (opp.Id).Contract__c == null && triggerOldMap.get (opp.Id).StageName != opp.StageName && opp.StageName == 'Review for Booking' && opp.Loan_Record_Type__c)
                oppIds.add (opp.Id);
        }
        
        Map <Id, String> contractNumberMap = TC_GetContractNumberMap.getContractNumberMap (oppIds);
        
        for (Opportunity opp : triggerNewMap.values ()) {
            if (oppIds.contains (opp.Id))
                opp.Contract__c = contractNumberMap.get (opp.Id);
            
            if(opp.Terms__c > opp.Max_Term_Approved__c){
                opp.Terms__c = opp.Max_Term_Approved__c;
            } 
            
            Opportunity oldOpp = triggerOldMap.get(opp.Id);
            if(opp.Terms__c <> oldOpp.Terms__c && (opp.createdbyId != label.PaymentAmountBlank) &&(opp.Loan_Record_Type__c == False) && (opp.StageName == 'Decision' || opp.StageName == 'Proposal')){
                opp.Payment_Amount__c = NULL;
            }
            
        }
    }
    
    //added by RajaSirivelle SAL-4281
    public static void BookingRulesCalGrossFinance(Map <Id, Opportunity> triggerNewMap, Map <Id, Opportunity> triggerOldMap){
        Set <Id> oppIds = new Set <Id> ();
        //set<string> recordTypeIds = new Set<String>();
       /* List<RecordType> rtList = [select Id,Name from RecordType where sObjectType='Opportunity' and Name like '%Loan%'];
        for(recordType str : rtList){
            recordTypeIds.add(str.id);
        }*/
        String recordTypeIds = System.Label.Loan_Opportunity_Record_Types;
         for (Opportunity opp : triggerNewMap.values ()) {
             Opportunity oldOpp = triggerOldMap != null ? triggerOldMap.get(opp.Id) : null;
            if (oldOpp.Equipment_Cost__c != opp.Equipment_Cost__c && oldOpp.Gross_Contract__c != opp.Gross_Contract__c && (opp.StageName == 'Docs Out' || opp.StageName == 'Docs In' || opp.StageName == 'Funding' || opp.StageName == 'Booking')){
                opp.Gross_Finance__c = (opp.Gross_Contract__c == null ? 0 : opp.Gross_Contract__c) - (opp.Equipment_Cost__c == null ? 0 : opp.Equipment_Cost__c);
                }//SAL4281
    //end
    //SAL-4273
            else if ((oldOpp.Equipment_Cost__c != opp.Equipment_Cost__c || oldOpp.Gross_Contract__c != opp.Gross_Contract__c || oldOpp.Variable_Payment__c != opp.Variable_Payment__c) && !opp.Variable_Payment__c && opp.Opportunity_CurrentUser_Profile__c != 'DataAdmin'){
                    opp.Gross_Finance__c = (opp.Gross_Contract__c == null ? 0 : opp.Gross_Contract__c) - (opp.Equipment_Cost__c == null ? 0 : opp.Equipment_Cost__c);
            }//SAL-4273
             //SAL-Opportunity - Default Rule - Gross Finance Flow             
             if((recordTypeIds.contains(opp.RecordTypeId) && oldOpp == null && opp.Gross_Contract__c != null && opp.Equipment_Cost__c != null)){
                       
                 opp.Gross_Finance__c = (opp.Gross_Contract__c == null ? 0 : opp.Gross_Contract__c) - (opp.Equipment_Cost__c == null ? 0 : opp.Equipment_Cost__c);
             }//(opp.RecordType.Name).contains('Loan') && 
             else if(recordTypeIds.contains(opp.RecordTypeId) && oldOpp != null && opp.Gross_Contract__c != null && opp.Equipment_Cost__c != null && oldOpp.Gross_Contract__c != null && opp.Gross_Contract__c != oldOpp.Gross_Contract__c 
                    && oldOpp.Equipment_Cost__c != null && opp.Equipment_Cost__c != oldOpp.Equipment_Cost__c){
                 opp.Gross_Finance__c = (opp.Gross_Contract__c == null ? 0 : opp.Gross_Contract__c) - (opp.Equipment_Cost__c == null ? 0 : opp.Equipment_Cost__c);
             }//end Opportunity - Default Rule - Gross Finance Flow
        }
    }
    //end
}
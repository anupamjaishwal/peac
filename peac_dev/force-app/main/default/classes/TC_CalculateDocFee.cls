public class TC_CalculateDocFee {
public static void calculateDocFee (Map <Id, Opportunity> oldMap, Map <Id, Opportunity> newMap) {
        Set <Id> oppIds = new Set <Id> ();
        Set <Id> cvgOppIds = new Set <Id> ();
        
        for (Opportunity opp : newMap.values ()) {
            if(opp.Doc_Fee_Exception_Amount__c != null && opp.Documentation_Fee__c != null){
                //If statment added for SAL 1612 --Tyler
                continue;
            }
            else{
                if (!opp.Loan_Record_Type__c  && opp.StageName == 'Proposal' && ((opp.Ready_to_Doc__c == 'Yes' && oldMap.get (opp.Id).Ready_to_Doc__c != 'Yes') || oldMap.get (opp.Id).StageName != 'Proposal')) {
                    if (opp.Channel__c != null && opp.Channel__c.toUpperCase () == 'CVG') {
                        cvgOppIds.add (opp.Id);
                    } else {
                        oppIds.add (opp.Id);
                    }

                }
            }
        }
        if (!oppIds.isEmpty ()) {
            TC_DocFeeRuleHelper.setDocFees (oppIds);
            
        }
        if (!cvgOppIds.isEmpty()) TC_DocFeeRuleHelper.setDocFeesCVG (cvgOppIds);
    }
}
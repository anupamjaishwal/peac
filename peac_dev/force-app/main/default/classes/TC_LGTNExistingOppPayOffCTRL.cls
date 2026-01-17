public class TC_LGTNExistingOppPayOffCTRL {
    
    @auraEnabled public static String grabPayOffs (String recordId, String oppId) {

        List <PayOffWrapper> payOffs = new List <PayOffWrapper > ();
        for (Payoff__c payOff: [SELECT Id, Name, Payoff_Amount__c, Third_Party__c, Lender_Name__c, Trade_Up_to_Return__c   FROM Payoff__c WHERE Opportunity__c = :oppId AND Payment__c != :recordId]){
            payOffs.add (new PayOffWrapper (payOff.Name, payOff.Payoff_Amount__c, payOff.Lender_Name__c, payOff.Third_Party__c, payOff.Id, payOff.Trade_Up_to_Return__c));
        }
        return JSON.serialize(payOffs);
    }
    
    @auraEnabled public static void savePayOffs (String payOffsJSON, String recordId) {
        List <PayOffWrapper> payOffs = (List <PayOffWrapper>) JSON.deserialize(payOffsJSON, List<PayOffWrapper>.class);
        List <Payoff__c> updateList = new List <Payoff__c> ();
        for (PayOffWrapper pow : payOffs) {
            if (pow != null && pow.selected !=null && pow.selected) {
                updateList.add (new Payoff__c (Id = pow.payOffId
                                                , Payment__c = recordId));
            }
        }
        System.debug ('>>>>> payOffs ' + updateList);
        update updateList;
        
    }
    
    @auraEnabled public static String grabOppInfo (String recordId) {
        return JSON.serialize([SELECT Opportunity__c, Opportunity__r.Loan_Record_Type__c FROM Payment__c WHERE Id = :recordId][0]);
    }
    
    
    
    public class PayOffWrapper {
        @auraEnabled public Boolean selected;
        @auraEnabled public String contractNumber;
        @auraEnabled public Decimal paymentAmount;
        @auraEnabled public String lenderName;
        @auraEnabled public Boolean thirdParty;
        @auraEnabled public Id payOffId;
        @auraEnabled public Boolean tradeUpToReturn; 
        
        public PayOffWrapper (String contractNumber, Decimal paymentAmount, String lenderName, Boolean thirdParty, Id payOffId, Boolean tradeUpToReturn) {
            this.selected = false;
            this.contractNumber = contractNumber;
            this.paymentAmount = paymentAmount;
            this.lenderName = lenderName;
            this.thirdParty = thirdParty;
            this.payOffId = payOffId;
            this.tradeUpToReturn = tradeUpToReturn;
            
        }
    }

}
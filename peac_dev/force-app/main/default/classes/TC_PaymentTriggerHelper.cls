public class TC_PaymentTriggerHelper {
	
    public static void updateOpportunityStage (Map <Id, Payment__c> oldMap, Map <Id, Payment__c> newMap) {
        Marlin_Configuration__c config = Marlin_Configuration__c.getOrgDefaults ();
        
        if (config != null && config.Enable_Auto_Move_to_Booking__c) {
            Set <Id> oppIds = new Set <Id> ();
            String paymentAcknowledgedAPIName = 'Payment Confirmed';
            
            for (Payment__c payment : newMap.values ()) {
                if (payment.Payment_Status__c != oldMap.get (payment.Id).Payment_Status__c && payment.Payment_Status__c == paymentAcknowledgedAPIName) {
                    oppIds.add (payment.Opportunity__c);
                }
            }
            
            if (!oppIds.isEmpty ()) {
                List <Opportunity> updateList = new List <Opportunity> ();
                for (Opportunity opp : [SELECT Id, (SELECT ID FROM Payments__r WHERE Payment_Status__c != :paymentAcknowledgedAPIName) FROM Opportunity WHERE Id IN :oppIds AND StageName = 'Funding' AND Loan_Record_Type__c = false]) {
                    if (opp.Payments__r.isEmpty ()) updateList.add (new Opportunity (Id = opp.Id, StageName = 'Booking'));
                }
                
                if (!updateList.isEmpty ()) update updateList;
            }
        }
        
    }

    public static void updateOpportunityFields (List<Payment__c> oldList, List<Payment__c> newList){

        Set <Id> oppIds = new Set <Id> ();

        for (Integer i=0; i < newList.size(); i++){
            if (oldList == null ||
                    oldList[i].Plus_Points__c != newList[i].Plus_Points__c ||
                    oldList[i].Less_Delivery_Guarantee_Fee__c != newList[i].Less_Delivery_Guarantee_Fee__c ||
                    oldList[i].Less_Wire_Fee__c != newList[i].Less_Wire_Fee__c ||
                    oldList[i].Less_UPS_Charge__c != newList[i].Less_UPS_Charge__c ||
                    oldList[i].Less_Titling_Fee__c != newList[i].Less_Titling_Fee__c ||
                    oldList[i].Payment_Status__c != newList[i].Payment_Status__c
                    ){
                oppIds.add(newList[i].Opportunity__c);
            }
        }

        if (!oppIds.isEmpty()) {

            List <Opportunity> oppList = new List <Opportunity> ([SELECT Id, Broker_Fees__c, Delivery_Guarantee_Fee__c, Wire_Fee__c, UPS_Fee__c, Titling_Fee__c, (SELECT Id, Plus_Points__c, Less_Delivery_Guarantee_Fee__c, Less_Wire_Fee__c, Less_UPS_Charge__c, Less_Titling_Fee__c FROM Payments__r WHERE Payment_Status__c != 'Void/Cancelled') FROM Opportunity WHERE Id IN :oppIds]);
            for (Opportunity opp : oppList) {
                opp.Broker_Fees__c = 0;
                opp.Delivery_Guarantee_Fee__c = 0;
                opp.Wire_Fee__c = 0;
                opp.UPS_Fee__c = 0;
                opp.Titling_Fee__c = 0;
                if (opp.Payments__r.size() > 0) {
                    for (Payment__c payment : opp.Payments__r) {
                        opp.Broker_Fees__c += (payment.Plus_Points__c == null ? 0 : payment.Plus_Points__c);
                        opp.Delivery_Guarantee_Fee__c += (payment.Less_Delivery_Guarantee_Fee__c == null ? 0 : payment.Less_Delivery_Guarantee_Fee__c);
                        opp.Wire_Fee__c += (payment.Less_Wire_Fee__c == null ? 0 : payment.Less_Wire_Fee__c);
                        opp.UPS_Fee__c += (payment.Less_UPS_Charge__c == null ? 0 : payment.Less_UPS_Charge__c);
                        opp.Titling_Fee__c += (payment.Less_Titling_Fee__c == null ? 0 : payment.Less_Titling_Fee__c);
                    }
                }
            }
            update oppList;
        }
    }

    public static void validateDelete(List<Payment__c> triggerOld){

        System.debug('#$#$# Validate payment delete #$#$#');

        Profile cms = [SELECT Id FROM Profile WHERE Name = 'CMS' LIMIT 1];

        System.debug('User Profile: ' + UserInfo.getProfileId());
        if (UserInfo.getProfileId() == cms.Id){
            for(Payment__c payment : triggerOld){

                System.debug('Payee Sent_to_Solomon__c: : ' + payment.Date_Sent_to_External_System__c);
                if(payment.Date_Sent_to_External_System__c != null){
                    payment.addError('CMS should not be able to use the "Delete" function on the payment object after they have Sent to Solomon.');
                }
            }
        }
    }
}
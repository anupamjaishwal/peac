public with sharing class SL_PayeeTriggerHandler extends SL_Trigger.baseHandler {


    public override void afterUpdate(Map<Id, SObject> oldMap, Map<Id, SObject> newMap){
        System.debug(' SL_PayeeTriggerHandler afterUpdate');
        for(SObject theObject :newMap.values()){
            Payee__c payee = (Payee__c)theObject;
            Payee__c oldPayee = (Payee__c)oldMap.get(payee.Id);

            if(payee.Dealer__c != null && (payee.SL_Vendor_ID__c != oldPayee.SL_Vendor_ID__c || payee.Dealer__c != oldPayee.Dealer__c) ){
                if(!Test.isRunningTest())TC_BWUpdateDealerCtrl.updateDealerFuture(payee.Dealer__c);
            }
        }


    }


    public override void afterInsert(Map<Id, SObject> newMap){
        System.debug(' SL_PayeeTriggerHandler afterInsert');

        for(SObject theObject :newMap.values()){
            Payee__c payee = (Payee__c)theObject;

            System.debug(' SL_PayeeTriggerHandler afterInsert payee SL_Vendor_ID__c' + payee.SL_Vendor_ID__c);

            if(payee.Dealer__c != null && payee.SL_Vendor_ID__c != null ){
                if(!Test.isRunningTest())TC_BWUpdateDealerCtrl.updateDealerFuture(payee.Dealer__c);
            }
        }

    }
}
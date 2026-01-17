/**
 * Created by jhber on 3/1/2019.
 */

public with sharing class TC_BWupdateDealerSurveillanceCtrl {

    @InvocableMethod(
            label='Update Dealer Surveillance in InfoLease'
            description='Updates Infolease Dealer Surveillance fields from Account'
    )
    public static void updateDealerSurveillance(List<Dealer_Surveillance__c> surv) {
        if (!System.isQueueable() && !Test.isRunningTest()) { // SAL-2852
            for (Dealer_Surveillance__c next : surv) {
                updateDealerSurveillanceFuture(next.Id);
            }
        }
    }
/*
    @future (callout=true)
    @AuraEnabled
    public static void updateDealerSurveillanceFuture(String recordId) {
        
        System.debug('UpdateDealerSurveillanceCtrl - ' + recordId);
        
        

        Dealer_Surveillance__c surv = TC_BWDealerUtility.getDealerSurveillance(recordId);

        TC_BWupdateDealer dealerAPI = new TC_BWupdateDealer(surv.Account__c);
        TC_BWupdateDealerCallout service = new TC_BWupdateDealerCallout ();

        if (dealerAPI.validateUpdateSurveillance()) {
            TC_BWDealerRequestBean request = dealerAPI.createSurveillanceRequest(surv);
            System.debug(JSON.serialize(request, true));

            TC_BWDealerResponseBean response = service.updateDealer(request);
            System.debug('sendDealer - DealerNumber: ' + response.Response.DealerNumber);

            if (response.Response.Success == 'true') {
                System.debug('Success, dealer surveillance updated: ' + response.Response.DealerNumber);
            }

            System.debug('Problem creating dealer:' + response.Response.Errors);
        }
        System.debug('Create Dealer failed validation: ' + dealerAPI.getErrorMessages());
    }*/
    
    // one at a time process builder method
    @future (callout=true)
    @AuraEnabled
    public static void updateDealerSurveillanceFuture(String recordId) {
        System.debug('UpdateDealerSurveillanceCtrl - ' + recordId);
        Dealer_Surveillance__c surv = TC_BWDealerUtility.getDealerSurveillance(recordId);
        if (surv != null) updateDealerSurveillance (surv);
    }
    
    // future and bulk job call this, core logic
    public static void updateDealerSurveillance(Dealer_Surveillance__c surv) {
        TC_BWupdateDealer dealerAPI = new TC_BWupdateDealer(surv.Account__c);
        TC_BWupdateDealerCallout service = new TC_BWupdateDealerCallout ();

        if (dealerAPI.validateUpdateSurveillance()) {
            TC_BWDealerRequestBean request = dealerAPI.createSurveillanceRequest(surv);
            System.debug(JSON.serialize(request, true));

            TC_BWDealerResponseBean response = service.updateDealer(request);
            System.debug('sendDealer - DealerNumber: ' + response.Response.DealerNumber);

            if (response.Response.Success == 'true') {
                System.debug('Success, dealer surveillance updated: ' + response.Response.DealerNumber);
            }

            System.debug('Problem creating dealer:' + response.Response.Errors);
        }
        System.debug('Create Dealer failed validation: ' + dealerAPI.getErrorMessages());
    }
}
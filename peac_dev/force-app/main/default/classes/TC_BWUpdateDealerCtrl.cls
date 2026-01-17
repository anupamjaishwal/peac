/**
 * Created by jhber on 3/1/2019.
 */

public with sharing class   TC_BWUpdateDealerCtrl {

    @InvocableMethod(
            label='Update Dealer in InfoLease'
            description='Updates Infolease Dealer fields from Account'
    )
    public static void updateDealer(List<Account> dealers) {
        if(!System.isBatch()) {
            updateDealerFuture(dealers[0].Id);
        } 
    }

    @future (callout=true)
    public static void updateDealerFuture(String dealerId) {
        TC_BWUpdateDealer dealerAPI = new TC_BWUpdateDealer(dealerId);
        TC_BWUpdateDealerCallout service = new TC_BWUpdateDealerCallout ();

        if (dealerAPI.validate()) {
            TC_BWDealerRequestBean request = dealerAPI.createRequest();
            TC_BWDealerResponseBean response = service.updateDealer(request);
            System.debug('updateDealer - Response: ' + response);
        }
        System.debug('updateDealer - Failed Validation: ' + dealerAPI.getErrorMessages());
    }
    
    public static void updateDealerNonFuture(String dealerId) {
        TC_BWUpdateDealer dealerAPI = new TC_BWUpdateDealer(dealerId);
        TC_BWUpdateDealerCallout service = new TC_BWUpdateDealerCallout ();

        if (dealerAPI.validate()) {
            TC_BWDealerRequestBean request = dealerAPI.createRequest();
            TC_BWDealerResponseBean response = service.updateDealer(request);
            System.debug('updateDealer - Response: ' + response);
        }
        System.debug('updateDealer - Failed Validation: ' + dealerAPI.getErrorMessages());
    }
}
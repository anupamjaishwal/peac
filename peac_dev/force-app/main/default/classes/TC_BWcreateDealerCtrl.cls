/**
 * Created by jhber on 3/1/2019.
 */

public with sharing class TC_BWcreateDealerCtrl {

    public static TC_BWDealerRequestBean request;
    public static TC_BWDealerResponseBean response;

    @AuraEnabled
    public static String createDealer(String recordId) {
        System.debug('CreateDealerCtrl - ' + recordId);

        TC_BWcreateDealer dealerAPI = new TC_BWcreateDealer(recordId);
        TC_BWcreateDealerCallout service = new TC_BWcreateDealerCallout ();

        if (dealerAPI.validate()) {
            request = dealerAPI.createRequest();
            System.debug(JSON.serialize(request, true));

            response = service.createDealer(request);
            System.debug('sendDealer - DealerNumber: ' + response.Response.DealerNumber);

            if (response.Response.Success == 'true') {
                Account account = dealerAPI.getAccount();
                account.Sent_to_InfoLease_Date_Time__c = System.now();
                account.Dealer_Number__c = response.Response.DealerNumber;
                update account;
                return 'Success, dealer created: ' + response.Response.DealerNumber;
            }

            return 'Problem creating dealer:' + response.Response.Errors;
        }
        return 'Create Dealer failed validation: ' + dealerAPI.getErrorMessages();
    }
}
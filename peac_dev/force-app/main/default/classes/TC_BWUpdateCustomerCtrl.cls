/**
 * Created by jhber on 3/1/2019.
 */

public with sharing class TC_BWUpdateCustomerCtrl {

    @InvocableMethod(
            label='Update Customer in InfoLease'
            description='Updates Infolease fields from Account'
    )
    public static void updateCustomer(List<Account> customers) {
        updateCustomerFuture(customers[0].Id, true);
        updateCustomerFuture(customers[0].Id, false);
    }

    @future (callout=true)
    public static void updateCustomerFuture(String customerId, Boolean isIL10) {
        TC_BWUpdateCustomer customerAPI = new TC_BWUpdateCustomer(customerId);
        TC_BWUpdateCustomerCallout service = new TC_BWUpdateCustomerCallout ();

        if (customerAPI.validate()) {
            TC_BWUpdateCustomerRequestBean request = customerAPI.createRequest();
            TC_BWCustomerResponseBean response = service.updateCustomer(request, isIL10);
            System.debug('updateCustomer - Response: ' + response);
        }
    }
}
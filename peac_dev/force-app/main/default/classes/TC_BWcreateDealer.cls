/**
 * Created by jhber on 2/14/2019.
 */

/**
 * Utility class to handle creating the Dealer request Bean and validating it.
 * Process is:
 *
 * 1. Call constructor with valid Dealer Account
 * 2. Call validate() to make sure all required fields exist and all business rules are validated
 * 3. Call createRequest() to create the request (which will map the fields).
 *
 */
public with sharing class TC_BWcreateDealer {


    private List<String> errorMessages;
    private Account account;

    private TC_BWDealerRequestBean request;
    private static String NITROAPI = 'BW.CREATE.DEALER.UDO';

    /**
 * Creates the DealerRequest Bean and populates it from a passed in Account object.
 *
 * @param o - The Account we want to create the IL Dealer from...
 */
    public TC_BWcreateDealer(String accountId) {
        try{
            account  = TC_BWDealerUtility.getAccountFields(accountId);
        } catch (Exception e) {
            throw new TC_BWcreateDealerException(e);
        }
    }

    public  Account getAccount() { return this.account; }

    /**
     * Map all fields for the request. Should be called only after validation, and assumes
     * there are no validation errors.
     *
     * @throws TC_BWcreateDealerException if there are any error messages in the error list,
     *          or if the account/contact is null.
     */
    private void mapFields() {

        request = TC_BWDealerUtility.mapFields(account);

        //Create specific mapping
        request.Header.NitroApi = NITROAPI;
        request.Request.DealerNumber = TC_BWDealerUtility.formatDealerNumber(account.Business_Phone__c);
        request.Request.DlrDealerId = TC_BWDealerUtility.formatDealerNumber(account.Business_Phone__c);

        System.debug('CreateDealer Mapping: ' + request);
    }

    /**
     * Create an actual request. Map the fields, create the request and return it.
     * Validate must be called first.
     *
     * @return TC_BWBrokerRequestBean
     */
    public TC_BWDealerRequestBean createRequest () {
        if (account == null)        throw new TC_BWcreateDealerException('Cannot map fields with null Dealer Account!');
        if (errorMessages == null)  throw new TC_BWcreateDealerException ('Cannot create request before validating fields');
        mapFields();
        return request;
    }


    /**
     * Validates the request for required fields or other business logic.
     *
     * Note: Use getErrorMessages() to access actual errors.
     *
     * @return TRUE if there are no missing fields or validation errors
     *          FALSE otherwise.
     */
    public Boolean validate() {
        errorMessages = new List<String>();

        if (account == null) {
            errorMessages.add('Null object sent to createDealer!');
            return errorMessages.isEmpty();
        }

            if (account.Name == null)
                errorMessages.add('Account: <' + account.Id + '> missing required field - Name');
            if (account.Dealer_Number__c != null)
                errorMessages.add('Account: <' + account.Id + '> appears to be in InfoLease already, Dealer Number: ' + account.Dealer_Number__c);
            if (!TC_BWDealerUtility.checkDealerNumber(account.Business_Phone__c))
                errorMessages.add('Account: <' + account.Id + '> invalid Business Phone: ' + account.Business_Phone__c);


        if (errorMessages.isEmpty()) System.debug('CreateDealer Validation Complete without errors');
        else System.debug('CreateDealer Validation found errors: '+ errorMessages);
        return errorMessages.isEmpty();
    }


    /**
     * Return the list of error Messages, if any
     *
     * @return List<String> that contains the error messages, or
     * an empty list of there are none.
     */
    public List<String> getErrorMessages() { return errorMessages; }

    /**
     * Returns whether or not the request as instanstiated is valid.
     *
     * @return TRUE if there are no validation errors, FALSE otherwise.
     */
    public boolean isValid() {
        if (errorMessages == null) throw new TC_BWcreateDealerException('Cannot check validity until validation has been completed');

        return errorMessages.isEmpty();
    }

    public class TC_BWcreateDealerException extends Exception {}
}
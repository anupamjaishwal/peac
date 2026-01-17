/**
 * Created by jhber on 2/14/2019.
 */

/**
 * Utility class to handle creating the Dealer Update request Bean and validating it.
 * Process is:
 *
 * 1. Call constructor with valid Account
 * 2. Call validate() to make sure all required fields exist and all business rules are validated
 * 3. Call createRequest() to create the request (which will map the fields).
 *
 */
public with sharing class TC_BWUpdateDealer {

    private List<String> errorMessages;
    private Account thisAccount;

    private TC_BWDealerRequestBean request;

    private static String NITROAPI = 'BW.UPDATE.DEALER.UDO';

    /**
     * Map all fields for the request. Should be called only after validation, and assumes
     * there are no validation errors.
     *
     * @return TC_BWUpdateDealerRequestBean object with mapped values in place
     * @throws TC_BWUpdateDealerException if there are any error messages in the error list,
     *          or if the account/contact is null.
     */
    private void mapFields() {
        request = TC_BWDealerUtility.mapFields(thisAccount);
        request.Header.NitroApi = NITROAPI;

        System.debug('UpdateDealer Mapping: ' + request);
    }

    private void mapSurveillanceFields(Dealer_Surveillance__c surv) {
        request = TC_BWDealerUtility.mapSurveillanceFields(surv);
        request.Header.NitroApi = NITROAPI;

        System.debug('UpdateDealerSurveillance Mapping: ' + request);
    }



    /**
     * Creates the Update Dealer Bean and populates it from a passed in Account object.
     *
     * @param o - Account we want to update the IL Dealer from...
     */
    public TC_BWUpdateDealer(String accountId) {
        try{
            thisAccount = TC_BWDealerUtility.getAccountFields(accountId);
        } catch (Exception e) {
            throw new TC_BWUpdateDealerException(e);
        }
    }

    /**
     * Create an actual request. Map the fields, create the request and return it.
     * Validate must be called first.
     *
     * @return TC_BWBrokerRequestBean
     */
    public TC_BWDealerRequestBean createRequest () {
        if (thisAccount == null)    throw new TC_BWUpdateDealerException('Cannot map fields with null Account!');
        if (errorMessages == null)  throw new TC_BWUpdateDealerException('Cannot create request before validating fields');
        mapFields();
        System.debug('Field Mapping complete: ' + request);
        return request;
    }

    public TC_BWDealerRequestBean createSurveillanceRequest (Dealer_Surveillance__c surv) {
        if (thisAccount == null)    throw new TC_BWUpdateDealerException('Cannot map fields with null Account!');
        if (errorMessages == null)  throw new TC_BWUpdateDealerException('Cannot create request before validating fields');
        mapSurveillanceFields(surv);
        System.debug('Surveillance Field Mapping complete: ' + request);
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

        if (thisAccount == null) {
            errorMessages.add('Null object sent to updateDealer!');
            return errorMessages.isEmpty();
        }

        System.debug(thisAccount.Dealer_Number__c);
        if (thisAccount.Dealer_Number__c == null) errorMessages.add('Account: <' + account.Id + '> missing required field - Dealer Number');

        //Check the picklist for valid values
        //if (thisAccount.Pass_Thru_Maintenance_Frequency__c == null || TC_DataUtility.checkPicklistIsValid('Account', 'Pass_Thru_Maintenance_Frequency__c', String.valueof(thisAccount.Pass_Thru_Maintenance_Frequency__c)))
        //    errorMessages.add('Account: <' + thisAccount.Id + '> has an invalid Pass Through Maintenance Frequency - ' + thisAccount.Pass_Thru_Maintenance_Frequency__c);
        if (errorMessages.isEmpty()) System.debug('Validation Complete without errors');
        else System.debug('Validation found errors: '+ errorMessages);
        return errorMessages.isEmpty();
    }

    /**
  * Validates the request for required fields or other business logic.
  *
  * Note: Use getErrorMessages() to access actual errors.
  *
  * @return TRUE if there are no missing fields or validation errors
  *          FALSE otherwise.
  */
    public Boolean validateUpdateSurveillance() {
        errorMessages = new List<String>();

        if (thisAccount == null) {
            errorMessages.add('Null object sent to updateDealer!');
            return errorMessages.isEmpty();
        }

        if (account.Dealer_Number__c == null) errorMessages.add('Account: <' + account.Id + '> missing required field - Dealer Number');

        if (errorMessages.isEmpty()) System.debug('Validation Complete without errors');
        else System.debug('Validation found errors: '+ errorMessages);
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
        if (errorMessages == null) throw new TC_BWUpdateDealerException('Cannot check validity until validation has been completed');

        return errorMessages.isEmpty(); }

    public class TC_BWUpdateDealerException extends Exception {}
}
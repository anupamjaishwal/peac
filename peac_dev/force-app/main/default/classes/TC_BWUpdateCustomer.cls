/**
 * Created by jhber on 2/14/2019.
 */

/**
 * Utility class to handle creating the Customer request Bean and validating it.
 * Process is:
 *
 * 1. Call constructor with valid Account
 * 2. Call validate() to make sure all required fields exist and all business rules are validated
 * 3. Call createRequest() to create the request (which will map the fields).
 *
 */
public with sharing class TC_BWUpdateCustomer {

    public static String getUCIDelimitedString(List<String> fields) {
        String str = '';
        for (String next : fields) {
            str += TC_UCIStringHelper.value(next);
        }
        return str;
    }


    /**
     * Map all fields for the request. Should be called only after validation, and assumes
     * there are no validation errors.
     *
     * @return TC_BWUpdateCustomerRequestBean object with mapped values in place
     * @throws TC_BWUpdateCustomerRequestBean if there are any error messages in the error list,
     *          or if the account/contact is null.
     */
    private TC_BWUpdateCustomerRequestBean mapFields() {

        //thisAccount = getAccountFields(thisAccount.Id);
                //TC_DataUtility.getAllFieldsOnAccountByRecordId(thisAccount.Id);

        request = new TC_BWUpdateCustomerRequestBean();
        request.Request.CCAN = thisAccount.CCAN__c;
        request.Request.CsDefaultSicCode = thisAccount.Account_EU_FS_SIC_Description__c;
        request.Request.CsUdCode = thisAccount.Fraud_Flag__c ? 'Yes' : null;
        request.Request.CsParentCode = thisAccount.Infolease_Group_Code__r.IL_Group_Code_ID__c;
        request.Request.CsDbRating = thisAccount.DUNS__c;
        //request.Request.CsDefaultContactPhone = thisAccount.Business_Phone__c;

        //End Mapping
        return request;

    }

    private List<String> errorMessages;
    private Account thisAccount;

    private TC_BWUpdateCustomerRequestBean request;

    /**
     * Creates the Update Customer Bean and populates it from a passed in Account object.
     *
     * @param o - Account we want to update the IL Customer from...
     */
    public TC_BWUpdateCustomer(String accountId) {
        try{
            thisAccount = getAccountFields(accountId);
        } catch (Exception e) {
            throw new TC_BWUpdateCustomerException(e);
        }
    }

    /**
     * Create an actual request. Map the fields, create the request and return it.
     * Validate must be called first.
     *
     * @return TC_BWBrokerRequestBean
     */
    public TC_BWUpdateCustomerRequestBean createRequest () {
        if (thisAccount == null)    throw new TC_BWUpdateCustomerException('Cannot map fields with null Account!');
        if (errorMessages == null)  throw new TC_BWUpdateCustomerException('Cannot create request before validating fields');
        mapFields();
        System.debug(request);
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
            errorMessages.add('Null object sent to updateCustomer!');
            return errorMessages.isEmpty();
        }

        if (account.CCAN__c == null) errorMessages.add('Account: <' + account.Id + '> missing required field - CCAN');

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
        if (errorMessages == null) throw new TC_BWUpdateCustomerException('Cannot check validity until validation has been completed');

        return errorMessages.isEmpty(); }

    private Account getAccountFields(String accountId) {

        Account a = [SELECT
                        Name,
                        Id,
                        Account_EU_FS_SIC_Description__c,
                        Business_Phone__c,
                        CCAN__c,
                     	Fraud_Flag__c,
                     	Infolease_Group_Code__r.IL_Group_Code_ID__c,
                        DUNS__c
                    FROM Account WHERE Id = :accountId];
        return a;
    }

    public class TC_BWUpdateCustomerException extends Exception {}
}
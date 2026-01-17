/**
 * Created by jhber on 2/14/2019.
 */

/**
 * Utility class to handle creating the Customer request Bean and validating it.
 * Process is:
 *
 * 1. Call constructor with valid Contact or Account
 * 2. Call validate() to make sure all required fields exist and all business rules are validated
 * 3. Call createRequest() to create the request (which will map the fields).
 *
 */
public with sharing class TC_BWcreateCustomer {
    
    // new instance variable
    public String recordId = ''; 

    private void mapDealerFields(Dealer__c d) {
        
        	// new assignment
        	this.recordId = d.Dealer__r.Id;

            request.Request.CsDefaultName = d.Dealer__r.Name;
            request.Request.CsDefaultAddr1 = d.Dealer__r.Business_Address__c;
            request.Request.CsDefaultCity = d.Dealer__r.Business_City__c;
            request.Request.CsDefaultState = d.Dealer__r.Business_State__c;
            request.Request.CsDefaultZip = d.Dealer__r.Business_Zip__c;
            if (d.Dealer__r.Dealer_Number__c != null)
                request.Request.Ccan = d.Dealer__r.Dealer_Number__c.remove('.');
            else
                request.Request.Ccan = formatPhone (d.Dealer__r.Business_Phone__c);
         	//JAH Replacing Fed Tax ID and Contact Phone with Dealer Phone (which is the CCAN)
        	//request.Request.CsDefaultFederalTaxId = d.Dealer__r.Tax_ID__c;
        	request.Request.CsDefaultFederalTaxId  = request.Request.Ccan;
        	//JAH-Apparently not setting the business phone for some reason?
        	//request.Request.CsBusinessPhone = request.Request.Ccan;
        	request.Request.CsDefaultContactPhone = request.Request.Ccan;

            List<String> udfFields = new List<String>();
            udfFields.add('') ;
            udfFields.add('') ;
            udfFields.add('') ;
            udfFields.add('') ;
            udfFields.add('') ;
            udfFields.add('') ;
            udfFields.add('') ;
            udfFields.add('') ;
            //udfFields.add(contact.Score__c != null ? contact.Score__c.toPlainString() : '') ;

            request.Request.AusrAdditionalData = getUCIDelimitedString(udfFields);
    }

    /**
     * Handles mapping when we are starting from the Guarantor object, rather than directly at the Account or Contact
     *
     * @param g
     */
    private void mapGuarantorFields(Guarantor__c g) {

        String ssn = ccanForNewCustomer(g.Contact__r);

        while (ssn != null && ssn.startsWith('0'))
            ssn = ssn.removeStart('0');

        if (g.RecordType.Name == 'Corporate') {
            // new assignment
        	this.recordId = g.Account__r.Id;
            
            request.Request.CsDefaultName = g.Account__r.Name;
            request.Request.CsDefaultAddr1 = g.Account__r.Business_Address__c;
            request.Request.CsDefaultCity = g.Account__r.Business_City__c;
            request.Request.CsDefaultState = g.Account__r.Business_State__c;
            request.Request.CsDefaultZip = g.Account__r.Business_Zip__c;
            request.Request.CsDefaultFederalTaxId = g.Account__r.Tax_ID__c;
            request.Request.CsBusinessPhone = formatPhone(g.Account__r.Business_Phone__c);

            List<String> udfFields = new List<String>();
            udfFields.add('') ;
            udfFields.add('') ;
            udfFields.add('') ;
            udfFields.add('') ;
            udfFields.add('') ;
            udfFields.add('') ;
            udfFields.add('') ;
            udfFields.add('') ;
            //udfFields.add(contact.Score__c != null ? contact.Score__c.toPlainString() : '') ;

            request.Request.AusrAdditionalData = getUCIDelimitedString(udfFields);
        }
        else {
            // new assignment
        	this.recordId = g.Contact__r.Id;
            
            request.Request.Ccan = ssn;
            String lastFirstName = g.Contact__r.LastName;
            lastFirstName += !String.isEmpty(g.Contact__r.FirstName) ? ', ' + g.Contact__r.FirstName : '';
            request.Request.CsDefaultName = lastFirstName;
            
            // if other street is empty, pass in mailing street. This is needed due to fields being displayed on the app wizard
            //https://marlinbusiness.atlassian.net/browse/SAL-1303
            if (!String.isBlank(g.Contact__r.OtherStreet)) {
                request.Request.CsDefaultAddr1 = g.Contact__r.OtherStreet;
            	request.Request.CsDefaultCity = g.Contact__r.OtherCity;
            	request.Request.CsDefaultState = g.Contact__r.OtherStateCode;
            	request.Request.CsDefaultZip = g.Contact__r.OtherPostalCode;
                request.Request.CsDefaultCountry = getCountryIdForIL(g.Contact__r.OtherCountryCode);
            } else {
                request.Request.CsDefaultAddr1 = g.Contact__r.MailingStreet;
            	request.Request.CsDefaultCity = g.Contact__r.MailingCity;
            	request.Request.CsDefaultState = g.Contact__r.MailingStateCode;
            	request.Request.CsDefaultZip = g.Contact__r.MailingPostalCode;
                request.Request.CsDefaultCountry = getCountryIdForIL(g.Contact__r.MailingCountryCode);
            }
            
            
            request.Request.CsDefaultCellPhone = formatPhone (g.Mobile__c);
            request.Request.CsDefaultContactPhone = formatPhone (g.Phone__c);
            request.Request.CsDefaultContactEmail = g.Email__c ;
            // ssn new
            request.Request.CsDefaultFederalTaxId = ssn;

            List<String> udfFields = new List<String>();
            udfFields.add('') ;
            udfFields.add('') ;
            udfFields.add('') ;
            udfFields.add('') ;
            udfFields.add('') ;
            udfFields.add('') ;
            udfFields.add('') ;
            udfFields.add('') ;

            request.Request.AusrAdditionalData = getUCIDelimitedString(udfFields);
        }
    }
    /**
     * Handles mapping of Contacts to Customer
     *
     * @param contact Contact to get data from
     *
     */
    private void mapContactFields(Contact con) {

        Contact contact = TC_DataUtility.getAllFieldsOnContactByRecordId(con.Id);
        
        // new assignment
        this.recordId = con.Id;

        String ssn = ccanForNewCustomer(con);

        while (ssn != null && ssn.startsWith('0'))
            ssn = ssn.removeStart('0');
        //Start Mapping
        request.Request.Ccan = ssn;
        request.Request.CsDefaultName = contact.Name;
        request.Request.CsDefaultAddr1 = contact.MailingStreet;
        request.Request.CsDefaultCity = contact.MailingCity;
        request.Request.CsDefaultState = contact.MailingStateCode ;
        request.Request.CsDefaultZip = contact.MailingPostalCode ;
        request.Request.CsDefaultTitle = contact.Title ;
        request.Request.CsDefaultArName = contact.Name ;
        request.Request.CsDefaultArAddr1 = contact.MailingStreet ;
        request.Request.CsDefaultArCity = contact.MailingCity ;
        request.Request.CsDefaultArState = contact.MailingStateCode ;
        request.Request.CsDefaultArZip = contact.MailingPostalCode ;
        request.Request.CsDefaultCellPhone = formatPhone (contact.MobilePhone);
        request.Request.CsDefaultContactEmail = contact.Email ;
        request.Request.CsDefaultFederalTaxId = contact.SSN__c ;

        List<String> udfFields = new List<String>();
        udfFields.add('') ;
        udfFields.add('') ;
        udfFields.add('') ;
        udfFields.add('') ;
        udfFields.add('') ;
        udfFields.add('') ;
        udfFields.add('') ;
        udfFields.add('') ;
        //udfFields.add(contact.Score__c != null ? contact.Score__c.toPlainString() : '') ;

        request.Request.AusrAdditionalData = getUCIDelimitedString(udfFields);
    }

    /**
     * Handles mapping of Accounts to Customer
     *
     * @param account Account to get data from
     *
     */
     private void mapAccountFields(Account acct) {
        Map<String, String> il10CountryIdsByCode = new Map<String, String>{
            'US' => '001', 'Canada' => '002'
        };
         //Get the "full" Account object
         Account account = TC_DataUtility.getAllFieldsOnAccountByRecordId(acct.Id);
         
         List <Account> infoLeaseGroupCode = new List <Account> ([SELECT Infolease_Group_Code__r.IL_Group_Code_ID__c FROM Account WHERE Id = :account.Id]);
         
         String email;
         String name;
         String phone;
         String fax;
         String title;
         List <AccountContactRole> acrs = new List <AccountContactRole> ([SELECT Contact.Name, Contact.Email, Contact.Phone, Contact.Fax, Contact.Title FROM AccountContactRole WHERE AccountId = :acct.Id AND (IsPrimary = true OR Role ='Primary Contact')]);
         
         // this is what is displayed in the lightning UI
         List <AccountContactRelation> accountContactRelation = new List <AccountContactRelation> ([SELECT Contact.Name, Contact.Email, Contact.Phone, Contact.Fax, Contact.Title FROM AccountContactRelation WHERE AccountId = :acct.Id AND Roles includes ('Primary Contact')]);
		
         if (!accountContactRelation.isEmpty()) {
             email = accountContactRelation[0].Contact.Email;
             name = accountContactRelation[0].Contact.Name;
             phone = formatPhone (accountContactRelation[0].Contact.Phone);
             fax = accountContactRelation[0].Contact.Fax;
             title = accountContactRelation[0].Contact.Title;
         } else if (!acrs.isEmpty ()) {
             email = acrs[0].Contact.Email;
             name = acrs[0].Contact.Name;
             phone = formatPhone(acrs[0].Contact.Phone);
             fax = acrs[0].Contact.Fax;
             title = acrs[0].Contact.Title;
         }
         
         System.debug ('here mapAccountFields' + acct.Id);
         // new assignment
         this.recordId = acct.Id;
         
         
         //Start Mapping
         request.Request.CsDefaultName = account.Name;
         request.Request.CsDefaultAddr1 = account.Business_Address__c;
         request.Request.CsDefaultCity = account.Business_City__c;
         request.Request.CsDefaultState = account.Business_State__c;
         request.Request.CsDefaultZip = account.Business_Zip__c;
         request.Request.CsDefaultDba = account.DBA__c ;
         request.Request.CsDefaultArName = account.Name ;
         request.Request.CsDefaultArAddr1 = account.Account_Billing_Street__c;
         request.Request.CsDefaultArCity = account.Account_Billing_City__c  ;
         request.Request.CsDefaultArState = account.Account_Billing_State_Province__c  ;
         request.Request.CsDefaultArZip = account.Account_Billing_Zip_Postal_Code__c  ;
         request.Request.CsDefaultFederalTaxId = account.Tax_Id__c ;
         // new fields
         request.Request.CsBusinessPhone = formatPhone(account.Business_Phone__c);
         request.Request.CsDefaultContactName = name;
         request.Request.CsDefaultContactEmail = email;
         request.Request.CsDefaultContactPhone = formatPhone(account.Business_Phone__c);
         //request.Request.CsDefaultContactPhone = formatPhone(phone);
         request.Request.CsDefaultContactFaxPhone = formatPhone(fax);
         request.Request.CsDefaultCountry = getCountryIdForIL(account.Business_Country__c);
         request.Request.CsDefaultArCountry = getCountryIdForIL(account.Account_Billing_Country__c);
         request.Request.CsDbRating = account.DUNS__c;
         request.Request.CsParentCode = !infoLeaseGroupCode.isEmpty () ? infoLeaseGroupCode[0].Infolease_Group_Code__r.IL_Group_Code_ID__c : '';
         request.Request.CsDefaultSicCode = account.Account_EU_FS_SIC_Description__c != null && account.Account_EU_FS_SIC_Description__c.isNumeric() ? account.Account_EU_FS_SIC_Description__c : '';
         request.Request.CsDefaultArAddr2 = account.Account_Billing_Street2__c ;
         request.Request.CsDefaultAddr2 = account.Business_Address2__c;
         MARLIN_RapportHelper.buildRapportMap();
         request.Request.CsBusinessType = account.Business_Type__c != null ? MARLIN_RapportHelper.transRapport('Business_Type',account.Business_Type__c) : '';
         request.Request.CsDefaultTitle = title;
         
         
         

         List<String> udfFields = new List<String>();
         udfFields.add('') ;
         udfFields.add('') ;
         udfFields.add('') ;
         udfFields.add('') ;
         udfFields.add('') ;
         udfFields.add('') ;
         udfFields.add('') ;
         udfFields.add('') ;

         request.Request.AusrAdditionalData = getUCIDelimitedString(udfFields);
     }

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
     * @return TC_BWCustomerRequestBean object with mapped values in place
     * @throws TC_BWcreateCustomerException if there are any error messages in the error list,
     *          or if the account/contact is null.
     */
    private TC_BWCustomerRequestBean mapFields() {

        request = new TC_BWCustomerRequestBean();

        if (Schema.Account.getSObjectType() == thisObject.getSObjectType()) {
            Account account = (Account) thisObject;
            mapAccountFields(account);
        }
        else if (Schema.Contact.getSObjectType() == thisObject.getSObjectType()) {
            Contact contact = (Contact) thisObject;
            mapContactFields(contact);
        }
        else if (Schema.Guarantor__c.getSObjectType() == thisObject.getSObjectType()) {
            Guarantor__c g = (Guarantor__c) thisObject;
            mapGuarantorFields(g);
        }
        else if (Schema.Dealer__c.getSObjectType() == thisObject.getSObjectType()) {
            Dealer__c d = (Dealer__c) thisObject;
            mapDealerFields(d);
        }
        else throw new TC_BWcreateCustomerException('Invalid Object sent to createCustomer - ' + thisObject.getSObjectType());



        //End Mapping
        return request;

    }

    private List<String> errorMessages;
    private SObject thisObject;
    //private Id id;

    //private static String NITRO_API = 'BW.CREATE.BROKER.UD';

    private TC_BWCustomerRequestBean request;

    /**
     * Creates the Customer Bean and populates it from a passed in Account or
     * Contact object.
     *
     * @param o - Either the Contact or Account we want to create the IL Customer from...
     */
    public TC_BWcreateCustomer(SObject o) {
        try{
            thisObject  = o;
        } catch (Exception e) {
            throw new TC_BWcreateCustomerException(e);
        }
    }

    /**
     * Create an actual request. Map the fields, create the request and return it.
     * Validate must be called first.
     *
     * @return TC_BWBrokerRequestBean
     */
    public TC_BWCustomerRequestBean createRequest() {
        if (thisObject == null)        throw new TC_BWcreateCustomerException('Cannot map fields with null Contact/Account!');
        if (errorMessages == null)  throw new TC_BWcreateCustomerException ('Cannot create request before validating fields');
        mapFields();
        System.debug('TC_BWCustomerRequestBean createRequest: '+request);
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

        if (thisObject == null) {
            errorMessages.add('Null object sent to createCustomer!');
            return errorMessages.isEmpty();
        }

        if (Schema.Account.getSObjectType() == thisObject.getSObjectType()) {
            Account account = (Account) thisObject;

            if (account.Name == null) errorMessages.add('Account: <' + account.Id + '> missing required field - Name');
        }

        if (Schema.Contact.getSObjectType() == thisObject.getSObjectType()) {
            Contact contact = (Contact) thisObject;

            if (contact.Name == null) errorMessages.add('Contact: <' + contact.Id + '> missing required field - Name');
        }
        System.debug(errorMessages);
        return errorMessages.isEmpty();
    }
    
    // need to either return a value or null
    private String formatPhone (String phoneInput) {
        String phoneOutput;
        if (phoneInput != null) phoneOutput = phoneInput.replaceAll('\\D', '');
        return phoneOutput;
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
        if (errorMessages == null) throw new TC_BWcreateCustomerException('Cannot check validity until validation has been completed');

        return errorMessages.isEmpty();
    }

    public static String ccanForNewCustomer(Contact customerContact){
        String ssn = '';
        if(customerContact != null){
            ssn = customerContact.SSN__c;
            IL10_Flag__c il10Setting = IL10_Flag__c.getValues('GeneralSetting');
            if(il10Setting.use_IL10__c){
                ssn = customerContact.Contact_CCAN__c;
            }
        }
        return ssn;
    }

    public static String getCountryIdForIL(String countryCode){
        Map<String, String> il10CountryIdsByCode = new Map<String, String>{
            'US' => '001', 'Canada' => '002'
        };
        String countryId = il10CountryIdsByCode.get(countryCode);
        return countryId != null? countryId: '';
    }
    
    public class TC_BWcreateCustomerException extends Exception {}
}
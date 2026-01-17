/**
 * Created by jhber on 3/1/2019.
 */
public with sharing class TC_BWcreateCustomerCtrl {

    @AuraEnabled
    public static String createDealerAsCustomer(Dealer__c customer, Boolean persist) {

        TC_BWcreateCustomer customerAPI = new TC_BWcreateCustomer(customer);
        TC_BWcreateCustomerCallout service = new TC_BWcreateCustomerCallout ();
        
        if (customerAPI.validate()) {
            TC_BWCustomerRequestBean request = customerAPI.createRequest();
            
            // new setting ids for integration log
			service.recordId = customerAPI.recordId;
            
            System.debug(JSON.serialize(request, true));

            TC_BWCustomerResponseBean response = service.createCustomer(request);
            response.Response.CCAN = response.Response.CCAN;
            System.debug('createDealerAsCustomer - CCAN: ' + response.Response.CCAN);
            return response.Response.CCAN;
        }
        return null;
    }

    @AuraEnabled
    public static String createCustomer(Guarantor__c customer, Boolean persist) {

        TC_BWcreateCustomer customerAPI = new TC_BWcreateCustomer(customer);
        TC_BWcreateCustomerCallout service = new TC_BWcreateCustomerCallout ();
        
        if (customerAPI.validate()) {
            TC_BWCustomerRequestBean request = customerAPI.createRequest();
            
            // new setting ids for integration log
			service.recordId = customerAPI.recordId;
            
            System.debug(JSON.serialize(request, true));

            TC_BWCustomerResponseBean response = service.createCustomer(request);
            response.Response.CCAN = response.Response.CCAN;
            System.debug('createCustomer - CCAN: ' + response.Response.CCAN);
            return response.Response.CCAN;
        }
        return null;
    }

    public static String createCustomer(Guarantor__c customer) {
        return createCustomer(customer, true);
    }

    public static List<Contact> checkAndUpdateILContacts(String recordId) {

        System.debug('checkandUpdateILContacts: ' + recordId);

        List<Guarantor__c> guarantors = getGuarantors(recordId, 'Personal');

        List<Contact> updateContacts = new List<Contact>();

        for (Guarantor__c next : guarantors) {
            System.debug('checkandUpdateILContacts: - Guarantor:' + next);
            if (next.Contact__r.Contact_CCAN__c == null) {
                next.Contact__r.Contact_CCAN__c = createCustomer(next, false);
                System.debug('Returned:' + next.Contact__r);
                next.Contact__r.Sent_to_InfoLease_Date_Time__c = System.now();
                updateContacts.add(next.Contact__r);
            }
            else System.debug(next.Contact__r.Name + ' already in InfoLease,(CCAN/SSN: ' +next.Contact__r.SSN__c + ') not sending');
        }

        return updateContacts;
    }

    public static List<Account> checkAndUpdateILAccounts(String recordId) {

        System.debug('checkandUpdateILAccounts: ' + recordId);
        List<Guarantor__c> guarantors = getGuarantors(recordId, 'Corporate');

        List<Dealer__c> dealers = getDealers(recordId);

        List<Account> updateAccounts = new List<Account>();

        for (Guarantor__c next : guarantors) {
            System.debug('checkandUpdateILAccounts: - Account:' + next.Account__r.Name);
            if (next.Account__r.CCAN__c == null) {
                String ccan = createCustomer(next, false);
                next.Account__r.CCAN__c = ccan;
                next.Account__r.Sent_to_InfoLease_Date_Time__c = System.now();
                updateAccounts.add(next.Account__r);
            }
            else System.debug(next.Account__r.Name + ' already in InfoLease (CCAN: '+next.Account__r.CCAN__c + '), not sending');
        }

        for (Dealer__c next : dealers) {
            System.debug('dealers: ' + next.Dealer__r.Name + ':' + next.Dealer__r.CCAN__c);
            if (next.Dealer__r.CCAN__c == null) {
                String ccan = createDealerAsCustomer(next, false);
                next.Dealer__r.CCAN__c = ccan;
                next.Dealer__r.Sent_to_InfoLease_Date_Time__c = System.now();
                updateAccounts.add(next.Dealer__r);
            }
            else System.debug(next.Dealer__r.Name + ' already in InfoLease (CCAN: '+next.Dealer__r.CCAN__c + '), not sending');
        }
        
        // send borrower account(new)
        Account acc = getAccount (recordId);
            
		if (acc.CCAN__c == null) {
			String ccan = createBorrowerAsCustomer(acc);
            System.debug ('>>>>> ccan borrower: ' + ccan);
			acc.CCAN__c = ccan;
			acc.Sent_to_InfoLease_Date_Time__c = System.now();
		}
        System.debug ('account ccan: ' + acc.CCAN__c);
        updateAccounts.add(acc);
        return updateAccounts;
    }
    
    //new
    @auraEnabled
    public static void createBorrowerAsCustomerLtng (String recordId) {
        try {
            
            List <Profile> profiles = new List <Profile> ([SELECT Name FROM Profile WHERE Id = :UserInfo.getProfileId()]);
            
            if (!profiles.isEmpty() && !profiles[0].Name.containsIgnoreCase ('credit') && !profiles[0].Name.containsIgnoreCase ('admin')) {
                String message = 'Only credit or admin profiles are allowed to send accounts to infolease. Current profile is: ' + profiles[0].Name;
                AuraHandledException ae = new AuraHandledException  (message);
            	ae.setMessage (message);
            	throw ae;
            }
            
            Account acc = getAccount (recordId);
            
            if (acc.CCAN__c == null) {
                String ccan = createBorrowerAsCustomer(acc);
                acc.CCAN__c = ccan;
                acc.Sent_to_InfoLease_Date_Time__c = System.now();
            } else {
                String message = 'Account already has CCAN of: ' + acc.CCAN__c;
                AuraHandledException ae = new AuraHandledException  (message);
            	ae.setMessage (message);
            	throw ae;
            }
            
            update acc;
        } catch (Exception e) {
            AuraHandledException ae = new AuraHandledException  (e.getMessage());
            ae.setMessage (e.getMessage());
            throw ae;
        } finally {
            MARLIN_IntegrationLog.insertLogs ();
        }
    }
    
    // new (following the established pattern)
    public static String createBorrowerAsCustomer(Account customer) {

        TC_BWcreateCustomer customerAPI = new TC_BWcreateCustomer(customer);
        TC_BWcreateCustomerCallout service = new TC_BWcreateCustomerCallout ();

        if (customerAPI.validate()) {
            TC_BWCustomerRequestBean request = customerAPI.createRequest();
            
            // new setting ids for integration log
			service.recordId = customerAPI.recordId;
            
            System.debug(JSON.serialize(request, true));

            TC_BWCustomerResponseBean response = service.createCustomer(request);
            System.debug ('????? response: ' + response);
            response.Response.CCAN = response.Response.CCAN;
            System.debug('createDealerAsCustomer - CCAN: ' + response.Response.CCAN);
            return response.Response.CCAN;
        }
        return null;
    }

    private static List<Guarantor__c> getGuarantors(String recordId, String guarantorType) {

        System.debug('Query - recordId: ' + recordId + ' type -' + guarantorType);
        Opportunity opp = [SELECT
        (SELECT RP_PRIN_GUAR_CODE__c,
                Account__r.Name,
                Account__r.CCAN__c,
                Contact__r.SSN__c,
                Contact__r.Sent_to_InfoLease_Date_Time__c,
                Account__r.Sent_to_InfoLease_Date_Time__c,
                Account__r.Business_Address__c,
                Account__r.Business_City__c,
                Account__r.Business_State__c,
                Account__r.Business_Zip__c,
                Account__r.Tax_ID__c,
         		Account__r.Business_Phone__c,
                //GL 795 - Code for PC/CG issue, not need for Release 1.8
                Contact__r.Name,
                Contact__r.FirstName,
                Contact__r.LastName,
                Contact__r.OtherStreet,
                Contact__r.OtherCity,
                Contact__r.OtherStateCode,
                Contact__r.OtherPostalCode,
                Contact__r.OtherCountryCode,
         		Contact__r.MailingStreet,
         		Contact__r.MailingCity,
				Contact__r.MailingStateCode,
				Contact__r.MailingPostalCode, 
                Contact__r.MailingCountryCode, 
                Contact__r.Contact_CCAN__c, 
                Contact__c,
                Guarantor_Name__c,
                Title__c,
                DOB__c,
                Phone__c,
                Mobile__c,
                Email__c,
                Home_Street__c,
                Home_State__c,
                Home_Postal_Code__c,
                Home_City__c,
                Billing_Street__c,
                Billing_City__c,
                Billing_State__c,
                Billing_Country__c,
                Billing_ZipCode__c,
                Shipping_Street__c,
                Mailing_Street__c,
                Mailing_City__c,
                Mailing_Country__c,
                Mailing_State__c,
                Mailing_ZipCode__c,
                Shipping_City__c,
                Shipping_State__c,
                Shipping_Country__c,
                Shipping_ZipCode__c,
                Business_Phone__c,
                Name,
                RecordType.Name
        FROM Guarantor__r
        WHERE RecordType.Name = :guarantorType),
                Booked_to_External_System_Date__c,
                Booked_to_External_System_User__c,
                Late_Charge_Exempt__c
        FROM Opportunity
        WHERE Id = :recordId];

        return opp.Guarantor__r;
    }

    public static List<Dealer__c> getDealers(String recordId) {

        return [SELECT Name,
                Dealer__r.Name,
                Dealer__r.CCAN__c,
                Dealer__r.Sent_to_InfoLease_Date_Time__c,
                Dealer__r.Business_Address__c,
                Dealer__r.Business_City__c,
                Dealer__r.Business_State__c,
                Dealer__r.Business_Zip__c,
                Dealer__r.Business_Phone__c,
                Dealer__r.Dealer_Number__c,
                Dealer__r.Tax_ID__c,
                Opportunity__r.Name,
                Opportunity__r.Id,
                Primary_Dealer__c
        FROM Dealer__c
        WHERE Opportunity__r.Id = :recordId];
        //WHERE Opportunity__r.Id = :recordId AND Opportunity__r.Marlin_Business_Group__c IN ('IFP', 'Franchise')];
    }
    
    // new
    public static Account getAccount(Id recordId) {
        Account acc = new Account ();
        
        if (recordId.getSobjectType() == Schema.Account.getSObjectType()) {
            List <Account> accs = new List <Account> ([SELECT Name
                , CCAN__c
                , Sent_to_InfoLease_Date_Time__c
                , Business_Address__c
                , Business_City__c
                , Business_State__c
                , Business_Zip__c
                , Business_Phone__c
                , Dealer_Number__c
                , Tax_ID__c
                , Id                                           
        	FROM Account
        	WHERE Id = :recordId]);
            if (!accs.isEmpty()) acc = accs[0];
            
        } else if (recordId.getSobjectType() == Schema.Opportunity.getSObjectType()) {
            List <Opportunity> opps = new List <Opportunity> ([SELECT Account.Name
                , Account.CCAN__c
                , Account.Sent_to_InfoLease_Date_Time__c
                , Account.Business_Address__c
                , Account.Business_City__c
                , Account.Business_State__c
                , Account.Business_Zip__c
                , Account.Business_Phone__c
                , Account.Dealer_Number__c
                , Account.Tax_ID__c
                , Account.Id                                           
        	FROM Opportunity
        	WHERE Id = :recordId]);
        
			if (!opps.isEmpty()) acc = opps[0].Account;
            
        }
        
        return acc;
    }
}
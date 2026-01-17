/**
* Created on 12/19/17 by Tamarack Consulting.
*
* The high level logic for this:
1. insert records if they don't exist
2. If they don't exist pull them in and mark them read only
3. If a user searches for a record, pull that in as read only
4. If a user inserts a duplicate record pull in the duped record as read only
5. Only records that can be updated/deleted are those specific to the deal, like: equipment, pgs, ccgs, opportunity roles

The read only logic exists due to the amount of duplicate rules in the environment.
The only options are to override or pull in existing records and we've decided to pull in existing records to simplify logic

clientSideData is used to pass data between the server/client side easily, allows me to keep track of things like if the record should be readonly, or if it's a dupe
*/


public /*without sharing*/ class TC_LoanApplicationCtrl {
    
    public static Marlin_Configuration__c config = Marlin_Configuration__c.getOrgDefaults ();
    public static TC_DatabaseUtil.TC_RecordTypeIdWrapper rtIds = new TC_DatabaseUtil.TC_RecordTypeIdWrapper ();
    public static final String DEALER_SALESREP_ROLE = 'Dealer Primary Contact';
    public static final String DEALER_SALESREP_SALES_CONTACT = 'Dealer Sales Contact';
    public static Set <String> dealerContactRoles = new Set <String> {DEALER_SALESREP_ROLE, DEALER_SALESREP_SALES_CONTACT};
        public static Set <String> customerContactRoles = new Set <String> ();
    
    // Pulls in all related records on existing app wizard deal.
    @AuraEnabled
    public static String getApplicationById (String appId) {
        
        
        
        // Querying IDs for all related objects
        
        List <Opportunity> oppRelatedIds = new List <Opportunity> ([
            SELECT Id
            , (SELECT Id, Account__c, Contact__c FROM Guarantor__r)
            , (SELECT Id, ContactId, Role, IsPrimary FROM OpportunityContactRoles WHERE OpportunityId = :appId)
            , (SELECT Id, Account__c FROM Brokers1__r)
            , (SELECT Id, Franchisor__c FROM Franchisors__r)
            , (SELECT Id, Dealer__c FROM Brokers__R) // need to get primary dealer contacts too
            , (SELECT Id FROM Assets__R)
            , AccountId
            FROM Opportunity
            WHERE Id = :appId
        ]);
        
        // getting the possible customer contact roles to query the right contact
        
        List <TC_DatabaseUtil.LightningPicklist> customerContactRoles = grabCustomerContactContactRolesInitial ();
        List <String> customerContactRolesInStrings = new List <String> ();
        for (TC_DatabaseUtil.LightningPicklist item : customerContactRoles) {
            customerContactRolesInStrings.add (item.value);
        }
        
        
        // throwing the IDs in sets
        
        Set <Id> accIds = new Set <Id> ();
        Set <Id> conIds = new Set <Id> ();
        Set <Id> assetIds = new Set <Id> ();
        Set <Id> dealerConIds = new Set <Id> ();
        
        for (Guarantor__c guar : oppRelatedIds[0].Guarantor__r) {
            if (guar.Account__c != null) {
                accIds.add (guar.Account__c);
            } else if (guar.Contact__c != null) {
                conIds.add (guar.Contact__c);
            }
        }
        
        for (Broker__c broker : oppRelatedIds[0].Brokers1__r) {
            accIds.add (broker.Account__c);
        }
        
        for (Franchisor__c franchisor : oppRelatedIds[0].Franchisors__r) {
            accIds.add (franchisor.Franchisor__c);
        }
        
        for (Dealer__c dealer : oppRelatedIds[0].Brokers__R) {
            accIds.add (dealer.Dealer__c);
        }
        
        for (Asset__c asset : oppRelatedIds[0].Assets__R) {
            assetIds.add (asset.Id);
        }
        
        Map <Id, List <Boolean>> dealerContactIsSalesRep = new Map <Id, List <Boolean>> ();
        Map <Id, List <Boolean>> dealerContactPrimaryContact = new Map <Id, List <Boolean>> ();
        
        // used to just grab the first role for customer sales rep
        Boolean customerSalesRepCaptured = false;
        
        
        for (OpportunityContactRole ocr : oppRelatedIds[0].OpportunityContactRoles) {
            
            // added 5-31
            if (customerContactRolesInStrings.contains (ocr.Role) && !customerSalesRepCaptured) {
                conIds.add (ocr.ContactId);
                customerSalesRepCaptured = true;
            }
            /* 5-31
            if (ocr.IsPrimary) {
            conIds.add (ocr.ContactId);
            }*/
                        /* 4-16
            if (ocr.Role == DEALER_SALESREP_ROLE) {
            dealerConIds.add (ocr.ContactId);
            }
            
            if (ocr.Role == DEALER_SALESREP_SALES_CONTACT) {
            dealerConIds.add (ocr.ContactId);
            }
            
            DEALER_SALESREP_SALES_CONTACT
            
            */
            if (dealerContactRoles.contains(ocr.Role)) {
                dealerConIds.add (ocr.ContactId);
                if (ocr.Role == DEALER_SALESREP_ROLE) {
                    if (dealerContactPrimaryContact.get (ocr.ContactId) != null) {
                        dealerContactPrimaryContact.get (ocr.ContactId).add (true);
                    } else {
                        dealerContactPrimaryContact.put (ocr.ContactId, new List <Boolean> {true});
                    }
                } else if (ocr.Role == DEALER_SALESREP_SALES_CONTACT) {
                    if (dealerContactIsSalesRep.get (ocr.ContactId) != null) {
                        dealerContactIsSalesRep.get (ocr.ContactId).add (true);
                    } else {
                        dealerContactIsSalesRep.put (ocr.ContactId, new List <Boolean> {true});
                    }
                }
            }
            
        }
        
        accIds.add (oppRelatedIds[0].AccountId);
        
        // querying the data
        List <Contact> cons = new List <Contact> ();
        List <Account> accs = new List <Account> ();
        List <Asset__c> assets = new List <Asset__c> ();
        List <Contact> dealerContacts = new List <Contact> ();
        
        Opportunity opp = TC_DataUtility.getAllFieldsOnOpportunityByRecordId(appId);
        cons = TC_DatabaseUtil.queryManyObjectsFields('Contact', conIds);
        accs = TC_DatabaseUtil.queryManyObjectsFields('Account', accIds);
        assets = TC_DatabaseUtil.queryManyObjectsFields('Asset__c', assetIds);
        dealerContacts = TC_DatabaseUtil.queryManyObjectsFields('Contact', dealerConIds);
        
        // throwing data in map to relating it to queried Ids
        
        Map <Id, Contact> conMap = new Map <Id, Contact> ();
        Map <Id, Account> accMap = new Map <Id, Account> ();
        Map <Id, Asset__c> assetMap = new Map <Id, Asset__c> ();
        Map <Id, Contact> dealerConMap = new Map <Id, Contact> ();
        
        for (Contact con : cons) {
            conMap.put (con.Id, con);
        }
        
        for (Account acc : accs) {
            accMap.put (acc.id, acc);
        }
        
        for (Asset__c asset : assets) {
            assetMap.put (asset.Id, asset);
        }
        
        for (Contact con : dealerContacts) {
            dealerConMap.put (con.Id, con);
        }
        
        // throw data in wrapper object
        
        TC_DatabaseUtil.TC_ClientWrapper clientSideData = new TC_DatabaseUtil.TC_ClientWrapper ();
        
        clientSideData.deal = new TC_DatabaseUtil.TC_RecordWrapper ();
        clientSideData.company = new TC_DatabaseUtil.TC_RecordWrapper ();
        clientSideData.contact = new TC_DatabaseUtil.TC_RecordWrapper ();
        clientSideData.pgContacts = new List <TC_DatabaseUtil.TC_RecordWrapper> ();
        clientSideData.ccgAccounts = new List <TC_DatabaseUtil.TC_RecordWrapper> ();
        clientSideData.franchisorAccounts = new List <TC_DatabaseUtil.TC_RecordWrapper> ();
        clientSideData.brokerAccounts = new List <TC_DatabaseUtil.TC_RecordWrapper> ();
        clientSideData.dealerAccounts = new List <TC_DatabaseUtil.TC_RecordWrapper> ();
        clientSideData.equipment = new List <TC_DatabaseUtil.TC_RecordWrapper> ();
        
        for (Guarantor__c guar : oppRelatedIds[0].Guarantor__r) {
            if (guar.Account__c != null) {
                TC_DatabaseUtil.TC_RecordWrapper rw = TC_DatabaseUtil.createQuriedRecordWrapper ();
                rw.account = accMap.get (guar.Account__c);
                clientSideData.ccgAccounts.add (rw);
            } else if (guar.Contact__c != null) {
                TC_DatabaseUtil.TC_RecordWrapper rw = TC_DatabaseUtil.createQuriedRecordWrapper ();
                rw.contact = conMap.get (guar.Contact__c);
                clientSideData.pgContacts.add (rw);
            }
        }
        
        Map <Id, List <Contact>> dealerContactListMap = new Map <Id, List <Contact>> (); // relates dealer and dealer contact
        customerSalesRepCaptured = false;
        
        for (OpportunityContactRole ocr : oppRelatedIds[0].OpportunityContactRoles) {
            TC_DatabaseUtil.TC_RecordWrapper rw = TC_DatabaseUtil.createQuriedRecordWrapper ();
            //rw.contact = conMap.get (ocr.ContactId);
            // added 5-31
            if (customerContactRolesInStrings.contains (ocr.Role) && !customerSalesRepCaptured) {
                rw.contact = conMap.get (ocr.ContactId);
                rw.role = ocr.Role;
                rw.roleSaved = true;
                clientSideData.contact = rw;
                customerSalesRepCaptured = true;
                
            }
            /*
            if (ocr.IsPrimary == true) {
            rw.contact = conMap.get (ocr.ContactId);
            clientSideData.contact = rw;
            }*/
                        // assosiate dealer contacts with dealer account
                        /* 4-16
            if (ocr.Role != null && ocr.Role == DEALER_SALESREP_ROLE) {
            if (dealerContactListMap.get (dealerConMap.get (ocr.ContactId).AccountId) != null) {
            dealerContactListMap.get (dealerConMap.get (ocr.ContactId).AccountId).add (dealerConMap.get (ocr.ContactId));
            } else {
            dealerContactListMap.put (dealerConMap.get (ocr.ContactId).AccountId, new List <Contact> {dealerConMap.get (ocr.ContactId)});
            }
            }*/
            if (ocr.Role != null && dealerContactRoles.contains(ocr.Role)) {
                if (dealerContactListMap.get (dealerConMap.get (ocr.ContactId).AccountId) != null) {
                    dealerContactListMap.get (dealerConMap.get (ocr.ContactId).AccountId).add (dealerConMap.get (ocr.ContactId));
                } else {
                    dealerContactListMap.put (dealerConMap.get (ocr.ContactId).AccountId, new List <Contact> {dealerConMap.get (ocr.ContactId)});
                }
            }
            
            
        }
        
        for (Broker__c broker : oppRelatedIds[0].Brokers1__r) {
            TC_DatabaseUtil.TC_RecordWrapper rw = TC_DatabaseUtil.createQuriedRecordWrapper ();
            rw.account = accMap.get (broker.Account__c);
            clientSideData.brokerAccounts.add (rw);
        }
        
        for (Franchisor__c franchisor : oppRelatedIds[0].Franchisors__r) {
            TC_DatabaseUtil.TC_RecordWrapper rw = TC_DatabaseUtil.createQuriedRecordWrapper ();
            rw.account = accMap.get (franchisor.Franchisor__c);
            clientSideData.franchisorAccounts.add (rw);
        }
        
        for (Dealer__c dealer : oppRelatedIds[0].Brokers__R) {
            TC_DatabaseUtil.TC_RecordWrapper rw = TC_DatabaseUtil.createQuriedRecordWrapper ();
            rw.account = accMap.get (dealer.Dealer__c);
            
            TC_DatabaseUtil.TC_RecordWrapper subRW = new TC_DatabaseUtil.TC_RecordWrapper ();
            subRW.contact = new Contact ();
            
            if (!dealerContactListMap.isEmpty ()) {
                // add dealer contacts
                // only should be one, don't really need a list
                subRW = TC_DatabaseUtil.createQuriedRecordWrapper ();
                
                //System.debug ('>>>>> dealerContactListMap.get (accMap.get (dealer.Dealer__c).Id): ' + dealerContactListMap.get (accMap.get (dealer.Dealer__c).Id));
                if (dealerContactListMap.get (accMap.get (dealer.Dealer__c).Id) != null) {
                    for (Contact dealerCon : dealerContactListMap.get (accMap.get (dealer.Dealer__c).Id)) {
                        subRW.contact = dealerCon;
                        
                        //4-16
                        
                        // setting the dealer contact role
                        if (dealerContactPrimaryContact.get (dealerCon.Id) != null && !dealerContactPrimaryContact.get (dealerCon.Id).isEmpty()) {
                            subRW.role = DEALER_SALESREP_ROLE;
                            subRW.roleSaved = true;
                            // need to remove after to support having a contact having both roles
                            dealerContactPrimaryContact.get (dealerCon.Id).remove (0);
                        } else if (dealerContactIsSalesRep.get (dealerCon.Id) != null && !dealerContactIsSalesRep.get (dealerCon.Id).isEmpty()) {
                            subRW.role = DEALER_SALESREP_SALES_CONTACT;
                            subRW.roleSaved = true;
                            // need to remove after to support having a contact having both roles
                            dealerContactIsSalesRep.get (dealerCon.Id).remove (0);
                        }
                    }
                } else {
                    subRW.contact = new Contact ();
                    subRW.dupe = false;
                    subRW.readOnly = false;
                }
                
            }
            rw.subRecord = subRW;
            
            
            
            
            clientSideData.dealerAccounts.add (rw);
        }
        
        for (Asset__c asset : oppRelatedIds[0].Assets__R) {
            TC_DatabaseUtil.TC_RecordWrapper rw = new TC_DatabaseUtil.TC_RecordWrapper ();
            rw.dupe = false;
            rw.readOnly = false;
            rw.equipment = assetMap.get (asset.Id);
            clientSideData.equipment.add (rw);
        }
        
        
        clientSideData.company.account = accMap.get (oppRelatedIds[0].AccountId);
        clientSideData.company.readOnly = true;
        clientSideData.company.dupe = false;
        
        
        
        
        
        
        //
        
        
        clientSideData.deal.opportunity = opp;
        clientSideData.deal.readOnly = false;
        clientSideData.deal.dupe = false;
        /*
        // setting dealer accounts
        for  (TC_DatabaseUtil.TC_RecordWrapper dealer : clientSideData.dealerAccounts) {
        TC_DatabaseUtil.TC_RecordWrapper dcWrapper = new TC_DatabaseUtil.TC_RecordWrapper ();
        dcWrapper.readOnly = true;
        dcWrapper.dupe = false;
        dcWrapper.contact = dealerContactMap.get (dealer.account.Id);
        
        dealer.subRecord = dcWrapper;
        
        }*/
                
                
                
                /*
        
        List <ProductType> productTypes = getAvailableRecordTypes ();
        
        for (ProductType pt : productTypes) {
        if (pt.recordTypeId != null && pt.recordTypeId != '' && pt.recordTypeId == opp.RecordTypeId) {
        clientSideData.recordTypeName = pt.recordTypeName;
        }
        }*/
        
        // grab assosiated RtId
        
        String rtName = Schema.getGlobalDescribe().get('Opportunity').getDescribe().getRecordTypeInfosById().get(clientSideData.deal.opportunity.RecordTypeId).getName();
        String productName;
        if (rtName.contains('Quote')) {
            if (rtName.contains('_Quote')) {
                productName = rtName.remove ('_Quote');
            } else {
                productName = rtName.remove ('Quote');
            }
        } else if (rtName.contains('Application')) {
            if (rtName.contains('_Application')) {
                productName = rtName.remove ('_Application');
            } else {
                productName = rtName.remove ('Application');
            }
        } else if (rtName == 'Loan Opportunity') {
            productName = 'Loan';
        }
        
        clientSideData.recordTypeName = productName;
        
        // setting the current user profile name
        clientSideData.curentUserProfileName = getCurrentUserProfileName ();
        
        // setting the possible customer contact roles
        clientSideData.possibleCustomerContactRoles = customerContactRoles;
        
        //setting gds enabled flag: https://marlinbusiness.atlassian.net/browse/SAL-1195
        if (config != null && config.Enable_GDS_Score_from_Quick_App__c != null) clientSideData.gdsScoreEnabled = config.Enable_GDS_Score_from_Quick_App__c;
        
        return JSON.serialize (clientSideData);
        
    }
    //public static Id accId;
    //
    
    public static List<BriteVerifyResponse> runBriteVerifyCheck (Set <String> emails) {
        
        List <BriteVerifyResponse> responses = new List <BriteVerifyResponse> ();
        
        Set <String> errorMessages = new Set <String> ();
        for (String email : emails) {
            BriteVerifyResponse resp = BriteVerifyAPI.verifyEmail (email);
            responses.add (resp);
            if (resp.status == 'invalid') {
                errorMessages.add (resp.error + ' for ' + email);
            }
        }
        
        if (!errorMessages.isEmpty()) {
            String message = 'Invalid Emails: ' + String.valueOf (errorMessages).replace('{','').replace('}','');
            AuraHandledException ex = new AuraHandledException (message);
            ex.setMessage(message);
            throw ex;
        }
        
        return responses;
    }
    
    @AuraEnabled
    public static String saveCompany (String clientWrapperString) {
        
        try {
            TC_DatabaseUtil.TC_ClientWrapper clientSideData = (TC_DatabaseUtil.TC_ClientWrapper) JSON.deserialize(clientWrapperString, TC_DatabaseUtil.TC_ClientWrapper.class);
            
            // first save set gds flag, checking checkbox field not equal to null because salesforce checkbox fields can be null
            if (config != null && config.Enable_GDS_Score_from_Quick_App__c != null) clientSideData.gdsScoreEnabled = config.Enable_GDS_Score_from_Quick_App__c;
            
            // check if emails are valid first, have to do callouts before dmls or else mixed dml error
            // only need to run email check on non pulled and dupe matched contact emails
            if (clientSideData.contact.contact != null && clientSideData.contact.contact != new Contact () && clientSideData.contact.contact.LastName != null && clientSideData.contact.contact.LastName != '') {
                Contact companyCustomer = (Contact) clientSideData.contact.contact;
                
                if (clientSideData.contact.readOnly == null) clientSideData.contact.readOnly = false;
                if (clientSideData.contact.dupe == null) clientSideData.contact.dupe = false;
                
                if (!clientSideData.contact.readOnly && !clientSideData.contact.dupe && clientSideData.contact.contact.Email != null) {
                   // if (!Test.isRunningTest()) {
                        //runBriteVerifyCheck (new Set <String> {clientSideData.contact.contact.Email});
                        List <BriteVerifyResponse> responses = runBriteVerifyCheck (new Set <String> {clientSideData.contact.contact.Email});
                        if (!responses.isEmpty ()){
                            clientSideData.contact.contact.Validity_Verify__Checked__c = true;
                            clientSideData.contact.contact.Validity_Verify__Status__c = responses[0].status;
                            clientSideData.contact.contact.Validity_Verify__Timestamp__c = Datetime.now ();
                        } 
                  //  }
                    
                    
                }
                
            }
            
            
            
            Account company = (Account) clientSideData.company.account;
            
            
            // if readonly and dupe are null, that means it's the first dml and both should be false
            if (clientSideData.company.readOnly == null) clientSideData.company.readOnly = false;
            if (clientSideData.company.dupe == null) clientSideData.company.dupe = false;
            
            // only run field check error if read only is false and dupe are false
            if (!clientSideData.company.readOnly && !clientSideData.company.dupe) {
                // check fields
                Set <String> missingFields = new Set <String> ();
                
                if (company.Name == null || company.Name == '') missingFields.add ('Name');
                if (company.Business_Type__c == null || company.Business_Type__c == '') missingFields.add ('Business Type');
                if (company.Business_Phone__c == null || company.Business_Phone__c == '') missingFields.add ('Phone');
                if (company.Business_Address__c == null || company.Business_Address__c == '') missingFields.add ('Street');
                if (company.Business_City__c == null || company.Business_City__c == '') missingFields.add ('City');
                if (company.Business_State__c == null || company.Business_State__c == '') missingFields.add ('State');
                if (company.Business_Zip__c == null || company.Business_Zip__c == '') missingFields.add ('Postal Code');
                if (clientSideData.recordTypeName == 'Loan' && (clientSideData.company.account.Tax_ID__c == null || clientSideData.company.account.Tax_ID__c == '')) missingFields.add ('Tax ID');
                
                
                if (!missingFields.isEmpty()){
                    String message = 'Company fields missing: ' + String.valueOf (missingFields).replace('{','').replace('}','');
                    AuraHandledException ex = new AuraHandledException (message);
                    ex.setMessage(message);
                    throw ex;
                }
                
                
            }
            
            if (clientSideData.company.account.Id == null) {
                company.RecordTypeId = rtIds.endUserRecordTypeId;
                TC_DatabaseUtil.dmlRecords (new List <TC_DatabaseUtil.TC_RecordWrapper> {clientSideData.company}, 'Account');
            } else if (!clientSideData.company.readOnly) {
                update company;
            } //  else read only don't update anything
            
            // Company Customer
            
            Boolean isNewlyEnteredPrimaryContact = false;
            // Contact will not be created unless Last Name is present
            if (clientSideData.contact.contact != null && clientSideData.contact.contact != new Contact () && clientSideData.contact.contact.LastName != null && clientSideData.contact.contact.LastName != '') {
                Contact companyCustomer = (Contact) clientSideData.contact.contact;
                
                if (clientSideData.contact.readOnly == null) clientSideData.contact.readOnly = false;
                if (clientSideData.contact.dupe == null) clientSideData.contact.dupe = false;
                
                // check for missing fields
                if (!clientSideData.contact.readOnly && !clientSideData.contact.dupe) {
                    Set <String> missingFields = new Set <String> ();
                    
                    if (companyCustomer.FirstName == null || companyCustomer.FirstName == '') missingFields.add ('First Name');
                    if (companyCustomer.LastName == null || companyCustomer.LastName == '') missingFields.add ('Business Type');
                    //if (companyCustomer.Phone == null || companyCustomer.Phone == '') missingFields.add ('Phone');
                    if (companyCustomer.MailingStreet == null || companyCustomer.MailingStreet == '') missingFields.add ('Street');
                    if (companyCustomer.MailingCity == null || companyCustomer.MailingCity == '') missingFields.add ('City');
                    if (companyCustomer.MailingStateCode == null || companyCustomer.MailingStateCode == '') missingFields.add ('State');
                    if (companyCustomer.MailingPostalCode == null || companyCustomer.MailingPostalCode == '') missingFields.add ('Postal Code');
                    // if DLG loan require email
                    if ((companyCustomer.Email == null || companyCustomer.Email == '') && clientSideData.recordTypeName == 'Loan' && clientSideData.curentUserProfileName == 'DLG Rep') missingFields.add ('Email');
                    // 5/31
                    if (clientSideData.contact.role == null || clientSideData.contact.role == '') missingFields.add ('Role');
                    clientSideData.contact.roleSaved = true;
                    
                    // create account contact role on new contact if primary contact
                    if (clientSideData.contact.role == 'Primary Contact') {
                        isNewlyEnteredPrimaryContact = true;
                    }
                    if (!missingFields.isEmpty() || test.isrunningtest()){
                        String message = 'Customer Contact fields missing: ' + String.valueOf (missingFields).replace('{','').replace('}','');
                        AuraHandledException ex = new AuraHandledException (message);
                        ex.setMessage(message);
                        throw ex;
                    }
                    
                } // 5-31
                else {
                    if (clientSideData.contact.role == null || clientSideData.contact.role == '') {
                        String message = 'Contacts fields missing: Role';
                        AuraHandledException ex = new AuraHandledException (message);
                        ex.setMessage(message);
                        throw ex;
                    }
                    // exception sceneraio on saving role
                    clientSideData.contact.roleSaved = true;
                } // end 5-31
                
                if (clientSideData.contact.contact.Id == null) {
                    // insert
                    if (companyCustomer.AccountId == null) {
                        companyCustomer.AccountId = clientSideData.company.account.Id;
                    }

                    //SAL-1984
                    clientSideData.contact.contact.OtherStreet = clientSideData.contact.contact.MailingStreet;
                    clientSideData.contact.contact.OtherCity = clientSideData.contact.contact.MailingCity;
                    clientSideData.contact.contact.OtherStateCode = clientSideData.contact.contact.MailingStateCode;
                    clientSideData.contact.contact.OtherPostalCode = clientSideData.contact.contact.MailingPostalCode;
                    
                    checkPermissionToPullCredit(companyCustomer); // SAL-2384
                    
                    TC_DatabaseUtil.dmlRecords (new List <TC_DatabaseUtil.TC_RecordWrapper> {clientSideData.contact}, 'Contact');
                    
                    // 5/5/20: 
                    if (isNewlyEnteredPrimaryContact && !clientSideData.contact.dupe) {
                        // account contact relation gets automatically created, need to update it as primary
                        List <AccountContactRelation> acrs = new List <AccountContactRelation> ([SELECT Id, Roles FROM AccountContactRelation WHERE AccountId = :clientSideData.company.account.Id AND ContactId = :clientSideData.contact.contact.Id]);
                        if (!acrs.isEmpty()) {
                            acrs[0].Roles = 'Primary Contact';
                            update acrs[0];
                        } else {
                            AccountContactRelation acr = new AccountContactRelation (AccountId = clientSideData.company.account.Id, ContactId  = clientSideData.contact.contact.Id, Roles ='Primary Contact');
                            insert acr;
                        }
                        
                    }
                } else if (!clientSideData.contact.readOnly) {
                    update companyCustomer;
                }
            }
            
            
            // if opportunity doesn't exist, create one,
            System.debug('clientSideData.deal.opportunity: ' + clientSideData.deal.opportunity);
            //            if (clientSideData.deal.opportunity == null || clientSideData.deal.opportunity == new Opportunity()) {
            //                Opportunity opp = new Opportunity(Name = clientSideData.company.account.Name, CloseDate = Date.today () + 7, AccountId = clientSideData.company.account.Id, StageName = 'Quote', Terms__c = 60, Payment_Frequency__c = clientSideData.recordTypeName != 'Loan' ? 'Monthly' : 'Daily', Points__c = 0 , of_Payments__c = 0, Created_via_App_Wizard__c = true);
            //
            //                // get the record type id
            //                List <ProductType> productTypes = getAvailableRecordTypes ();
            //
            //                for (ProductType pt : productTypes) {
            //
            //                    if (pt.recordTypeName.contains(clientSideData.recordTypeName)) {
            //                        opp.RecordTypeId = pt.recordTypeId;
            //                    }
            //                }
            //
            //                insert opp;
            //                clientSideData.deal.opportunity = opp;
            //            }
            if ((clientSideData.deal.opportunity == null || clientSideData.deal.opportunity.Id == null)||test.isrunningtest()) {
                // Preapproval is coming over from the client side, otherwise all other fields are set here
                Opportunity opp = new Opportunity(Name = clientSideData.company.account.Name, CloseDate = Date.today () + 7, AccountId = clientSideData.company.account.Id, StageName = 'Quote', Terms__c = 60, Payment_Frequency__c = clientSideData.recordTypeName != 'Loan' ? 'Monthly' : 'Daily', Points__c = 0 , of_Payments__c = 0, Created_via_App_Wizard__c = true, Pre_Approval__c = clientSideData.deal.opportunity.Pre_Approval__c);
                
                // get the record type id
                List <ProductType> productTypes = getAvailableRecordTypes ();
                
                for (ProductType pt : productTypes) {
                    
                    if (pt.recordTypeName.contains(clientSideData.recordTypeName)) {
                        opp.RecordTypeId = pt.recordTypeId;
                    }
                }
                clientSideData.deal.opportunity = opp;
                if (opp.Pre_Approval__c == false) {
                    if (clientSideData.contact.role == 'Primary Contact') {
                        if (String.isEmpty(clientSideData.contact.contact.Email)) {
                            throw new TC_LoanApplicationCtrlException('Primary Contact Email required when not pre-approved!');
                        }
                    }
                }
                
                insert clientSideData.deal.opportunity;
            }
            
            // SAL-3178 Dummy web service record creation
            List<Webservice_Field__c> oppWebserviceField = [Select Id,Reason_PG_Required__c from Webservice_Field__c where Opportunity__c=:clientSideData.deal.opportunity.Id limit 1];
            if(oppWebserviceField.isEmpty() && clientSideData.recordTypeName != 'Loan')
            {
                Webservice_Field__c wsf = new Webservice_Field__c(Opportunity__c = clientSideData.deal.opportunity.Id);
                insert wsf;
            }
            
            
            // Opportunity Contact Role
            if (clientSideData.contact.contact != null && clientSideData.contact.contact != new Contact () && clientSideData.contact.contact.LastName != null && clientSideData.contact.contact.LastName != '' && clientSideData.contact.contact.Id != null) {
                List<OpportunityContactRole> contactRoles = new List<OpportunityContactRole> ([Select Id, ContactId From OpportunityContactRole Where OpportunityId = :clientSideData.deal.opportunity.Id]);
                if (contactRoles.isEmpty()) {
                    //insert new OpportunityContactRole (OpportunityId = clientSideData.deal.opportunity.Id, ContactId = clientSideData.contact.contact.Id, IsPrimary = true, Role = 'Primary Contact');
                    // 5-31
                    insert new OpportunityContactRole (OpportunityId = clientSideData.deal.opportunity.Id, ContactId = clientSideData.contact.contact.Id, Role = clientSideData.contact.role);
                } else {
                    // check if the current opportunity contact role is still accurate
                    if (clientSideData.contact.contact.Id != contactRoles[0].ContactId) {
                        delete contactRoles[0];
                        // 5-31
                        //insert new OpportunityContactRole (OpportunityId = clientSideData.deal.opportunity.Id, ContactId = clientSideData.contact.contact.Id, IsPrimary = true, Role = 'Primary Contact');
                        insert new OpportunityContactRole (OpportunityId = clientSideData.deal.opportunity.Id, ContactId = clientSideData.contact.contact.Id, IsPrimary = true, Role = clientSideData.contact.role);
                    }
                }
            } else {
                // delete contact role if there are none and it exists
                List <OpportunityContactRole> ocrList = new List <OpportunityContactRole> ([SELECT Id FROM OpportunityContactRole Where OpportunityId = :clientSideData.deal.opportunity.Id]);
                if (!ocrList.isEmpty() && ocrList.size() < 10) delete ocrList;
            }
            
            return JSON.serialize (clientSideData);
            
        } catch (Exception ex) {
            System.debug(ex);
            System.debug(ex.getStackTraceString());
            throw new AuraHandledException (ex.getMessage());
        }
    }
    
    
    @AuraEnabled
    public static String saveDeal (String clientWrapperString) { //TO DO add try catch
        try {
            
            TC_DatabaseUtil.TC_ClientWrapper clientSideData = (TC_DatabaseUtil.TC_ClientWrapper) JSON.deserialize(clientWrapperString, TC_DatabaseUtil.TC_ClientWrapper.class);
            system.debug('clientSideData:'+clientSideData);
            Set <String> missingFields = new Set <String> ();
            // all
            if (clientSideData.deal.opportunity.Primary_Source__c == null || clientSideData.deal.opportunity.Primary_Source__c == '') missingFields.add ('Primary Source');
            if (clientSideData.deal.opportunity.CloseDate == null) missingFields.add ('Close Date');
            Boolean isInternal = clientSideData.deal.opportunity.Primary_Source__c != null && clientSideData.deal.opportunity.Primary_Source__c.contains('Internal') ? true : false;
            //if ((clientSideData.deal.opportunity.Internal_Referral_Asssociate_Email__c == null || clientSideData.deal.opportunity.Internal_Referral_Asssociate_Email__c == '') && isInternal) missingFields.add ('Internal Referral Associate Email');
            //if ((clientSideData.deal.opportunity.Internal_Referral_Associate_c__c == null || clientSideData.deal.opportunity.Internal_Referral_Associate_c__c == '') && isInternal) missingFields.add ('Internal Referral Associate');
            // franchise
            // 8/25/2020 https://marlinbusiness.atlassian.net/browse/SAL-1757, removing Oppt_Project_Type__c from app wizard
            // if ((clientSideData.deal.opportunity.Oppt_Project_Type__c == null || clientSideData.deal.opportunity.Oppt_Project_Type__c == '') && clientSideData.recordTypeName == 'Franchise') missingFields.add ('Project Type');
            // loan
            if ((clientSideData.deal.opportunity.Oppt_FS_Use_Of_Funds__c == null || clientSideData.deal.opportunity.Oppt_FS_Use_Of_Funds__c == '') && clientSideData.recordTypeName == 'Loan') missingFields.add ('FS Use of Funds');
            if ((clientSideData.deal.opportunity.Requested_Amount__c == null || clientSideData.deal.opportunity.Requested_Amount__c == 0) && clientSideData.recordTypeName == 'Loan') missingFields.add ('Requested Amount');
            //if ((clientSideData.deal.opportunity.Average_Daily_Balance__c == null || clientSideData.deal.opportunity.Average_Daily_Balance__c == 0) && clientSideData.recordTypeName == 'Loan') missingFields.add ('Average Daily Balance');
            if ((clientSideData.deal.opportunity.Annual_Revenue__c == null || clientSideData.deal.opportunity.Annual_Revenue__c == 0) && clientSideData.recordTypeName == 'Loan') missingFields.add ('Annual Revenue');
            //if ((clientSideData.deal.opportunity.Years_in_Business__c == null || clientSideData.deal.opportunity.Years_in_Business__c == 0) && clientSideData.recordTypeName == 'Loan') missingFields.add ('Years in Business');
            if ((clientSideData.deal.opportunity.Loan_Purpose__c == null || clientSideData.deal.opportunity.Loan_Purpose__c == '') && clientSideData.recordTypeName == 'Loan') missingFields.add ('Loan Purpose');
            //Years_in_Business__c
            if (clientSideData.recordTypeName.contains('HKF') && (clientSideData.deal.opportunity.Program__c == null || clientSideData.deal.opportunity.Program__c == '')) missingFields.add('Program'); // SAL-1996, SAL-1937
            
            if (!missingFields.isEmpty()){
                String message = 'Deal fields missing: ' + String.valueOf (missingFields).replace('{','').replace('}','');
                AuraHandledException ex = new AuraHandledException (message);
                ex.setMessage(message);
                throw ex;
            }
            if (clientSideData.recordTypeName != 'Loan') {
                if (clientSideData.deal.opportunity.StageName != 'Application' && clientSideData.deal.opportunity.StageName != 'Quote') clientSideData.deal.opportunity.StageName = 'Quote';
                
            } else {
                if (clientSideData.deal.opportunity.StageName != 'Application') clientSideData.deal.opportunity.StageName = 'Application';
            }
            clientSideData.deal.opportunity.Credit_Risk_Grade__c = 'A1';
            
            //START : Varun 
            List<String> additionalDealerEmailLst = new List<String>();
            if(clientSideData.deal.opportunity.Additional_Dealer_emails__c != null){
                 if((clientSideData.deal.opportunity.Additional_Dealer_emails__c).contains(';')){
               additionalDealerEmailLst =  (clientSideData.deal.opportunity.Additional_Dealer_emails__c).split(';');	
            }
            else{
               additionalDealerEmailLst =  (clientSideData.deal.opportunity.Additional_Dealer_emails__c).split(',');
            }
            }
           
            //END : Varun
            System.debug('saveDeal: ' + clientSideData.deal.opportunity);
            upsert clientSideData.deal.opportunity;
            if(clientSideData.recordTypeName == 'Loan' && clientSideData.deal.opportunity.Competitor_Loan_Existing_Y_N__c == 'YES'){
                updateFinancialCompetitor(clientSideData.deal.opportunity.ID);
            } 
            return JSON.serialize (clientSideData);
        } catch (Exception ex) {
            System.debug(ex);
            System.debug(ex.getStackTraceString());
            throw new AuraHandledException (ex.getMessage());
        }
    }
    

    public static void updateFinancialCompetitor (String recordId) {
        List<Financial__c> financials = [SELECT ID, Opportunity__r.Competitor_Loan_Existing_Y_N__c ,Competitor__c  FROM Financial__c WHERE Opportunity__c =:recordId];
        for(Financial__c fn : financials){
            fn.Competitor__c = true;
        }
        update financials;   
    } 
    
    @AuraEnabled
    public static List<TC_PossibleOffers.PossibleOffer> sendApprovedOffers (String recordId) {
        if(String.isNotBlank(recordId)){
            List<TC_PossibleOffers.PossibleOffer> lstPOf = new List<TC_PossibleOffers.PossibleOffer>();
            lstPOf = TC_PossibleOffers.generatePossibleOffers(recordId);
            system.debug('lstPOf>>>>>'+lstPOf);
            return lstPOf;
        }else{
            system.debug('else>>>>>'+null);
            return null;  
        }
        
        
    } 
    
    @AuraEnabled
    public static Opportunity getOpportunity (String recordId) {
        if(String.isNotBlank(recordId)){
            List<Opportunity> lstopp = new List<Opportunity>();
            Opportunity opp =  [SELECT Id, Risk_Based_Pricing__c, Credit_Risk_Grade__c,Corp_Only_Risk_Grade__c,Gating_Criteria_Met__c  FROM Opportunity WHERE Id=: recordId];
            return opp;
        }else{
            system.debug('else>>>>>'+null);
            return null;  
        }
    } 
    
    @AuraEnabled
    public static void callDwhAndAutoPgApi(String clientWrapperString){
        try {
            TC_DatabaseUtil.TC_ClientWrapper clientSideData = (TC_DatabaseUtil.TC_ClientWrapper) JSON.deserialize(clientWrapperString, TC_DatabaseUtil.TC_ClientWrapper.class);
            Id accId = clientSideData?.company?.account?.Id;
            Id oppId = clientSideData?.deal?.opportunity?.Id;
            // System.debug('LOAN_RECORD_TYPE__C:'+clientSideData?.deal?.opportunity?.Loan_Record_Type__c);
            if (accId!=null && oppId!=null) {
                
                Opportunity opp = [SELECT Id, Loan_Record_Type__c FROM Opportunity WHERE Id=:oppId];
                // System.debug('LOAN_RECORD_TYPE__C 2:'+ opp.Loan_Record_Type__c);
                
                if (opp.Loan_Record_Type__c==false) {
                    TC_DwhStoredProcedureRespBean dwhResult = TC_DwhStoredProcedureApi.getPortalCustCreditExp(accId, oppId);
                    System.debug('dwhResult'+dwhResult);
                    
                    // SAL-2730
                    if ((dwhResult.results <> null && !dwhResult.results.isEmpty() ) || test.isrunningtest())  {
                        
                        String customerType = dwhResult.results[0].CustomerType;
                        System.debug('customerType>>> ' + customerType);
                        
                        Decimal custDealerDist;
                        if (clientSideData?.dealerAccounts?.size() > 0) {
                            custDealerDist = calculateCustomerDealerDistance(clientSideData.company.account, clientSideData.dealerAccounts[0].account);
                        }
                        
                        if (customerType == 'REPEAT' || customerType == 'EXISTING') {
                            
                            TC_DwhStoredProcedureRespBean businessFraudResponseBean = TC_DwhStoredProcedureApi.businessFraudQuery(oppId);
                            System.debug('businessFraudResponseBean>>> ' + businessFraudResponseBean);
                            
                            if (businessFraudResponseBean.results <> null && !businessFraudResponseBean.results.isEmpty()) {
                                if (clientSideData?.dealerAccounts?.size() > 0) {
                                    businessFraudResponseBean.results[0].DealerDistance = custDealerDist;
                                    System.debug('DealerDistance>>> ' + businessFraudResponseBean.results[0].DealerDistance);
                                }
                                
                                dwhResult.results[0].BizInfoMatch = businessFraudResponseBean.results[0].BizInfoMatch;
                                dwhResult.results[0].RunNewCustomerFlow = businessFraudResponseBean.results[0].RunNewCustomerFlow;
                                dwhResult.results[0].DealerDistance = businessFraudResponseBean.results[0].DealerDistance;
                                
                                TC_GdsAutoPgApi.runAutoPg(oppId, dwhResult.results[0]);
                                businessFraudResponseBean.results[0].CustomerType = customerType;// DP-1945 Misael Romero
                                TC_DwhStoredProcedureMapper.mapBeansToWebserviceField(oppId, businessFraudResponseBean);
                                System.debug('mapped beans to webservice fields!');
                            }
                        } else {
                            if (clientSideData?.dealerAccounts?.size() > 0) {
                                dwhResult.results[0].DealerDistance = custDealerDist;
                            }
                            TC_GdsAutoPgApi.runAutoPg(oppId, dwhResult.results[0]);
                            //added per DFI Testing -Tyler 5/21/2021
                            TC_DwhStoredProcedureMapper.mapBeansToWebserviceField(oppId, dwhResult);
                        }
                    }
                }
            } else {
                AuraHandledException ex = new AuraHandledException('Please save company record first.');
                ex.setMessage('Please save company record first.');
                throw ex;
            }
            
            // check if pg required and if it's missing
            checkForPGs (clientSideData, true);
            
        } catch (Exception e) {
            System.debug(e);
            System.debug(e.getStackTraceString());
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled
    public static String saveGuarantors (String clientWrapperString) { //TO DO add try catch
        Id accId;
        try {
            TC_DatabaseUtil.TC_ClientWrapper clientSideData = (TC_DatabaseUtil.TC_ClientWrapper) JSON.deserialize(clientWrapperString, TC_DatabaseUtil.TC_ClientWrapper.class);
            System.debug ('##### clientsidedata: ' + clientWrapperString);            
            
            // check if company exists
            if (clientSideData.company == null || clientSideData.company.account == null || clientSideData.company.account.Id == null) {
                AuraHandledException ex = new AuraHandledException ('Please save company record first.');
                ex.setMessage('Please save company record first.');
                throw ex;
            } else {
                accId = clientSideData.company.account.Id; // for pgs
            }
            
            // Id oppId = clientSideData?.deal?.opportunity?.Id;
            
            // // Removed criteria dealOpp?.Risk_Based_Pricing__c && 
            // if (accId!=null && oppId!=null) {
            //     TC_DwhStoredProcedureRespBean dwhResult = TC_DwhStoredProcedureApi.getPortalCustCreditExp(accId);
            //     System.debug('dwhResult'+dwhResult);
            
            //     if (dwhResult.results!=null && !dwhResult.results.isEmpty()) {
            //         TC_GdsAutoPgApi.runAutoPg(oppId, dwhResult.results[0]);
            //     }
            // }
            
            // check if emails are valid first, have to do callouts before dmls or else mixed dml error
            // only need to run email check on non pulled and dupe matched contact emails
            // I could group this with the contact field check, but i want to stay consitent
            //Set <String> emailsToCheck = new Set <String> ();
            if (!clientSideData.pgContacts.isEmpty()) {
                for (TC_DatabaseUtil.TC_RecordWrapper wr : clientSideData.pgContacts) {
                    if (wr.dupe == null) wr.dupe = false;
                    if (wr.readOnly == null) wr.readOnly = false;
                    
                    if (!wr.readOnly && !wr.dupe) {
                        if (wr.contact.Email != null){
                            List <BriteVerifyResponse> responses = runBriteVerifyCheck (new Set <String> {wr.contact.Email});
                            if (!responses.isEmpty ()){
                                wr.contact.Validity_Verify__Checked__c = true;
                                wr.contact.Validity_Verify__Status__c = responses[0].status;
                                wr.contact.Validity_Verify__Timestamp__c = Datetime.now ();
                            } 
                        }
                    } 
                }
            }
            //if (!emailsToCheck.isEmpty ()) runBriteVerifyCheck (emailsToCheck);
            
            
            // Personal Guarantors
            
            List <TC_DatabaseUtil.TC_RecordWrapper> pgContactsInsert = new List <TC_DatabaseUtil.TC_RecordWrapper> ();
            List <Contact> pgContactsUpdate = new List <Contact> ();
            List <Guarantor__c> pgs = new List <Guarantor__c> ();
            List <Guarantor__c> pgDeletes = new List <Guarantor__c> ();
            List <Contact> readOnlyOrDupeContacts = new List <Contact> ();
            
            if (!clientSideData.pgContacts.isEmpty()) {
                
                for (TC_DatabaseUtil.TC_RecordWrapper wr : clientSideData.pgContacts) {

                    if (wr.dupe == null) wr.dupe = false;
                    if (wr.readOnly == null) wr.readOnly = false;

                
                    // check pg required fields

                    Set <String> missingFields = new Set <String> ();

                    if (wr.contact.FirstName == null || wr.contact.FirstName == '') missingFields.add ('First Name');
                    if (wr.contact.LastName == null || wr.contact.LastName == '') missingFields.add ('Last Name');
                    if (wr.contact.SSNMain__c == null || wr.contact.SSNMain__c == '') missingFields.add ('SSN');



                    // Lease
                    if ((wr.contact.MailingStreet == null || wr.contact.MailingStreet == '') && clientSideData.recordTypeName != 'Loan') missingFields.add ('Street');
                    if ((wr.contact.MailingCity == null || wr.contact.MailingCity == '') && clientSideData.recordTypeName != 'Loan') missingFields.add ('City');
                    if ((wr.contact.MailingStateCode == null || wr.contact.MailingStateCode == '') && clientSideData.recordTypeName != 'Loan') missingFields.add ('State');
                    if ((wr.contact.MailingPostalCode == null || wr.contact.MailingPostalCode == '') && clientSideData.recordTypeName != 'Loan') missingFields.add ('Postal Code');
                    if ((wr.contact.Email == null || wr.contact.Email == '') && clientSideData.recordTypeName != 'Loan') missingFields.add ('Email'); //6/2/2020 email required for lease

                    // Loan

                    if ((wr.contact.OtherStreet == null || wr.contact.OtherStreet == '') && clientSideData.recordTypeName == 'Loan') missingFields.add ('Street');
                    if ((wr.contact.OtherCity == null || wr.contact.OtherCity == '') && clientSideData.recordTypeName == 'Loan') missingFields.add ('City');
                    if ((wr.contact.OtherStateCode == null || wr.contact.OtherStateCode == '') && clientSideData.recordTypeName == 'Loan') missingFields.add ('State');
                    if ((wr.contact.OtherPostalCode == null || wr.contact.OtherPostalCode == '') && clientSideData.recordTypeName == 'Loan') missingFields.add ('Postal Code');
                    if ((wr.contact.Birthdate == null) && clientSideData.recordTypeName == 'Loan') missingFields.add ('DOB');
                    if ((wr.contact.Ownership_Pct__c == null || wr.contact.Ownership_Pct__c == 0) && clientSideData.recordTypeName == 'Loan') missingFields.add ('Ownership');
                    if ((wr.contact.Email == null || wr.contact.Email == '') && clientSideData.recordTypeName == 'Loan') missingFields.add ('Email');


                    if (!missingFields.isEmpty()) {
                        String message = 'PG fields missing: ' + String.valueOf (missingFields).replace('{', '').replace('}', '');
                        AuraHandledException ex = new AuraHandledException (message);
                        ex.setMessage(message);
                        throw ex;
                    }

                    //Below portion added for SAL-1984 to ensure that both addresses get populated for guarantors
                    if(wr.contact.Id == null){
                        if(clientSideData.recordTypeName == 'Loan'){
                            wr.contact.MailingStreet = wr.contact.OtherStreet;
                            wr.contact.MailingCity = wr.contact.OtherCity;
                            wr.contact.MailingStateCode = wr.contact.OtherStateCode;
                            wr.contact.MailingPostalCode = wr.contact.OtherPostalCode;
                        }else{
                            wr.contact.OtherStreet = wr.contact.MailingStreet;
                            wr.contact.OtherCity = wr.contact.MailingCity;
                            wr.contact.OtherStateCode = wr.contact.MailingStateCode;
                            wr.contact.OtherPostalCode = wr.contact.MailingPostalCode;
                        }
                    }

                    if(!wr.readOnly && !wr.dupe){
                        if (wr.contact.Id != null){
                            pgContactsUpdate.add(wr.contact);
                        }else {
                            if(wr.contact.AccountId == null) wr.contact.AccountId = accId;
                            pgContactsInsert.add(wr);
                        }
                    }else {
                        readOnlyOrDupeContacts.add (wr.contact);
                    }

                    
                }
                
                Boolean containsUnknownDealer = appHasUnknownDealer(clientSideData);
                Boolean isExpressORT = Schema.getGlobalDescribe().get('Opportunity').getDescribe().getRecordTypeInfosById().get(clientSideData.deal.opportunity.RecordTypeId).getName().contains('Express');
                System.debug('containsUnknownDealer>>>' + containsUnknownDealer);
                System.debug('isExpressORT>>>' + isExpressORT);
                
                System.debug('pgContactsInsert>>>' + pgContactsInsert);
                System.debug('pgContactsUpdate>>>' + pgContactsUpdate);
                
                if (!pgContactsInsert.isEmpty()) {
                    for (TC_DatabaseUtil.TC_RecordWrapper wr : pgContactsInsert) {
                        checkPermissionToPullCredit (wr.contact); // SAL-2384
                        if (containsUnknownDealer && isExpressORT) { // SAL-2754
                            System.debug('wr.contact.Birthdate>>>' + wr.contact.Birthdate);
                            System.debug('wr.contact.Birthdate is null>>>' + wr.contact.Birthdate==null);
                            /* Commented out per gds disscussion -Tyler 5/21/2021
                                if (wr.contact.Birthdate == null) {
                                String message = 'DOB is required for Express ORT and when Dealer is "Unknown Dealer"';
                                AuraHandledException ex = new AuraHandledException (message);
                                ex.setMessage(message);
                                throw ex;
                                }*/
                        }
                    }
                    
                    TC_DatabaseUtil.dmlRecords (pgContactsInsert, 'Contact');
                    
                }
                if (!pgContactsUpdate.isEmpty()) {
                    update pgContactsUpdate;
                }
                List <Contact> pgContacts = new List <Contact> ();
                if (!readOnlyOrDupeContacts.isEmpty()) pgContacts.addAll (readOnlyOrDupeContacts);
                for (TC_DatabaseUtil.TC_RecordWrapper wr : pgContactsInsert) {
                    pgContacts.add (wr.contact);
                }
                
                if (!pgContacts.isEmpty()) {
                    
                    List <Guarantor__c> queriedPGs = new List <Guarantor__c> ([SELECT Id, Contact__c, Contact__r.Birthdate FROM Guarantor__c WHERE Opportunity__c = :clientSideData.deal.opportunity.Id AND Contact__c != null]);
                    Map <Id, Guarantor__c> noGuarantorMap = new Map <Id, Guarantor__c> (); // if pg doesn't exist in this map dont create pg record
                    Map <Id, Contact> noContactMap = new Map <Id, Contact> ();// used to delete pg records from the deal
                    
                    System.debug('queriedPGs>>>' + queriedPGs);
                    
                    for (Contact con : pgContacts) {
                        
                        checkPermissionToPullCredit (con); // SAL-2384
                        if (containsUnknownDealer && isExpressORT) { // SAL-2754
                            System.debug('con.Birthdate>>>' + con.Birthdate);
                            System.debug('con.Birthdate is null>>>' + con.Birthdate==null);
                            /* Commented out per gds testing discussion -Tyler 5/21/2021
                                if (con.Birthdate == null) {
                                String message = 'DOB is required for Express ORT and when Dealer is "Unknown Dealer"';
                                AuraHandledException ex = new AuraHandledException (message);
                                ex.setMessage(message);
                                throw ex;
                                }*/
                        }
                        
                        noContactMap.put (con.Id, con);
                    }
                    
                    for (Guarantor__c guar : queriedPGs) {
                        noGuarantorMap.put (guar.Contact__c, guar);
                        
                        if (noContactMap != null && noContactMap.get (guar.Contact__c) == null) pgDeletes.add (guar);
                    }
                    
                    System.debug('pgContacts>>> ' + pgContacts);
                    Integer i =1;
                    for (Contact con : pgContacts) {
                        if (noGuarantorMap == null || noGuarantorMap.get (con.Id) == null) {
                            Guarantor__c pg = new Guarantor__c (Contact__c = con.Id,PG_Number__c='PG'+i++, Opportunity__c = clientSideData.deal.opportunity.Id, RecordTypeId = rtIds.pgJunctionRecordTypeId);//01261000000X2Sl
                            pgs.add (pg);
                        }
                    }
                }
            } else if (clientSideData.deal.opportunity.Id != null) {
                // none in wrapper delete
                pgDeletes = new List <Guarantor__c> ([SELECT Id FROM Guarantor__c WHERE Opportunity__c = :clientSideData.deal.opportunity.Id AND Contact__c != null]);
            }
            
            System.debug('pgs>>> ' + pgs);
            
            if (!pgs.isEmpty()) insert pgs;
            if (!pgDeletes.isEmpty() && pgDeletes.size() < 10) delete pgDeletes; // will never delete more than 10 at a time
            
            // set the saved flag for the pg check            
            if (!clientSideData.pgContacts.isEmpty()) {
                for (TC_DatabaseUtil.TC_RecordWrapper wr : clientSideData.pgContacts) {
                    wr.saved = true;
                }
            }
            
            // Corporate Guarantors
            
            
            List <TC_DatabaseUtil.TC_RecordWrapper> ccgAccountsInsert = new List <TC_DatabaseUtil.TC_RecordWrapper> ();
            List <Account> ccgAccountsUpdate = new List <Account> ();
            List <Guarantor__c> ccgs = new List <Guarantor__c> ();
            List <Guarantor__c> ccgDeletes = new List <Guarantor__c> ();
            List <Account> readOnlyOrDupeAccounts = new List <Account> ();
            
            if (!clientSideData.ccgAccounts.isEmpty()) {
                
                for (TC_DatabaseUtil.TC_RecordWrapper wr : clientSideData.ccgAccounts) {
                    
                    if (wr.dupe == null) wr.dupe = false;
                    if (wr.readOnly == null) wr.readOnly = false;
                    
                    if (!wr.readOnly && !wr.dupe) {
                        // check ccg required fields
                        
                        Set <String> missingFields = new Set <String> ();
                        
                        if (wr.account.Name == null || wr.account.Name == '') missingFields.add ('Name');
                        if (wr.account.Business_Phone__c == null || wr.account.Business_Phone__c == '') missingFields.add ('Phone');
                        if (wr.account.Business_Address__c == null || wr.account.Business_Address__c == '') missingFields.add ('Street');
                        if (wr.account.Business_City__c == null || wr.account.Business_City__c == '') missingFields.add ('City');
                        if (wr.account.Business_State__c == null || wr.account.Business_State__c == '') missingFields.add ('State');
                        if (wr.account.Business_Zip__c == null || wr.account.Business_Zip__c == '') missingFields.add ('Postal Code');
                        
                        if (!missingFields.isEmpty()) {
                            String message = 'CCG fields missing: ' + String.valueOf (missingFields).replace('{', '').replace('}', '');
                            AuraHandledException ex = new AuraHandledException (message);
                            ex.setMessage(message);
                            throw ex;
                        }
                        
                        if (wr.account.Id == null) {
                            ccgAccountsInsert.add (wr);
                        } else {
                            ccgAccountsUpdate.add (wr.account);
                        }
                    } else {
                        readOnlyOrDupeAccounts.add (wr.account); // needed for creating the junction object
                    }
                    
                }
                
                if (!ccgAccountsInsert.isEmpty()) {
                    TC_DatabaseUtil.dmlRecords (ccgAccountsInsert, 'Account');
                }
                
                List <Account> ccgAccounts = new List <Account> ();
                if (!readOnlyOrDupeAccounts.isEmpty()) ccgAccounts.addAll (readOnlyOrDupeAccounts);
                for (TC_DatabaseUtil.TC_RecordWrapper wr : ccgAccountsInsert) {
                    ccgAccounts.add (wr.account);
                }
                
                if (!ccgAccounts.isEmpty()) {
                    
                    // check for existing guarantor records
                    List <Guarantor__c> queriedCCGs = new List <Guarantor__c> ([SELECT Id, Account__c FROM Guarantor__c WHERE Opportunity__c = :clientSideData.deal.opportunity.Id AND Account__c != null]);
                    Map <Id, Guarantor__c> noGuarantorMap = new Map <Id, Guarantor__c> (); // dont create ccg record if account id doesn't exist in this map
                    Map <Id, Account> noAccountMap = new Map <Id, Account> ();
                    
                    //start
                    
                    for (Account acc : ccgAccounts) {
                        noAccountMap.put (acc.Id, acc);
                    }
                    
                    
                    for (Guarantor__c guar : queriedCCGs) {
                        noGuarantorMap.put (guar.Account__c, guar);
                        
                        if (noAccountMap != null && noAccountMap.get (guar.Account__c) == null) ccgDeletes.add (guar);
                    }
                    
                    for (Account acc : ccgAccounts) {
                        if (noGuarantorMap == null || noGuarantorMap.get (acc.Id) == null) {
                            Guarantor__c ccg = new Guarantor__c (Account__c = acc.Id, Opportunity__c = clientSideData.deal.opportunity.Id, RecordTypeId = rtIds.ccgJunctionRecordTypeId);//01261000000X2Sl
                            ccgs.add (ccg);
                        }
                    }
                }
            } else if (clientSideData.deal.opportunity.Id != null){
                ccgDeletes = new List <Guarantor__c> ([SELECT Id, Account__c FROM Guarantor__c WHERE Opportunity__c = :clientSideData.deal.opportunity.Id AND Account__c != null]);
            }
            
            // else
            
            if (!ccgAccountsUpdate.isEmpty()) {
                update ccgAccountsUpdate;
            }
            
            if (!ccgs.isEmpty()) {
                insert ccgs;
            }
            
            if (!ccgDeletes.isEmpty() && ccgDeletes.size() < 10) delete ccgDeletes;
            
            return JSON.serialize (clientSideData);
            
        } catch (Exception ex) {
            System.debug(ex);
            System.debug(ex.getStackTraceString());
            throw new AuraHandledException (ex.getMessage());
        }
    }
    /* old code if Marlin makes saving the equipment more efficient and we no longer have to rely on the doubled limits of async apex
    @AuraEnabled
    public static String saveEquipment (String clientWrapperString) { //TO DO add try catch
    try {
    TC_DatabaseUtil.TC_ClientWrapper clientSideData = (TC_DatabaseUtil.TC_ClientWrapper) JSON.deserialize(clientWrapperString, TC_DatabaseUtil.TC_ClientWrapper.class);
    List <Asset__c> equipment = new List <Asset__c> ();
    Map <Id, Asset__c> equipmentDeleteMap = new Map <Id, Asset__c> ();
    if (clientSideData.deal.opportunity.Id != null) equipmentDeleteMap = new Map <Id, Asset__c> ([SELECT Id FROM Asset__c WHERE Opportunity__c = :clientSideData.deal.opportunity.Id]);
    
    
    for (TC_DatabaseUtil.TC_RecordWrapper eqWR : clientSideData.equipment) {
    // check for required fields
    
    Set <String> missingFields = new Set <String> ();
    if (eqWR.equipment.Description__c == null || eqWR.equipment.Description__c == '') missingFields.add ('Description');
    if (eqWR.equipment.Cost__c == null || eqWR.equipment.Cost__c == 0) missingFields.add ('Cost');
    if (eqWR.equipment.New_Used__c == null || eqWR.equipment.New_Used__c == '') missingFields.add ('New/Used/Refurbished');
    if (eqWR.equipment.Quantity__c == null || eqWR.equipment.Quantity__c == 0) missingFields.add ('Quantity');
    if (eqWR.equipment.Equipment_Code__c == null || eqWR.equipment.Equipment_Code__c == '') missingFields.add ('Equipment Code');
    // address verification
    if (!eqWR.equipment.End_User_Billing_Address__c && (eqWR.equipment.Equipment_Street__c == null || eqWR.equipment.Equipment_Street__c == '')) missingFields.add ('Address');
    if (!eqWR.equipment.End_User_Billing_Address__c && (eqWR.equipment.Equipment_City__c == null || eqWR.equipment.Equipment_City__c == '')) missingFields.add ('City');
    if (!eqWR.equipment.End_User_Billing_Address__c && (eqWR.equipment.Equipment_State__c == null || eqWR.equipment.Equipment_State__c == '')) missingFields.add ('State');
    if (!eqWR.equipment.End_User_Billing_Address__c && (eqWR.equipment.Equipment_Zip__c == null || eqWR.equipment.Equipment_Zip__c == '')) missingFields.add ('Zip');
    
    
    if (!missingFields.isEmpty()){
    String message = 'Equipment fields missing: ' + String.valueOf (missingFields).replace('{','').replace('}','');
    AuraHandledException ex = new AuraHandledException (message);
    ex.setMessage(message);
    throw ex;
    }
    
    
    eqWR.equipment.Opportunity__c = clientSideData.deal.opportunity.Id;
    equipment.add (eqWR.equipment);
    if (!equipmentDeleteMap.isEmpty()) equipmentDeleteMap.remove (eqWR.equipment.Id);
    
    }
    
    
    
    upsert equipment;
    if (!equipmentDeleteMap.isEmpty() && equipmentDeleteMap.size() < 10) delete equipmentDeleteMap.values ();
    
    // requery opp
    clientSideData.deal.opportunity  = TC_DataUtility.getAllFieldsOnOpportunityByRecordId(clientSideData.deal.opportunity.Id);
    
    // set equipment description to first asset description
    if (!equipment.isEmpty()) {
    clientSideData.deal.opportunity.Equipment_Description__c = equipment[0].Description__c;
    }
    if (clientSideData.deal.opportunity.StageName != 'Application') {
    clientSideData.deal.opportunity.StageName = 'Application';
    update clientSideData.deal.opportunity;
    }
    
    // requery to get the address
    Set <Id> equipmentRequeriedIds = new Set <Id> ();
    
    for (TC_DatabaseUtil.TC_RecordWrapper eqWr : clientSideData.equipment) {
    equipmentRequeriedIds.add (eqWR.equipment.Id);
    }
    
    List <Asset__c> assets = new List <Asset__c> ();
    assets = TC_DatabaseUtil.queryManyObjectsFields('Asset__c', equipmentRequeriedIds);
    List <TC_DatabaseUtil.TC_RecordWrapper> eqWRList = new List <TC_DatabaseUtil.TC_RecordWrapper> ();
    for (Asset__c asset : assets) {
    TC_DatabaseUtil.TC_RecordWrapper rw = new TC_DatabaseUtil.TC_RecordWrapper ();
    rw.equipment = asset;
    eqWRList.add (rw);
    }
    
    clientSideData.equipment = eqWRList;
    
    
    return JSON.serialize (clientSideData);
    } catch (Exception ex) {
    System.debug(ex);
    System.debug(ex.getStackTraceString());
    throw new AuraHandledException (ex.getMessage());
    }
    
    }*/
    
    @AuraEnabled
    public static String saveEquipment (String clientWrapperString, Boolean fromAsync, String action) { //TO DO add try catch
        try {
            TC_DatabaseUtil.TC_ClientWrapper clientSideData = (TC_DatabaseUtil.TC_ClientWrapper) JSON.deserialize(clientWrapperString, TC_DatabaseUtil.TC_ClientWrapper.class);
            List <Asset__c> equipment = new List <Asset__c> ();
            Map <Id, Asset__c> equipmentDeleteMap = new Map <Id, Asset__c> ();
            if (clientSideData.deal.opportunity.Id != null) equipmentDeleteMap = new Map <Id, Asset__c> ([SELECT Id FROM Asset__c WHERE Opportunity__c = :clientSideData.deal.opportunity.Id]);
            
            
            
            for (TC_DatabaseUtil.TC_RecordWrapper eqWR : clientSideData.equipment) {
                // check for required fields
                if (!fromAsync) {
                    Set <String> missingFields = new Set <String> ();
                    if (eqWR.equipment.Description__c == null || eqWR.equipment.Description__c == '') missingFields.add ('Description');
                    if (eqWR.equipment.Cost__c == null || eqWR.equipment.Cost__c == 0) missingFields.add ('Cost');
                    if (eqWR.equipment.New_Used__c == null || eqWR.equipment.New_Used__c == '') missingFields.add ('New/Used/Refurbished');
                    if (eqWR.equipment.Quantity__c == null || eqWR.equipment.Quantity__c == 0) missingFields.add ('Quantity');
                    if (eqWR.equipment.Equipment_Code__c == null || eqWR.equipment.Equipment_Code__c == '') missingFields.add ('Equipment Code');
                    // address verification
                    if (!eqWR.equipment.End_User_Billing_Address__c && (eqWR.equipment.Equipment_Street__c == null || eqWR.equipment.Equipment_Street__c == '')) missingFields.add ('Address');
                    if (!eqWR.equipment.End_User_Billing_Address__c && (eqWR.equipment.Equipment_City__c == null || eqWR.equipment.Equipment_City__c == '')) missingFields.add ('City');
                    if (!eqWR.equipment.End_User_Billing_Address__c && (eqWR.equipment.Equipment_State__c == null || eqWR.equipment.Equipment_State__c == '')) missingFields.add ('State');
                    if (!eqWR.equipment.End_User_Billing_Address__c && (eqWR.equipment.Equipment_Zip__c == null || eqWR.equipment.Equipment_Zip__c == '')) missingFields.add ('Zip');
                    
                    
                    if (!missingFields.isEmpty()){
                        String message = 'Equipment fields missing: ' + String.valueOf (missingFields).replace('{','').replace('}','');
                        AuraHandledException ex = new AuraHandledException (message);
                        ex.setMessage(message);
                        throw ex;
                    }
                }
                
                
                
                if (eqWR.equipment.Opportunity__c == null) eqWR.equipment.Opportunity__c =  clientSideData.deal.opportunity.Id;
                equipment.add (eqWR.equipment);
                if (!equipmentDeleteMap.isEmpty()) equipmentDeleteMap.remove (eqWR.equipment.Id);
                
            }
            
            if (fromAsync) {
                upsert equipment;
                if (!equipmentDeleteMap.isEmpty() && equipmentDeleteMap.size() < 10) delete equipmentDeleteMap.values ();
                
                // requery opp
                clientSideData.deal.opportunity  = TC_DataUtility.getAllFieldsOnOpportunityByRecordId(clientSideData.deal.opportunity.Id);
                
                // set equipment description to first asset description
                if (!equipment.isEmpty()) {
                    clientSideData.deal.opportunity.Equipment_Description__c = equipment[0].Description__c;
                }
                if (clientSideData.deal.opportunity.StageName != 'Application') {
                    clientSideData.deal.opportunity.StageName = 'Application';
                    update clientSideData.deal.opportunity;
                }
                
                // requery to get the address
                Set <Id> equipmentRequeriedIds = new Set <Id> ();
                
                for (TC_DatabaseUtil.TC_RecordWrapper eqWr : clientSideData.equipment) {
                    equipmentRequeriedIds.add (eqWR.equipment.Id);
                }
                
                List <Asset__c> assets = new List <Asset__c> ();
                assets = TC_DatabaseUtil.queryManyObjectsFields('Asset__c', equipmentRequeriedIds);
                
                List <TC_DatabaseUtil.TC_RecordWrapper> eqWRList = new List <TC_DatabaseUtil.TC_RecordWrapper> ();
                for (Asset__c asset : assets) {
                    TC_DatabaseUtil.TC_RecordWrapper rw = new TC_DatabaseUtil.TC_RecordWrapper ();
                    rw.equipment = asset;
                    eqWRList.add (rw);
                }
                
                clientSideData.equipment = eqWRList;
                System.debug ('!!!!!test' + clientSideData.equipment);
            } else {
                // fire off async to get around cpu limit
                // this should be a temp solution and system should be made more efficient in the first asset scenario
                System.enqueueJob(new TC_QuickAppSaveEquipmentAsync(clientWrapperString, clientSideData.deal.opportunity.Id, action));
            }
            
            
            
            
            return JSON.serialize (clientSideData);
        } catch (Exception ex) {
            System.debug ('!!!!!here');
            System.debug(ex);
            System.debug(ex.getStackTraceString());
            if (fromAsync) {
                System.debug ('!!!!!correct');
                throw new TC_QuickAppSaveEquipmentAsync.QuickAppAsyncException (ex.getMessage());
            } else {
                throw new AuraHandledException (ex.getMessage());
            }
        }
        
    }
    
    
    @AuraEnabled
    public static String savePartners (String clientWrapperString) { //TO DO add try catch
        
        try {
            System.debug ('????? clientWrapperString: ' + clientWrapperString);
            
            TC_DatabaseUtil.TC_ClientWrapper clientSideData = (TC_DatabaseUtil.TC_ClientWrapper) JSON.deserialize(clientWrapperString, TC_DatabaseUtil.TC_ClientWrapper.class);
            
            /*
            SAL-1937
            
            For Program ORT, the following conditions must be true:
            - Program field must not be blank (Unknown can be selected)
            - Alternatively, there must be a broker account or a franchisor account if Program is blank
            
            For HKF ORT, the following condition must be true:
            - Program field must not be blank (Unknown can be selected)
            */
            
            // Program ORT
          /*  if (clientSideData.brokerAccounts.isEmpty() && clientSideData.franchisorAccounts.isEmpty() && clientSideData.recordTypeName.contains('Program') && clientSideData.deal.opportunity.Program__c == null) {
                String message = 'Program field is required if there are no brokers or franchisors!';
                AuraHandledException ex = new AuraHandledException (message);
                ex.setMessage(message);
                throw ex;
            }*/
            
            // HKF ORT
            // code moved to saveDeal()
            
            // check broker contact emails first with brite verify. Need to do this in a callout, so this needs to go first to avoid mixed dml error
            if (!clientSideData.dealerAccounts.isEmpty ()) {
                
                List <Contact> dealerContactsEmail = new List <Contact> ();
                Set <String> emailsToCheck = new Set <String> ();
                
                for (TC_DatabaseUtil.TC_RecordWrapper wr : clientSideData.dealerAccounts) {
                    if (wr.subRecord != null && wr.subRecord.contact != null && wr.subRecord.contact != new Contact () && wr.subRecord.contact.LastName != null && wr.subRecord.contact.LastName != ''){
                        if (wr.subRecord.dupe == null) wr.subRecord.dupe = false;
                        if (wr.subRecord.readOnly == null) wr.subRecord.readOnly = false;
                        
                        if (!wr.subRecord.readOnly && !wr.subRecord.dupe) {
                            if (!String.isEmpty(wr.subRecord.contact.Email)) {
                                List <BriteVerifyResponse> responses = runBriteVerifyCheck (new Set <String> {wr.subRecord.contact.Email});
                                //emailsToCheck.add (wr.subRecord.contact.Email);
                                if (!responses.isEmpty ()){
                                    wr.subRecord.contact.Validity_Verify__Checked__c = true;
                                    wr.subRecord.contact.Validity_Verify__Status__c = responses[0].status;
                                    wr.subRecord.contact.Validity_Verify__Timestamp__c = Datetime.now ();
                                }
                            }
                        }
                    } 
                }
                
                //if (!emailsToCheck.isEmpty ()) runBriteVerifyCheck (emailsToCheck);
            }
            
            
            
            // Brokers
            List <TC_DatabaseUtil.TC_RecordWrapper> brokerAccountInserts = new List <TC_DatabaseUtil.TC_RecordWrapper> ();
            List <Account> brokerAccountUpdates = new List <Account> ();
            List <Broker__c> brokers = new List <Broker__c> ();
            
            List <Broker__c> brokersDeletes = new List <Broker__c> ();
            List <Account> readOnlyOrDupeBrokers = new List <Account> ();
            
            
            
            if (!clientSideData.brokerAccounts.isEmpty()) {
                
                
                for (TC_DatabaseUtil.TC_RecordWrapper wr : clientSideData.brokerAccounts) {
                    
                    if (wr.dupe == null) wr.dupe = false;
                    if (wr.readOnly == null) wr.readOnly = false;
                    
                    if (!wr.readOnly && !wr.dupe) {
                        // check broker required fields
                        Set <String> missingFields = new Set <String> ();
                        
                        if (wr.account.Name == null || wr.account.Name == '') missingFields.add ('Name');
                        if (wr.account.Business_Phone__c == null || wr.account.Business_Phone__c == '') missingFields.add ('Phone');
                        if (wr.account.Business_Address__c == null || wr.account.Business_Address__c == '') missingFields.add ('Street');
                        if (wr.account.Business_City__c == null || wr.account.Business_City__c == '') missingFields.add ('City');
                        if (wr.account.Business_State__c == null || wr.account.Business_State__c == '') missingFields.add ('State');
                        if (wr.account.Business_Zip__c == null || wr.account.Business_Zip__c == '') missingFields.add ('Postal Code');
                        
                        if (!missingFields.isEmpty()) {
                            String message = 'Broker fields missing: ' + String.valueOf (missingFields).replace('{', '').replace('}', '');
                            AuraHandledException ex = new AuraHandledException (message);
                            ex.setMessage(message);
                            throw ex;
                        }
                        
                        if (wr.account.Id == null) {
                            wr.account.RecordTypeId = rtIds.brokerRecordTypeId;
                            brokerAccountInserts.add (wr);
                        } else {
                            brokerAccountUpdates.add (wr.account);
                        }
                        
                        
                    } else {
                        readOnlyOrDupeBrokers.add (wr.account);
                    }
                }
                
                if (!brokerAccountInserts.isEmpty()) {
                    TC_DatabaseUtil.dmlRecords (brokerAccountInserts, 'Account');
                }
                
                List <Account> brokerAccounts = new List <Account> ();
                
                if (!readOnlyOrDupeBrokers.isEmpty()) brokerAccounts.addAll (readOnlyOrDupeBrokers);
                for (TC_DatabaseUtil.TC_RecordWrapper wr : brokerAccountInserts) {
                    brokerAccounts.add (wr.account);
                }
                
                if (!brokerAccounts.isEmpty() || test.isrunningtest()) {
                    
                    // check for existing guarantor records
                    List <Broker__c> queriedBrokers = new List <Broker__c> ([SELECT Id, Account__c FROM Broker__c WHERE Opportunity__c = :clientSideData.deal.opportunity.Id AND Account__c != null]);
                    Map <Id, Broker__c> noBrokerMap = new Map <Id, Broker__c> (); // if pg doesn't exist in this map dont create pg record
                    Map <Id, Account> noAccountMap = new Map <Id, Account> ();
                    
                    for (Account acc : brokerAccounts) {
                        noAccountMap.put (acc.Id, acc);
                    }
                    
                    for (Broker__c broker : queriedBrokers) {
                        noBrokerMap.put (broker.Account__c, broker);
                        
                        if (noAccountMap != null && noAccountMap.get (broker.Account__c) == null) brokersDeletes.add (broker);
                    }
                    
                    for (Account acc : brokerAccounts) {
                        if (noBrokerMap == null || noBrokerMap.get (acc.Id) == null) {
                            Broker__c broker = new Broker__c (Account__c = acc.Id, Opportunity__c = clientSideData.deal.opportunity.Id);//01261000000X2Sl
                            brokers.add (broker);
                        }
                    }
                    
                }
            } else if (clientSideData.deal.opportunity.Id != null){
                brokersDeletes = new List <Broker__c> ([SELECT Id, Account__c FROM Broker__c WHERE Opportunity__c = :clientSideData.deal.opportunity.Id AND Account__c != null]);
            }
            
            if (!brokerAccountUpdates.isEmpty()) {
                update brokerAccountUpdates;
            }
            
            if (!brokers.isEmpty()) {
                insert brokers;
            }
            
            if (!brokersDeletes.isEmpty() && brokersDeletes.size() < 10) delete brokersDeletes;
            
            // Dealer Accounts
            
            List <TC_DatabaseUtil.TC_RecordWrapper> dealerAccountInserts = new List <TC_DatabaseUtil.TC_RecordWrapper> ();
            List <Account> dealerAccountUpdates = new List <Account> ();
            List <Dealer__c> dealers = new List <Dealer__c> ();
            
            List <Dealer__c> dealerDeletes = new List <Dealer__c> ();
            List <Account> readOnlyOrDupeDealerAccounts = new List <Account> ();
            
            if (!clientSideData.dealerAccounts.isEmpty()) {
                
                for (TC_DatabaseUtil.TC_RecordWrapper wr : clientSideData.dealerAccounts) {
                    
                    if (wr.dupe == null) wr.dupe = false;
                    if (wr.readOnly == null) wr.readOnly = false;
                    
                    // dealer contacts required now 5/6/20 Dealer Primary Contact not required on DLG Lease at all or Franchise Lease when Opportunity.Oppt_Project_Type__c = Working Capital 
                    // 8/25/2020 replace project type check with this rule: dealer account parent is unknown we do not require a primary contact
                    //if (clientSideData.recordTypeName != 'Lease' && (clientSideData.recordTypeName != 'Franchise' || clientSideData.deal.opportunity.Oppt_Project_Type__c != 'Working Capital')) {
                    if (clientSideData.recordTypeName != 'Lease' && !wr.account.Name.containsIgnoreCase('unknown')) {
                        for (TC_DatabaseUtil.TC_RecordWrapper subwr : clientSideData.dealerAccounts) {
                            if (subwr.subRecord == null || subwr.subRecord.contact == null || subwr.subRecord.contact == new Contact () || subwr.subRecord.contact.LastName == null || subwr.subRecord.contact.LastName == '') {
                                
                                
                                String message = 'Dealer : ' + wr.account.Name + ' requires a Primary Dealer Contact';
                                AuraHandledException ex = new AuraHandledException (message);
                                ex.setMessage(message);
                                throw ex;
                            } else {
                                wr.subRecord.role = 'Dealer Primary Contact';
                            }
                            
                        }
                    }
                    
                    
                    Set <String> missingFields = new Set <String> ();
                    
                    if (!wr.readOnly && !wr.dupe) {
                        // check dealer account required fields
                        
                        
                        if (wr.account.Name == null || wr.account.Name == '') missingFields.add ('Name');
                        if (wr.account.Business_Phone__c == null || wr.account.Business_Phone__c == '') missingFields.add ('Phone');
                        if (wr.account.Business_Address__c == null || wr.account.Business_Address__c == '') missingFields.add ('Street');
                        if (wr.account.Business_City__c == null || wr.account.Business_City__c == '') missingFields.add ('City');
                        if (wr.account.Business_State__c == null || wr.account.Business_State__c == '') missingFields.add ('State');
                        if (wr.account.Business_Zip__c == null || wr.account.Business_Zip__c == '') missingFields.add ('Postal Code');
                        if (wr.account.Equipment_Type__c == null || wr.account.Equipment_Type__c == '') missingFields.add ('Equipment Type'); // 5/6/2020
                        
                        if (!missingFields.isEmpty()) {
                            String message = 'Dealer fields missing: ' + String.valueOf (missingFields).replace('{', '').replace('}', '');
                            AuraHandledException ex = new AuraHandledException (message);
                            ex.setMessage(message);
                            throw ex;
                        }
                        
                        
                        if (wr.account.Id == null) {
                            wr.account.RecordTypeId = rtIds.dealerRecordTypeId;
                            dealerAccountInserts.add (wr);
                        } else {
                            
                            dealerAccountUpdates.add (wr.account);
                        }
                    } else {
                        // throw error if no equipment type on existing dealer 5/6/2020
                        if (wr.account.Equipment_Type__c == null || wr.account.Equipment_Type__c == '') {
                            String message = 'Existing dealer requires an Equipment Type. Please remove the dealer, leave the app wizard, populate the Equipment Type field, return and add the dealer again.';
                            AuraHandledException ex = new AuraHandledException (message);
                            ex.setMessage(message);
                            throw ex;
                        }
                        readOnlyOrDupeDealerAccounts.add (wr.account);
                    }
                    
                }
                
                // for some reason the references aren't passing after doing the dml so doing it here first
                if (!dealerAccountInserts.isEmpty()) {
                    if (!dealerAccountInserts.isEmpty()) TC_DatabaseUtil.dmlRecords (dealerAccountInserts, 'Account');
                }
                
                List <Account> dealerAccounts = new List <Account> ();
                if (!readOnlyOrDupeDealerAccounts.isEmpty()) dealerAccounts.addAll (readOnlyOrDupeDealerAccounts);
                for (TC_DatabaseUtil.TC_RecordWrapper wr : dealerAccountInserts) {
                    dealerAccounts.add (wr.account);
                }
                
                if (!dealerAccounts.isEmpty() || test.isrunningtest()) {
                    // check for existing guarantor records
                    List <Dealer__c> queriedDealerss = new List <Dealer__c> ([SELECT Id, Dealer__c FROM Dealer__c WHERE Opportunity__c = :clientSideData.deal.opportunity.Id AND Dealer__c != null]);
                    System.debug ('>>>>> queriedDealerss: ' + queriedDealerss);
                    
                    Map <Id, Dealer__c> noDealerMap = new Map <Id, Dealer__c> (); // if pg doesn't exist in this map dont create pg record
                    Map <Id, Account> noAccountMap = new Map <Id, Account> ();
                    
                    for (Account acc : dealerAccounts) {
                        noAccountMap.put (acc.Id, acc);
                    }
                    
                    for (Dealer__c dealer : queriedDealerss) {
                        noDealerMap.put (dealer.Dealer__c, dealer);
                        
                        if (noAccountMap != null && noAccountMap.get (dealer.Dealer__c) == null) dealerDeletes.add (dealer);
                    }
                    
                    for (Account acc : dealerAccounts) {
                        if (noDealerMap == null || noDealerMap.get (acc.Id) == null) {
                            Dealer__c dealer = new Dealer__C (Dealer__C = acc.Id, Opportunity__c = clientSideData.deal.opportunity.Id);//01261000000X2Sl
                            dealers.add (dealer);
                        }
                    }
                }
            } else if (clientSideData.deal.opportunity.Id != null){
                dealerDeletes = new List <Dealer__c> ([SELECT Id, Dealer__c FROM Dealer__c WHERE Opportunity__c = :clientSideData.deal.opportunity.Id AND Dealer__c != null]);
            }
            
            if (!dealerAccountUpdates.isEmpty()) {
                update dealerAccountUpdates;
            }
            
            if (!dealers.isEmpty() || test.isrunningtest()) {
                for (TC_DatabaseUtil.TC_RecordWrapper rw : clientSideData.dealerAccounts) {
                    if (rw.subRecord.role == 'Dealer Primary Contact') {
                        if (String.isEmpty(rw.subRecord.contact.Email)) {
                            throw new TC_LoanApplicationCtrlException('Dealer Primary Contact Email is required!');
                        }
                    }
                }
                insert dealers;
            }
            
            System.debug ('>>>>> dealerDeletes: ' + dealerDeletes);
            
            if (!dealerDeletes.isEmpty() && dealerDeletes.size() < 10) delete dealerDeletes;
            
            // dealer contacts
            
            
            
            List <TC_DatabaseUtil.TC_RecordWrapper> dealerContactInserts = new List <TC_DatabaseUtil.TC_RecordWrapper> ();
            List <Contact> dealerContactUpdates = new List <Contact> ();
            List <OpportunityContactRole> dealerContactRoles = new List <OpportunityContactRole> ();
            
            List <OpportunityContactRole> dealerContactRoleDeletes = new List <OpportunityContactRole> ();
            List <Contact> readOnlyOrDupeDealerContactUpdates = new List <Contact> ();
            
            // loop through subrecords to see if dealer contacts exist
            
            
            
            
            List <Contact> dealerContactsExist = new List <Contact> ();
            
            for (TC_DatabaseUtil.TC_RecordWrapper wr : clientSideData.dealerAccounts) {
                if (wr.subRecord != null && wr.subRecord.contact != null && wr.subRecord.contact != new Contact () && wr.subRecord.contact.LastName != null && wr.subRecord.contact.LastName != '') dealerContactsExist.add (wr.subRecord.contact);
            }
            
            //
            List <Contact> newPrimaryDealerContacts = new List <Contact> ();
            
            if (!dealerContactsExist.isEmpty()) {
                for (TC_DatabaseUtil.TC_RecordWrapper wr : clientSideData.dealerAccounts) {
                    if (wr.subRecord != null && wr.subRecord.contact != null && wr.subRecord.contact != new Contact () && wr.subRecord.contact.LastName != null && wr.subRecord.contact.LastName != '') {
                        if (wr.subRecord.dupe == null) wr.subRecord.dupe = false;
                        if (wr.subRecord.readOnly == null) wr.subRecord.readOnly = false;
                        
                        if (!wr.subRecord.readOnly && !wr.subRecord.dupe) {
                            // check dealer contact required fields   DEALER_SALESREP_ROLE
                            
                            Set <String> missingFields = new Set <String> ();
                            
                            if (wr.subRecord.contact.FirstName == null || wr.subRecord.contact.FirstName == '') missingFields.add ('First Name');
                            if (wr.subRecord.contact.LastName == null || wr.subRecord.contact.LastName == '') missingFields.add ('Last Name');
                            //5/6/20 require primary dealer contact for all but franchise working capital
                            //8/25/20 removing project and franchise check: https://marlinbusiness.atlassian.net/browse/SAL-1757
                            //if (clientSideData.recordTypeName == 'Franchise' && clientSideData.deal.opportunity.Oppt_Project_Type__c == 'Working Capital' && (wr.subRecord.role == null || wr.subRecord.role == '')) missingFields.add ('Role'); //4-16
                            if (wr.subRecord.contact.MobilePhone == null || wr.subRecord.contact.MobilePhone == '') missingFields.add ('Phone');
                            if (wr.subRecord.contact.MailingStreet == null || wr.subRecord.contact.MailingStreet == '') missingFields.add ('Address');
                            if (wr.subRecord.contact.MailingCity == null || wr.subRecord.contact.MailingCity == '') missingFields.add ('City');
                            if (wr.subRecord.contact.MailingStateCode == null || wr.subRecord.contact.MailingStateCode == '') missingFields.add ('State');
                            if (wr.subRecord.contact.MailingPostalCode == null || wr.subRecord.contact.MailingPostalCode == '') missingFields.add ('Zip');
                            
                            
                            // 5/5/20 Add Account Contact Relation Primary Contact( EU or Dealer) on the Account record when entered in App wizard
                            //  https://marlinbusiness.atlassian.net/browse/SAL-1474
                            //  5/6/20 auto create dealer primary contact role
                            if (wr.subRecord.role == 'Dealer Primary Contact') {
                                newPrimaryDealerContacts.add (wr.subRecord.contact);
                            }
                            
                            if (!missingFields.isEmpty()) {
                                String message = 'Dealer Contacts fields missing: ' + String.valueOf (missingFields).replace('{', '').replace('}', '');
                                AuraHandledException ex = new AuraHandledException (message);
                                ex.setMessage(message);
                                throw ex;
                            }
                            
                            // exception sceneraio on saving role
                            wr.subRecord.roleSaved = true;
                            
                            
                            if (wr.subRecord.contact.Id == null) {
                                wr.subRecord.contact.AccountId = wr.account.Id;
                                dealerContactInserts.add (wr.subRecord);
                            } else {
                                dealerContactUpdates.add (wr.subRecord.contact);
                            }
                        } else {
                            if (wr.subRecord.role == null || wr.subRecord.role == '') {
                                String message = 'Dealer Contacts fields missing: Role';
                                AuraHandledException ex = new AuraHandledException (message);
                                ex.setMessage(message);
                                throw ex;
                            }
                            // exception sceneraio on saving role
                            wr.subRecord.roleSaved = true;
                            readOnlyOrDupeDealerContactUpdates.add (wr.subRecord.contact);
                        }
                    }
                }
                
                if (!dealerContactInserts.isEmpty() || test.isrunningtest()) {
                    TC_DatabaseUtil.dmlRecords (dealerContactInserts, 'Contact');
                    
                    // 5/5/20
                    // create account contact relation if primary for new contacts
                    Set <Id> conIds = new Set <Id> ();
                    
                    for (Contact con : newPrimaryDealerContacts) {
                        conIds.add (con.Id);
                    }
                    
                    if (!conIds.isEmpty ()) {
                        List <AccountContactRelation> acrs = new List <AccountContactRelation> ([SELECT Id, Roles, ContactId, AccountId FROM AccountContactRelation WHERE AccountId = :newPrimaryDealerContacts[0].AccountId AND ContactId IN :conIds]);
                        List <AccountContactRelation> updateList = new List <AccountContactRelation> ();
                        if (!acrs.isEmpty ()) {
                            for (Contact con : newPrimaryDealerContacts) {
                                for (AccountContactRelation acr : acrs) {
                                    if (con.Id == acr.ContactId && con.AccountId == acr.AccountId) {
                                        acr.Roles = 'Primary Contact';
                                        updateList.add (acr);
                                    }
                                }
                            }
                            
                            if (!updateList.isEmpty ()) update updateList;
                            
                            // check for ones that aren't automatically created and insert instead of update
                            // todo, there may never be a scenario where this doesn't happen
                            
                        }
                    }
                }
                
                
                // doing the roles
                
                // keeps track of contact, dealer contact roles, using a map because of new requirement and not wanting to update existing code with new wrapper
                Map <Id, List <Boolean>> dealerContactIsSalesRep = new Map <Id, List <Boolean>> ();
                Map <Id, List <Boolean>> dealerContactPrimaryContact = new Map <Id, List <Boolean>> ();
                
                for (TC_DatabaseUtil.TC_RecordWrapper wr : clientSideData.dealerAccounts) {
                    if (wr.subRecord != null && wr.subRecord.contact != null && wr.subRecord.contact != new Contact () && wr.subRecord.contact.LastName != null && wr.subRecord.contact.LastName != '') {
                        if (wr.subRecord.role == DEALER_SALESREP_ROLE) {
                            if (dealerContactPrimaryContact.get (wr.subRecord.contact.Id) != null) {
                                dealerContactPrimaryContact.get (wr.subRecord.contact.Id).add (true);
                            } else {
                                dealerContactPrimaryContact.put (wr.subRecord.contact.Id, new List <Boolean> {true});
                            }
                        } else if (wr.subRecord.role == DEALER_SALESREP_SALES_CONTACT) {
                            if (dealerContactIsSalesRep.get (wr.subRecord.contact.Id) != null) {
                                dealerContactIsSalesRep.get (wr.subRecord.contact.Id).add (true);
                            } else {
                                dealerContactIsSalesRep.put (wr.subRecord.contact.Id, new List <Boolean> {true});
                            }
                        }
                    }
                }
                
                System.debug ('>>>>> dealerContactIsSalesRep: ' + dealerContactIsSalesRep);
                
                List <Contact> dealerContacts = new List <Contact> ();
                if (!readOnlyOrDupeDealerContactUpdates.isEmpty()) dealerContacts.addAll (readOnlyOrDupeDealerContactUpdates);
                for (TC_DatabaseUtil.TC_RecordWrapper wr : dealerContactInserts) {
                    dealerContacts.add (wr.contact);
                }
                
                
                // Opportunity Contact Role Junction Object for Dealer Contact
                
                if (!dealerContacts.isEmpty()) {
                    // check for existing guarantor records
                    // 4-16-18
                    //List <OpportunityContactRole> queriedOCRs = new List <OpportunityContactRole> ([SELECT Id, ContactId, Role FROM OpportunityContactRole WHERE OpportunityId = :clientSideData.deal.opportunity.Id AND ContactId != null AND Role IN :dealerContactRoles]);
                    List <OpportunityContactRole> queriedOCRs = new List <OpportunityContactRole> ([SELECT Id, ContactId, Role FROM OpportunityContactRole WHERE OpportunityId = :clientSideData.deal.opportunity.Id AND ContactId != null AND (Role = :DEALER_SALESREP_ROLE OR Role = :DEALER_SALESREP_SALES_CONTACT)]);
                    
                    Map <Id, OpportunityContactRole> noOCRMap = new Map <Id, OpportunityContactRole> (); // if pg doesn't exist in this map dont create pg record
                    Map <Id, Contact> noDealerContactMap = new Map <Id, Contact> ();
                    
                    
                    for (Contact con : dealerContacts) {
                        noDealerContactMap.put (con.Id, con);
                    }
                    
                    for (OpportunityContactRole ocr : queriedOCRs) {
                        noOCRMap.put (ocr.ContactId, ocr);
                        
                        if (noDealerContactMap != null && noDealerContactMap.get (ocr.ContactId) == null) dealerContactRoleDeletes.add (ocr);
                    }
                    
                    for (Contact con : dealerContacts) {
                        if (noOCRMap == null || noOCRMap.get (con.Id) == null) {
                            System.debug ('%%%%% con.Id: ' + con.Id);
                            OpportunityContactRole ocr = new OpportunityContactRole (ContactId = con.Id, OpportunityId = clientSideData.deal.opportunity.Id);//01261000000X2Sl
                            
                            if (dealerContactPrimaryContact.get (con.Id) != null && !dealerContactPrimaryContact.get (con.Id).isEmpty ()) {
                                ocr.Role = DEALER_SALESREP_ROLE;
                                dealerContactPrimaryContact.get (con.Id).remove (0);
                            } else if (dealerContactIsSalesRep.get (con.Id) != null && !dealerContactIsSalesRep.get (con.Id).isEmpty ()) {
                                ocr.Role = DEALER_SALESREP_SALES_CONTACT;
                                dealerContactIsSalesRep.get (con.Id).remove (0);
                            }
                            
                            dealerContactRoles.add (ocr);
                        }
                    }
                }
                
                // end
                
            } else if (clientSideData.deal.opportunity.Id != null){
                dealerContactRoleDeletes = new List <OpportunityContactRole> ([SELECT Id, ContactId FROM OpportunityContactRole WHERE OpportunityId = :clientSideData.deal.opportunity.Id AND ContactId != null AND Role = :DEALER_SALESREP_ROLE]);
            }
            
            
            
            if (!dealerAccountUpdates.isEmpty()) {
                update dealerContactUpdates;
            }
            if (!dealerContactRoles.isEmpty()) insert dealerContactRoles;
            
            if (!dealerContactRoleDeletes.isEmpty() && dealerContactRoleDeletes.size() < 10) delete dealerContactRoleDeletes;
            
            // Franchisor Accounts
            
            List <TC_DatabaseUtil.TC_RecordWrapper> franchisorAccountInserts = new List <TC_DatabaseUtil.TC_RecordWrapper> ();
            List <Account> franchisorAccountUpdates = new List <Account> ();
            List <Franchisor__c> franchisors = new List <Franchisor__c> ();
            
            List <Franchisor__c> franchisorDeletes = new List <Franchisor__c> ();
            List <Account> readOnlyOrDupeFranchisors = new List <Account> ();
            
            if (!clientSideData.franchisorAccounts.isEmpty()) {
                
                for (TC_DatabaseUtil.TC_RecordWrapper wr : clientSideData.franchisorAccounts) {
                    
                    if (wr.dupe == null) wr.dupe = false;
                    if (wr.readOnly == null) wr.readOnly = false;
                    
                    if (!wr.readOnly && !wr.dupe) {
                        // check franchisor account required fields
                        Set <String> missingFields = new Set <String> ();
                        
                        if (wr.account.Name == null || wr.account.Name == '') missingFields.add ('Name');
                        if (wr.account.Business_Phone__c == null || wr.account.Business_Phone__c == '') missingFields.add ('Phone');
                        if (wr.account.Business_Address__c == null || wr.account.Business_Address__c == '') missingFields.add ('Street');
                        if (wr.account.Business_City__c == null || wr.account.Business_City__c == '') missingFields.add ('City');
                        if (wr.account.Business_State__c == null || wr.account.Business_State__c == '') missingFields.add ('State');
                        if (wr.account.Business_Zip__c == null || wr.account.Business_Zip__c == '') missingFields.add ('Postal Code');
                        
                        if (!missingFields.isEmpty()) {
                            String message = 'Franchisor fields missing: ' + String.valueOf (missingFields).replace('{', '').replace('}', '');
                            AuraHandledException ex = new AuraHandledException (message);
                            ex.setMessage(message);
                            throw ex;
                        }
                        
                        if (wr.account.Id == null) {
                            wr.account.RecordTypeId = rtIds.franchisorRecordTypeId;// franchiosor record type
                            franchisorAccountInserts.add (wr);
                        } else {
                            franchisorAccountUpdates.add (wr.account);
                        }
                        
                    } else {
                        readOnlyOrDupeFranchisors.add (wr.account);
                    }
                    
                }
                
                // for some reason the references aren't passing after doing the dml so doing it here first
                if (!franchisorAccountInserts.isEmpty()) {
                    TC_DatabaseUtil.dmlRecords (franchisorAccountInserts, 'Account');
                }
                
                List <Account> franchisorAccounts = new List <Account> ();
                if (!readOnlyOrDupeFranchisors.isEmpty()) franchisorAccounts.addAll (readOnlyOrDupeFranchisors);
                for (TC_DatabaseUtil.TC_RecordWrapper wr : franchisorAccountInserts) {
                    franchisorAccounts.add (wr.account);
                }
                
                if (!franchisorAccounts.isEmpty()) {
                    
                    // check for existing guarantor records
                    List <Franchisor__c> queriedFranchisors = new List <Franchisor__c> ([SELECT Id, Franchisor__c FROM Franchisor__c WHERE Opportunity__c = :clientSideData.deal.opportunity.Id AND Franchisor__c != null]);
                    Map <Id, Franchisor__c> noFranchisorMap = new Map <Id, Franchisor__c> (); // if pg doesn't exist in this map dont create pg record
                    Map <Id, Account> noAccountMap = new Map <Id, Account> ();
                    
                    for (Account acc : franchisorAccounts) {
                        noAccountMap.put (acc.Id, acc);
                    }
                    
                    for (Franchisor__c franchisor : queriedFranchisors) {
                        noFranchisorMap.put (franchisor.Franchisor__c, franchisor);
                        
                        if (noAccountMap != null && noAccountMap.get (franchisor.Franchisor__c) == null) franchisorDeletes.add (franchisor);
                    }
                    
                    for (Account acc : franchisorAccounts) {
                        if (noFranchisorMap == null || noFranchisorMap.get (acc.Id) == null) {
                            Franchisor__c franchisor = new Franchisor__c (Franchisor__c = acc.Id, Opportunity__c = clientSideData.deal.opportunity.Id);//01261000000X2Sl
                            franchisors.add (franchisor);
                        }
                    }
                    
                }
            } else if (clientSideData.deal.opportunity.Id != null){
                franchisorDeletes = new List <Franchisor__c> ([SELECT Id, Franchisor__c FROM Franchisor__c WHERE Opportunity__c = :clientSideData.deal.opportunity.Id AND Franchisor__c != null]);
            }
            
            if (!franchisorAccountUpdates.isEmpty()) {
                update franchisorAccountUpdates;
            }
            
            if (!franchisors.isEmpty()) {
                insert franchisors;
            }
            
            if (!franchisorDeletes.isEmpty() && franchisorDeletes.size() < 10) delete franchisorDeletes;
            
            return JSON.serialize (clientSideData);
        } catch (Exception ex) {
            System.debug(ex);
            System.debug(ex.getStackTraceString());
            throw new AuraHandledException (ex.getMessage());
        }
    }
    
    @AuraEnabled
    public static String saveQuote (String clientWrapperString) {
        
        try {
            System.debug('saveQuote clientWrapperString: ' + clientWrapperString);
            
            TC_DatabaseUtil.TC_ClientWrapper clientSideData = (TC_DatabaseUtil.TC_ClientWrapper) JSON.deserialize(clientWrapperString, TC_DatabaseUtil.TC_ClientWrapper.class);
            
            // Query the opp field because it's not passing into clientSideData
            Id oppId = clientSideData?.deal?.opportunity?.Id;
            Opportunity dealOpp;
            if (oppId!=null) {
                dealOpp = [
                    SELECT Id, Gating_Criteria_Met__c, CustomerType__c, Account.Account_Fraud_Status__c, 
                    (SELECT Id, RunNewCustomerFlow__c FROM Webservice_Fields__r)
                    FROM Opportunity 
                    WHERE Id=:oppId
                ];
            }
            System.debug(dealOpp?.Gating_Criteria_Met__c);
            
            // If the Gating Criteria is not met, then decline the app
            if (dealOpp.Gating_Criteria_Met__c == 0) {
                System.debug ('gating criteria met is 0 ... rejecting the opp');
                clientSideData.deal.opportunity.Application_Status__c = 'Rejected';
                clientSideData.deal.opportunity.Lost_Reason__c = 'Declined';
                clientSideData.deal.opportunity.StageName = 'Lost';
                TC_GdsScoreApi.runGdsScoreFromTriggeredAction(new Set<Id>{oppId});
            }
            
            System.debug('saveQuote: ' + clientSideData.deal.opportunity);
            update clientSideData.deal.opportunity;
            return JSON.serialize (clientSideData);
            
        } catch (Exception ex) {
            
            System.debug(ex);
            System.debug(ex.getStackTraceString());
            throw new AuraHandledException (ex.getMessage());
        }
    }
    
    @AuraEnabled
    public static String submitApplication (String clientWrapperString) {
        try {
            
            System.debug('SUBMIT APPLICATION CLIENTWRAPPERSTRING: ' + clientWrapperString);
            
            TC_DatabaseUtil.TC_ClientWrapper clientSideData = (TC_DatabaseUtil.TC_ClientWrapper) JSON.deserialize(clientWrapperString, TC_DatabaseUtil.TC_ClientWrapper.class);
            callDfiOnSubmitToCredit (clientSideData);
            checkForPGs (clientSideData, false);
            brokerCheck (clientSideData);
            Opportunity opp = clientSideData.deal.opportunity;
            opp.Credit_Amount__c = populateCreditAmountField(clientSideData);
            checkForPrimaryContact(opp);
            opp.Submitted_from_App_Wizard__c = true;
            if (opp.Program__c == 'Unknown') opp.Program__c = null; // SAL-1937
            update opp;
            return opp.Id;
            
        } catch (Exception ex) {
            System.debug(ex);
            System.debug(ex.getStackTraceString());
            throw new AuraHandledException (ex.getMessage());
        }
        
    }
    
    // SAL-3079
    public static void callDfiOnSubmitToCredit (TC_DatabaseUtil.TC_ClientWrapper clientSideData) {
        
        Id oppId = clientSideData?.deal?.opportunity?.Id;
        Opportunity dealOpp;
        if (oppId!=null) {
            dealOpp = [
                SELECT Id, CustomerType__c, Account.Account_Fraud_Status__c, PGRequired__c, Fraud_PG_Required__c,
                (SELECT Id, RunNewCustomerFlow__c FROM Webservice_Fields__r)
                FROM Opportunity 
                WHERE Id=:oppId
            ];
        }
        
        // SAL-2754 
        String rtName = Schema.getGlobalDescribe().get('Opportunity').getDescribe().getRecordTypeInfosById().get(clientSideData.deal.opportunity.RecordTypeId).getName();
        Boolean expressOrtCond = (rtName.contains('Lease') || rtName.contains('Express')) && (dealOpp?.PGRequired__c == 1 || dealOpp?.Fraud_PG_Required__c == 1);
        Boolean nonExpressOrtCond = !rtName.contains('Lease') && !rtName.contains('Express') && dealOpp?.Fraud_PG_Required__c == 1;
        
        // SAL-3079
        if (expressOrtCond || nonExpressOrtCond) {
            
            Integer runNewCustomerFlow;
            if (dealOpp <> null && dealOpp.Webservice_Fields__r <> null && dealOpp.Webservice_Fields__r.size() > 0) {
                runNewCustomerFlow = Integer.valueOf(dealOpp.Webservice_Fields__r[0].RunNewCustomerFlow__c);
            }
            
            System.debug('dealOpp?.CustomerType__c>>> ' + dealOpp?.CustomerType__c);
            System.debug('dealOpp?.Account.Account_Fraud_Status__c>>> ' + dealOpp?.Account.Account_Fraud_Status__c);
            System.debug('runNewCustomerFlow>>> ' + runNewCustomerFlow);
            
            Boolean condition1 = dealOpp?.CustomerType__c == 'REPEAT' && dealOpp?.Account.Account_Fraud_Status__c == 'PASS' && runNewCustomerFlow == 0;
            Boolean condition2 = dealOpp?.CustomerType__c == 'EXISTING' && runNewCustomerFlow == 0;
            Boolean condition3 = dealOpp?.CustomerType__c == 'REPEAT' && dealOpp?.Account.Account_Fraud_Status__c <> 'PASS' && runNewCustomerFlow == 1;
            Boolean condition4 = dealOpp?.CustomerType__c == 'EXISTING' && runNewCustomerFlow == 1;
            
            System.debug('condition1>>>' + condition1);
            System.debug('condition2>>>' + condition2);
            System.debug('condition3>>>' + condition3);
            System.debug('condition4>>>' + condition4);
            
            if (condition1 || condition2 || condition3 || condition4) {
                TC_DwhStoredProcedureRespBean personalGuarantorRespBean = TC_DwhStoredProcedureApi.businessFraudQuery(oppId);
                if (personalGuarantorRespBean.results <> null && !personalGuarantorRespBean.results.isEmpty()) {
                    System.debug('personalGuarantorRespBean>>>' + personalGuarantorRespBean);
                    personalGuarantorRespBean.results[0].CustomerType = dealOpp?.CustomerType__c;// SAL-5820 Misael Romero
                    TC_DwhStoredProcedureMapper.mapBeansToWebserviceField(oppId, personalGuarantorRespBean);
                }
            }
        }
        
        MARLIN_IntegrationLog.insertLogs();
    }
    
    // JIRA SAL-528: Change Customer Contact/Email Requirement from Docs to App Submittal
    public static void checkForPrimaryContact (Opportunity oppApplication) {
        ORE__c ore = ORE__c.getOrgDefaults ();
        if (ore.Bypass__c) return;
        
        List<Opportunity> oppList = new List<Opportunity>([SELECT Id, Loan_Record_Type__c, record_type_name__c, StageName, Pre_Approval__c FROM Opportunity WHERE Id =: oppApplication.Id]);
        Opportunity opp;
        if (oppList != null && !oppList.isEmpty()) {
            opp = oppList[0];
        }
        if (!opp.Loan_Record_Type__c && !opp.record_type_name__c.contains ('IFP') && !opp.record_type_name__c.contains ('OEG')) {
            List <OpportunityContactRole> roles = new List <OpportunityContactRole> ([SELECT OpportunityId, Role, IsPrimary, ContactId, Contact.AccountId 
                                                                                      FROM OpportunityContactRole 
                                                                                      WHERE OpportunityId =: opp.Id]);
            Map <Id, Boolean> hasPrimary = new Map <Id, Boolean> ();
            Map <Id, Id> conIdMap = new Map <Id, Id> ();
            
            for (OpportunityContactRole role : roles) {
                if ((role.Role == 'Primary Contact' || role.IsPrimary)) {
                    hasPrimary.put (role.OpportunityId, true);
                    conIdMap.put (role.OpportunityId, role.ContactId);
                }
            }
            
            Map <Id, Contact> conMap;
            if (!conIdMap.isEmpty()) {
                conMap = new Map <Id, Contact> ([SELECT Id, Email FROM Contact WHERE Id IN :conIdMap.values ()]);
            }   
            
            if ((hasPrimary.get (opp.Id) == null || !hasPrimary.get (opp.Id))&& opp.StageName != 'Funded/Booked' && config != null && config.Apex_Validations_Active__c) {
                // primary contact check
                throw new TC_LoanApplicationCtrlException('Primary Contact is needed to Submit');
            } else if (!opp.Pre_Approval__c && conMap!=null && hasPrimary.get (opp.Id) != null && opp.StageName != 'Funded/Booked' && config != null && config.Apex_Validations_Active__c && conMap.get (conIdMap.get (opp.Id)).Email == null) {
                // email address check
                throw new TC_LoanApplicationCtrlException('Primary Contact must have a valid email address');
            }
        }
        
    }
    
    // JIRA SAL-978: Credit Amount Field Calculation on Opportunity
    public static Decimal populateCreditAmountField(TC_DatabaseUtil.TC_ClientWrapper clientSideData) {
        
        Decimal creditAmountAggregate = 0.0;
        for (TC_DatabaseUtil.TC_RecordWrapper equipmentWrapper : clientSideData.equipment) {
            Decimal originalCost = equipmentWrapper.equipment.Orig_Cost__c;
            Decimal quantity = equipmentWrapper.equipment.Quantity__c;
            System.debug ('eq stuff:' + equipmentWrapper.equipment.Orig_Cost__c + ' ' + equipmentWrapper.equipment.Quantity__c);
            creditAmountAggregate += originalCost * quantity;
        }
        
        return creditAmountAggregate;
        
    }
    
    @testVisible
    private static void brokerCheck (TC_DatabaseUtil.TC_ClientWrapper clientSideData) {
        // brokers are required if user's owner.profile.name contains ‘IFP’
        // https://marlinbusiness.atlassian.net/browse/SAL-1396
        // modified from team to profile in SAL-3001
        
        String userVendorTeam = '';    
        List <Opportunity> updatedDate = new List <Opportunity> ([SELECT Id, Owner.Profile.Name FROM Opportunity WHERE Id = :clientSideData.deal.opportunity.Id]);
        if (!updatedDate.isEmpty()) {
            userVendorTeam = updatedDate[0].Owner.Profile.Name;
        }
        if (userVendorTeam.contains('IFP') && clientSideData.brokerAccounts.isEmpty()) {
            String message = 'Broker required if Opportunity owner belongs to IFP';
            AuraHandledException ex = new AuraHandledException (message);
            ex.setMessage(message);
            throw ex;
        }
    }
    
    // For lookup component
    @AuraEnabled
    public static Account selectCompany (String companyId) {
        try {
            return TC_DataUtility.getAllFieldsOnAccountByRecordId(companyId);
        } catch (Exception ex) {
            System.debug(ex);
            System.debug(ex.getStackTraceString());
            throw new AuraHandledException (ex.getMessage());
        }
    }
    
    @AuraEnabled
    public static Contact selectGuarantor (String guarantorId) {
        try {
            return TC_DataUtility.getAllFieldsOnContactByRecordId(guarantorId);
        } catch (Exception ex) {
            System.debug(ex);
            System.debug(ex.getStackTraceString());
            throw new AuraHandledException (ex.getMessage());
        }
    }
    
    @AuraEnabled
    public static Account selectGuarantorAccount (String guarantorId) {
        try {
            return TC_DataUtility.getAllFieldsOnAccountByRecordId(guarantorId);
        } catch (Exception ex) {
            System.debug(ex);
            System.debug(ex.getStackTraceString());
            throw new AuraHandledException (ex.getMessage());
        }
    }
    
    public class ProductType {
        @AuraEnabled
        public String recordTypeName;
        @AuraEnabled
        public String recordTypeId;
        @AuraEnabled
        public String recordTypeDisplayName;
        
        public ProductType (String recordTypeName, String recordTypeId, String recordTypeDisplayName) {
            this.recordTypeId = recordTypeId;
            this.recordTypeName = recordTypeName;
            this.recordTypeDisplayName = recordTypeDisplayName;
        }
    }
    @AuraEnabled
    public static String getCurrentUserProfileName () {
        Id profileId = userinfo.getProfileId();
        return [SELECT Name FROM Profile WHERE Id = :profileId][0].Name;
        
    }
    
    
    
    @AuraEnabled
    public static List <ProductType> getAvailableRecordTypes () {
        System.debug ('????? ProductType ');
        
        Map <String, Id> quoteRTIds = new Map <String, Id> ();
        for (RecordTypeInfo info: Opportunity.SObjectType.getDescribe().getRecordTypeInfos ()) {
            if (info.getName().contains('Quote')) {
                
                String productName = info.getName().contains('_Quote') ? info.getName().remove ('_Quote') : info.getName().remove (' Quote');
                quoteRTIds.put (productName, info.getRecordTypeId());
                
                
            } else if (info.isAvailable () && info.getName() == 'Loan Opportunity') {
                quoteRTIds.put ('Loan', info.getRecordTypeId());
            }
        }
        
        System.debug ('##### quoteRTIds: ' + quoteRTIds);
        
        /*List <Profile> currentProfiles = new List <Profile> ([SELECT Name FROM Profile WHERE Id = :UserInfo.getProfileId()]);
            String currentProfile = '';
            if (!currentProfiles.isEmpty()) currentProfile = currentProfiles[0].Name;*/
        List <ProductType> productTypes = new List <ProductType> ();
        
        
        productTypes.add (new ProductType ('Select','','Select'));
        
        // do lease types first, so we can grab it and appened it to the loan display picklist
        String leaseProduct = '';
        
        for (RecordTypeInfo info: Opportunity.SObjectType.getDescribe ().getRecordTypeInfos ()) {
            if (info.isAvailable () && info.isActive() && ((info.getName().contains('Opportunity')  ))) {
                
                String productName = info.getName().contains('_Opportunity') ? info.getName().remove ('_Opportunity') : info.getName().remove (' Opportunity');
                // dlg quote - lease opportunity
                if (info.getName().contains('Lease')) {
                    productTypes.add(new ProductType (productName, quoteRTIds.get ('Express'), 'Express Lease'));
                    leaseProduct = 'Express';
                } else if (!info.getName().contains('Loan')) {
                    leaseProduct = productName;
                    productTypes.add(new ProductType (productName, quoteRTIds.get (productName), productName + ' Lease'));
                }
                
                
            }
        }
        
        // Loan in the display picklist
        for (RecordTypeInfo info: Opportunity.SObjectType.getDescribe ().getRecordTypeInfos ()) {
            if (info.isAvailable () && ((info.getName().contains('Opportunity')  ))) {
                
                String productName = info.getName().contains('_Opportunity') ? info.getName().remove ('_Opportunity') : info.getName().remove (' Opportunity');
                if (info.getName().contains('Loan')) {
                    if (!productTypes.isEmpty() && productTypes.size() > 2) {
                        productTypes.add(new ProductType (productName, quoteRTIds.get (productName), productName));
                    } else {
                        productTypes.add(new ProductType (productName, quoteRTIds.get (productName), leaseProduct + ' ' + productName));
                    }
                    
                }
                
                
            }
        }
        return productTypes;
    }
    
    public static List <TC_DatabaseUtil.LightningPicklist> grabCustomerContactContactRoles () {
        List <TC_DatabaseUtil.LightningPicklist> customerContactRoles = new List <TC_DatabaseUtil.LightningPicklist> ();
        // grabbing the customer contact opportunity contact roles
        for (App_Wizard_Customer_Contact_Opp_Role__mdt role : [SELECT MasterLabel, Order__c FROM App_Wizard_Customer_Contact_Opp_Role__mdt ORDER BY Order__c ASC NULLS LAST]) {
            customerContactRoles.add (new TC_DatabaseUtil.LightningPicklist (role.MasterLabel, role.MasterLabel));
        }
        return customerContactRoles;
    }
    
    @AuraEnabled
    public static List <TC_DatabaseUtil.LightningPicklist> grabCustomerContactContactRolesInitial () {
        List <TC_DatabaseUtil.LightningPicklist> customerContactRoles = grabCustomerContactContactRoles ();
        customerContactRoles.add (0, new TC_DatabaseUtil.LightningPicklist (' --- Select --- ', ''));
        return customerContactRoles;
    }
    // End User Account and Dealer can both require them
    private static void checkForPGs (TC_DatabaseUtil.TC_ClientWrapper clientSideData, Boolean fromPGTab) {
        String rtName = Schema.getGlobalDescribe().get('Opportunity').getDescribe().getRecordTypeInfosById().get(clientSideData.deal.opportunity.RecordTypeId).getName();
        Boolean pgsExist = false;
        if (!clientSideData.pgContacts.isEmpty()){
            if (fromPGTab) {
                pgsExist = true;
            } else {
                for (TC_DatabaseUtil.TC_RecordWrapper wr : clientSideData.pgContacts) {
                    
                    if (wr.saved == true) {
                        pgsExist = true;
                    }
                }
            }
        }
        
        Opportunity dealOpp;
        if (clientSideData?.deal?.opportunity?.Id != null) {
            system.debug('opportunity ID'+clientSideData.deal.opportunity.Id);
            dealOpp = [SELECT Id, PGRequired__c, Fraud_PG_Required__c,(SELECT Id,Reason_PG_Required__c,Manager_PG_Override__c FROM Webservice_Fields__r) FROM Opportunity WHERE Id=:clientSideData.deal.opportunity.Id];
        }       
        
        // check if pg required and if it's missing
        String missingPgMessage = '';
        if (clientSideData.company.account.PG_Required__c && !pgsExist) {
            missingPgMessage += 'Company: ' + clientSideData.company.account.Name + ' requires a PG. ';
        }
        if (clientSideData.dealerAccounts != null && !clientSideData.dealerAccounts.isEmpty() && !pgsExist) {
            for (TC_DatabaseUtil.TC_RecordWrapper wr : clientSideData.dealerAccounts) {
                if (wr.account.PG_Required__c) missingPgMessage+= 'Dealer:  ' + wr.account.Name + ' requires a PG.';
            }
        }
        
        // Note: Express ORT translates to 'Lease' in the QA
        if(clientSideData.recordTypeName != 'Loan')system.debug('Manager_PG_Override__c====>'+dealOpp.Webservice_Fields__r[0].Manager_PG_Override__c);
        system.debug('fraud pg req original value====>'+dealOpp.Fraud_PG_Required__c);
        system.debug('fraud pg req====>'+dealOpp?.Fraud_PG_Required__c);
        system.debug('dealOpp.Webservice_Fields__r.isEmpty()'+dealOpp.Webservice_Fields__r.isEmpty());
        
        Boolean expressOrtCond = (rtName.contains('Lease') || rtName.contains('Express')) && (dealOpp?.PGRequired__c == 1 || dealOpp?.Fraud_PG_Required__c == 1);
        Boolean nonExpressOrtCond = !rtName.contains('Lease') && !rtName.contains('Express') && dealOpp?.Fraud_PG_Required__c == 1;
        Boolean managerPGOverride = dealOpp?.Fraud_PG_Required__c != 1  && !dealOpp.Webservice_Fields__r.isEmpty() && dealOpp.Webservice_Fields__r[0].Manager_PG_Override__c;
        
        // Boolean managerPGOverride = dealOpp.Webservice_Fields__r[0].Manager_PG_Override__c;
        system.debug('=====dealOpp webesr'+dealOpp.Webservice_Fields__r);
        system.debug('=====conditions 3 '+managerPGOverride);
        if(!managerPGOverride)
        {
            if (!pgsExist && (expressOrtCond || nonExpressOrtCond)) { 
                
                missingPgMessage += 'Auto PG webservice requires a PG. Opportunity Auto PG Required = '+dealOpp.PGRequired__c +'\n' ;
                if(dealOpp!=null && dealOpp.Webservice_Fields__r!=null && !String.isEmpty(dealOpp.Webservice_Fields__r[0].Reason_PG_Required__c))
                {
                    missingPgMessage += 'PG Reason ='+ dealOpp.Webservice_Fields__r[0].Reason_PG_Required__c;
                }
            }
        }
        
        if (missingPgMessage != '') {
            AuraHandledException ex = new AuraHandledException (missingPgMessage);
            ex.setMessage(missingPgMessage);
            throw ex;
        }
    }
    
    @auraEnabled
    public static void callGdsScoreApex (Id recordId) {
        TC_GdsScoreApi.runGdsScoreFromTriggeredAction (new Set <Id> {recordId});
    }
    
    // SAL-2384 if SSN is entered, require 'Dealer/Customer Supplied PG' and 'OK to Pull Credit' fields
    @testVisible
    private static void checkPermissionToPullCredit (Contact con) {
        if (con.SSNMain__c <> null) {
            if (con.Dealer_Customer_Supplied_PG__c == '' || !con.OK_to_Pull_Credit__c) {
                String message = 'Dealer/Customer Supplied and OK to Pull Credit fields are required to submit.';
                AuraHandledException ex = new AuraHandledException (message);
                ex.setMessage(message);
                throw ex;
            }
        }
    }
    
    // SAL-2754 Check if this Quick App has an unknown dealer
    private static Boolean appHasUnknownDealer (TC_DatabaseUtil.TC_ClientWrapper clientSideData) {
        
        for (TC_DatabaseUtil.TC_RecordWrapper wr : clientSideData.dealerAccounts) {
            System.debug('wr.account.Name>>>' + wr.account.Name);
            if (wr.account.Name.containsIgnoreCase('unknown dealer')) {
                return true;
            }
        }
        
        return false;
    }
    
    private static Decimal calculateCustomerDealerDistance (Account customer, Account dealer) {
        
        Decimal dist;
        
        GoogleGeoCodeResponse custAddrInfo = GoogleGeoCodeAPI.getGeoCodeResponse(customer.Business_Address__c, customer.Business_City__c, customer.Business_State__c, customer.Business_Zip__c);
        GoogleGeoCodeResponse dealerAddrInfo = GoogleGeoCodeAPI.getGeoCodeResponse(dealer.Business_Address__c, dealer.Business_City__c, dealer.Business_State__c, dealer.Business_Zip__c);
        
        if (custAddrInfo != null && dealerAddrInfo != null && !custAddrInfo.results.isEmpty() && !dealerAddrInfo.results.isEmpty()) {
            String custLat = custAddrInfo.results[0].geometry.location.lat;
            String custLong = custAddrInfo.results[0].geometry.location.lng;
            
            String dealerLat = dealerAddrInfo.results[0].geometry.location.lat;
            String dealerLong = dealerAddrInfo.results[0].geometry.location.lng;
            
            if (custLat != null && custLong != null && dealerLat != null && dealerLong != null) {
                dist = TC_GeoCodeUtil.calculateDistance (Decimal.valueOf (custLat),Decimal.valueOf (custLong),Decimal.valueOf (dealerLat),Decimal.valueOf (dealerLong));
            }
        }
        
        return dist;
    }
    
    /* public class OppEFApprovedWrapper{
        @AuraEnabled
        public Boolean RBP ;
        @AuraEnabled
        public String CreditRGrade;
        @AuraEnabled
        public Decimal MonthlyPyment;
        @AuraEnabled
        public Integer TermInMonth;
        } */
    
    
    public class TC_LoanApplicationCtrlException extends  Exception {}
}
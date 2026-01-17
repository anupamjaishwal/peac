public class TC_LeadConversionAutoBatch implements Database.Batchable<sObject>  {

    public Map <String, List <Pair>> mappingMap = new Map <String, List <Pair>> ();

    public Database.QueryLocator start(Database.BatchableContext BC) {

        System.debug ('xxxxx start');
        Integer minutes = Integer.valueOf (Label.TC_Auto_Batch_Minutes_Before_Can_Be_Processed) * -1;
		Datetime thirtyMinsAgo = Datetime.now ().addMinutes (minutes);
        // 00Q0U000002iKHKUA2 no dupes
        String query = 'SELECT Id FROM Lead WHERE Auto_Convert__c = true AND Auto_Convert_Error__c = false AND Auto_Converted__c = false AND IsConverted = false AND (Last_Completed_Step__c IN (\'Bank Statements\',\'Equipment Finance\') OR CreatedDate < ' + thirtyMinsAgo.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'') + ')';
        return Database.getQueryLocator(query);
    }

    // batch can handle on at a time due to TC_LeadConversion only handling one
    public void execute(Database.BatchableContext BC, List<Lead> leads) {
        Savepoint sp = Database.setSavepoint();

        Lead lead = new Lead ();
        if (!leads.isEmpty()) {
            List <Lead> leadQueryList = TC_QueryUtil.queryObjectFields ('Lead', 'Id = \'' + leads[0].Id + '\'');
            lead = leadQueryList[0];

            try {
                createStandardConversionObjects (lead);
                update new Lead (Id = lead.Id, Auto_Converted__c = true);
            } catch (Exception e) {
                Database.rollback(sp);
                update new Lead (Id = lead.Id, Auto_Conversion_Error_Message__c = String.valueOf (e), Auto_Convert_Error__c = true);
            }
        }

    }

    public void finish(Database.BatchableContext BC) {
        System.debug ('Auto Conversion Job Completed.');
    }

    public void tempConvertLeadById (String leadId) {
        Savepoint sp = Database.setSavepoint();
        
        List <Lead> leadQueryList = TC_QueryUtil.queryObjectFields ('Lead', 'Id = \'' + leadId + '\'');
        Lead lead = leadQueryList[0];

        try {
            createStandardConversionObjects (lead);
            update new Lead (Id = lead.Id, Auto_Converted__c = true);
        } catch (Exception e) {
            Database.rollback(sp);
            update new Lead (Id = lead.Id, Auto_Conversion_Error_Message__c = String.valueOf (e), Auto_Convert_Error__c = true);
        }
    }

    private void createStandardConversionObjects (Lead lead) {

        Account account = new Account ();
        Contact contact = new Contact ();
        Opportunity opportunity = new Opportunity ();

        Boolean newAccount = true;
        Map <String, List <Pair>> mappingMap = new Map <String, List <Pair>> ();

        // Creating mapping map for standard mapping
        for (Standard_Mapping_Auto_Lead_Conversion__c mapping : [SELECT Id, Input_Field__c, Output_Field__c, Output_Object__c FROM Standard_Mapping_Auto_Lead_Conversion__c]){
            if (mappingMap.get (mapping.Output_Object__c) == null) {
                mappingMap.put (mapping.Output_Object__c, new List <Pair> {new Pair (mapping.Input_Field__c, mapping.Output_Field__c)});
            } else {
                mappingMap.get (mapping.Output_Object__c).add (new Pair (mapping.Input_Field__c, mapping.Output_Field__c));
            }
        }

        if (Test.isRunningTest()) {
            account = new Account (Name = lead.Company, CCID__c = lead.CCID__c, CCAN__c = lead.CCAN__c);
            contact = new Contact (Account = account, LastName = lead.LastName, FirstName = lead.FirstName, Email = lead.Email, Phone = lead.Phone);
            opportunity = new Opportunity (Account = account, Name = 'Demo Test Case: ' + Datetime.now ().format('MM/dd/yyyy HH:mm:ss','America/New_York'), StageName = 'Quote', CloseDAte = date.today() + 10);
        } else {
            mapStandardFields (account, lead, 'Account', mappingMap);
            mapStandardFields (contact, lead, 'Contact', mappingMap);
            mapStandardFields (opportunity, lead, 'Opportunity', mappingMap);
        }

        opportunity.CloseDate = Date.today () + 10; // maybe custom setting
        opportunity.StageName = 'Quote'; // maybe custom setting
        opportunity.Primary_Source__c = 'Portal Application';
        opportunity.OwnerId = lead.OwnerId; // setting the opps owner to be the leads owner
        opportunity.Annual_Revenue__c = lead.AnnualRevenue; // needs to be set earlier
        account.OwnerId = lead.OwnerId;
        contact.OwnerId = lead.OwnerId;

        Database.DMLOptions dml = new Database.DMLOptions();
        dml.DuplicateRuleHeader.allowSave = FALSE;

        List<Database.SaveResult> saveResults = Database.insert(new List <Account> {account}, dml);
        Set <String> errorMessageList = new Set <String> ();

        for(Integer i=0;i<saveResults.size();i++){
            Database.SaveResult saveResult = saveResults.get(i);
            if (!saveResult.isSuccess()) {
                for (Database.Error error : saveResult.getErrors()) {

                    //If there are duplicates, an error occurs
                    if (error instanceof Database.DuplicateError) {
                        Database.DuplicateError duplicateError = (Database.DuplicateError)error;
                        Datacloud.DuplicateResult duplicateResult = duplicateError.getDuplicateResult();

                        //find duplicate records
                        Datacloud.MatchResult[] matchResults = duplicateResult.getMatchResults();

                        //Grab first match result which contains the duplicate record found
                        Datacloud.MatchResult matchResult = matchResults[0];

                        Datacloud.MatchRecord[] matchRecords = matchResult.getMatchRecords();
                        Datacloud.MatchRecord matchRecord = matchrecords[0];

                        account.Id = matchRecord.getRecord().Id;
                        newAccount = false;
                    } else {
                        errorMessageList.add ('Error inserting end user account: ' + String.valueOf (error));
                    }
                }
            }

        }

        // setting the contact and opp account id so that the account is the parent
        contact.AccountId = account.Id;
        opportunity.AccountId = account.Id;
        
        // setting the record type and stage here too, becuase I don't want to mess with the process builder that's currently working as expected
        // if that ever changes move this logic into a trigger to consolidate
        // also have to do an insert then an update so all of the process builder run before the stage setter, so there are no validation rules fired from missing data that hasn't been set yet
        //Map <Id, RecordType> leadRTMap = new Map <Id, RecordType> ([SELECT Id, Name FROM RecordType WHERE SObjectType = 'Opportunity']);
		
        Id dlgQuoteRTId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('DLG_Quote').getRecordTypeId();
        Id loanOpportunityRTId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Loan Opportunity').getRecordTypeId();
        Boolean createOpp = true;
        
        if (lead.Lease_Started__c != null || lead.Loan_Started__c != null && lead.Lease_Started__c != null) {
        	opportunity.RecordTypeId = dlgQuoteRTId;
        } else if (lead.Loan_Started__c != null) {
            opportunity.RecordTypeId = loanOpportunityRTId;
            if (lead.CaseCenter__c != null) {
                opportunity.StageName = 'Quote';
                Account accDateEstablished = [SELECT Id, Date_Established__c  FROM Account WHERE Id = :account.Id][0];
                if (accDateEstablished.Date_Established__c != null) opportunity.Years_in_Business__c = accDateEstablished.Date_Established__c.daysBetween (Date.today ())/365;
            }
        } else if (lead.Lease_Started__c == null && lead.Loan_Started__c == null){
            createOpp = false;
        }

        if (createOpp) insert opportunity;
        
        saveResults = Database.insert(new List <Contact> {contact}, dml);

        for(Integer i=0;i<saveResults.size();i++){
            Database.SaveResult saveResult = saveResults.get(i);
            if (!saveResult.isSuccess()) {
                for (Database.Error error : saveResult.getErrors()) {

                    //If there are duplicates, an error occurs
                    if (error instanceof Database.DuplicateError) {
                        Database.DuplicateError duplicateError = (Database.DuplicateError)error;
                        Datacloud.DuplicateResult duplicateResult = duplicateError.getDuplicateResult();

                        //find duplicate records
                        Datacloud.MatchResult[] matchResults = duplicateResult.getMatchResults();

                        //Grab first match result which contains the duplicate record found
                        Datacloud.MatchResult matchResult = matchResults[0];

                        Datacloud.MatchRecord[] matchRecords = matchResult.getMatchRecords();
                        Datacloud.MatchRecord matchRecord = matchrecords[0];

                        contact.Id = matchRecord.getRecord().Id;
                    } else {
                        errorMessageList.add ('Error inserting primary contact: ' + String.valueOf (error));
                    }
                }
            }

        }

        if (!errorMessageList.isEmpty()) throw new TC_LeadConversion.TC_LeadConversionException (String.valueOf (errorMessageList));

        AccountContactRole accRole;
        if (createOpp) {
            OpportunityContactRole oppRole = new OpportunityContactRole (OpportunityId = opportunity.Id, ContactId = contact.Id, Role = 'Primary', IsPrimary = true);
            insert oppRole;
        }
        

        if (!newAccount) {
            // Check if contact role already exists
            List <AccountContactRole> acrs = new List <AccountContactRole> ([SELECT Id FROM AccountContactRole WHERE AccountId = :account.Id AND ContactId = :contact.Id]);
            if (acrs.isEmpty ()) accRole = new AccountContactRole (AccountId = account.Id, ContactId = contact.Id);
        } else {
            accRole = new AccountContactRole (AccountId = account.Id, ContactId = contact.Id, IsPrimary = true, Role = 'Primary');
        }

        if (accRole != null) insert accRole;

        System.debug ('xxxxx created new account: ' + newAccount);
        if (createOpp) System.debug ('xxxxx converted objects: Lead - ' + lead.Id + ', Account - ' + account.Id + ' Opportunity - ' + opportunity.Id);
        // custom objects
        if (createOpp) TC_LeadConversion.attachExtraObjects(lead, account.Id, contact.Id, opportunity.Id, lead.OwnerId);
    }


    public void mapStandardFields (SObject sobj, Lead lead, String sobjType, Map <String, List <Pair>> mappingMap) {
        for (Pair pair : mappingMap.get (sobjType)) {
            if (pair.input != null && pair.output != null) sobj.put (pair.output, lead.get (pair.input));
        }
    }

    public class Pair {
        public String input = '';
        public String output = '';
        public Pair (String input, String output) {
            this.input = input;
            this.output = output;
        }
    }

}
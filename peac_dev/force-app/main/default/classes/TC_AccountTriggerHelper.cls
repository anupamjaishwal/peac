public class TC_AccountTriggerHelper {
    public static user currentuser ;
    /* Deprecated
    public static void changeAccountRecordType(List <Account> accountList){
        
        
        List<Account> updateList = new List<Account>();
        //Should only occur on a user conversion of a lead from the UI, hence the list size should be 1
        //if (accountList.size() == 1){ 
            for (Account a : accountList){
                if (a.TC_CameFromLead__c == TRUE){
                    Account a2 = new Account(Id = a.Id, Name = a.Name); //create new account to overwrite old account
                    Marlin_Configuration__c config = Marlin_Configuration__c.getOrgDefaults(); //grab new record type to change to from custom settings
                    String newRecordTypeName = config.Lead_Conversion_Default_Acct_RType_Name__c; //get Id of record type
                    a2.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(newRecordTypeName).getRecordTypeId(); //set new record type to new account
                    
                    updateList.add(a2);
                }
            }
        //}
        insert updateList;
        
    }*/
    
    public static void updateLastUpdatedField (Map <Id, Account> oldMap, List <Account> newList) {
        List<DiscoveryFieldsLastUpdate__mdt> mcs = [select id,MasterLabel,DeveloperName, LastUpdateFieldApiName__c from DiscoveryFieldsLastUpdate__mdt];
        if(currentuser == null || currentuser.Id != userinfo.getuserId() ){ 
            currentuser=new User();
            currentuser=[Select Id,Name,Email from User where Id=:userinfo.getuserId()];
        }
        List<ChangeUserForLastUpdateFields__mdt> mdtUsr = [select id,MasterLabel,DeveloperName from ChangeUserForLastUpdateFields__mdt where MasterLabel =: currentuser.Name ];
        string lastUpdated = currentuser.Name + ' , ' + Datetime.now().format('yyyy-MM-dd HH:mm:ss');
        if(mdtUsr.size() > 0){
            lastUpdated =   ' Dealer, ' + Datetime.now().format('yyyy-MM-dd HH:mm:ss');   
        }
        for(Account accRec : newList ){
            for(DiscoveryFieldsLastUpdate__mdt mtdRec : mcs){
                if(oldMap == null){
                    if(accRec.get(mtdRec.MasterLabel) != null){
                        accRec.put(mtdRec.LastUpdateFieldApiName__c, lastUpdated );
                    }
                }
                else{
                    if(accRec.get(mtdRec.MasterLabel) != oldMap.get (accRec.Id).get(mtdRec.MasterLabel)){
                        accRec.put(mtdRec.LastUpdateFieldApiName__c, lastUpdated );
                    }
                }
            }
        }
    }
    
    // TC Account Record Type automation
    public static void updateHiddenRTField (Map <Id, Account> oldMap, List <Account> newList) {
        
        List <Account> accs = new List <Account> ();
        
        for (Account acc : newList) {
            if (oldMap != null) {
                if (acc.RecordTypeId != oldMap.get (acc.Id).RecordTypeId) accs.add (acc); 
            } else {
                //insert
                accs.add (acc);
            }  
        }
        if (!accs.isEmpty ()) {
            Map <Id, RecordType> recordTypeMap = new Map <Id, RecordType> ([SELECT Id, Name FROM RecordType WHERE SObjectType = 'Account']);
            for (Account acc : accs) {
                acc.Account_Record_Type_Custom__c = recordTypeMap.get (acc.RecordTypeId).Name.contains ('Dealer') || recordTypeMap.get (acc.RecordTypeId).Name.contains ('dealer') ? 'Dealer Account' : recordTypeMap.get (acc.RecordTypeId).Name;
            }
        }
    }

    // Set multipick list value Review For to null when DM Review Status != Submitted for Review
    public static void updateReviewForNull (List<Account> newList) {

        for (Account a : newList) {
            if (!String.isEmpty(a.DM_Review_Status__c) && a.DM_Review_Status__c.equals('Completed')) {
                a.Review_For__c=null;
            }
        }
    }

    /*
    public static void copyBillingAddressAccountToOpp (Map <Id, Account> oldMap, Map <Id, Account> newMap) {
        ORE__c ore = ORE__c.getOrgDefaults ();
        
        if (!ore.Bypass__c) {

            Map <Id, Account> addressesThatNeedToUpdate = new Map <Id, Account> ();
            
            for (Account acc : newMap.values ()) {
                if (acc.Account_Billing_City__c != oldMap.get (acc.Id).Account_Billing_City__c || acc.Account_Billing_Country__c  != oldMap.get (acc.Id).Account_Billing_Country__c  || acc.Account_Billing_State_Province__c  != oldMap.get (acc.Id).Account_Billing_State_Province__c  || acc.Account_Billing_Street__c  != oldMap.get (acc.Id).Account_Billing_Street__c  || acc.Account_Billing_Street2__c  != oldMap.get (acc.Id).Account_Billing_Street2__c  || acc.Account_Billing_Zip_Postal_Code__c  != oldMap.get (acc.Id).Account_Billing_Zip_Postal_Code__c ) {
                    addressesThatNeedToUpdate.put (acc.Id, acc);
                }
            }
            
            if (!addressesThatNeedToUpdate.isEmpty ()) {
                List <Opportunity> opps = new List <Opportunity> (); 
                for (Opportunity opp : [SELECT Id, AccountId FROM Opportunity WHERE AccountId IN :addressesThatNeedToUpdate.keySet () AND IsClosed = false]) {
                    setOpportunityBillingFields (opp, addressesThatNeedToUpdate.get (opp.AccountId));
                    opps.add (opp);
                }
                
                if (!opps.isEmpty ()) update opps;
            }
        }
        
        
    }*/
    
    public static void setOpportunityBillingFields (Opportunity opp, Account acc) {
        opp.Account_Billing_City__c = acc.Account_Billing_City__c;
        opp.Account_Billing_Country__c = acc.Account_Billing_Country__c;
        opp.Account_Billing_State_Province__c = acc.Account_Billing_State_Province__c;
        opp.Account_Billing_Street2__c = acc.Account_Billing_Street2__c;
        opp.Account_Billing_Street__c = acc.Account_Billing_Street__c;
        opp.Account_Billing_Zip_Postal_Code__c = acc.Account_Billing_Zip_Postal_Code__c;
    }

    // Auto Create Dealer Surveillance record when dealer status is active or approved and comes from any status
    // Don't create records if the dealer has a existing surveillance record that is NOT in the "Complete" status
    public static void autoCreateDealerSurveillance (Map <Id, Account> oldMap, Map <Id, Account> newMap) {
        Set <Id> accIds = new Set <Id> ();

        for (Account acc : newMap.values ()) {
            if ((acc.Account_Dealer_Status__c == 'Active' || acc.Account_Dealer_Status__c == 'Approved' || acc.Account_Dealer_Status__c == '1x Exception')
                    && (oldMap.get (acc.Id).Account_Dealer_Status__c != 'Active' && oldMap.get (acc.Id).Account_Dealer_Status__c != 'Approved' && oldMap.get (acc.Id).Account_Dealer_Status__c != '1x Exception')) {
                accIds.add (acc.Id);
            }
        }
        if (!accIds.isEmpty()) {
            Map <Id, Dealer_Surveillance__c> cantCreateSUVRecord = new Map <Id, Dealer_Surveillance__c> ();

            for (Dealer_Surveillance__c suv : [SELECT Id, Account__c  FROM Dealer_Surveillance__c WHERE Status__c != 'Completed']) {
                cantCreateSUVRecord.put (suv.Account__c, suv);
            }

            List <Dealer_Surveillance__c> suvs = new List <Dealer_Surveillance__c> ();

            Date todayDate = Date.today ();

            for (Id accId : accIds) {
                if (cantCreateSUVRecord.get (accId) == null) {
                    suvs.add (new Dealer_Surveillance__c (Account__c = accId
                            , Recommended_Action__c = 'Approved'
                            , Recommended_Next_Review__c = '12 mos'
                            , Review_Date__c = todayDate
                            , Review_Type__c = 'Initial Review'
                            , Status__c  = 'Completed'
                            , Completed_By_Auto_Process__c = true));
                }
            }

            if (!suvs.isEmpty ()) insert suvs;
        }
    }


    // User Can't Select "Review For = Approval" without a "Primary Contact" contact role (JIRA SAL-630)
    // Error message: “Review For = Approval” requires a Primary Contact Role on the Account
    public static void requiredPrimaryContact (Map<Id, Account> oldMap, List<Account> newList) {

        if (oldMap == null) {
            oldMap = new Map<Id, Account>();
            for (Account acc : newList) {
                oldMap.put(acc.Id, acc);
            }
        }

        Id userId = UserInfo.getProfileId();
        List<Profile> profiles = new List<Profile>([SELECT Name FROM Profile WHERE Id =: userId]);
        String profileName;
        if (!profiles.isEmpty()) profileName = profiles[0].Name;

        Map<Id, Account> accMap = new Map<Id, Account>([SELECT Id, RecordType.Name, (SELECT Id FROM AccountContactRelations WHERE Roles='Primary Contact') FROM Account WHERE Id IN :oldMap.keySet()]);

        for (Account acc : newList) {

            if (String.isEmpty(acc.Review_For__c) || !acc.Review_For__c.contains('Approval') || acc.Review_For__c == oldMap.get(acc.Id).Review_For__c ||
                profileName.contains('DLG') || profileName.contains('Franchise') || profileName.contains('IFP')) {
                continue;
            }

            if ((accMap.get(acc.Id).RecordType.Name == 'Dealer Account' || accMap.get(acc.Id).RecordType.Name == 'Franchisor Account' || accMap.get(acc.Id).RecordType.Name == 'Broker Account') 
                && accMap.get(acc.Id).AccountContactRelations.isEmpty()) {
                acc.addError('“Review For = Approval” requires a Primary Contact Role on the Account');
            }
        }
    }

    // When Authorized Seller = No, default Transaction Limit to $20K (JIRA SAL-734)
    public static void setTransactionLimit(Map<Id, Account> oldMap, List<Account> newList) {

        for (Account acc : newList) {
            if ((acc.Id == null && acc.Authorized_Seller__c == 'No') ||
                    (acc.Id != null && acc.Authorized_Seller__c != oldMap.get(acc.Id).Authorized_Seller__c && acc.Authorized_Seller__c == 'No')) {
                acc.Transaction_Limit__c = '$20K';
            }
        }

    }

    //Create SUV record if Dealer status is changed to "Watch list"
    // https://marlinbusiness.atlassian.net/browse/SAL-853
    public static void createSurveillanceOnWatchList (Map <Id, Account> oldMap, Map <Id, Account> newMap) {
        Set <Id> accIds = new Set <Id> ();
        for (Account acc : newMap.values ()) {
            if ((acc.Account_Dealer_Status__c == 'Watch List') && (oldMap == null || oldMap.get (acc.Id).Account_Dealer_Status__c != 'Watch List')) {
                accIds.add (acc.Id);
            }
        }
        if (!accIds.isEmpty()) {
            Map <Id, Dealer_Surveillance__c> cantCreateSUVRecord = new Map <Id, Dealer_Surveillance__c> ();

            for (Dealer_Surveillance__c suv : [SELECT Id, Account__c  FROM Dealer_Surveillance__c WHERE Status__c != 'Completed']) {
                cantCreateSUVRecord.put (suv.Account__c, suv);
            }

            List <Dealer_Surveillance__c> suvs = new List <Dealer_Surveillance__c> ();

            Date todayDate = Date.today ();

            for (Id accId : accIds) {
                if (cantCreateSUVRecord.get (accId) == null) {
                    suvs.add (new Dealer_Surveillance__c (Account__c = accId
                            , Recommended_Action__c = 'Approved'
                            , Recommended_Next_Review__c = '12 mos'
                            , Review_Date__c = todayDate));
                }
            }

            if (!suvs.isEmpty ()) insert suvs;
        }
    }

    // Auto set portfolio threshold for the portfolio job when dealer is submitted for approval
    // dont have to worry about new condition because primary account is required before, which requires an account to be dmled
    // didn't know that until testing
    public static void autoSetPortfolioThresholds (Map <Id, Account> oldMap,List <Account> newList) {

        System.debug('autoSetPortfolioThresholds');

        Set <Id> ownerIds = new Set <Id> ();
        List <Account> updateList = new List <Account> ();
        for (Account acc : newList) {
            if (acc.OwnerId != null && acc.DM_Review_Status__c == 'Submitted for Review' && (oldMap == null || oldMap.get (acc.Id).DM_Review_Status__c != acc.DM_Review_Status__c)) {
                ownerIds.add (acc.OwnerId);
                updateList.add (acc);
            }
        }

        System.debug('ownerIds: ' + ownerIds);
        System.debug('updateList: ' + updateList);

        if (!ownerIds.isEmpty()) {
            Map <Id, User> userMap = new Map <Id, User> ([SELECT Id, Profile.Name FROM User WHERE Id IN :ownerIds]);
            System.debug('userMap: ' + userMap);

            for (Account acc : updateList) {
                String team = userMap.get (acc.OwnerId) != null ? userMap.get (acc.OwnerId).Profile.Name: null;
                System.debug('team>>>' + team);
                if (team != null) {
                    if (!team.contains('IFP') && !team.contains('Express') && !team.contains('DataAdmin') && acc.Authorized_Seller__c == '2') {
                        acc.Portfolio_Review_Threshold__c = '500,000';
                    } else {
                        acc.Portfolio_Review_Threshold__c = '250,000';
                    }
                } else {
                    acc.Portfolio_Review_Threshold__c = '250,000';
                }

            }
        }
    }

    // CDR-014 Update Months in Business Fields (SAL-1046)
    // If Months in Business is updated, Months Verified fields on Opportunities must be updated too
    // COMMENTED OUT: https://marlinbusiness.atlassian.net/browse/SAL-1046
    /*public static void updateOppBusinessFields(Map<Id, Account> oldMap, Map<Id, Account> newMap) {

        Set<Id> accountIdSet = new Set<Id>();
        for (Account account : newMap.values()) {
            if (account.Account_Months_In_Business__c != null &&
                    account.Account_Months_In_Business__c != oldMap.get(account.Id).Account_Months_In_Business__c) {
                accountIdSet.add(account.Id);
            }
        }
        if (!accountIdSet.isEmpty ()) {
            List<Opportunity> oppList = new List<Opportunity>([
                SELECT Id, Months_Verified__c, Months_Verified_TIB__c, AccountId
                        , StageName, Last_Date_Scorex_Retrieved__c, Loan_Record_Type__c
                FROM Opportunity
                WHERE AccountId IN: accountIdSet
            ]);
    
            List<Opportunity> oppUpdateList = new List<Opportunity>();
    
            for (Opportunity opp : oppList) {
                if (opp.StageName == 'Decision' && opp.Last_Date_Scorex_Retrieved__c <> null && !opp.Loan_Record_Type__c) {
                    Decimal accMIB = newMap.get(opp.AccountId).Account_Months_In_Business__c;
                    Boolean oppUpdated = false;
                    if (accMIB != null && accMIB <= 23 && opp.Months_Verified__c == null) {
                        opp.Months_Verified__c = accMIB;
                        oppUpdated = true;
                    } else if (accMIB != null && accMIB > 23 && opp.Months_Verified_TIB__c == null) {
                        opp.Months_Verified_TIB__c = accMIB;
                        oppUpdated = true;
                    }
                    if (accMIB < 24) {
                        opp.Required_Adv_Payments__c = 2;
                        opp.Terms__c = 36;
                        oppUpdated = true;
                    }
                    if (oppUpdated) oppUpdateList.add(opp);
                }
            }
    
            update oppUpdateList;
        }
        

    }*/

    // CDR-005 Set Verbal and Stips Based on Preferred Dealer (SAL-1024)
    // Based on Preferred Dealer Level (Account) and Credit Amount (Opportunity field), set the No Verbal & Stipulations
    // on an Opportunity
    public static void updateOppVerbalStips(Map<Id, Account> oldMap, Map<Id, Account> newMap) {

        Set<Id> accountPDLChangedIdSet = new Set<Id>();
        for (Account account : newMap.values()) {
            if (account.Preferred_Dealer_Level__c != null &&
                    account.Preferred_Dealer_Level__c != oldMap.get(account.Id).Preferred_Dealer_Level__c) {
                accountPDLChangedIdSet.add(account.Id);
            }
        }

        List<Dealer__c> dealerList = new List<Dealer__c>();
        if (!accountPDLChangedIdSet.isEmpty()) {
            dealerList = new List<Dealer__c>([
                    SELECT Dealer__r.Preferred_Dealer_Level__c, Opportunity__c
                    FROM Dealer__c
                    WHERE Dealer__c IN: accountPDLChangedIdSet
            ]);
        }


        Map<Id, Dealer__c> oppIdDealerMap = new Map<Id, Dealer__c>();

        for (Dealer__c dealer : dealerList) {
            oppIdDealerMap.put(dealer.Opportunity__c, dealer);
        }

        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>();
        if (!oppIdDealerMap.keySet().isEmpty()) {
            oppMap = new Map<Id, Opportunity>([
                    SELECT AccountId, Waived_Stipulations__c, No_Verbal__c, Primary_Dealer__c, Credit_Amount__c
                    FROM Opportunity
                    WHERE Id IN: oppIdDealerMap.keySet()
                    AND StageName = 'Decision'
                    AND Loan_Record_Type__c = false
                    AND Last_Date_Scorex_Retrieved__c != null
            ]);
        }

        Map<Id, Id> accountRetrieveNoVerbalIdOpportunityMap = new Map<Id, Id>();
        for (Opportunity opp : oppMap.values()) {
            String pdl = newMap.get(oppIdDealerMap.get(opp.Id).Dealer__c).Preferred_Dealer_Level__c;
            Decimal ca = opp.Credit_Amount__c;
            if (pdl != null && ca != null) {
                if ((pdl.equals('1') && ca <= 50000) || (pdl.equals('2') && ca <= 30000) || (pdl.equals('3') && ca <= 20000)) {
                    opp.No_Verbal__c = 'Yes';
                } else {
                    accountRetrieveNoVerbalIdOpportunityMap.put(opp.AccountId, opp.Id);
                }

                if ((pdl == '1' || pdl == '2' || pdl == '3') && ca <= 20000) {
                    List<String> waivedStipsList = new List<String>{
                            'Copy of drivers\'s license',
                            'Corporate Officer to Sign',
                            'Proof of equipment location'};
                    opp.Waived_Stipulations__c = String.join(waivedStipsList, ';');
                }
            }
        }

        Map<Id, Account> accountRetrieveNoVerbalMap = new Map<Id, Account>();
        if (!accountRetrieveNoVerbalIdOpportunityMap.keySet().isEmpty()) {
            accountRetrieveNoVerbalMap = new Map<Id, Account>([
                    SELECT No_Verbal__c
                    FROM Account
                    WHERE Id IN: accountRetrieveNoVerbalIdOpportunityMap.keySet()
            ]);
        }

        for (Id accountId : accountRetrieveNoVerbalIdOpportunityMap.keySet()) {
            oppMap.get(accountRetrieveNoVerbalIdOpportunityMap.get(accountId)).No_Verbal__c =
                    newMap.containsKey(accountId) ? newMap.get(accountId).No_Verbal__c :
                    accountRetrieveNoVerbalMap.get(accountId).No_Verbal__c;
        }

        update oppMap.values();
    }

    // SAL-1236: New Email Notification to partnermanagementteam@marlincapitalsolutions.com when Dealer Status is set to "On Hold"
    public static void newDealerRampupNotification(Map<Id, Account> oldMap, Map<Id, Account> newMap) {
        Set<Id> accIdSet = new Set<Id>();
        for (Account account : newMap.values()) {
            if (account.Account_Dealer_Status__c == 'On Hold' && oldMap.get(account.Id).Account_Dealer_Status__c != account.Account_Dealer_Status__c) {
                accIdSet.add(account.Id);
            }
        }

        if (!accIdSet.isEmpty()) {
            Map<Id, List<Dealer__c>> accIdDealerListMap = new Map<Id, List<Dealer__c>>();
            List<Dealer__c> dealerList = new List<Dealer__c>([
                    SELECT Id, Dealer__c, Opportunity__r.Application__c, Opportunity__r.Name, Opportunity__r.Credit_Amount__c
                    FROM Dealer__c
                    WHERE Dealer__c IN :accIdSet]);
            for (Dealer__c dealer : dealerList) {
                if (accIdDealerListMap.containsKey(dealer.Dealer__c)) {
                    accIdDealerListMap.get(dealer.Dealer__c).add(dealer);
                } else {
                    accIdDealerListMap.put(dealer.Dealer__c, new List<Dealer__c>{dealer});
                }
            }

            Map<Id, String> accIdOwnerEmailMap = new Map<Id, String>();
            List<Account> accountList = new List<Account>([SELECT Id, Owner.Email FROM Account WHERE Id IN: accIdSet]);
            for (Account account : accountList) {
                accIdOwnerEmailMap.put(account.Id, account.Owner.Email);
            }

            List <OrgWideEmailAddress> noreply = new List <OrgWideEmailAddress> ([select id, Address, DisplayName from OrgWideEmailAddress where address like '%noreply%']);
            List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();

            for (Id accId : accIdSet) {
                Messaging.SingleEmailMessage emailMessage = new Messaging.SingleEmailMessage ();

                if (!noreply.isEmpty()) emailMessage.setOrgWideEmailAddressId(noreply[0].Id);
                emailMessage.setToAddresses (new List <String>{'partnermanagementteam@marlincapitalsolutions.com'});
                emailMessage.setCcAddresses(new List<String>{accIdOwnerEmailMap.get(accId)});
                emailMessage.saveAsActivity = false;
                emailMessage.setSubject('New Dealer Ramp-up Notification');

                String applicationDescriptionHTML = '';
                String applicationDescriptionPlainText = '';
                if (accIdDealerListMap.containsKey(accId)) {
                    applicationDescriptionHTML += '<ul>';
                    applicationDescriptionPlainText += '';
                    for (Dealer__c dealer : accIdDealerListMap.get(accId)) {
                        String descriptionString = dealer.Opportunity__r.Name;

                        descriptionString += ': Application # = ';
                        descriptionString += dealer.Opportunity__r.Application__c != null ? dealer.Opportunity__r.Application__c : 'N/A';

                        descriptionString += '; Credit Amount = ';
                        String currencyString = dealer.Opportunity__r.Credit_Amount__c != null ? (dealer.Opportunity__r.Credit_Amount__c.setScale(2) + 0.001).format() : '0.000';
                        descriptionString += '$' + currencyString.subString(0, currencyString.length()-1);
                        applicationDescriptionHTML += '<li>' + descriptionString + '</li>';
                        applicationDescriptionPlainText += '\n' + descriptionString;
                    }
                    applicationDescriptionHTML += '</ul>';
                } else {
                    applicationDescriptionHTML = '<p>This account is not yet a Dealer for an opportunity.</p>';
                    applicationDescriptionPlainText = '\nThis account is not yet a Dealer for an opportunity.';
                }

                String htmlBody =
                        '<p>New dealer approved within the last 90 days has reached 5 apps and/or $250K in credit amount.</p>' +
                                '<p>Dealer #: ' + newMap.get(accId).Dealer_Number__c + '</p>' +
                                '<p>Dealer Name: ' + newMap.get(accId).Name + '</p>' +
                                '<p>App #\'s Associated with Dealer: ' + applicationDescriptionHTML + '</p>';
                String plainTextBody =
                        'New dealer approved within the last 90 days has reached 5 apps and/or $250K in credit amount.\n' +
                                'Dealer #: ' + newMap.get(accId).Dealer_Number__c + '\n' +
                                'Dealer Name: ' + newMap.get(accId).Name + '\n' +
                                'App #\'s Associated with Dealer:' + applicationDescriptionPlainText;
                emailMessage.setHtmlBody(htmlBody);
                emailMessage.setPlainTextBody(plainTextBody);

                emailList.add(emailMessage);
            }

            system.debug ('>>>>> newDealerRampupNotification emailList size: ' + emailList.size ());

            if (!emailList.isEmpty()) {
                Messaging.SendEmailResult[] results = new List<Messaging.SendEmailResult>();
                if (!Test.isRunningTest()) results = Messaging.sendEmail(emailList);
            }
        }
    }
    
    public static void setReviewTrackingField (Map <Id, Account> oldMap, List <Account> newList)  {
        for (Account acc : newList) {
            if (acc.Review_For__c != oldMap.get (acc.Id).Review_For__c ) {
                acc.Review_For_Tracking__c = acc.Review_For__c;
            }
        }
    }
    
 /*   public static void submitForReviewEmployeeCheck (Map <Id, Account> oldMap, Map <Id, Account> newMap) {
        System.debug ('>>>>> rb hello');
        Set <Id> accIds = new Set <Id> ();
        
        for (Account acc : newMap.values ()) {
            if (acc.DM_Review_Status__c == 'Submitted for Review'
                && acc.Account_Record_Type_Custom_Formula__c == 'Dealer Account'
                && acc.DM_Review_Status__c != oldMap.get (acc.Id).DM_Review_Status__c
                && (acc.NumberOfEmployees == null || acc.NumberOfEmployees <10)
                && acc.Dealer_Service_Based__c == false
                    ) {
                accIds.add (acc.Id);
            }
        }
        
        System.debug ('>>>>> rb accIds' + accIds);
        
        if (!accIds.isEmpty ()) {
            List <Account> accs = new List <Account> ([SELECT Id,  (SELECT Id, OK_to_Pull_Credit__c, SSN__c, Validity_Verify__Status__c  FROM Contacts) FROM Account WHERE Id IN :accIds]);
            for (Account acc: accs) {
                
                Boolean hasValidContact = false;
                System.debug ('>>>>> right before alsdkjf');
                for (Contact con : acc.Contacts) {
                    System.debug ('con.OK_to_Pull_Credit__c: ' + con.OK_to_Pull_Credit__c + ' con.SSN__c ' + con.SSN__c + ' con.Validity_Verify__Status__c ' + con.Validity_Verify__Status__c);
                    if (con.OK_to_Pull_Credit__c && !String.isBlank (con.SSN__c) && con.Validity_Verify__Status__c != 'Invalid' && !String.isBlank(con.Validity_Verify__Status__c)) {
                        hasValidContact = true;
                    }
                }
                
                if (!hasValidContact) newMap.get (acc.Id).addError ('Submiting a dealer with under 10 employees requires a contact that has the following: Ok To PullCcredit, SSN, and valid email');
            }
        }
    }*/
    
    /*public static void validateAttachmentForDealerManagement (Map <Id, Account> oldMap, Map <Id, Account> newMap) {

        Set <Id> accIds = new Set <Id> ();

        for (Account acc : newMap.values()){
            if (acc.DM_Review_Status__c == 'Submitted for Review' &&
                acc.Dealer_Service_Based__c &&
                acc.Review_For__c.contains('Approval')) accIds.add(acc.Id);
        }

        if (!accIds.isEmpty()){

            List <Account> accList = [SELECT Id, RecordType.DeveloperName, Dealer_Service_Based__c, (SELECT Id FROM ContentDocumentLinks) FROM Account WHERE Id IN :accIds];

            if (accList != null && !accList.isEmpty()){
                for (Account acc : accList){
                    if (acc.RecordType.DeveloperName == 'Dealer_Vendor' && acc.Dealer_Service_Based__c == false && (acc.ContentDocumentLinks == null || acc.ContentDocumentLinks.isEmpty()) && !Test.isRunningTest()) newMap.get(acc.Id).addError('You must upload a sample invoice and service agreement prior to submitting to Dealer Management');
                }
            }
        }
    }*/

    //Auto Create new Dealer Surv record when Net Investment reaches each threshold
    //https://marlinbusiness.atlassian.net/browse/SAL-1593
    public static void thresholdReachedCreateSurv (Map <Id, Account> oldMap, Map <Id, Account> newMap) {
        
        // throw values in maps so we don't have to loop inside of a loop
        Map <String, String> thresholdMap = new Map <String, String> ();
        Map <String, Id> accIdRefMap = new Map <String, Id> ();
        
        for (Account acc : newMap.values ()) {
            if (acc.Net_Investment__c!= null && (oldMap == null || acc.Net_Investment__c != oldMap.get (acc.Id).Net_Investment__c)) {
                String thresh = valueToThreshold (acc.Net_Investment__c);
                if (thresh != null) {
                    String key = createThresholdKey (acc.Id, thresh);
                    thresholdMap.put (key, thresh);
                    accIdRefMap.put (key, acc.Id);
                } 
            }
                
        }
        
        if (accIdRefMap.isEmpty() || thresholdMap.isEmpty()) return;
        
        for (Dealer_Surveillance__c surv : [SELECT Id, Account__c, Dealer_Surveillance__c FROM Dealer_Surveillance__c WHERE Account__c IN :accIdRefMap.values() AND Review_Type__c = 'Portfolio Threshold' AND Dealer_Surveillance__c Like 'Portfolio Threshold %']) {
            List <String> splitName = surv.Dealer_Surveillance__c.split (' ');
            if (splitName.size() == 3) {
                String thresh = splitName[2];
                String key = createThresholdKey (surv.Account__c, thresh);
                if (thresholdMap.get (key) != null) {
                    thresholdMap.remove (key);
                }
            }
        }
        
        if (thresholdMap.isEmpty ()) return;
        
        List <Dealer_Surveillance__c> insertList = new List <Dealer_Surveillance__c> ();
        
        for (String key : thresholdMap.keySet ()) {
            insertList.add (new Dealer_Surveillance__c (Account__c = accIdRefMap.get (key)
                                                       , Dealer_Surveillance__c = 'Portfolio Threshold ' + thresholdMap.get (key)
                                                       , Review_Type__c = 'Portfolio Threshold'
                                                       , Status__c = 'In Queue'));
        }
        
        insert insertList;
        

    }
    
    private static String createThresholdKey (Id accId, String thresh) {
        return accId + '-' + thresh;
    }
    
    private static String valueToThreshold (Decimal value) {
        if (value == null || value < 250000) {
            return null;
        } else if (value < 500000) {
            return '$250K';
        } else if (value < 1000000) {
            return '$500K';
        } else if (value < 2500000) {
            return '$1MM';
        } else if (value < 5000000) {
            return '$2.5MM';
        } else if (value < 10000000) {
            return '$5MM';
        } else {
            return '$10MM';
        }
    }

}
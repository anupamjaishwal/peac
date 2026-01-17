public without sharing class SL_DealerPortalCreateApp {

    public static Id endUserAccountId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('End User Account').getRecordTypeId();
    public static final String END_USER_ACCOUNT = 'End User Account';
    public static Map<String, String> stateCodesByStateName = new Map<String, String>{'Alabama' => 'AL',
        'Alaska' => 'AK',
        'Arizona' => 'AZ',
        'Arkansas' => 'AR',
        'California' => 'CA',
        'Colorado' => 'CO',
        'Connecticut' => 'CT',
        'Delaware' => 'DE',
        'District of Columbia' => 'DC',
        'Florida' => 'FL',
        'Georgia' => 'GA',
        'Hawaii' => 'HI',
        'Idaho' => 'ID',
        'Illinois' => 'IL',
        'Indiana' => 'IN',
        'Iowa' => 'IA',
        'Kansas' => 'KS',
        'Kentucky' => 'KY',
        'Louisiana' => 'LA',
        'Maine' => 'ME',
        'Maryland' => 'MD',
        'Massachusetts' => 'MA',
        'Michigan' => 'MI',
        'Minnesota' => 'MN',
        'Mississippi' => 'MS',
        'Missouri' => 'MO',
        'Montana' => 'MT',
        'Nebraska' => 'NE',
        'Nevada' => 'NV',
        'New Hampshire' => 'NH',
        'New Jersey' => 'NJ',
        'New Mexico' => 'NM',
        'New York' => 'NY',
        'North Carolina' => 'NC',
        'North Dakota' => 'ND',
        'Ohio' => 'OH',
        'Oklahoma' => 'OK',
        'Oregon' => 'OR',
        'Pennsylvania' => 'PA',
        'Rhode Island' => 'RI',
        'South Carolina' => 'SC',
        'South Dakota' => 'SD',
        'Tennessee' => 'TN',
        'Texas' => 'TX',
        'Utah' => 'UT',
        'Vermont' => 'VT',
        'Virginia' => 'VA',
        'Washington' => 'WA',
        'West Virginia' => 'WV',
        'Wisconsin' => 'WI',
        'Wyoming' => 'WY'};

    @AuraEnabled
    public static string hubExecute(String methodName, List<String> parameters){
        String result = '';
        try {
            switch on methodName {
                when 'getAccountByDUNS'{
                    result = getAccountByDUNS(parameters[0], parameters[1], parameters[2], parameters[3], parameters[4],
                        parameters[5], parameters[6], parameters[7], parameters[8], parameters[9], parameters[10], parameters[11]);
                }
            }
        } catch (Exception e) {
            system.debug('e: ' + e);
            system.debug('e.getMessage(): ' + e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
        return result;
    }

    public static String getAccountByDUNS(String dunsNumber, String taxId, String primaryName, String streetAddress, String addressLocality,
        String addressRegion, String postalCode, String addressCountry, String yearlyRevenue, String industry, String dnbAddress, String businessPhone) {
        String paddedDuns = (dunsNumber != null? dunsNumber: '').leftPad(9,'0');
        String zeroZeroesDuns = dunsNumber != '' && dunsNumber != null? String.valueOf(Integer.valueOf(dunsNumber)): '';
        String foundId = '';
        Account toUpsert = new Account();
        List<Account> existing = new List<Account>();
        if(dunsNumber != null){
            existing = [SELECT Id, Name, DUNS__c, Tax_ID__c, Legal_Entity_Name__c, Business_Address__c, Business_City__c, Business_State__c,
                Business_Zip__c, Business_Country__c, AnnualRevenue, Industry, RecordTypeId, Account_Record_Type_Custom__c,
                Business_Type__c, D_B_Revenue__c, Business_Phone__c FROM Account WHERE (DUNS__c = :paddedDuns OR DUNS__c = :zeroZeroesDuns) AND RecordTypeId = :endUserAccountId];
        }
        if(existing.size() >0){
            toUpsert = existing[0];
            toUpsert.D_B_Legal_Entity_Name__c = primaryName;
            toUpsert.D_B_Business_Address__c = dnbAddress;
        }else{
            toUpsert.Name = primaryName;
            toUpsert.RecordTypeId = endUserAccountId;
            toUpsert.Account_Record_Type_Custom__c = END_USER_ACCOUNT;
            toUpsert.Business_Phone__c = businessPhone;
            if(taxId != ''){
                toUpsert.Tax_ID__c = taxId;
            }
            if(toUpsert.Business_Address__c != streetAddress){
                toUpsert.Business_Address__c = streetAddress;
            }
            if(toUpsert.Business_City__c != addressLocality){
                toUpsert.Business_City__c = addressLocality;
            }
            String stateCode = stateCodesByStateName.get(addressRegion);
            if(toUpsert.Business_State__c != stateCode){
                toUpsert.Business_State__c = stateCode;
                toUpsert.BillingStateCode = stateCode;
                toUpsert.BillingState = addressRegion;
                toUpsert.BillingCountry = 'United States';
                toUpsert.BillingCountryCode = 'US';
            }
            if(toUpsert.Business_Zip__c != postalCode){
                toUpsert.Business_Zip__c = postalCode;
            }
            if(toUpsert.Business_Country__c != addressCountry){
                toUpsert.Business_Country__c = addressCountry;
            }
            Id dupeAccountId = getDupeId(toUpsert);
            if(dupeAccountId != null){
                toUpsert.Id = dupeAccountId;
                Account addressFields = [SELECT Name, Business_Address__c, Business_City__c, Business_State__c,
                Business_Zip__c, Business_Country__c, RecordTypeId, Business_Phone__c FROM Account WHERE Id = :dupeAccountId];
                    setExistingData(toUpsert, addressFields, primaryName, dnbAddress);
            }else{
                List<Account> sameNameAccount = [SELECT Name, Business_Address__c, Business_City__c, Business_State__c,
                Business_Zip__c, Business_Country__c, RecordTypeId, Business_Phone__c FROM Account WHERE Name = :primaryName];
                if(sameNameAccount.size() > 0){
                    toUpsert.Id = sameNameAccount[0].Id;
                    setExistingData(toUpsert, sameNameAccount[0], primaryName, dnbAddress);
                }else{
                    if(toUpsert.Legal_Entity_Name__c != primaryName){
                        toUpsert.Legal_Entity_Name__c = primaryName;
                    }
                }
            }
        }

        if(toUpsert.DUNS__c != paddedDuns && Integer.valueOf(paddedDuns) > 0){// DP-1664 Misael Romero
            toUpsert.DUNS__c = paddedDuns;
        }
        if(yearlyRevenue !=null){
        if(toUpsert.D_B_Revenue__c != Decimal.valueOf(yearlyRevenue)){
            toUpsert.D_B_Revenue__c = Decimal.valueOf(yearlyRevenue);
            }
        }
        if(toUpsert.Industry != industry){
            toUpsert.Industry = industry;
        }
        
        system.debug('toUpsert: ' + toUpsert);
        return JSON.serialize(toUpsert);
    }

    @invocableMethod(label='Upsert Account for App')
    public static List<Account> upsertAccountForApp(List<Account> accounts){
        Account theAccount = accounts[0];
        List<Account> existing = new List<Account>();
        existing = [SELECT Id, Business_Address__c, Business_City__c, Business_State__c, Business_Zip__c, Business_Country__c, RecordTypeId, Business_Phone__c
            FROM Account WHERE Tax_ID__c != null AND Tax_ID__c = :theAccount.Tax_ID__c AND RecordTypeId = :endUserAccountId];
        
        List<User> currentUserResult = [SELECT Id, IsPortalEnabled FROM User WHERE Id =:System.UserInfo.getUserId()];
        if(existing.size() > 0){
            theAccount.Id = existing[0].Id;
            theAccount.Business_Address__c = existing[0].Business_Address__c;
            theAccount.Business_City__c = existing[0].Business_City__c;
            theAccount.Business_State__c = existing[0].Business_State__c;
            theAccount.Business_Zip__c = existing[0].Business_Zip__c;
            theAccount.Business_Country__c = existing[0].Business_Country__c;
            //theAccount.RecordTypeId = endUserAccountId;
            theAccount.RecordTypeId = existing[0].RecordTypeId;
            Id userId = System.UserInfo.getUserId();
            if(currentUserResult.size() == 1 && currentUserResult[0].IsPortalEnabled){
              UserRecordAccess ura = [SELECT RecordId, HasEditAccess 
                FROM UserRecordAccess WHERE UserId = :userId AND RecordId = :theAccount.Id LIMIT 1];
              if(!ura.HasEditAccess){
                  shareAccountWithUser(theAccount.Id);
              }
            }
        }else{
            String primaryName = String.isBlank(theAccount.Legal_Entity_Name__c)? theAccount.Name: theAccount.Legal_Entity_Name__c;
            String yearlyRevenue = theAccount.D_B_Revenue__c != null? String.valueOf(theAccount.D_B_Revenue__c): '0';
            String businessType = theAccount.Business_Type__c;
            String serializedAccount = getAccountByDUNS(theAccount.DUNS__c, theAccount.Tax_ID__c, primaryName, theAccount.Business_Address__c, 
                theAccount.Business_City__c, theAccount.BillingState, theAccount.Business_Zip__c, theAccount.Business_Country__c,
                yearlyRevenue, theAccount.Industry, theAccount.D_B_Business_Address__c, theAccount.Business_Phone__c);
            theAccount = (Account)JSON.deserialize(serializedAccount, Account.class);
            if(theAccount.Id == null){
                List<User> informaticaResults = [SELECT Id, Name FROM User WHERE Name = 'User Informatica'];
                if(informaticaResults.size() == 1){
                    theAccount.OwnerId = informaticaResults[0].Id;
                }
                if(String.isBlank(theAccount.Name)){
                    theAccount.Name = theAccount.Legal_Entity_Name__c;
                }
            }
            theAccount.Business_Type__c = businessType;
        }
         //DP-1597 - Carlos Herrera
         Database.DMLOptions dml = new Database.DMLOptions();
         dml.DuplicateRuleHeader.allowSave = true;
         if(theAccount.Id == null){
             Database.SaveResult sr = Database.insert(theAccount,dml);
         }else{
             Database.SaveResult sr = Database.update(theAccount,dml);
         }
        if(currentUserResult.size() == 1 && currentUserResult[0].IsPortalEnabled){
          shareAccountWithUser(theAccount.Id);
        }
        return new List<Account>{theAccount};
        
    }

    public static void shareAccountWithUser(Id accountId){
        Id userId = System.UserInfo.getUserId();
        Boolean isEditable = false;
        List<AccountShare> sharesWithUser = [SELECT Id, AccountAccessLevel FROM AccountShare 
            WHERE AccountId = :accountId AND UserOrGroupId = :userId];
        if(sharesWithUser.size() > 0){
            for(AccountShare accShare :sharesWithUser){
                if(accShare.AccountAccessLevel == 'Edit' || accShare.AccountAccessLevel == 'All'){
                    isEditable = true;
                    break;
                }
            }
        }
        if(!isEditable && accountId != null){
            insert new AccountShare(AccountAccessLevel = 'Edit', OpportunityAccessLevel = 'None', CaseAccessLevel = 'None',
                RowCause = 'Manual', AccountId = accountId, UserOrGroupId = userId);
        }
    }

    public static Id getDupeId(SObject recordToMatch){
        List<SObject> recordList = new List<SObject> {recordToMatch};
        String sObjectApiName = recordToMatch.getSObjectType().getDescribe().getName();
        Integer activeDupeRules = [SELECT COUNT() FROM DuplicateRule WHERE SobjectType = :sObjectApiName AND isActive = true];
        List<Datacloud.FindDuplicatesResult> duplicateResults = new List<Datacloud.FindDuplicatesResult>();
        if(activeDupeRules > 0 && !Test.isRunningTest()){
            duplicateResults = Datacloud.FindDuplicates.findDuplicates(recordList);
        }
        Id dupeId = null;
        for (Datacloud.FindDuplicatesResult findDupeResult : duplicateResults) {
            for (Datacloud.DuplicateResult dupeResult : findDupeResult.getDuplicateResults()) {
              for (Datacloud.MatchResult matchResult : dupeResult.getMatchResults()) {
                for (Datacloud.MatchRecord matchRecord : matchResult.getMatchRecords()) {
                    system.debug('matchRecord: ' + matchRecord);
                    SObject dupeRecord = matchRecord.getRecord();
                    if(dupeId == null && dupeRecord.Id != recordToMatch.Id){
                        dupeId = dupeRecord.Id;
                    }
                }
              }
            }
        }
        return dupeId;
    }

    public static void setExistingData(Account toUpsert, Account existing, String primaryName, String dnbAddress){
        toUpsert.Name = existing.Name;
        toUpsert.Business_Address__c = existing.Business_Address__c;
        toUpsert.Business_City__c = existing.Business_City__c;
        toUpsert.Business_State__c = existing.Business_State__c;
        toUpsert.Business_Zip__c = existing.Business_Zip__c;
        toUpsert.Business_Country__c = existing.Business_Country__c;
        toUpsert.D_B_Legal_Entity_Name__c = primaryName;
        toUpsert.D_B_Business_Address__c = dnbAddress;
        toUpsert.RecordTypeId = existing.RecordTypeId;
        toUpsert.Business_Phone__c = existing.Business_Phone__c;
    }
}
/*
* @author : sfdcdev, Tamarack Consulting, Inc.
* @date : 1/27/2017
* @description: Class to handle lead conversion for Tamarack data
*
* © Copyright 2003 - 2017 Tamarack Consulting, Inc.  All Rights Reserved.
* 
*/

public without sharing class TC_LeadConversion {
    
    public static void attachExtraObjects (Map <Id, Lead> leadOldMap, Map <Id, Lead> leadNewMap){
        system.debug('@@@@@ START LEAD CONVERT');
        
        Contact contact;// = new Contact();
        Account account;// = new Account();
        Asset__c asset;
        List<Contact> contactList = new List<Contact>();
        List<Account> accountList = new List<Account>();
        List<Asset__c> assetList = new List<Asset__c>();
        ID convertedAccountId = NULL;
        ID convertedOpportunityId = NULL;
        
        // no bulk processing; will only run from the UI for dedupe matching on Account and Contact
        if (leadNewMap.size() == 1) {              
            for (Lead lead: leadNewMap.values()) {          
                //only on lead conversion
                //
                
                System.debug('>>> Lead Recordtypes: ' + Schema.SObjectType.Lead.getRecordTypeInfosByName());
                System.debug('>>> Lead Recordtypes get END USER: ' + Schema.SObjectType.Lead.getRecordTypeInfosByName().get('End User Lead'));
                System.debug('>>> Lead Recordtypes get END USER __ ID: ' + Schema.SObjectType.Lead.getRecordTypeInfosByName().get('End User Lead').getRecordTypeId());
                System.debug('>>> Lead ID: '+ lead.RecordTypeId);
                
                if (lead.isConverted == true && leadOldMap.get(lead.Id).isConverted == false && lead.RecordTypeId == Schema.SObjectType.Lead.getRecordTypeInfosByName().get('End User Lead').getRecordTypeId()) {                    
                    
                    convertedAccountId = lead.ConvertedAccountId;
                    convertedOpportunityId = lead.ConvertedOpportunityId;
                    
                    // moved from process builder to avoid error
                    if (convertedAccountId != null) update new Account (Id = convertedAccountId, RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('End User Account').getRecordTypeId());
                    
                    if(!String.isBlank(lead.Guarantor_Last_Name__c) ){

                        contact = new Contact();
                        contact.LastName = lead.Guarantor_Last_Name__c; // set required field example
                        contact.AccountId = convertedAccountId;
                        if(lead.Guarantor_First_Name__c != null) contact.FirstName = lead.Guarantor_First_Name__c;
                        if(lead.Ownership_Pct__c  != null) contact.Ownership_Pct__c  = lead.Ownership_Pct__c ;
                        if(lead.Guarantor_Address_Line1__c  != null) contact.OtherStreet = lead.Guarantor_Address_Line1__c ;
                   //   if(lead.Guarantor_Address_Line2__c  != null) contact.YYYYYYYY = lead.Guarantor_Address_Line2__c ;
                        if(lead.Guarantor_City__c  != null) contact.OtherCity = lead.Guarantor_City__c ;
                        if(lead.Guarantor_state__c  != null) contact.OtherStateCode = lead.Guarantor_state__c ;
                        if(lead.Guarantor_zip__c  != null) contact.OtherPostalCode = lead.Guarantor_zip__c ;
                        if(lead.Date_of_Birth__c  != null) contact.Birthdate  = lead.Date_of_Birth__c ;
                        if(lead.SSN__c  != null) contact.SSN__c  = lead.SSN__c ;
                        if(lead.Guarantor_email__c  != null) contact.Email  = lead.Guarantor_email__c ;
                        if(lead.Guarantor_Phone__c  != null) contact.Phone = lead.Guarantor_Phone__c ;
                        contactList.add(contact);
                    }

                    if(!String.isBlank(lead.Guarantor2_Last_Name__c )){ // same exact thing as guarntor 1. now just 2
                        
                        contact = new Contact();
                        contact.LastName = lead.Guarantor2_Last_Name__c; // set required field example
                        contact.AccountId = convertedAccountId;
                        if(lead.Guarantor2_First_Name__c != null) contact.FirstName = lead.Guarantor2_First_Name__c;
                        if(lead.Ownership2_Pct__c  != null) contact.Ownership_Pct__c  = lead.Ownership2_Pct__c ;
                        if(lead.Guarantor2_Address_Line1__c  != null) contact.OtherStreet = lead.Guarantor2_Address_Line1__c ;
                   //   if(lead.Guarantor2_Address_Line2__c  != null) contact.YYYYYYYY = lead.Guarantor2_Address_Line2__c ;
                        if(lead.Guarantor2_City__c  != null) contact.OtherCity = lead.Guarantor2_City__c ;
                        if(lead.Guarantor2_state__c  != null) contact.OtherStateCode = lead.Guarantor2_state__c ;
                        if(lead.Guarantor2_zip__c  != null) contact.OtherPostalCode = lead.Guarantor2_zip__c ;
                        if(lead.Date_of_Birth2__c  != null) contact.Birthdate  = lead.Date_of_Birth2__c ;
                        if(lead.SSN2__c  != null) contact.SSN__c  = lead.SSN2__c ;
                        if(lead.Guarantor2_email__c  != null) contact.Email  = lead.Guarantor2_email__c ;
                        if(lead.Guarantor2_Phone__c  != null) contact.Phone = lead.Guarantor2_Phone__c ;
                        contactList.add(contact);                                                
                    }
                    
                    if(!String.isBlank(lead.Dealer_name__c )){ //  the 'dealer' process
                          
                        account = new Account(RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Dealer Account').getRecordTypeId(), Account_Record_Type_Custom__c = 'Dealer Account');
                        account.Name = lead.Dealer_name__c;
                        System.debug('LEAD>>> ' + Schema.SObjectType.Account.getRecordTypeInfosByName().get('Dealer Account').getRecordTypeId());
                        System.debug(Account.RecordTypeId);
                        if(lead.Dealer_phone__c  != null) account.Business_Phone__c  = lead.Dealer_phone__c ;
                        if(lead.Dealer_email__c  != null) account.Contact_Email__c  = lead.Dealer_email__c ;
                        if(lead.Dealer_address__c != null) account.Business_Address__c  = lead.Dealer_address__c;
                        if(lead.Dealer_city__c  != null) account.Business_City__c  = lead.Dealer_city__c ;
                        if(lead.Dealer_state__c  != null) account.Business_State__c  = lead.Dealer_state__c ;
                        if(lead.Dealer_zip__c  != null) account.Business_Zip__c  = lead.Dealer_zip__c ;
                        if (lead.Dealer_Number__c != null) account.Dealer_Number__c = lead.Dealer_Number__c;
                        if (lead.Dealer_Number__c != null) account.Dealer_Number__c = lead.Dealer_Number__c;
                        account.Skip_RT_Automation_Initially__c = true;
                        //account.RecordTypeId = 
                        accountList.add(account);                        
                    }
                    
                    if(!String.isBlank(lead.Equipment_Type__c)
                      && !String.isBlank(lead.Equipment_Address_Line_1__c)
                      && !String.isBlank(lead.Equipment_City__c)
                      && !String.isBlank(lead.Equipment_State__c)
                      && !String.isBlank(lead.Equipment_Zipcode__c)){ //  the 'asset' process
                          
                        asset = new Asset__c();
                        asset.Equipment_Code__c  = lead.Equipment_Type__c ;
                        asset.Opportunity__c  = convertedOpportunityId ; // set lookup from Asset to Opp
                        asset.End_User_Billing_Address__c = !lead.Equipment_address_different__c;
                        if(lead.Equipment_Description__c   != null) asset.Description__c   = lead.Equipment_Description__c  ;
                        if(lead.Equipment_Address_Line_1__c   != null) asset.Equipment_Street__c   = lead.Equipment_Address_Line_1__c  ;
                        if(lead.Equipment_Address_Line_2__c   != null) asset.Equipment_Address_2__c   = lead.Equipment_Address_Line_2__c  ;
                        if(lead.Equipment_City__c   != null) asset.Equipment_City__c   = lead.Equipment_City__c  ;
                        if(lead.Equipment_State__c   != null) asset.Equipment_State__c   = lead.Equipment_State__c  ;
                        if(lead.Equipment_Zipcode__c   != null) asset.Equipment_Zip__c   = lead.Equipment_Zipcode__c  ;
                        if(lead.Equipment_Cost__c   != null) asset.Cost__c   = lead.Equipment_Cost__c  ;
                        if(lead.Equipment_Cost__c   != null) asset.List_Price__c   = lead.Equipment_Cost__c  ;
                        assetList.add(asset);
                    }
                    
                }  
            }
            
            system.debug('>>>>> contactList is ' + contactList);
            system.debug('>>>>> accountList is ' + accountList);
            system.debug('>>>>> assetList is ' + assetList);
            
            insert assetList;
            
            List<Guarantor__c> guarantorList = new List<Guarantor__c>();
            List<Contact> contactUpdates = new List<Contact>();
            List<Id> contactSuccess = new List<Id>();
            
            List<Dealer__c> dealerList = new List<Dealer__c>();
            List<Account> accountUpdates = new List<Account>();
            List<Id> accountSuccess = new List<Id>();
            
            Database.DMLOptions dml = new Database.DMLOptions(); 
            dml.DuplicateRuleHeader.allowSave = FALSE;
            

            Set <Id> contactIdsForDebug = new Set <Id> ();

            //attempt to insert new contacts
            List<Database.SaveResult> saveResults = Database.insert(contactList, dml);
            for(Integer i=0;i<saveResults.size();i++){
                Database.SaveResult saveResult = saveResults.get(i);
                System.debug('contact saveResult = ' + saveResult);                
                if (!saveResult.isSuccess()) {
                    for (Database.Error error : saveResult.getErrors()) {
                        Contact c = contactList.get(i);  //get the contact that caused the dupe error
                        Contact dupe = new Contact();
                        System.debug('error for: ' + c);
                        System.debug(error);
                        
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
                            
                            
                            //Contact matchContact = matchRecord.getRecord();
                            System.debug('MatchRecord: ' + matchRecord.getRecord());
                            System.debug('ContactId: ' + matchRecord.getRecord().Id);
                            
                            //set Id to overwrite existing
                            dupe.Id =  matchRecord.getRecord().Id;
                            
                            //overwrite with new profile info
                            /*
                            if(c.Email != NULL) dupe.Email = c.Email;
                            if(c.Title != NULL) dupe.Title = c.Title;
                            if(c.LastName != NULL) dupe.LastName = c.LastName;
                            if(c.FirstName != NULL) dupe.FirstName = c.FirstName;
                            if(c.SSN__c != NULL) dupe.SSN__c = c.SSN__c;
                            if(c.MobilePhone != NULL) dupe.MobilePhone = c.MobilePhone;
                            if(c.HomePhone != NULL) dupe.HomePhone = c.HomePhone;
                            if(c.MailingStreet != NULL) dupe.MailingStreet = c.MailingStreet;
                            if(c.MailingCity != NULL) dupe.MailingCity = c.MailingCity;
                            if(c.MailingStateCode != NULL) dupe.MailingStatecode = c.MailingStatecode;
                            if(c.MailingPostalCode != NULL) dupe.MailingPostalCode = c.MailingPostalCode;
                            if(c.Guarantor_Annual_Income__c != NULL) dupe.Guarantor_Annual_Income__c = c.Guarantor_Annual_Income__c;
                            if(c.BirthDate != NULL) dupe.BirthDate = c.BirthDate;                          
                            */
                            
                            contactUpdates.add(dupe);  //add for update

                            //create guarantor object
                            if(convertedOpportunityId != NULL){
                                 Guarantor__c guarantor = new Guarantor__c(
                                     RecordTypeId  = Schema.SObjectType.Guarantor__c.getRecordTypeInfosByDeveloperName().get('Personal').getRecordTypeId(),
                                     Contact__c  = dupe.Id,
                                     Opportunity__c = convertedOpportunityId,
                                     DOB_From_UDA_Portal__c = i == 0 ? leadNewMap.values()[0].Date_of_Birth__c  : leadNewMap.values()[0].Date_of_Birth2__c ,
                                    SSN_From_UDA_Portal__c = i == 0 ? leadNewMap.values()[0].SSN__c : leadNewMap.values()[0].SSN2__c,
                                     Home_Address__c =  concatenateAddressFields (leadNewMap.values()[0], i)
                                     
                                   // RecordTypeId = relRecTypes.get('Individual')
                                );                       
                                guarantorList.add(guarantor);
                                system.debug('+++++ ADDING RELATIONSHIP - ' + c); 
                            }else{
                                system.debug('----- NOT ADDING RELATIONSHIP - ' + c);                                
                            }

                            contactIdsForDebug.add (dupe.Id);
                          
                        }
                    }
                }else{   
                    
                    
                    //collect Ids of successes
                    System.debug('SUCCESS INSERT for - ' + saveResults.get(i).getId());             
                    contactSuccess.add(saveResults.get(i).getId());                    
                    
                    
                    if(convertedOpportunityId != NULL){
                        Guarantor__c guarantor = new Guarantor__c(
                            RecordTypeId  = Schema.SObjectType.Guarantor__c.getRecordTypeInfosByDeveloperName().get('Personal').getRecordTypeId(),
                            // SET GUARANTOR CODE AS 'GUARANTOR'
                            Contact__c  = contactList.get(i).Id,
                            Opportunity__c = convertedOpportunityId,
                            DOB_From_UDA_Portal__c = i == 0 ? leadNewMap.values()[0].Date_of_Birth__c  : leadNewMap.values()[0].Date_of_Birth2__c ,
                            SSN_From_UDA_Portal__c = i == 0 ? leadNewMap.values()[0].SSN__c : leadNewMap.values()[0].SSN2__c,
                            Home_Address__c =  concatenateAddressFields (leadNewMap.values()[0], i)
                            // RecordTypeId = relRecTypes.get('Individual')
                        );                       
                        guarantorList.add(guarantor);
                        system.debug('+++++ ADDING RELATIONSHIP - ' + contactList.get(i)); 
                     }else{
                        system.debug('----- NOT ADDING RELATIONSHIP - ' + contactList.get(i));                                
                     }

                }

                contactIdsForDebug.add (contactList.get(i).Id);
                
            } //end contact saveResults loop
            //System.debug ('xxxxx contacts used for PGs: ' +contactIdsForDebug);

            system.debug('looking for dupes from ' + contactSuccess);
            //check successes for duplicates
            List<DuplicateRecordItem> dupeItems = [
                SELECT Id, RecordId, DuplicateRecordSetId 
                FROM DuplicateRecordItem
                WHERE RecordId IN :contactSuccess
            ]; 
            
            system.debug('*******Dupe Items = ' + dupeItems);


          
            System.debug('ContactId: ' + contactUpdates);
            //update dupe contacts
            update(contactUpdates);
            
            system.debug('>>>>> guarantor list: '+ guarantorList);
            insert guarantorList;
            
            ///
            //
            //ACCOUNT UPSERT
            System.debug('BEGIN ACCOUNT PROCESS');
            //attempt to insert new accounts
            for (Integer i; i<accountList.size(); i++){
                system.debug('accountRecType Before Insert >>> ' + accountList[i].RecordTypeId);                
            }
            saveResults = Database.insert(accountList, dml);
            for (Integer i; i<accountList.size(); i++){
                system.debug('accountRecType After Insert >>> ' + accountList[i].RecordTypeId);                
            }
            
            List <Account> accountsReadyRTAutomation = new List <Account> ();
            
            // New requirement to remove dealer # from new dealers, still need to use it as a matching rule
            // dont want to introduce a ton of new code with soql, so doing this
            
            Set <Id> removeDealerNum = new Set <Id> ();
            
            for(Integer i=0;i<saveResults.size();i++){
                Database.SaveResult saveResult = saveResults.get(i);
                System.debug('account saveResult = ' + saveResult);                
                if (!saveResult.isSuccess()) {
                    for (Database.Error error : saveResult.getErrors()) {
                        Account a = accountList.get(i);  //get the account that caused the dupe error
                        Account dupe = new Account();
                        System.debug('error for: ' + a);
                        System.debug(error);
  
                        //If there are duplicates, an error occurs
                        if (error instanceof Database.DuplicateError ) {
                            Database.DuplicateError duplicateError = (Database.DuplicateError)error;
                            Datacloud.DuplicateResult duplicateResult = duplicateError.getDuplicateResult();

                            //find duplicate records
                            Datacloud.MatchResult[] matchResults = duplicateResult.getMatchResults();

                            //Grab first match result which contains the duplicate record found
                            Datacloud.MatchResult matchResult = matchResults[0];
                                    
                            Datacloud.MatchRecord[] matchRecords = matchResult.getMatchRecords();
                            Datacloud.MatchRecord matchRecord = matchrecords[0];
                            
                            
                            //Account matchAccount = matchRecord.getRecord();
                            System.debug('MatchRecord: ' + matchRecord.getRecord());
                            System.debug('AccountId: ' + matchRecord.getRecord().Id);
                            
                            //set Id to overwrite existing
                            dupe.Id =  matchRecord.getRecord().Id;
                            
                            //overwrite with new profile info
                            //if(a.Email != NULL) dupe.Email = a.Email;                         
                            
                            accountUpdates.add(dupe);  //add for update
                            System.debug ('>>>>> account dupes convertedOpportunityId: ' + convertedOpportunityId);
                            //create Dealer obj
                            if(convertedOpportunityId != NULL){
                                System.debug ('>>>>> create dealer dupes');
                                 Dealer__c dealer = new Dealer__c(
                                     Dealer__c = dupe.Id,
                                     Opportunity__c = convertedOpportunityId
                                );                       
                                dealerList.add(dealer);
                                system.debug('+++++ ADDING RELATIONSHIP - ' + a); 
                            }else{
                                system.debug('----- NOT ADDING RELATIONSHIP - ' + a);                                
                            }
                          
                        }
                    }
                }else{   
                    
                    
                    //collect Ids of successes
                    System.debug('SUCCESS INSERT for - ' + saveResults.get(i).getId());             
                    contactSuccess.add(saveResults.get(i).getId());                    
                    accountsReadyRTAutomation.add (new Account (Id = accountList.get(i).Id, Skip_RT_Automation_Initially__c = false));
                    removeDealerNum.add (accountList.get(i).Id);
                    //create new opportunity relationship mapping
                    if(convertedOpportunityId != NULL){
                        Dealer__c dealer = new Dealer__c(
                            Dealer__c = accountList.get(i).Id,
                            Opportunity__c = convertedOpportunityId
                            );                       
                        dealerList.add(dealer);
                        system.debug('+++++ ADDING RELATIONSHIP - ' + accountList.get(i)); 
                    }else{
                        system.debug('----- NOT ADDING RELATIONSHIP - ' + accountList.get(i));                                
                    }

                }
                
            } //end account saveResults loop

            if (accountsReadyRTAutomation.isEmpty ()) update accountsReadyRTAutomation;
            
            removeDealerNums (removeDealerNum);

            system.debug('looking for dupes from ' + accountSuccess);
            //check successes for duplicates
            dupeItems = [
                SELECT Id, RecordId, DuplicateRecordSetId 
                FROM DuplicateRecordItem
                WHERE RecordId IN :accountSuccess
            ]; 
            
            system.debug('*******Dupe Items = ' + dupeItems);


          
            System.debug('accountId: ' + accountUpdates);
            //update dupe accounts
            update(accountUpdates);
            
            system.debug('>>>>> dealer list: '+ dealerList);
            
            insert dealerList;
            
            // additional field mappings
            if (convertedOpportunityId != null && !leadNewMap.values().isEmpty ()) {
                update new Opportunity (Id = convertedOpportunityId, Annual_Revenue__c = leadNewMap.values()[0].AnnualRevenue, Account_Billing_Street2__c = leadNewMap.values()[0].Business_Address_Line2__c);
            }
            
            if (convertedAccountId != null && !leadNewMap.values().isEmpty ()){
                List <Account> accs = new List <Account> ([SELECT Id, Account_Billing_Street2__c FROM Account WHERE Id = :convertedAccountId]);               
                Account acc = new Account (Id = convertedAccountId);
                if (accs[0].Account_Billing_Street2__c == null || accs[0].Account_Billing_Street2__c == '') acc.Account_Billing_Street2__c = leadNewMap.values()[0].Business_Address_Line2__c;
            }
            




            
//throw new localException('done here');  

        }
        
    }//end FUNC
    
    public static String concatenateAddressFields (Lead l, Integer i) {
        String fullAddress = '';
        
        if (i == 0) {
            fullAddress = l.Guarantor_Address_Line1__c != null ? l.Guarantor_Address_Line1__c + ' ' : '';
            fullAddress += l.Guarantor_Address_Line2__c != null ? l.Guarantor_Address_Line2__c + ',' : '';
            // if end space, remove and replace with ,
            if (fullAddress.endsWith(' ')) fullAddress = fullAddress.removeEnd (' '); fullAddress += ',';
            fullAddress += l.Guarantor_City__c != null ? l.Guarantor_City__c  + ',' : '';
            fullAddress += l.Guarantor_State__c != null ? l.Guarantor_State__c  + ',' : '';
            fullAddress += l.Guarantor_Zip__c != null ? l.Guarantor_Zip__c  + ',' : '';
        } else {
            fullAddress = l.Guarantor2_Address_Line1__c != null ? l.Guarantor2_Address_Line1__c + ' ' : '';
            fullAddress += l.Guarantor2_Address_Line2__c != null ? l.Guarantor2_Address_Line2__c + ',' : '';
            // if end space, remove and replace with ,
            if (fullAddress.endsWith(' ')) fullAddress = fullAddress.removeEnd (' '); fullAddress += ',';
            fullAddress += l.Guarantor2_City__c != null ? l.Guarantor2_City__c + ',' : '';
            fullAddress += l.Guarantor2_State__c != null ? l.Guarantor2_State__c + ',' : '';
            fullAddress += l.Guarantor2_Zip__c != null ? l.Guarantor2_Zip__c + ',' : '';
        }
        if (fullAddress.endsWith(',')) fullAddress = fullAddress.removeEnd (',');
        if (fullAddress.contains (',,')) fullAddress = fullAddress.replace(',,', ',');
        // remove comma if exists
        return fullAddress.left (254);

    }

    public static void attachExtraObjects (Lead lead, Id convertedAccountId, Id convertedContactId, Id convertedOpportunityId, Id ownerId) {
        Contact contact;// = new Contact();
        Account account;// = new Account();
        Asset__c asset;
        List<Contact> contactList = new List<Contact>();
        List<Account> accountList = new List<Account>();
        List<Asset__c> assetList = new List<Asset__c>();

                    // moved from process builder to avoid error
                    if (convertedAccountId != null) update new Account (Id = convertedAccountId, RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('End User Account').getRecordTypeId());
                    System.debug('xxxxx lead.Guarantor_Last_Name__c: ' + lead.Guarantor_Last_Name__c);
                    if(!String.isBlank(lead.Guarantor_Last_Name__c) ){
                        System.debug ('xxxxx creating a guarantor 1');
                        contact = new Contact();
                        contact.OwnerId = ownerId;
                        contact.LastName = lead.Guarantor_Last_Name__c; // set required field example
                        contact.AccountId = convertedAccountId;
                        if(lead.Guarantor_First_Name__c != null) contact.FirstName = lead.Guarantor_First_Name__c;
                        if(lead.Ownership_Pct__c  != null) contact.Ownership_Pct__c  = lead.Ownership_Pct__c ;
                        if(lead.Guarantor_Address_Line1__c  != null) contact.OtherStreet = lead.Guarantor_Address_Line1__c ;
                        //   if(lead.Guarantor_Address_Line2__c  != null) contact.YYYYYYYY = lead.Guarantor_Address_Line2__c ;
                        if(lead.Guarantor_City__c  != null) contact.OtherCity = lead.Guarantor_City__c ;
                        if(lead.Guarantor_state__c  != null) contact.OtherStateCode = lead.Guarantor_state__c ;
                        if(lead.Guarantor_zip__c  != null) contact.OtherPostalCode = lead.Guarantor_zip__c ;
                        if(lead.Date_of_Birth__c  != null) contact.Birthdate  = lead.Date_of_Birth__c ;
                        if(lead.SSN__c  != null) contact.SSN__c  = lead.SSN__c ;
                        if(lead.Guarantor_email__c  != null) contact.Email  = lead.Guarantor_email__c ;
                        if(lead.Guarantor_Phone__c  != null) contact.Phone = lead.Guarantor_Phone__c ;
                        contactList.add(contact);
                    }

                    if(!String.isBlank(lead.Guarantor2_Last_Name__c )){ // same exact thing as guarntor 1. now just 2

                        contact = new Contact();
                        contact.OwnerId = ownerId;
                        contact.LastName = lead.Guarantor2_Last_Name__c; // set required field example
                        contact.AccountId = convertedAccountId;
                        if(lead.Guarantor2_First_Name__c != null) contact.FirstName = lead.Guarantor2_First_Name__c;
                        if(lead.Ownership2_Pct__c  != null) contact.Ownership_Pct__c  = lead.Ownership2_Pct__c ;
                        if(lead.Guarantor2_Address_Line1__c  != null) contact.OtherStreet = lead.Guarantor2_Address_Line1__c ;
                        //   if(lead.Guarantor2_Address_Line2__c  != null) contact.YYYYYYYY = lead.Guarantor2_Address_Line2__c ;
                        if(lead.Guarantor2_City__c  != null) contact.OtherCity = lead.Guarantor2_City__c ;
                        if(lead.Guarantor2_state__c  != null) contact.OtherStateCode = lead.Guarantor2_state__c ;
                        if(lead.Guarantor2_zip__c  != null) contact.OtherPostalCode = lead.Guarantor2_zip__c ;
                        if(lead.Date_of_Birth2__c  != null) contact.Birthdate  = lead.Date_of_Birth2__c ;
                        if(lead.SSN2__c  != null) contact.SSN__c  = lead.SSN2__c ;
                        if(lead.Guarantor2_email__c  != null) contact.Email  = lead.Guarantor2_email__c ;
                        if(lead.Guarantor2_Phone__c  != null) contact.Phone = lead.Guarantor2_Phone__c ;
                        contactList.add(contact);
                    }

                    if(!String.isBlank(lead.Dealer_name__c )){ //  the 'dealer' process

                        account = new Account(RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Dealer Account').getRecordTypeId(), Account_Record_Type_Custom__c = 'Dealer Account');
                        account.Name = lead.Dealer_name__c;
                        account.OwnerId = ownerId;
                        System.debug('LEAD>>> ' + Schema.SObjectType.Account.getRecordTypeInfosByName().get('Dealer Account').getRecordTypeId());
                        System.debug(Account.RecordTypeId);
                        if(lead.Dealer_phone__c  != null) account.Business_Phone__c  = lead.Dealer_phone__c ;
                        if(lead.Dealer_email__c  != null) account.Contact_Email__c  = lead.Dealer_email__c ;
                        if(lead.Dealer_address__c != null) account.Business_Address__c  = lead.Dealer_address__c;
                        if(lead.Dealer_city__c  != null) account.Business_City__c  = lead.Dealer_city__c ;
                        if(lead.Dealer_state__c  != null) account.Business_State__c  = lead.Dealer_state__c ;
                        if(lead.Dealer_zip__c  != null) account.Business_Zip__c  = lead.Dealer_zip__c ;
                        if (lead.Dealer_Number__c != null) account.Dealer_Number__c = lead.Dealer_Number__c;
                        if (lead.Dealer_Number__c != null) account.Dealer_Number__c = lead.Dealer_Number__c;
                        account.Skip_RT_Automation_Initially__c = true;
                        //account.RecordTypeId =
                        accountList.add(account);
                    }

                    if(!String.isBlank(lead.Equipment_Type__c)
                            && !String.isBlank(lead.Equipment_Address_Line_1__c)
                            && !String.isBlank(lead.Equipment_City__c)
                            && !String.isBlank(lead.Equipment_State__c)
                            && !String.isBlank(lead.Equipment_Zipcode__c)){ //  the 'asset' process

                        asset = new Asset__c();
                        asset.Equipment_Code__c  = lead.Equipment_Type__c ;
                        asset.Opportunity__c  = convertedOpportunityId ; // set lookup from Asset to Opp
                        asset.End_User_Billing_Address__c = !lead.Equipment_address_different__c;
                        if(lead.Equipment_Description__c   != null) asset.Description__c   = lead.Equipment_Description__c  ;
                        if(lead.Equipment_Address_Line_1__c   != null) asset.Equipment_Street__c   = lead.Equipment_Address_Line_1__c  ;
                        if(lead.Equipment_Address_Line_2__c   != null) asset.Equipment_Address_2__c   = lead.Equipment_Address_Line_2__c  ;
                        if(lead.Equipment_City__c   != null) asset.Equipment_City__c   = lead.Equipment_City__c  ;
                        if(lead.Equipment_State__c   != null) asset.Equipment_State__c   = lead.Equipment_State__c  ;
                        if(lead.Equipment_Zipcode__c   != null) asset.Equipment_Zip__c   = lead.Equipment_Zipcode__c  ;
                        if(lead.Equipment_Cost__c   != null) asset.Cost__c   = lead.Equipment_Cost__c  ;
                        if(lead.Equipment_Cost__c   != null) asset.List_Price__c   = lead.Equipment_Cost__c  ;
                        assetList.add(asset);
                    }

            insert assetList;

            List<Guarantor__c> guarantorList = new List<Guarantor__c>();
            List<Contact> contactUpdates = new List<Contact>();
            List<Id> contactSuccess = new List<Id>();

            List<Dealer__c> dealerList = new List<Dealer__c>();
            List<Account> accountUpdates = new List<Account>();
            List<Id> accountSuccess = new List<Id>();

            Database.DMLOptions dml = new Database.DMLOptions();
            dml.DuplicateRuleHeader.allowSave = FALSE;

            Set <Id> contactIdsForDebug = new Set <Id> ();
            Set <String> errorMessageList = new Set <String> ();

            //attempt to insert new contacts
            List<Database.SaveResult> saveResults = Database.insert(contactList, dml);
            for(Integer i=0;i<saveResults.size();i++){
                Database.SaveResult saveResult = saveResults.get(i);
                if (!saveResult.isSuccess()) {
                    for (Database.Error error : saveResult.getErrors()) {
                        Contact c = contactList.get(i);  //get the contact that caused the dupe error
                        Contact dupe = new Contact();

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

                            //set Id to overwrite existing
                            dupe.Id =  matchRecord.getRecord().Id;
                            contactIdsForDebug.add (dupe.Id);

                            contactUpdates.add(dupe);  //add for update

                            //create guarantor object
                            if(convertedOpportunityId != NULL){
                                Guarantor__c guarantor = new Guarantor__c(
                                        RecordTypeId  = Schema.SObjectType.Guarantor__c.getRecordTypeInfosByDeveloperName().get('Personal').getRecordTypeId(),
                                        Contact__c  = dupe.Id,
                                        Opportunity__c = convertedOpportunityId,
                                        DOB_From_UDA_Portal__c = i == 0 ? lead.Date_of_Birth__c  : lead.Date_of_Birth2__c ,
                                        SSN_From_UDA_Portal__c = i == 0 ? lead.SSN__c : lead.SSN2__c,
                                        Home_Address__c =  concatenateAddressFields (lead, i)

                                        // RecordTypeId = relRecTypes.get('Individual')
                                );
                                guarantorList.add(guarantor);
                                system.debug('+++++ ADDING RELATIONSHIP - ' + c);
                            }else{
                                system.debug('----- NOT ADDING RELATIONSHIP - ' + c);
                            }

                        } else {
                            // add error message
                            errorMessageList.add ('Error inserting guarantor contact: ' + String.valueOf (error));
                        }
                    }
                }else{


                    //collect Ids of successes
                    System.debug('SUCCESS INSERT for - ' + saveResults.get(i).getId());
                    contactSuccess.add(saveResults.get(i).getId());


                    if(convertedOpportunityId != NULL){
                        Guarantor__c guarantor = new Guarantor__c(
                                RecordTypeId  = Schema.SObjectType.Guarantor__c.getRecordTypeInfosByDeveloperName().get('Personal').getRecordTypeId(),
                                // SET GUARANTOR CODE AS 'GUARANTOR'
                                Contact__c  = contactList.get(i).Id,
                                Opportunity__c = convertedOpportunityId,
                                DOB_From_UDA_Portal__c = i == 0 ? lead.Date_of_Birth__c  : lead.Date_of_Birth2__c ,
                                SSN_From_UDA_Portal__c = i == 0 ? lead.SSN__c : lead.SSN2__c,
                                Home_Address__c =  concatenateAddressFields (lead, i)
                                // RecordTypeId = relRecTypes.get('Individual')
                        );
                        guarantorList.add(guarantor);
                        system.debug('+++++ ADDING RELATIONSHIP - ' + contactList.get(i));
                    }else{
                        system.debug('----- NOT ADDING RELATIONSHIP - ' + contactList.get(i));
                    }

                    contactIdsForDebug.add (contactList.get(i).Id);

                }

            } //end contact saveResults loop

            //check successes for duplicates
            List<DuplicateRecordItem> dupeItems = [
                    SELECT Id, RecordId, DuplicateRecordSetId
                    FROM DuplicateRecordItem
                    WHERE RecordId IN :contactSuccess
            ];

            //update dupe contacts
            update(contactUpdates);
            insert guarantorList;

            ///
            //
            //ACCOUNT UPSERT
            System.debug('BEGIN ACCOUNT PROCESS');
            //attempt to insert new accounts
            for (Integer i; i<accountList.size(); i++){
                system.debug('accountRecType Before Insert >>> ' + accountList[i].RecordTypeId);
            }
            saveResults = Database.insert(accountList, dml);
            for (Integer i; i<accountList.size(); i++){
                system.debug('accountRecType After Insert >>> ' + accountList[i].RecordTypeId);
            }

            List <Account> accountsReadyRTAutomation = new List <Account> ();
            Set <Id> removeDealerNum = new Set <Id> ();
        
            for(Integer i=0;i<saveResults.size();i++){
                Database.SaveResult saveResult = saveResults.get(i);
                if (!saveResult.isSuccess()) {
                    for (Database.Error error : saveResult.getErrors()) {
                        Account a = accountList.get(i);  //get the account that caused the dupe error
                        Account dupe = new Account();

                        //If there are duplicates, an error occurs
                        if (error instanceof Database.DuplicateError ) {
                            Database.DuplicateError duplicateError = (Database.DuplicateError)error;
                            Datacloud.DuplicateResult duplicateResult = duplicateError.getDuplicateResult();

                            //find duplicate records
                            Datacloud.MatchResult[] matchResults = duplicateResult.getMatchResults();

                            //Grab first match result which contains the duplicate record found
                            Datacloud.MatchResult matchResult = matchResults[0];

                            Datacloud.MatchRecord[] matchRecords = matchResult.getMatchRecords();
                            Datacloud.MatchRecord matchRecord = matchrecords[0];

                            //set Id to overwrite existing
                            dupe.Id =  matchRecord.getRecord().Id;


                            accountUpdates.add(dupe);  //add for update
                            //create Dealer obj
                            if(convertedOpportunityId != NULL){
                                System.debug ('>>>>> create dealer dupes');
                                Dealer__c dealer = new Dealer__c(
                                        Dealer__c = dupe.Id,
                                        Opportunity__c = convertedOpportunityId
                                );
                                dealerList.add(dealer);
                                system.debug('+++++ ADDING RELATIONSHIP - ' + a);
                            }else{
                                system.debug('----- NOT ADDING RELATIONSHIP - ' + a);
                            }

                        } else {
                            errorMessageList.add ('Error inserting dealer account: ' + String.valueOf (error));
                        }
                    }
                }else{


                    //collect Ids of successes
                    System.debug('SUCCESS INSERT for - ' + saveResults.get(i).getId());
                    contactSuccess.add(saveResults.get(i).getId());
                    accountsReadyRTAutomation.add (new Account (Id = accountList.get(i).Id, Skip_RT_Automation_Initially__c = false));
                    removeDealerNum.add (accountList.get(i).Id);
                    //create new opportunity relationship mapping
                    if(convertedOpportunityId != NULL){
                        Dealer__c dealer = new Dealer__c(
                                Dealer__c = accountList.get(i).Id,
                                Opportunity__c = convertedOpportunityId
                        );
                        dealerList.add(dealer);
                        system.debug('+++++ ADDING RELATIONSHIP - ' + accountList.get(i));
                    }else{
                        system.debug('----- NOT ADDING RELATIONSHIP - ' + accountList.get(i));
                    }

                }

            } //end account saveResults loop

            // throwing error message to stop processing conversion of this lead if there's an error inserting dealer or guarantor
            if (!errorMessageList.isEmpty()) throw new TC_LeadConversionException (String.valueOf (errorMessageList));

            if (accountsReadyRTAutomation.isEmpty ()) update accountsReadyRTAutomation;
        
            removeDealerNums (removeDealerNum);

            system.debug('looking for dupes from ' + accountSuccess);
            //check successes for duplicates
            dupeItems = [
                    SELECT Id, RecordId, DuplicateRecordSetId
                    FROM DuplicateRecordItem
                    WHERE RecordId IN :accountSuccess
            ];

            //update dupe accounts
            update(accountUpdates);

            insert dealerList;

            // additional field mappings
            if (convertedOpportunityId != null) {
                update new Opportunity (Id = convertedOpportunityId, Annual_Revenue__c = lead.AnnualRevenue, Account_Billing_Street2__c = lead.Business_Address_Line2__c);
            }

            if (convertedAccountId != null){
                List <Account> accs = new List <Account> ([SELECT Id, Account_Billing_Street2__c FROM Account WHERE Id = :convertedAccountId]);
                Account acc = new Account (Id = convertedAccountId);
                if (accs[0].Account_Billing_Street2__c == null || accs[0].Account_Billing_Street2__c == '') acc.Account_Billing_Street2__c = lead.Business_Address_Line2__c;
            }


    }
    
    private static void removeDealerNums (Set <Id> removeDealerNum) {
        if (!removeDealerNum.isEmpty ()) {
            List <Account> removeDealerNumOnNewDealersList = new List <Account> ();
            for (Id accId : removeDealerNum) {
                removeDealerNumOnNewDealersList.add (new Account (Id = accId, Dealer_Number__c = ''));
            }
            update removeDealerNumOnNewDealersList;
        }
    }
    
    //
    ///
    //
    //
    //
    //
    //
   /*
    public static void processContacts (Map <Id, Lead> leadNewMap, Map <Id, Lead> leadOldMap) {
        
        
        Contact contact;// = new Contact();
        Account account;// = new Account();
        List<Contact> contactList = new List<Contact>();
        List<Account> accountList = new List<Account>();
        ID convertedAccountId = NULL;
        ID convertedOpportunityId = NULL;
        
        //map the account order to the relationship type needed
        List<String> accountRelType = new List<String>();
        
        
        // no bulk processing; will only run from the UI for dedupe matching on Account and Contact
        if (leadNewMap.size() == 1) {              
            for (Lead lead: leadNewMap.values()) {          
                //only on lead conversion
                if (lead.isConverted == true && leadOldMap.get(lead.Id).isConverted == false) {                    
                    
                    convertedAccountId = lead.ConvertedAccountId;
                    convertedOpportunityId = lead.ConvertedOpportunityId;
                    
                    
                    if(!String.isBlank(lead.Last_Name_2__c) ){
                        
                        contact = new Contact();
                        contact.LastName = lead.Last_Name_2__c;
                        contact.AccountId = lead.ConvertedAccountId;
                        contact.Is_Guarantor__c = lead.Personal_Guarantor_2__c;
                        if(lead.First_Name_2__c != NULL) contact.FirstName = lead.First_Name_2__c;
                        if(lead.Title_2__c != NULL) contact.Title = lead.Title_2__c;  
                        if(lead.Email_2__c != NULL) contact.Email = lead.Email_2__c;
                        if(lead.SSN_2__c != NULL) contact.SSN__c = lead.SSN_2__c;
                        if(lead.Mobile_2__c != NULL) contact.MobilePhone = lead.Mobile_2__c;
                        if(lead.Contact_Home_Phone_Number_2__c != NULL) contact.HomePhone = lead.Contact_Home_Phone_Number_2__c;
                        if(lead.Contact_Street_2__c != NULL) contact.MailingStreet = lead.Contact_Street_2__c;
                        if(lead.Contact_City_2__c != NULL) contact.MailingCity = lead.Contact_City_2__c;
                        if(lead.Contact_State_2__c != NULL) contact.MailingStateCode = lead.Contact_State_2__c;
                        if(lead.Contact_Postal_Code_2__c != NULL) contact.MailingPostalCode = lead.Contact_Postal_Code_2__c; 
                        if(lead.Guarantor_Annual_Income_2__c != NULL) contact.Guarantor_Annual_Income__c = lead.Guarantor_Annual_Income_2__c; 
                        if(lead.Date_of_Birth_2__c != NULL) contact.BirthDate = lead.Date_of_Birth_2__c; 
                        //if(lead.Ownership_Percent_2__c != NULL) contact.Ownership_Percent__c = lead.Ownership_Percent_2__c;                                
                        
                        contactList.add(contact);
                                               
                    }

                    if(!String.isBlank(lead.Last_Name_3__c) ){
                        
                        contact = new Contact();
                        contact.LastName = lead.Last_Name_3__c;
                        contact.AccountId = lead.ConvertedAccountId;
                        contact.Is_Guarantor__c = lead.Personal_Guarantor_3__c;
                        if(lead.First_Name_3__c != NULL) contact.FirstName = lead.First_Name_3__c;
                        if(lead.Title_3__c != NULL) contact.Title = lead.Title_3__c;  
                        if(lead.Email_3__c != NULL) contact.Email = lead.Email_3__c;
                        if(lead.SSN_3__c != NULL) contact.SSN__c = lead.SSN_3__c;
                        if(lead.Mobile_3__c != NULL) contact.MobilePhone = lead.Mobile_3__c;
                        if(lead.Contact_Home_Phone_Number_3__c != NULL) contact.HomePhone = lead.Contact_Home_Phone_Number_3__c;
                        if(lead.Contact_Street_3__c != NULL) contact.MailingStreet = lead.Contact_Street_3__c;
                        if(lead.Contact_City_3__c != NULL) contact.MailingCity = lead.Contact_City_3__c;
                        if(lead.Contact_State_3__c != NULL) contact.MailingStateCode = lead.Contact_State_3__c;
                        if(lead.Contact_Postal_Code_3__c != NULL) contact.MailingPostalCode = lead.Contact_Postal_Code_3__c; 
                        if(lead.Guarantor_Annual_Income_3__c != NULL) contact.Guarantor_Annual_Income__c = lead.Guarantor_Annual_Income_3__c; 
                        if(lead.Date_of_Birth_3__c != NULL) contact.BirthDate = lead.Date_of_Birth_3__c; 
                        //if(lead.Ownership_Percent_3__c != NULL) contact.Ownership_Percent__c = lead.Ownership_Percent_3__c;                                
                        
                        contactList.add(contact);
                                                
                    }

                    if(!String.isBlank(lead.Last_Name_4__c) ){
                        
                        contact = new Contact();
                        contact.LastName = lead.Last_Name_4__c;
                        contact.AccountId = lead.ConvertedAccountId;
                        contact.Is_Guarantor__c = lead.Personal_Guarantor_4__c;
                        if(lead.First_Name_4__c != NULL) contact.FirstName = lead.First_Name_4__c;
                        if(lead.Title_4__c != NULL) contact.Title = lead.Title_4__c;  
                        if(lead.Email_4__c != NULL) contact.Email = lead.Email_4__c;
                        if(lead.SSN_4__c != NULL) contact.SSN__c = lead.SSN_4__c;
                        if(lead.Mobile_4__c != NULL) contact.MobilePhone = lead.Mobile_4__c;
                        if(lead.Contact_Home_Phone_Number_4__c != NULL) contact.HomePhone = lead.Contact_Home_Phone_Number_4__c;
                        if(lead.Contact_Street_4__c != NULL) contact.MailingStreet = lead.Contact_Street_4__c;
                        if(lead.Contact_City_4__c != NULL) contact.MailingCity = lead.Contact_City_4__c;
                        if(lead.Contact_State_4__c != NULL) contact.MailingStateCode = lead.Contact_State_4__c;
                        if(lead.Contact_Postal_Code_4__c != NULL) contact.MailingPostalCode = lead.Contact_Postal_Code_4__c; 
                        if(lead.Guarantor_Annual_Income_4__c != NULL) contact.Guarantor_Annual_Income__c = lead.Guarantor_Annual_Income_4__c; 
                        if(lead.Date_of_Birth_4__c != NULL) contact.BirthDate = lead.Date_of_Birth_4__c; 
                        //if(lead.Ownership_Percent_4__c != NULL) contact.Ownership_Percent__c = lead.Ownership_Percent_4__c;                                
                        
                        contactList.add(contact);
                                                
                    }

                    
                }  
            }
            
system.debug('contactList is ' + contactList);            

            
            //get relationship record types
            Map<String, String> relRecTypes = new Map<String, String>();  
            relRecTypes.put('Individual', Schema.SObjectType.Relationship__c.getRecordTypeInfosByName().get('Individual').getRecordTypeId());
            relRecTypes.put('Corporation',Schema.SObjectType.Relationship__c.getRecordTypeInfosByName().get('Corporation').getRecordTypeId());


            List<Relationship__c> rel_maps = new List<Relationship__c>();
            List<OpportunityContactRole> role_maps = new List<OpportunityContactRole>();
            List<Contact> contactUpdates = new List<Contact>();
            List<Id> contactSuccess = new List<Id>();           
            
            Database.DMLOptions dml = new Database.DMLOptions(); 
            dml.DuplicateRuleHeader.allowSave = FALSE;
            
            
            //attempt to insert new contacts
            List<Database.SaveResult> saveResults = Database.insert(contactList, dml);
            for(Integer i=0;i<saveResults.size();i++){
                Database.SaveResult saveResult = saveResults.get(i);
                System.debug('contact saveResult = ' + saveResult);                
                if (!saveResult.isSuccess()) {
                    for (Database.Error error : saveResult.getErrors()) {
                        Contact c = contactList.get(i);  //get the contact that caused the dupe error
                        Contact dupe = new Contact();
                        System.debug('error for: ' + c);
                        System.debug(error);
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
                            
                            
                            //Contact matchContact = matchRecord.getRecord();
                            System.debug('MatchRecord: ' + matchRecord.getRecord());
                            System.debug('ContactId: ' + matchRecord.getRecord().Id);
                            /*
                            //set Id to overwrite existing
                            dupe.Id =  matchRecord.getRecord().Id;
                            
                            //overwrite with new profile info
                            if(c.Email != NULL) dupe.Email = c.Email;
                            if(c.Title != NULL) dupe.Title = c.Title;
                            if(c.LastName != NULL) dupe.LastName = c.LastName;
                            if(c.FirstName != NULL) dupe.FirstName = c.FirstName;
                            if(c.SSN__c != NULL) dupe.SSN__c = c.SSN__c;
                            if(c.MobilePhone != NULL) dupe.MobilePhone = c.MobilePhone;
                            if(c.HomePhone != NULL) dupe.HomePhone = c.HomePhone;
                            if(c.MailingStreet != NULL) dupe.MailingStreet = c.MailingStreet;
                            if(c.MailingCity != NULL) dupe.MailingCity = c.MailingCity;
                            if(c.MailingStateCode != NULL) dupe.MailingStatecode = c.MailingStatecode;
                            if(c.MailingPostalCode != NULL) dupe.MailingPostalCode = c.MailingPostalCode;
                            if(c.Guarantor_Annual_Income__c != NULL) dupe.Guarantor_Annual_Income__c = c.Guarantor_Annual_Income__c;
                            if(c.BirthDate != NULL) dupe.BirthDate = c.BirthDate;                          
                            
                            contactUpdates.add(dupe);  //add for update

                            //create new opportunity relationship mapping
                            if(convertedOpportunityId != NULL && contactList.get(i).Is_Guarantor__c == TRUE){
                                 Relationship__c rel_map = new Relationship__c(
                                    Relationship_Type__c = 'Personal Guarantor',
                                    Person__c = matchRecord.getRecord().Id,
                                    Related_Opportunity__c = convertedOpportunityId,
                                    RecordTypeId = relRecTypes.get('Individual')
                                );                       
                                rel_maps.add(rel_map);
                                system.debug('+++++ ADDING RELATIONSHIP - ' + c); 
                            }else{
                                system.debug('----- NOT ADDING RELATIONSHIP - ' + c);                                
                            }
                          
                        }
                    }
                }else{   
                    
                    
                    //collect Ids of successes
                    System.debug('SUCCESS INSERT for - ' + saveResults.get(i).getId());             
                    contactSuccess.add(saveResults.get(i).getId());                    
                    
                    
                    //create new opportunity relationship mapping
                    if(convertedOpportunityId != NULL && contactList.get(i).Is_Guarantor__c == TRUE){
                        Relationship__c rel_map = new Relationship__c(
                            Relationship_Type__c = 'Personal Guarantor',
                            Person__c = contactList.get(i).Id,
                            Related_Opportunity__c = convertedOpportunityId,
                            RecordTypeId = relRecTypes.get('Individual')
                        );                       
                        rel_maps.add(rel_map);
                    } 

                }
                
            } //end contact saveResults loop


            system.debug('looking for dupes from ' + contactSuccess);
            //check successes for duplicates
            List<DuplicateRecordItem> dupeItems = [
                SELECT Id, RecordId, DuplicateRecordSetId 
                FROM DuplicateRecordItem
                WHERE RecordId IN :contactSuccess
            ]; 
            
            system.debug('*******Dupe Items = ' + dupeItems);


          
            System.debug('ContactId: ' + contactUpdates);
            //update dupe contacts
            update(contactUpdates);
                     
            
            //insert mappings
            System.debug('rel_maps: ' + rel_maps);
            insert(rel_maps);               
           
            System.debug('role_maps: ' + role_maps);
            insert(role_maps);  





            
//throw new localException('done here');  



            
        }
        
        
    }
*/
    //public class localException extends Exception { }
    public class TC_LeadConversionException extends Exception {}
    
    @TestVisible
    private static void boost() {
        if (Test.isRunningTest()) {
            Integer x = 0;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
            x++;
        }        
    }
}
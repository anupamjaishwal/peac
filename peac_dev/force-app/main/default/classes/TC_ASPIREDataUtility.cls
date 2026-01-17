/*
* @author : sfdc, Tamarack Consulting, Inc.
* @date : 11/23/2015
* @description: Util class for getting ASPIRE API data. 
*
* © Copyright 2003 - 2015 Tamarack Consulting, Inc.  All Rights Reserved.
* 
*/

public without sharing class TC_ASPIREDataUtility {
    public class TC_ASPIREDataUtilityException extends Exception {}
    
    public static void createASPIREObjectData(String opportunityId) {
        Opportunity opportunitytoSend = [Select Id, Name, AccountId, /*Broker__c, Facility_Lender__c, Salesrep__c, */OwnerId From Opportunity Where Id =: opportunityId];
        List<TC_ASPIRE__Contract__c> contracts = [Select Id From TC_ASPIRE__Contract__c Where TC_ASPIRE__RecordId__c = :opportunityId];
        
        if (contracts.size() > 0)
            throw new TC_ASPIREDataUtilityException('Another ASPIRE API call is currently in progress for this Opportunity.');
        
        List<Broker__c> brokers = [Select Account__c From Broker__c Where Opportunity__c =: opportunityId];
        List<Dealer__c> dealers = [Select Dealer__c From Dealer__c Where Opportunity__c =: opportunityId];
        
        List<TC_ASPIRE__Account__c> accounts = new List<TC_ASPIRE__Account__c>();
        List<TC_ASPIRE__Location__c> locations = new List<TC_ASPIRE__Location__c>();
        Set<String> accountSet = new Set<String>();
        Map<String, Set<String>> customerRoleMap = new Map<String, Set<String>>();
        Map<String, List<TC_ASPIRE__PhoneNumber__c>> customerPhoneMap = new Map<String, List<TC_ASPIRE__PhoneNumber__c>>();
        
        addAccount(opportunitytoSend.AccountId, 'CUST', accountSet, accounts, locations, customerRoleMap, customerPhoneMap);
        //addAccount(opportunitytoSend.Broker__c, 'BROK', accountSet, accounts, locations, customerRoleMap, customerPhoneMap);
        //addAccount(opportunitytoSend.Facility_Lender__c, 'FNDSRC', accountSet, accounts, locations, customerRoleMap, customerPhoneMap);
        addUser(opportunitytoSend.OwnerId, 'SLSREP', accountSet, accounts, locations, customerRoleMap, customerPhoneMap);
        
        for (Broker__c b : brokers)
            addAccount(b.Account__c, 'BROK', accountSet, accounts, locations, customerRoleMap, customerPhoneMap);
        
        for (Dealer__c d : dealers)
            addAccount(d.Dealer__c, 'VEND', accountSet, accounts, locations, customerRoleMap, customerPhoneMap);
        
        List<OpportunityContactRole> contactRoles = [Select ContactId
                                                     From OpportunityContactRole
                                                     Where OpportunityId =: opportunityId];
        
        for (OpportunityContactRole contactRole : contactRoles)
            addContact(contactRole.ContactId, 'CONTACT', accountSet, accounts, locations, customerRoleMap, customerPhoneMap);
        
        List<Guarantor__c> guarantors = [Select Id,
                                         Type__c,
                                         Contact__c,
                                         Account__c
                                         From Guarantor__c
                                         Where Type__c != null
                                         And Opportunity__c =: opportunityId];
        
        for (Guarantor__c guarantor : guarantors) {
            if (guarantor.Contact__c != null && guarantor.Type__c == 'Personal Guarantor')
                addContact(guarantor.Contact__c, 'GUAR', accountSet, accounts, locations, customerRoleMap, customerPhoneMap);
            else if (guarantor.Account__c != null && guarantor.Type__c == 'Corporate Guarantor')
                addAccount(guarantor.Account__c, 'GUAR', accountSet, accounts, locations, customerRoleMap, customerPhoneMap);
        }
        /*
        List<Relationship__c> guarantors = [Select Id,
                                            Relationship_Type__c,
                                            Person__c,
                                            Business__c
                                            From Relationship__c
                                            Where Relationship_Type__c != null
                                            And Related_Opportunity__c =: opportunityId];
        
        for (Relationship__c guarantor : guarantors) {
            String role = (guarantor.Relationship_Type__c == 'Co-Applicant' ? 'CUST' : 'GUAR');
            
            if (guarantor.Person__c != null && guarantor.Relationship_Type__c == 'Co-Applicant')
                addContact(guarantor.Person__c, role, accountSet, accounts, locations, customerRoleMap, customerPhoneMap);
            else if (guarantor.Business__c != null && guarantor.Relationship_Type__c == 'Co-Applicant')
                addAccount(guarantor.Business__c, role, accountSet, accounts, locations, customerRoleMap, customerPhoneMap);
            else
                addGuarantor(guarantor.Id, guarantor.Relationship_Type__c, role, accountSet, accounts, locations, customerRoleMap, customerPhoneMap);
        }
        
        List<Equipment__c> equipment = [Select Vendor__c
                                        From Equipment__c
                                        Where Opportunity__c =: opportunityId];
        */
        List<TC_ASPIRE__Asset__c> assets = new List<TC_ASPIRE__Asset__c>();
        List<TC_ASPIRE__ContractAsset__c> contractAssets = new List<TC_ASPIRE__ContractAsset__c>();
        List<TC_ASPIRE__Status__c> statuses = new List<TC_ASPIRE__Status__c>();
        Map<String, List<TC_ASPIRE__AssetSerialNumber__c>> assetSerialNumberMap = new Map<String, List<TC_ASPIRE__AssetSerialNumber__c>>();
        /*
        for (Equipment__c item : equipment) {
            addAccount(item.Vendor__c, 'VEND', accountSet, accounts, locations, customerRoleMap, customerPhoneMap);
            addAsset(item.Id, assets, contractAssets, locations, statuses, assetSerialNumberMap);
        }
        */
        Map<String, TC_ASPIRE__SerialNumber__c> serialNumberMap = new Map<String, TC_ASPIRE__SerialNumber__c>();
        List<TC_ASPIRE__Location__c> locationsFiltered = new List<TC_ASPIRE__Location__c>();
        Set<String> locationsSet = new Set<String>();
        
        for (TC_ASPIRE__Location__c location : locations) {
            if (!locationsSet.contains(location.TC_ASPIRE__RecordId__c)) {
                locationsSet.add(location.TC_ASPIRE__RecordId__c);
                locationsFiltered.add(location);
            }
        }
        
        insert locationsFiltered;
        Map<String, Id> locationsMap = new Map<String, Id>();
        
        for (TC_ASPIRE__Location__c location : locationsFiltered) {
            locationsMap.put(location.TC_ASPIRE__RecordId__c, location.Id);
        }
        
        for (TC_ASPIRE__Account__c account : accounts) {
            if (locationsMap.get(account.TC_ASPIRE__RecordId__c + 'Location') != null)
                account.put('TC_ASPIRE__LocationRecordId__c', locationsMap.get(account.TC_ASPIRE__RecordId__c + 'Location'));
            else {
                account.put('TC_ASPIRE__LocationRecordId__c', locationsMap.get(account.TC_ASPIRE__RecordId__c + 'Shipping'));
                account.put('TC_ASPIRE__BillToLocationRecordId__c', locationsMap.get(account.TC_ASPIRE__RecordId__c + 'Billing'));
            }
        }
        
        insert accounts;
        insert statuses;
        Integer i = 0;
        
        for (TC_ASPIRE__Asset__c asset : assets) {
            if (statuses[i].TC_ASPIRE__Name__c != 'SKIP') asset.put('TC_ASPIRE__TitleStatus__c', statuses[i].Id); i++;
        }
        
        insert assets;
        
        List<TC_ASPIRE__Role__c> roles = new List<TC_ASPIRE__Role__c>();
        List<TC_ASPIRE__PhoneNumber__c> phoneNumbers = new List<TC_ASPIRE__PhoneNumber__c>();
        
        for (TC_ASPIRE__Account__c account : accounts) {
            Set<String> roleSet = customerRoleMap.get(account.TC_ASPIRE__RecordId__c);
            
            for (String role : roleSet)
                roles.add(new TC_ASPIRE__Role__c(TC_ASPIRE__Account__c = account.Id,
                                                 TC_ASPIRE__RoleType__c = role,
                                                 TC_ASPIRE__Description__c = (role == 'GUAR' ? 'Guarantor' :
                                                         role == 'VEND' ? 'Vendor' :
                                                                 role == 'CUST' ? 'Customer' :
                                                                         role == 'BROK' ? 'Broker' :
                                                                                 role == 'FNDSRC' ? 'Funding Source' :
                                                                                         role == 'SLSREP' ? 'Sales Rep' :
                                                                                                 role == 'CONTACT' ? 'Contact' : null)));
            
            List<TC_ASPIRE__PhoneNumber__c> phoneNumberList = customerPhoneMap.get(account.TC_ASPIRE__RecordId__c);
            
            if (phoneNumberList != null) {
                for (TC_ASPIRE__PhoneNumber__c phoneNumber: phoneNumberList) {
                    phoneNumber.TC_ASPIRE__Account__c = account.Id;
                    phoneNumbers.add(phoneNumber);
                }
            }
        }
        
        insert roles;
        insert phoneNumbers;
        
        List<TC_ASPIRE__AssetSerialNumber__c> assetSerialNumbers = new List<TC_ASPIRE__AssetSerialNumber__c>();
        
        for (TC_ASPIRE__Asset__c asset : assets) {
            List<TC_ASPIRE__AssetSerialNumber__c> serialNumbers = assetSerialNumberMap.get(asset.TC_ASPIRE__RecordId__c);
            
            for (TC_ASPIRE__AssetSerialNumber__c serialNumber : serialNumbers) {
                serialNumber.TC_ASPIRE__Asset__c = asset.Id;
                assetSerialNumbers.add(serialNumber);
            }
        }
        
        insert assetSerialNumbers;
        
        TC_ContractMapping contractMapping = new TC_ContractMapping(opportunitytoSend.Id);
        contractMapping.createASPIRERecord();
        
        TC_BankMapping bankMapping = new TC_BankMapping(opportunitytoSend.Id);
        bankMapping.createASPIRERecord();
        
        if (String.isNotEmpty(((TC_ASPIRE__Bank__c) bankMapping.aspireRecord).TC_ASPIRE__Name__c)) {
            insert bankMapping.aspireRecord;
        
            if (bankMapping.bankAccount != null) insert bankMapping.bankAccount;
        }
        
        List<TC_ASPIRE__RelatedAccount__c> relatedAccounts = new List<TC_ASPIRE__RelatedAccount__c>();
        
        for (TC_ASPIRE__Role__c role : roles) {
            if (role.TC_ASPIRE__RoleType__c != 'CUST') relatedAccounts.add(new TC_ASPIRE__RelatedAccount__c(TC_ASPIRE__ContractId__c = contractMapping.aspireRecord.Id,TC_ASPIRE__EntityId__c = role.TC_ASPIRE__Account__c,TC_ASPIRE__Role__c = role.Id,TC_ASPIRE__IsPrimary__c = (role.TC_ASPIRE__RoleType__c == 'SLSREP'),TC_ASPIRE__RecordId__c = (String) contractMapping.aspireRecord.Id + role.TC_ASPIRE__Account__c + role.TC_ASPIRE__RoleType__c));
        }
        
        insert relatedAccounts;
        
        for (TC_ASPIRE__ContractAsset__c contractAsset : contractAssets) {
            contractAsset.TC_ASPIRE__ContractId__c = contractMapping.aspireRecord.Id;
            contractAsset.put('TC_ASPIRE__LocationId__c', locationsMap.get(contractAsset.TC_ASPIRE__RecordId__c + 'Location'));
            contractAsset.put('TC_ASPIRE__BillToLocationId__c', accounts[0].TC_ASPIRE__BillToLocationRecordId__c);
        }
        
        insert contractAssets;
        
        List<TC_ASPIRE__SerialNumber__c> serialNumbers = new List<TC_ASPIRE__SerialNumber__c>();
        
        for (TC_ASPIRE__ContractAsset__c contractAsset : contractAssets) {
            TC_ASPIRE__SerialNumber__c serialNumber = serialNumberMap.get(contractAsset.TC_ASPIRE__RecordId__c);
            if (serialNumber != null) {
                serialNumber.TC_ASPIRE__ContractAsset__c = contractAsset.Id;
                serialNumbers.add(serialNumber);
            }
        }
        
        insert serialNumbers;
    }
    
    private static void addAccount(Id salesforceId, String role, Set<String> accountSet, List<TC_ASPIRE__Account__c> accounts, List<TC_ASPIRE__Location__c> locations, Map<String, Set<String>> customerRoleMap, Map<String, List<TC_ASPIRE__PhoneNumber__c>> customerPhoneMap) {
        if (salesforceId != null) {
            TC_AccountMapping accountMapping = new TC_AccountMapping(salesforceId);
            accountMapping.createASPIRERecord();
            String accountId = ((TC_ASPIRE__Account__c) accountMapping.aspireRecord).TC_ASPIRE__RecordId__c;
            
            if (!accountSet.contains(accountId)) {
                accounts.add((TC_ASPIRE__Account__c) accountMapping.aspireRecord);
                locations.addAll(accountMapping.locations);
                if (accountMapping.phoneNumbers != null)
                    customerPhoneMap.put(accountId, accountMapping.phoneNumbers);
                accountSet.add(accountId);
            }
            
            addToCustomerRoleMap(customerRoleMap, accountId, role);
        }
    }
    
    private static void addUser(Id salesforceId, String role, Set<String> accountSet, List<TC_ASPIRE__Account__c> accounts, List<TC_ASPIRE__Location__c> locations, Map<String, Set<String>> customerRoleMap, Map<String, List<TC_ASPIRE__PhoneNumber__c>> customerPhoneMap) {
        if (salesforceId != null) {
            TC_UserMapping userMapping = new TC_UserMapping(salesforceId);
            userMapping.createASPIRERecord();
            String accountId = ((TC_ASPIRE__Account__c) userMapping.aspireRecord).TC_ASPIRE__RecordId__c;
            
            if (!accountSet.contains(accountId)) {
                accounts.add((TC_ASPIRE__Account__c) userMapping.aspireRecord);
                locations.addAll(userMapping.locations);
                if (userMapping.phoneNumbers != null)
                    customerPhoneMap.put(accountId, userMapping.phoneNumbers);
                accountSet.add(accountId);
            }
            
            addToCustomerRoleMap(customerRoleMap, accountId, role);
        }
    }
    
    private static void addContact(Id salesforceId, String role, Set<String> accountSet, List<TC_ASPIRE__Account__c> accounts, List<TC_ASPIRE__Location__c> locations, Map<String, Set<String>> customerRoleMap, Map<String, List<TC_ASPIRE__PhoneNumber__c>> customerPhoneMap) {
        if (salesforceId != null) {
            TC_ContactMapping contactMapping = new TC_ContactMapping(salesforceId);
            contactMapping.createASPIRERecord();
            String accountId = ((TC_ASPIRE__Account__c) contactMapping.aspireRecord).TC_ASPIRE__RecordId__c;
            
            if (!accountSet.contains(accountId)) {
                accounts.add((TC_ASPIRE__Account__c) contactMapping.aspireRecord);
                locations.addAll(contactMapping.locations);
                if (contactMapping.phoneNumbers != null)
                    customerPhoneMap.put(accountId, contactMapping.phoneNumbers);
                accountSet.add(accountId);
            }
            
            addToCustomerRoleMap(customerRoleMap, accountId, role);
        }
    }
    /*
    private static void addGuarantor(Id salesforceId, String type, String role, Set<String> accountSet, List<TC_ASPIRE__Account__c> accounts, List<TC_ASPIRE__Location__c> locations, Map<String, Set<String>> customerRoleMap, Map<String, List<TC_ASPIRE__PhoneNumber__c>> customerPhoneMap) {
        if (salesforceId != null) {
            TC_GuarantorMapping guarantorMapping = new TC_GuarantorMapping(salesforceId, type);
            guarantorMapping.createASPIRERecord();
            String accountId = ((TC_ASPIRE__Account__c) guarantorMapping.aspireRecord).TC_ASPIRE__RecordId__c;
            TC_ASPIRE.ASPIREAccount guarantorAccount;
            
            if (!accountSet.contains(accountId)) { 
                accounts.add((TC_ASPIRE__Account__c) guarantorMapping.aspireRecord);
                locations.addAll(guarantorMapping.locations);
                if (guarantorMapping.phoneNumbers != null)
                    customerPhoneMap.put(accountId, guarantorMapping.phoneNumbers);
                accountSet.add(accountId); 
            }
            
            addToCustomerRoleMap(customerRoleMap, accountId, role);
        }
    }
    
    private static void addAsset(Id salesforceId, List<TC_ASPIRE__Asset__c> assets, List<TC_ASPIRE__ContractAsset__c> contractAssets, List<TC_ASPIRE__Location__c> locations, List<TC_ASPIRE__Status__c> statuses, Map<String, List<TC_ASPIRE__AssetSerialNumber__c>> assetSerialNumberMap) {
        if (salesforceId != null) {
            TC_AssetMapping assetMapping = new TC_AssetMapping(salesforceId);
            assetMapping.createASPIRERecord();
            assets.add((TC_ASPIRE__Asset__c) assetMapping.aspireRecord);
            locations.addAll(assetMapping.locations);
            if (assetMapping.TitleStatus != null)
                statuses.add(assetMapping.TitleStatus);
            
            assetSerialNumberMap.put(((TC_ASPIRE__Asset__c) assetMapping.aspireRecord).TC_ASPIRE__RecordId__c, assetMapping.serialNumbers);
            
            TC_ContractAssetMapping contractAssetMapping = new TC_ContractAssetMapping(salesforceId);
            contractAssetMapping.createASPIRERecord();
            contractAssets.add((TC_ASPIRE__ContractAsset__c) contractAssetMapping.aspireRecord);
            locations.addAll(contractAssetMapping.locations);
        }
    }
    */
    private static void addToCustomerRoleMap(Map<String, Set<String>> customerRoleMap, String accountId, String role) {
        Set<String> roleSet = customerRoleMap.get(accountId);
        
        if (roleSet == null) {
            roleSet = new Set<String>();
            customerRoleMap.put(accountId, roleSet);
        }
        
        roleSet.add(role);
    }
    
    public static Map<String, Object> selectASPIREObjectData(String opportunityId) {
        Opportunity oppToSend = [Select Id,
                                 Contract__c
                                 From Opportunity
                                 Where Id = :opportunityId
                                 Limit 1];
        
        List<TC_ASPIRE__Contract__c> contracts = [Select Id,
                                                  TC_ASPIRE__RecordId__c,
                                                  TC_ASPIRE__CustomerRecordId__c,
                                                  TC_ASPIRE__Loan__c,
                                                  TC_ASPIRE__Lease__c,
                                                  (Select TC_ASPIRE__EntityId__c, TC_ASPIRE__Role__c from TC_ASPIRE__RelatedAccounts__r),
                                                  (Select Id, TC_ASPIRE__LocationId__c from TC_ASPIRE__ContractAssets__r),
                                                  TC_ASPIRE__BillToLocationRecordId__c
                                                  From TC_ASPIRE__Contract__c
                                                  Where TC_ASPIRE__RecordId__c Like :opportunityId + '%'
                                                  Or TC_ASPIRE__RecordId__c = :oppToSend.Contract__c];
        
        List<TC_ASPIRE__ContractAsset__c> contractAssets = new List<TC_ASPIRE__ContractAsset__c>();
        List<String> accountIds = new List<String>();
        List<String> roleIds = new List<String>();
        List<String> locationIds = new List<String>();
        TC_ASPIRE__Contract__c contract = new TC_ASPIRE__Contract__c();
        
        if (contracts.size() > 0) {
            contract = contracts[0];
            contractAssets = contract.TC_ASPIRE__ContractAssets__r;
            accountIds.add(contract.TC_ASPIRE__CustomerRecordId__c);
            
            for (TC_ASPIRE__RelatedAccount__c relatedAccount : contract.TC_ASPIRE__RelatedAccounts__r) {
                accountIds.add(relatedAccount.TC_ASPIRE__EntityId__c);
                roleIds.add(relatedAccount.TC_ASPIRE__Role__c);
            }
            
            locationIds.add(contract.TC_ASPIRE__BillToLocationRecordId__c);
        }
        
        List<TC_ASPIRE__Account__c> accounts = [Select Id, TC_ASPIRE__LocationRecordId__c, TC_ASPIRE__BillToLocationRecordId__c From TC_ASPIRE__Account__c Where Id In :accountIds];
        List<TC_ASPIRE__Role__c> roles = [Select Id From TC_ASPIRE__Role__c Where Id In :roleIds];
        
        for (TC_ASPIRE__ContractAsset__c contractAsset : contractAssets) {
            locationIds.add(contractAsset.TC_ASPIRE__LocationId__c);
        }
        
        for (TC_ASPIRE__Account__c account : accounts) {
            locationIds.add(account.TC_ASPIRE__LocationRecordId__c);
            locationIds.add(account.TC_ASPIRE__BillToLocationRecordId__c);
        }
        
        List<TC_ASPIRE__Location__c> locations = [Select Id From TC_ASPIRE__Location__c Where Id In :locationIds];
        
        List<TC_ASPIRE__Asset__c> assets = [Select Id, TC_ASPIRE__LocationEntityRecordId__c From TC_ASPIRE__Asset__c];
        
        List<String> locationRecordIds = new List<String>();
        for (TC_ASPIRE__Asset__c asset : assets)
            locationRecordIds.add(asset.TC_ASPIRE__LocationEntityRecordId__c);
        
        List<TC_ASPIRE__Location__c> assetLocations = [Select Id From TC_ASPIRE__Location__c Where TC_ASPIRE__RecordId__c In :locationRecordIds];
        locations.addAll(assetLocations);
        
        List<TC_ASPIRE__Bank__c> banks = [Select Id From TC_ASPIRE__Bank__c Where TC_ASPIRE__RecordId__c = :(contract.TC_ASPIRE__RecordId__c + 'Bank')];
        List<TC_ASPIRE__Bank_Account__c> bankAccounts = [Select Id From TC_ASPIRE__Bank_Account__c Where TC_ASPIRE__RecordId__c = :(contract.TC_ASPIRE__RecordId__c + 'BankAccount')];
        
        Map<String, Object> objectMap = new Map<String, Object>();
        objectMap.put('accounts', accounts);
        objectMap.put('roles', roles);
        objectMap.put('locations', locations);
        objectMap.put('contractAssets', contractAssets);
        objectMap.put('contracts', contracts);
        objectMap.put('assets', assets);
        objectMap.put('banks', banks);
        objectMap.put('bankAccounts', bankAccounts);
        
        return objectMap;
    }
    
    public static void deleteASPIREObjectData(Map<String, Object> objectMap) {
        List<TC_ASPIRE__Contract__c> contracts = (List<TC_ASPIRE__Contract__c>) objectMap.get('contracts');
        
        if (contracts != null && contracts.size() > 0) {
            TC_ASPIRE__Contract__c contract = contracts[0];
            delete [Select Id From TC_ASPIRE__Payment__c Where TC_ASPIRE__LoanEconomics__c = :contract.TC_ASPIRE__Loan__c];
            delete [Select Id From TC_ASPIRE__LoanEconomics__c Where Id = :contract.TC_ASPIRE__Loan__c];
            //delete [Select Id From TC_ASPIRE__LeaseEconomics__c Where Id = :contract.TC_ASPIRE__Lease__c];
            delete contract;
        }
        
        if (objectMap.get('accounts') != null)
            delete (List<TC_ASPIRE__Account__c>) objectMap.get('accounts');
        
        if (objectMap.get('roles') != null)
            delete (List<TC_ASPIRE__Role__c>) objectMap.get('roles');
        
        if (objectMap.get('locations') != null)
            delete (List<TC_ASPIRE__Location__c>) objectMap.get('locations');
        
        if (objectMap.get('assets') != null)
            delete (List<TC_ASPIRE__Asset__c>) objectMap.get('assets');
        
        if (objectMap.get('banks') != null)
            delete (List<TC_ASPIRE__Bank__c>) objectMap.get('banks');
        
        if (objectMap.get('bankAccounts') != null)
            delete (List<TC_ASPIRE__Bank_Account__c>) objectMap.get('bankAccounts');
    }
}
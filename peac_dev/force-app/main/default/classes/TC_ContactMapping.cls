/**
* @author : sfdc, Tamarack Consulting, Inc.
* @date : 9/6/2016
* @description: Class for mapping ASPIRE API contacts.
*
* © Copyright 2003 - 2016 Tamarack Consulting, Inc.  All Rights Reserved.
* 
*/

public virtual class TC_ContactMapping extends TC_ASPIRE.Mapping {
    public List<TC_ASPIRE__PhoneNumber__c> phoneNumbers = new List<TC_ASPIRE__PhoneNumber__c>();
    public List<TC_ASPIRE__Location__c> locations = new List<TC_ASPIRE__Location__c>();
    private String recordId = '';
    
    public TC_ContactMapping(Id salesforceId) {
        this.salesforceId = salesforceId;
        this.aspireName = 'TC_ASPIRE__Account__c';
        this.salesforceName = 'Contact';
    }
    
    public virtual override void addMappingFields() {
        // TC_ASPIRE.FieldMapping(aspireName, salesforceName)
        //fieldList.add(new TC_ASPIRE.FieldMapping('', 'External_Id__c'));
        fieldList.add(new TC_ASPIRE.FieldMapping('TC_ASPIRE__FirstName__c', 'FirstName'));
        fieldList.add(new TC_ASPIRE.FieldMapping('TC_ASPIRE__LastName__c', 'LastName'));
        //fieldList.add(new TC_ASPIRE.FieldMapping('TC_ASPIRE__Salutation__c', 'Salutation'));
        //fieldList.add(new TC_ASPIRE.FieldMapping('TC_ASPIRE__Title__c', 'Title'));
        fieldList.add(new TC_ASPIRE.FieldMapping('TC_ASPIRE__Department__c', 'Department'));
        fieldList.add(new TC_ASPIRE.FieldMapping('', 'Phone'));
        fieldList.add(new TC_ASPIRE.FieldMapping('', 'MobilePhone'));
        fieldList.add(new TC_ASPIRE.FieldMapping('', 'HomePhone'));
        fieldList.add(new TC_ASPIRE.FieldMapping('TC_ASPIRE__Email__c', 'Email'));
        fieldList.add(new TC_ASPIRE.FieldMapping('TC_ASPIRE__LegalName__c', 'Name'));
        fieldList.add(new TC_ASPIRE.FieldMapping('TC_ASPIRE__FederalIdentificationNumber__c', 'SSN__c'));
        fieldList.add(new TC_ASPIRE.FieldMapping('', 'MailingStreet'));
        fieldList.add(new TC_ASPIRE.FieldMapping('', 'MailingCity'));
        fieldList.add(new TC_ASPIRE.FieldMapping('', 'MailingStateCode'));
        fieldList.add(new TC_ASPIRE.FieldMapping('', 'MailingPostalCode'));
        fieldList.add(new TC_ASPIRE.FieldMapping('', 'MailingCountryCode'));
        fieldList.add(new TC_ASPIRE.FieldMapping('', 'OtherStreet'));
        fieldList.add(new TC_ASPIRE.FieldMapping('', 'OtherCity'));
        fieldList.add(new TC_ASPIRE.FieldMapping('', 'OtherStateCode'));
        fieldList.add(new TC_ASPIRE.FieldMapping('', 'OtherPostalCode'));
        fieldList.add(new TC_ASPIRE.FieldMapping('', 'OtherCountryCode'));
        fieldList.add(new TC_ASPIRE.FieldMapping('TC_ASPIRE__PercentOwnership__c', 'Ownership_Pct__c'));
        fieldList.add(new TC_ASPIRE.FieldMapping('TC_ASPIRE__DateOfBirth__c', 'Birthdate'));
    }
    
    public virtual override void addOtherFields(sObject aspireRecord) {
        // Action = "6" for create/update
        aspireRecord.put('TC_ASPIRE__Action__c', '6');
        aspireRecord.put('TC_ASPIRE__AccountType__c', 'Individual');
        
        //recordId = ((Contact) salesforceRecord).External_Id__c;
        recordId = ((Contact) salesforceRecord).SSN__c;
        recordId = (String.isNotEmpty(recordId) ? recordId : (String) salesforceRecord.Id);
        aspireRecord.put('TC_ASPIRE__RecordId__c', recordId.left(15));
        aspireRecord.put('TC_ASPIRE__AccountId__c', recordId.left(15));
    }
    
    public virtual override void addChildrenRecords(sObject aspireRecord) {
        TC_ASPIRE__PhoneNumber__c phoneNumber;
        String phone = ((Contact) salesforceRecord).MobilePhone;
        
        if (String.isNotEmpty(phone)) {
            phoneNumber = new TC_ASPIRE__PhoneNumber__c(TC_ASPIRE__Account__c = aspireRecord.Id,
                                                        TC_ASPIRE__PhoneNumberType__c = 'Mobile',
                                                        TC_ASPIRE__Number__c = phone);
            phoneNumbers.add(phoneNumber);
        }
        
        phone = ((Contact) salesforceRecord).HomePhone;
        
        if (String.isNotEmpty(phone)) {
            phoneNumber = new TC_ASPIRE__PhoneNumber__c(TC_ASPIRE__Account__c = aspireRecord.Id,
                                                        TC_ASPIRE__PhoneNumberType__c = 'Home',
                                                        TC_ASPIRE__Number__c = phone);
            phoneNumbers.add(phoneNumber);
        }
        
        phone = ((Contact) salesforceRecord).Phone;
        
        if (String.isNotEmpty(phone)) {
            phoneNumber = new TC_ASPIRE__PhoneNumber__c(TC_ASPIRE__Account__c = aspireRecord.Id,
                                                        TC_ASPIRE__PhoneNumberType__c = 'Main',
                                                        TC_ASPIRE__Number__c = phone);
            phoneNumbers.add(phoneNumber);
        }
    }
    
    public virtual override void addLookupRecords(sObject aspireRecord) {
        addLocation('Mailing');
        addLocation('Other');
    }
    
    protected void addLocation(String addressType) {
        String country = (String) salesforceRecord.get(addressType + 'CountryCode');
        if (country == 'US' || country == 'United States')
            country = 'USA';
        
        TC_ASPIRE__Location__c location = new TC_ASPIRE__Location__c(TC_ASPIRE__EntityRecordId__c = recordId,
                                                                     TC_ASPIRE__RecordId__c = recordId + (addressType == 'Mailing' ? 'Shipping' : 'Billing'),
                                                                     TC_ASPIRE__Action__c = '6',
                                                                     TC_ASPIRE__Address1__c = (String) salesforceRecord.get(addressType + 'Street'),
                                                                     TC_ASPIRE__City__c = (String) salesforceRecord.get(addressType + 'City'),
                                                                     TC_ASPIRE__State__c = (String) salesforceRecord.get(addressType + 'StateCode'),
                                                                     TC_ASPIRE__PostalCode__c = (String) salesforceRecord.get(addressType + 'PostalCode'),
                                                                     TC_ASPIRE__Country__c = country,
                                                                     TC_ASPIRE__IsActive__c = True
                                                                    );
        
        if (String.isNotEmpty(location.TC_ASPIRE__Address1__c))
            locations.add(location);
    }
}
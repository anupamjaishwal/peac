/**
* @author : sfdc, Tamarack Consulting, Inc.
* @date : 12/14/2016
* @description: Class for mapping ASPIRE API users.
*
* © Copyright 2003 - 2016 Tamarack Consulting, Inc.  All Rights Reserved.
* 
*/

public virtual class TC_UserMapping extends TC_ASPIRE.Mapping {
    public List<TC_ASPIRE__PhoneNumber__c> phoneNumbers = new List<TC_ASPIRE__PhoneNumber__c>();
    public List<TC_ASPIRE__Location__c> locations = new List<TC_ASPIRE__Location__c>();
    private String recordId = '';
    
    public TC_UserMapping(Id salesforceId) {
        this.salesforceId = salesforceId;
        this.aspireName = 'TC_ASPIRE__Account__c';
        this.salesforceName = 'User';
    }
    
    public virtual override void addMappingFields() {
        // TC_ASPIRE.FieldMapping(aspireName, salesforceName)
        //fieldList.add(new TC_ASPIRE.FieldMapping('', 'External_Id__c'));
        fieldList.add(new TC_ASPIRE.FieldMapping('TC_ASPIRE__FirstName__c', 'FirstName'));
        fieldList.add(new TC_ASPIRE.FieldMapping('TC_ASPIRE__LastName__c', 'LastName'));
        fieldList.add(new TC_ASPIRE.FieldMapping('TC_ASPIRE__Department__c', 'Department'));
        fieldList.add(new TC_ASPIRE.FieldMapping('', 'Phone'));
        fieldList.add(new TC_ASPIRE.FieldMapping('', 'Street'));
        fieldList.add(new TC_ASPIRE.FieldMapping('', 'City'));
        fieldList.add(new TC_ASPIRE.FieldMapping('', 'StateCode'));
        fieldList.add(new TC_ASPIRE.FieldMapping('', 'PostalCode'));
        fieldList.add(new TC_ASPIRE.FieldMapping('', 'CountryCode'));
        fieldList.add(new TC_ASPIRE.FieldMapping('TC_ASPIRE__Email__c', 'Email'));
        //fieldList.add(new TC_ASPIRE.FieldMapping('TC_ASPIRE__Title__c', 'Title'));
    }
    
    public virtual override void addOtherFields(sObject aspireRecord) {
        // Action = "6" for create/update
        aspireRecord.put('TC_ASPIRE__Action__c', '6');
        aspireRecord.put('TC_ASPIRE__AccountType__c', 'Individual');
        
        //recordId = ((User) salesforceRecord).External_Id__c;
        recordId = (String.isNotEmpty(recordId) ? recordId : (String) salesforceRecord.Id);
        aspireRecord.put('TC_ASPIRE__RecordId__c', recordId.left(15));
        aspireRecord.put('TC_ASPIRE__AccountId__c', recordId.left(15));
    }
    
    public virtual override void addChildrenRecords(sObject aspireRecord) {
        TC_ASPIRE__PhoneNumber__c phoneNumber;
        String phone = ((User) salesforceRecord).Phone;
        
        if (String.isNotEmpty(phone)) {
            phoneNumber = new TC_ASPIRE__PhoneNumber__c(TC_ASPIRE__Account__c = aspireRecord.Id,
                                                        TC_ASPIRE__PhoneNumberType__c = 'Main',
                                                        TC_ASPIRE__Number__c = phone);
            phoneNumbers.add(phoneNumber);
        }
    }
    
    public virtual override void addLookupRecords(sObject aspireRecord) {
        addLocation('');
    }
    
    protected void addLocation(String addressType) {
        String country = (String) salesforceRecord.get(addressType + 'CountryCode');
        if (country == 'US' || country == 'United States')
            country = 'USA';
        
        TC_ASPIRE__Location__c location = new TC_ASPIRE__Location__c(TC_ASPIRE__EntityRecordId__c = recordId,
                                                                     TC_ASPIRE__RecordId__c = recordId + 'Location',
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
/**
* @author : sfdc, Tamarack Consulting, Inc.
* @date : 11/23/2015
* @description: Class for mapping ASPIRE API accounts.
*
* © Copyright 2003 - 2015 Tamarack Consulting, Inc.  All Rights Reserved.
* 
*/

public virtual class TC_AccountMapping extends TC_ASPIRE.Mapping {
    public List<TC_ASPIRE__PhoneNumber__c> phoneNumbers = new List<TC_ASPIRE__PhoneNumber__c>();
    public List<TC_ASPIRE__Location__c> locations = new List<TC_ASPIRE__Location__c>();
    private String recordId = '';
    
    public TC_AccountMapping(Id salesforceId) {
        this.salesforceId = salesforceId;
        this.aspireName = 'TC_ASPIRE__Account__c';
        this.salesforceName = 'Account';
    }
    
    public virtual override void addMappingFields() {
        // TC_ASPIRE.FieldMapping(aspireName, salesforceName)
        //fieldList.add(new TC_ASPIRE.FieldMapping('TC_ASPIRE__RecordId__c', 'External_Id__c'));
        fieldList.add(new TC_ASPIRE.FieldMapping('TC_ASPIRE__RecordId__c', 'CCID__c'));
        fieldList.add(new TC_ASPIRE.FieldMapping('TC_ASPIRE__Name__c', 'Name'));
        //fieldList.add(new TC_ASPIRE.FieldMapping('', 'Phone'));
        fieldList.add(new TC_ASPIRE.FieldMapping('TC_ASPIRE__LegalName__c', 'Name'));
        fieldList.add(new TC_ASPIRE.FieldMapping('TC_ASPIRE__DoingBusinessAs__c', 'DBA__c'));
        //fieldList.add(new TC_ASPIRE.FieldMapping('TC_ASPIRE__Email__c', 'Company_Email__c'));
       	//fieldList.add(new TC_ASPIRE.FieldMapping('TC_ASPIRE__FederalIdentificationNumber__c', 'Fed_Tax_ID__c'));
       	fieldList.add(new TC_ASPIRE.FieldMapping('TC_ASPIRE__FederalIdentificationNumber__c', 'Tax_ID__c'));
        //fieldList.add(new TC_ASPIRE.FieldMapping('', 'Company_Type__c'));
        //fieldList.add(new TC_ASPIRE.FieldMapping('TC_ASPIRE__StateOfIncorporation__c', 'State_of_Incorporation__c'));
        fieldList.add(new TC_ASPIRE.FieldMapping('TC_ASPIRE__StateOfIncorporation__c', 'Account_State_Of_Incorporation__c'));
        //fieldList.add(new TC_ASPIRE.FieldMapping('TC_ASPIRE__EstablishedDate__c', 'Inception_Date__c'));
        fieldList.add(new TC_ASPIRE.FieldMapping('TC_ASPIRE__EstablishedDate__c', 'Account_Business_Start_Date__c'));
        //fieldList.add(new TC_ASPIRE.FieldMapping('', 'ShippingStreet'));
        //fieldList.add(new TC_ASPIRE.FieldMapping('', 'ShippingCity'));
        //fieldList.add(new TC_ASPIRE.FieldMapping('', 'ShippingStateCode'));
        //fieldList.add(new TC_ASPIRE.FieldMapping('', 'ShippingPostalCode'));
        //fieldList.add(new TC_ASPIRE.FieldMapping('', 'ShippingCountryCode'));
        fieldList.add(new TC_ASPIRE.FieldMapping('', 'BillingStreet'));
        fieldList.add(new TC_ASPIRE.FieldMapping('', 'BillingCity'));
        fieldList.add(new TC_ASPIRE.FieldMapping('', 'BillingStateCode'));
        fieldList.add(new TC_ASPIRE.FieldMapping('', 'BillingPostalCode'));
        fieldList.add(new TC_ASPIRE.FieldMapping('', 'BillingCountryCode'));
        fieldList.add(new TC_ASPIRE.FieldMapping('', 'Business_Address__c'));
        fieldList.add(new TC_ASPIRE.FieldMapping('', 'Business_Address2__c'));
        fieldList.add(new TC_ASPIRE.FieldMapping('', 'Business_City__c'));
        fieldList.add(new TC_ASPIRE.FieldMapping('', 'Business_State__c'));
        fieldList.add(new TC_ASPIRE.FieldMapping('', 'Business_Zip__c'));
        fieldList.add(new TC_ASPIRE.FieldMapping('', 'Business_Country__c'));
        fieldList.add(new TC_ASPIRE.FieldMapping('', 'Business_Phone__c'));
        /*fieldList.add(new TC_ASPIRE.FieldMapping('TC_ASPIRE__IsTaxExempt__c', 'Tax_Exempt__c'));*/
    }
    
    public virtual override void addOtherFields(sObject aspireRecord) {
        // Action = "6" for create/update
        aspireRecord.put('TC_ASPIRE__Action__c', '6');
        aspireRecord.put('TC_ASPIRE__AccountType__c', 'Business');
        
        //recordId = ((Account) salesforceRecord).External_Id__c;
        recordId = ((Account) salesforceRecord).CCID__c;
        recordId = (String.isNotEmpty(recordId) ? (recordId.startsWith('C') ? recordId.right(recordId.length() - 1) : recordId) : (String) salesforceRecord.Id);
        recordId = recordId.left(15);
        aspireRecord.put('TC_ASPIRE__RecordId__c', recordId);
        aspireRecord.put('TC_ASPIRE__AccountId__c', recordId);
    }
    
    public virtual override void addChildrenRecords(sObject aspireRecord) {
        //String phone = ((Account) salesforceRecord).Phone;
        String phone = ((Account) salesforceRecord).Business_Phone__c;
        
        if (String.isNotEmpty(phone)) {
            TC_ASPIRE__PhoneNumber__c phoneNumber = new TC_ASPIRE__PhoneNumber__c(TC_ASPIRE__Account__c = aspireRecord.Id,
                                                        TC_ASPIRE__PhoneNumberType__c = 'Main',
                                                        TC_ASPIRE__Number__c = phone);
            phoneNumbers.add(phoneNumber);
        }
    }
    
    public virtual override void addLookupRecords(sObject aspireRecord) {
        //addLocation('Shipping');
        addLocation('Billing');
        addLocationCustom('Shipping');
    }
    
    protected void addLocation(String addressType) {
        String country = (String) salesforceRecord.get(addressType + 'CountryCode');
        if (country == 'US' || country == 'United States')
            country = 'USA';
        
        TC_ASPIRE__Location__c location = new TC_ASPIRE__Location__c(TC_ASPIRE__EntityRecordId__c = recordId,
                                                                     TC_ASPIRE__RecordId__c = recordId + addressType,
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
    
    protected void addLocationCustom(String addressType) {
        String country = (String) salesforceRecord.get('Business_Country__c');
        if (country == 'US' || country == 'United States')
            country = 'USA';
        
        TC_ASPIRE__Location__c location = new TC_ASPIRE__Location__c(TC_ASPIRE__EntityRecordId__c = recordId,
                                                                     TC_ASPIRE__RecordId__c = recordId + addressType,
                                                                     TC_ASPIRE__Action__c = '6',
                                                                     TC_ASPIRE__Address1__c = (String) salesforceRecord.get('Business_Address__c'),
                                                                     TC_ASPIRE__Address2__c = (String) salesforceRecord.get('Business_Address2__c'),
                                                                     TC_ASPIRE__City__c = (String) salesforceRecord.get('Business_City__c'),
                                                                     TC_ASPIRE__State__c = (String) salesforceRecord.get('Business_State__c'),
                                                                     TC_ASPIRE__PostalCode__c = (String) salesforceRecord.get('Business_Zip__c'),
                                                                     TC_ASPIRE__Country__c = country,
                                                                     TC_ASPIRE__IsActive__c = True
                                                                    );
        
        if (String.isNotEmpty(location.TC_ASPIRE__Address1__c))
            locations.add(location);
    }
}
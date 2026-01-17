/**
* @author : sfdc, Tamarack Consulting, Inc.
* @date : 5/8/2018
* @description: Class for mapping ASPIRE API accounts.
*
* © Copyright 2003 - 2018 Tamarack Consulting, Inc.  All Rights Reserved.
* 
*/

public virtual class TC_BankMapping extends TC_ASPIRE.Mapping {
    public TC_ASPIRE__Bank_Account__c bankAccount = null;
    private String recordId = '';
    
    public TC_BankMapping(Id salesforceId) {
        this.salesforceId = salesforceId;
        this.aspireName = 'TC_ASPIRE__Bank__c';
        this.salesforceName = 'Opportunity';
    }
    
    public virtual override void addMappingFields() {
        // TC_ASPIRE.FieldMapping(aspireName, salesforceName)
        fieldList.add(new TC_ASPIRE.FieldMapping('TC_ASPIRE__Name__c', 'Bank_Name__c'));
        fieldList.add(new TC_ASPIRE.FieldMapping('TC_ASPIRE__Address1__c', 'Bank_Address__c'));
        fieldList.add(new TC_ASPIRE.FieldMapping('TC_ASPIRE__City__c', 'Bank_City__c'));
        fieldList.add(new TC_ASPIRE.FieldMapping('TC_ASPIRE__State__c', 'Bank_State__c'));
        fieldList.add(new TC_ASPIRE.FieldMapping('TC_ASPIRE__PostalCode__c', 'Bank_Zip__c'));
        fieldList.add(new TC_ASPIRE.FieldMapping('TC_ASPIRE__RoutingNumber__c', 'Bank_Number__c'));
        fieldList.add(new TC_ASPIRE.FieldMapping('', 'Contract__c'));
        fieldList.add(new TC_ASPIRE.FieldMapping('', 'Account.CCID__c'));
        fieldList.add(new TC_ASPIRE.FieldMapping('', 'AccountId'));
        fieldList.add(new TC_ASPIRE.FieldMapping('', 'Bank_Account_Number__c'));
    }
    
    public virtual override void addOtherFields(sObject aspireRecord) {
        // Action = "6" for create/update
        aspireRecord.put('TC_ASPIRE__Action__c', '6');
        
        recordId = ((Opportunity) salesforceRecord).Contract__c;
        recordId = (String.isNotEmpty(recordId) ? recordId : (String) salesforceRecord.Id);
        aspireRecord.put('TC_ASPIRE__RecordId__c', recordId + 'Bank');
        
        String customerRecordId = ((Opportunity) salesforceRecord).Account.CCID__c;
        customerRecordId = (String.isNotEmpty(customerRecordId) ? recordId : (String) ((Opportunity) salesforceRecord).AccountId);
        aspireRecord.put('TC_ASPIRE__CustomerRecordId__c', customerRecordId);
    }
    
    public virtual override void addChildrenRecords(sObject aspireRecord) {
        String bankAccountNumber = ((Opportunity) salesforceRecord).Bank_Account_Number__c;
        
        if (String.isNotEmpty(bankAccountNumber)) {
            bankAccount = new TC_ASPIRE__Bank_Account__c(TC_ASPIRE__Action__c = '6',
                                                         TC_ASPIRE__RecordId__c = recordId + 'BankAccount',
                                                         TC_ASPIRE__BankRecordId__c = recordId + 'Bank',
                                                         TC_ASPIRE__AccountNumber__c = bankAccountNumber,
                                                         TC_ASPIRE__Active__c = true);
        }
    }
}
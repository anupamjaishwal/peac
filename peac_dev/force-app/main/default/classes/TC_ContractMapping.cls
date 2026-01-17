/**
* @author : sfdc, Tamarack Consulting, Inc.
* @date : 11/23/2015
* @description: Class for mapping ASPIRE API contracts.
*
* © Copyright 2003 - 2015 Tamarack Consulting, Inc.  All Rights Reserved.
* 
*/

public virtual class TC_ContractMapping extends TC_ASPIRE.Mapping {

    public static Marlin_Configuration__c config = Marlin_Configuration__c.getOrgDefaults ();

    private TC_ASPIRE__ContractStatus__c contractStatus;
    private TC_ASPIRE__LoanEconomics__c loanEconomics;
    private TC_ASPIRE__LeaseEconomics__c leaseEconomics;
    private TC_ASPIRE__Payment__c payment;
    public List<TC_ASPIRE__Role__c> roles = new List<TC_ASPIRE__Role__c>();
    public List<TC_ASPIRE__UserDefinedField__c> userDefinedFields = new List<TC_ASPIRE__UserDefinedField__c>();
    private TC_ASPIRE__TransactionCode__c transactionCode;
    
    public TC_ContractMapping(Id salesforceId) {
        this.salesforceId = salesforceId;
        this.aspireName = 'TC_ASPIRE__Contract__c';
        this.salesforceName = 'Opportunity';
    }
    
    public virtual override void addMappingFields() {
        fieldList.add(new TC_ASPIRE.FieldMapping('TC_ASPIRE__RecordId__c', 'Id'));
        fieldList.add(new TC_ASPIRE.FieldMapping('TC_ASPIRE__ContractId__c', 'Id'));
        //fieldList.add(new TC_ASPIRE.FieldMapping('', 'Account.External_Id__c'));
        fieldList.add(new TC_ASPIRE.FieldMapping('', 'Account.CCID__c'));
        fieldList.add(new TC_ASPIRE.FieldMapping('', 'AccountId'));
        fieldList.add(new TC_ASPIRE.FieldMapping('TC_ASPIRE__StartDate__c', 'Commencement_Date__c'));
        //fieldList.add(new TC_ASPIRE.FieldMapping('TC_ASPIRE__Term__c', 'Term__c'));
        fieldList.add(new TC_ASPIRE.FieldMapping('', 'Selected_Approved_Offer__r.Term__c'));
        fieldList.add(new TC_ASPIRE.FieldMapping('TC_ASPIRE__FinanceProduct__c', 'Product__c'));
        //fieldList.add(new TC_ASPIRE.FieldMapping('', 'Payment_Start_Date__c'));
        fieldList.add(new TC_ASPIRE.FieldMapping('', 'Payment_Frequency__c'));
        //fieldList.add(new TC_ASPIRE.FieldMapping('', 'Payment__c'));
        fieldList.add(new TC_ASPIRE.FieldMapping('', 'Contract__c'));
        fieldList.add(new TC_ASPIRE.FieldMapping('', 'Selected_Approved_Offer__r.Offer_Amount__c'));
        fieldList.add(new TC_ASPIRE.FieldMapping('', 'First_Payment_Date__c'));
        fieldList.add(new TC_ASPIRE.FieldMapping('', 'of_Payments__c'));
        fieldList.add(new TC_ASPIRE.FieldMapping('', 'Payment_Amount__c'));
        fieldList.add(new TC_ASPIRE.FieldMapping('', 'Selected_Approved_Offer__r.Number_Of_Payments__c'));
        fieldList.add(new TC_ASPIRE.FieldMapping('', 'Selected_Approved_Offer__r.Daily_Payment__c'));
        fieldList.add(new TC_ASPIRE.FieldMapping('', 'Selected_Approved_Offer__r.Weekly_Payment__c'));
        fieldList.add(new TC_ASPIRE.FieldMapping('', 'CaseCenter__c'));
        fieldList.add(new TC_ASPIRE.FieldMapping('', 'Competitor_Payoff_Amount__c'));
        fieldList.add(new TC_ASPIRE.FieldMapping('', 'Renewal_Payoff_Amount__c'));
        fieldList.add(new TC_ASPIRE.FieldMapping('', 'Renewal_Payoff_Contract_Number__c'));
        fieldList.add(new TC_ASPIRE.FieldMapping('', 'Account_Billing_Street__c'));
        fieldList.add(new TC_ASPIRE.FieldMapping('', 'Account_Billing_Street2__c'));
        fieldList.add(new TC_ASPIRE.FieldMapping('', 'Account_Billing_City__c'));
        fieldList.add(new TC_ASPIRE.FieldMapping('', 'Account_Billing_State_Province__c'));
        fieldList.add(new TC_ASPIRE.FieldMapping('', 'Account_Billing_Zip_Postal_Code__c'));
        fieldList.add(new TC_ASPIRE.FieldMapping('', 'Account_Billing_Country__c'));
        fieldList.add(new TC_ASPIRE.FieldMapping('', 'Loan_Points_Amount__c'));
        fieldList.add(new TC_ASPIRE.FieldMapping('', 'Account.CCID__c'));
    }
    
    public virtual override void addOtherFields(sObject aspireRecord) {
        // Action = "6" for create/update
        aspireRecord.put('TC_ASPIRE__Action__c', '6');
        //aspireRecord.put('TC_ASPIRE__FinanceCompanyRecordId__c', '01');
        aspireRecord.put('TC_ASPIRE__FinanceCompanyRecordId__c', 'ASPIRE_OID_4');
        
        String recordId = ((Opportunity) salesforceRecord).Contract__c;
        recordId = (String.isNotEmpty(recordId) ? recordId : (String) salesforceRecord.Id);
        aspireRecord.put('TC_ASPIRE__RecordId__c', recordId);
        aspireRecord.put('TC_ASPIRE__ContractId__c', recordId);
        
        TC_ASPIRE__Account__c account;
        String ccId = ((Opportunity) salesforceRecord).Account.CCID__c;
        ccId = (String.isNotEmpty(ccId) ? (ccId.startsWith('C') ? ccId.right(ccId.length() - 1) : ccId) : ((Opportunity) salesforceRecord).AccountId);
        //List<TC_ASPIRE__Account__c> accounts = [SELECT Id, TC_ASPIRE__BillToLocationRecordId__r.Id FROM TC_ASPIRE__Account__c WHERE TC_ASPIRE__RecordId__c = :((Opportunity) salesforceRecord).Account.External_Id__c];
        List<TC_ASPIRE__Account__c> accounts = [SELECT Id, TC_ASPIRE__BillToLocationRecordId__r.Id FROM TC_ASPIRE__Account__c WHERE TC_ASPIRE__RecordId__c = :ccId];
        
        if (accounts.size() > 0)
            account = accounts[0];
        else {
            accounts = [SELECT Id, TC_ASPIRE__BillToLocationRecordId__r.Id FROM TC_ASPIRE__Account__c WHERE TC_ASPIRE__RecordId__c = :((Opportunity) salesforceRecord).AccountId];
            if (accounts.size() > 0) account = accounts[0];
        }
        
        if (account != null) {
            aspireRecord.put('TC_ASPIRE__CustomerRecordId__c', account.Id);
            //aspireRecord.put('TC_ASPIRE__BillToLocationRecordId__c', account.TC_ASPIRE__BillToLocationRecordId__r.Id);
        }
        
        TimeZone tz = UserInfo.getTimeZone();
        Datetime datetimeToUse = System.now();
        Integer offsetSeconds = tz.getOffset(datetimeToUse) / 1000;
        datetimeToUse = datetimeToUse.addSeconds(-offsetSeconds);
        datetimeToUse = Datetime.newInstance(datetimeToUse.year(), datetimeToUse.month(), datetimeToUse.day(), 0, 0, 0);
        
        //if (salesforceRecord.get('Commencement_Date__c') == null) {
            aspireRecord.put('TC_ASPIRE__StartDate__c', datetimeToUse);
        //}
        
        aspireRecord.put('TC_ASPIRE__SignDate__c', datetimeToUse);
        aspireRecord.put('TC_ASPIRE__Term__c', ((Opportunity) salesforceRecord).Selected_Approved_Offer__r.Term__c);
        aspireRecord.put('TC_ASPIRE__InvoiceCode__c', 'DONOTPRINT');
        aspireRecord.put('TC_ASPIRE__AccountDistributionCode__c', '0000024');
        aspireRecord.put('TC_ASPIRE__InterestCalculationMethod__c', 'FixedAmortization');
        aspireRecord.put('TC_ASPIRE__FinanceProduct__c', 'Loan2');
        aspireRecord.put('TC_ASPIRE__DelinquencyCode__c', '15PERCENT');
        aspireRecord.put('TC_ASPIRE__InvoiceLeadDays__c', '1DAY');
        aspireRecord.put('TC_ASPIRE__CompoundingPeriod__c', 'FollowPaymentFrequency');
        aspireRecord.put('TC_ASPIRE__ComputeMethod__c', 'Normal');
        aspireRecord.put('TC_ASPIRE__YearLength__c', 'YearLength365');
    }
    
    public virtual override void addChildrenRecords(sObject aspireRecord) {
        contractStatus = new TC_ASPIRE__ContractStatus__c(TC_ASPIRE__RecordId__c = aspireRecord.get('TC_ASPIRE__RecordId__c') + 'Status',
                                                          TC_ASPIRE__ContractRecordId__c = aspireRecord.get('TC_ASPIRE__RecordId__c') + '',
                                                          //TC_ASPIRE__Status__c = '01 - Submitted'
                                                          TC_ASPIRE__Status__c = 'Approved for Booking'
                                                         );
        insert contractStatus;
        aspireRecord.put('TC_ASPIRE__ContractStatus__c', contractStatus.Id);
        
        transactionCode = new TC_ASPIRE__TransactionCode__c(TC_ASPIRE__Code__c = 'LOAN',
                                                            TC_ASPIRE__Description__c = 'Loan Payment',
                                                            TC_ASPIRE__InvoiceDescription__c = 'Loan Payment'
                                                           );
        insert transactionCode;
        aspireRecord.put('TC_ASPIRE__TransactionCode__c', transactionCode.Id);
        
       	loanEconomics = new TC_ASPIRE__LoanEconomics__c();
        insert loanEconomics;
        
        aspireRecord.put('TC_ASPIRE__Loan__c', loanEconomics.Id);
        
        TimeZone tz = UserInfo.getTimeZone();
        Datetime datetimeToUse = System.now();
        Integer offsetSeconds = tz.getOffset(datetimeToUse) / 1000;
        datetimeToUse = datetimeToUse.addSeconds(-offsetSeconds);
        datetimeToUse = Datetime.newInstance(datetimeToUse.year(), datetimeToUse.month(), datetimeToUse.day(), 0, 0, 0);
        
        TC_ASPIRE__Loan__c loan = new TC_ASPIRE__Loan__c(TC_ASPIRE__LoanEconomics__c = loanEconomics.Id,
                                                         TC_ASPIRE__EffectiveDate__c = datetimeToUse,
                                                         TC_ASPIRE__Category__c = 'Loan',
                                                         TC_ASPIRE__Type__c = 'SYSTEM_DEFINED',
                                                         TC_ASPIRE__Value__c = ((Opportunity) salesforceRecord).Selected_Approved_Offer__r.Offer_Amount__c
                                                        );
        insert loan;
        
        /*
       	leaseEconomics = new TC_ASPIRE__LeaseEconomics__c();
        leaseEconomics.TC_ASPIRE__BookTreatment__c = 'DirectFinance';
        leaseEconomics.TC_ASPIRE__TaxTreatment__c = 'ConditionalSale';
        insert leaseEconomics;
        
        aspireRecord.put('TC_ASPIRE__Lease__c', leaseEconomics.Id);
        */
        
        String paymentFrequency = ((Opportunity) salesforceRecord).Payment_Frequency__c;
        
        if (paymentFrequency == 'Monthly') paymentFrequency = '0';
        else if (paymentFrequency == 'Quarterly') paymentFrequency = '3';
        else if (paymentFrequency == 'Annually') paymentFrequency = '5';
        else if (paymentFrequency == 'Weekly') paymentFrequency = '7';
        else if (paymentFrequency == 'Daily') paymentFrequency = '6';
        
        
        System.debug ('>>>>> $$$$$ should be 0: ' + paymentFrequency);
        /*
        Double paymentAmount = 0;
        
        if (paymentFrequency == '6')
            paymentAmount = ((Opportunity) salesforceRecord).Selected_Approved_Offer__r.Daily_Payment__c;
        else if (paymentFrequency == '7')
            paymentAmount = ((Opportunity) salesforceRecord).Selected_Approved_Offer__r.Weekly_Payment__c;
        */
        payment = new TC_ASPIRE__Payment__c(TC_ASPIRE__LoanEconomics__c = loanEconomics.Id,
                                            //TC_ASPIRE__StartDate__c = ((Opportunity) salesforceRecord).Payment_Start_Date__c,
                                            TC_ASPIRE__StartDate__c = (((Opportunity) salesforceRecord).First_Payment_Date__c != null ? Datetime.newInstance(((Opportunity) salesforceRecord).First_Payment_Date__c, Time.newInstance(0,0,0,0)) : null),
                                            //TC_ASPIRE__Occurrences__c = ((Opportunity) salesforceRecord).Term__c,
                                            TC_ASPIRE__Occurrences__c = (((Opportunity) salesforceRecord).of_Payments__c != null ? ((Opportunity) salesforceRecord).of_Payments__c.round() : null),
                                            //TC_ASPIRE__Frequency__c = ((Opportunity) salesforceRecord).Payment_Frequency__c,
                                            TC_ASPIRE__Frequency__c = paymentFrequency,
                                            //TC_ASPIRE__Amount__c = ((Opportunity) salesforceRecord).Payment__c
                                            TC_ASPIRE__Amount__c = ((Opportunity) salesforceRecord).Payment_Amount__c != null ? ((Opportunity) salesforceRecord).Payment_Amount__c.setScale(2, RoundingMode.HALF_UP) : null
                                           );
            
        insert payment;

        /* new */
        /*
        insert new TC_ASPIRE__Adjustment__c (TC_ASPIRE__EffectiveDate__c = System.today()
            , TC_ASPIRE__Category__c = '3rd Party Commission and Broker Fees'
            , TC_ASPIRE__LoanEconomics__c = loanEconomics.Id
            , TC_ASPIRE__Value__c = ((Opportunity) salesforceRecord).Loan_Points_Amount__c != null ? ((Opportunity) salesforceRecord).Loan_Points_Amount__c.setScale(2, RoundingMode.HALF_UP) : null
            , TC_ASPIRE__Type__c = 'Commission');*/

        
        String country = (String) salesforceRecord.get('Account_Billing_Country__c');
        if (country == 'US' || country == 'United States') country = 'USA';
        
        String accountRecordId =  ((Opportunity) salesforceRecord).Account.CCID__c;
        accountRecordId = (String.isNotEmpty(accountRecordId) ? (accountRecordId.startsWith('C') ? accountRecordId.right(accountRecordId.length() - 1) : accountRecordId) : (String) ((Opportunity) salesforceRecord).AccountId);
        accountRecordId = accountRecordId.left(15);
        
        TC_ASPIRE__Location__c location = new TC_ASPIRE__Location__c(TC_ASPIRE__EntityRecordId__c = accountRecordId, TC_ASPIRE__RecordId__c = aspireRecord.get('TC_ASPIRE__RecordId__c') + 'Billing',TC_ASPIRE__Action__c = '6',TC_ASPIRE__Address1__c = (String) salesforceRecord.get('Account_Billing_Street__c'),TC_ASPIRE__Address2__c = (String) salesforceRecord.get('Account_Billing_Street2__c'),TC_ASPIRE__City__c = (String) salesforceRecord.get('Account_Billing_City__c'),TC_ASPIRE__State__c = (String) salesforceRecord.get('Account_Billing_State_Province__c'),TC_ASPIRE__PostalCode__c = (String) salesforceRecord.get('Account_Billing_Zip_Postal_Code__c'),TC_ASPIRE__Country__c = country,TC_ASPIRE__IsActive__c = True);
        
        insert location;
        aspireRecord.put('TC_ASPIRE__BillToLocationRecordId__c', location.Id);
        
        insert aspireRecord;

        /*
        New but commented out*/

        if (((Opportunity) salesforceRecord).Loan_Points_Amount__c != null && ((Opportunity) salesforceRecord).Loan_Points_Amount__c != 0) {
            insert new TC_ASPIRE__Adjustment__c (//TC_ASPIRE__EffectiveDate__c = System.today()
                TC_ASPIRE__EffectiveDate__c = datetimeToUse
                , TC_ASPIRE__Category__c = 'Commission'
                , TC_ASPIRE__LoanEconomics__c = loanEconomics.Id
                , TC_ASPIRE__Value__c = ((Opportunity) salesforceRecord).Loan_Points_Amount__c != null ? ((Opportunity) salesforceRecord).Loan_Points_Amount__c.setScale(2, RoundingMode.HALF_UP) : null
                , TC_ASPIRE__Type__c = '3rd Party Commissions and Broker Fees'
                , TC_ASPIRE__TaxLocationRecordId__c = location.Id);
        }


        insert new TC_ASPIRE__Adjustment__c (
                    TC_ASPIRE__EffectiveDate__c = datetimeToUse
                    , TC_ASPIRE__Category__c = 'IDC'
                    , TC_ASPIRE__LoanEconomics__c = loanEconomics.Id
                    , TC_ASPIRE__Value__c = config.IDC_Operating__c
                    , TC_ASPIRE__Type__c = 'IDC Operating'
                    , TC_ASPIRE__TaxLocationRecordId__c = location.Id);

        insert new TC_ASPIRE__Adjustment__c (
                TC_ASPIRE__EffectiveDate__c = datetimeToUse
                , TC_ASPIRE__Category__c = 'IDC'
                , TC_ASPIRE__LoanEconomics__c = loanEconomics.Id
                , TC_ASPIRE__Value__c = config.IDC_Salary__c
                , TC_ASPIRE__Type__c = 'IDC Salary'
                , TC_ASPIRE__TaxLocationRecordId__c = location.Id);

        
        userDefinedFields.add(createUDF('5', 'Text', ((Opportunity) salesforceRecord).CaseCenter__c));
        userDefinedFields.add(createUDF('3', 'Numeric', ((Opportunity) salesforceRecord).Competitor_Payoff_Amount__c));
        userDefinedFields.add(createUDF('4', 'Numeric', ((Opportunity) salesforceRecord).Renewal_Payoff_Amount__c));
        userDefinedFields.add(createUDF('6', 'Text', ((Opportunity) salesforceRecord).Renewal_Payoff_Contract_Number__c));
        
        List<TC_ASPIRE__UserDefinedField__c> userDefinedFieldsFiltered = new List<TC_ASPIRE__UserDefinedField__c>();
        
        for (TC_ASPIRE__UserDefinedField__c udf : userDefinedFields) {
            if (udf != null) {
                udf.TC_ASPIRE__Contract__c = aspireRecord.Id;
                userDefinedFieldsFiltered.add(udf);
            }
        }
        
        insert userDefinedFieldsFiltered;
    }
    
    public virtual override void deleteRecords() {
        delete contractStatus;
        delete transactionCode;
        delete loanEconomics;
        //delete leaseEconomics;
        delete payment;
        super.deleteRecords();
    }
    
    public virtual TC_ASPIRE__UserDefinedField__c createUDF(String recordId, String valueType, Object value) {
        if (value == null)
            return null;
        
        TC_ASPIRE__UserDefinedField__c udf = new TC_ASPIRE__UserDefinedField__c();
        udf.TC_ASPIRE__RecordId__c = recordId;
        udf.TC_ASPIRE__ValueType__c = valueType;
        udf.TC_ASPIRE__Value__c = String.valueOf(value);
        
        return udf;
    }
    
}
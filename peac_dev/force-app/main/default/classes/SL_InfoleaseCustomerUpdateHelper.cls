/**
 * @File Name          : SL_InfoleaseCustomerUpdateHelper.cls
 * @Description        : Helper class for CCAN Account SF to IL via BW
 * @Author             : Silverline
 * @Group              :
 * @Last Modified By   :
 * @Last Modified On   :
 * @Modification Log   :
 * Ver       Date            Author                 Modification
 * 1.0    10/06/2021      Silverline                Initial Version
 */
public with sharing class SL_InfoleaseCustomerUpdateHelper {

    private List<String> errorMessages;
    private Account thisAccount;
    public String recordId;

    private SL_InfoleaseUpdateCustomerRequestWrapper request;

    public SL_InfoleaseCustomerUpdateHelper(String accountId) {
        recordId = accountId;
        thisAccount = getAccountFields(accountId);
    }


    public SL_InfoleaseUpdateCustomerRequestWrapper createRequest () {
        mapFields();
        return request;
    }

    private SL_InfoleaseUpdateCustomerRequestWrapper mapFields() {

        request = new SL_InfoleaseUpdateCustomerRequestWrapper();

        request.Request.CCAN = thisAccount.CCAN__c;
        request.Request.CsDefaultName = thisAccount.Name;
        request.Request.CsDefaultAddr1 = thisAccount.Business_Address__c;
        request.Request.CsDefaultAddr2 = thisAccount.Business_Address2__c;
        request.Request.CsDefaultAddr3 = thisAccount.Address_3__c;
        request.Request.CsDefaultCity = thisAccount.Business_City__c;
        request.Request.CsDefaultState = thisAccount.Business_State__c;
        request.Request.CsDefaultZip = thisAccount.Business_Zip__c;
        request.Request.CsDefaultDba = thisAccount.DBA__c ;
        request.Request.CsDefaultFederalTaxId = thisAccount.Tax_Id__c ;
        request.Request.CsDefaultArName = thisAccount.Account_Billing_Name__c ;
        request.Request.CsDefaultArAddr1 = thisAccount.Account_Billing_Street__c;
        request.Request.CsDefaultArAddr2 = thisAccount.Account_Billing_Street2__c ;
        request.Request.CsDefaultArAddr3 = thisAccount.Account_Billing_Street3__c;
        request.Request.CsDefaultArCity = thisAccount.Account_Billing_City__c  ;
        request.Request.CsDefaultArState = thisAccount.Account_Billing_State_Province__c  ;
        request.Request.CsDefaultArZip = thisAccount.Account_Billing_Zip_Postal_Code__c  ;

        //End Mapping
        return request;

    }

    public String mapSpecificFields(String customerId, Set<String> changedFieldSet){

        List<String> fieldList = new List<String>(changedFieldSet);

        Map<String,String> wrapVarFieldMap = new Map<String,String>{
            'CCAN__c' => 'Ccan',
            'Name' => 'CsDefaultName',
            'Business_Address__c' => 'CsDefaultAddr1' ,
            'Business_Address2__c' => 'CsDefaultAddr2' ,
            'Address_3__c' => 'CsDefaultAddr3' ,
            'Business_City__c' => 'CsDefaultCity' ,
            'Business_State__c' => 'CsDefaultState' ,
            'Business_Zip__c' => 'CsDefaultZip' ,
            'DBA__c' => 'CsDefaultDba' ,
            'Tax_Id__c' => 'CsDefaultFederalTaxId' ,
            'Account_Billing_Name__c' => 'CsDefaultArName' ,
            'Account_Billing_Street__c' => 'CsDefaultArAddr1' ,
            'Account_Billing_Street2__c' => 'CsDefaultArAddr2' ,
            'Account_Billing_Street3__c' => 'CsDefaultArAddr3' ,
            'Account_Billing_City__c' => 'CsDefaultArCity' ,
            'Account_Billing_State_Province__c' => 'CsDefaultArState' ,
            'Account_Billing_Zip_Postal_Code__c' => 'CsDefaultArZip' 
        }; 

        JSONGenerator gen = JSON.createGenerator(true);

        gen.writeStartObject();
        for(String thisField : fieldList){
            gen.writeStringField(wrapVarFieldMap.get(thisField), String.valueOf(thisAccount.get(thisField) != null ? thisAccount.get(thisField) : ''));
        }
        gen.writeEndObject();

        String pretty = gen.getAsString();

        pretty = '{'+
                '"Header" : {'+
                '"NitroApi" : "BW.UPDATE.CUSTOMER.UDO"'+
                '},'+
                '"Request" : '+ pretty +
                '}';
        System.debug('pretty: '+pretty);

        return pretty;
    }

    public Boolean validate() {
        errorMessages = new List<String>();

        if (thisAccount == null) {
            errorMessages.add('Null object sent to updateCustomer!');
            return errorMessages.isEmpty();
        }

        if (account.CCAN__c == null) errorMessages.add('Account: ' + account.Name + ' missing required field - CCAN');

        return errorMessages.isEmpty();
    }


    public List<String> getErrorMessages() { return errorMessages; }


    public boolean isValid() {
        return errorMessages.isEmpty();
    }

    private Account getAccountFields(String accountId) {
        Account a;
        try {
            a = [SELECT
                Name,
                Id,
                CCAN__c,
                Business_Address__c, Business_Address2__c, Business_City__c, Business_State__c,
                Business_Zip__c, DBA__c , Tax_Id__c , Account_Billing_Name__c , Account_Billing_Street__c, Account_Billing_Street3__c,
                Account_Billing_Street2__c , Address_3__c, Account_Billing_City__c, Account_Billing_State_Province__c,
                Account_Billing_Zip_Postal_Code__c,      
                Integration_Status__c
            FROM Account WHERE Id = :accountId];
            return a;
            
        } catch (Exception e) {
            return null;
        }
    }
}
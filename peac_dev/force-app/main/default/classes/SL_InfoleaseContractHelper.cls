public with sharing class SL_InfoleaseContractHelper {
    private List<String> errorMessages;
    private Contract__c thisContract;
    public Id recordId;

    private SL_InfoleaseContractRequestWrapper request;
    public SL_InfoleaseUtils util = SL_InfoleaseUtils.getInstance();

    public SL_InfoleaseContractHelper(Id contractId) {
        recordId = contractId;
        thisContract = getFields(recordId);
    }

    public SL_InfoleaseContractRequestWrapper createRequest() {
        mapFields();
        return request;
    }

    public Boolean validate() {
        errorMessages = new List<String>();

        if (thisContract == null) {
            errorMessages.add('Null object sent to updateContract!');
            return errorMessages.isEmpty();
        }
        return errorMessages.isEmpty();
    }

    public List<String> getErrorMessages() { return errorMessages; }

    public boolean isValid() {
        return errorMessages.isEmpty();
    }

    private SL_InfoleaseContractRequestWrapper mapFields() {  
        String insuranceCode = getInsuranceCode(thisContract, errorMessages);
        request = new SL_InfoleaseContractRequestWrapper();

        request.Request.ContractNumber = thisContract.Name;
        request.Request.UserId = util.getServiceSettings().UserId__c == null ? 'servcloud' : util.getServiceSettings().UserId__c;

        request.Request.CUST_NAME = thisContract.Customer__r.Name;
        request.Request.CUST_ADDRESS1 = thisContract.Address_1__c;
        request.Request.CUST_ADDRESS2 = thisContract.Address_2__c;
        request.Request.CUST_ADDRESS3 = thisContract.Address_3__c;
        request.Request.CUST_CITY = thisContract.City__c;
        request.Request.CUST_STATE = thisContract.State__c;
        request.Request.CUST_ZIP = thisContract.Zip_Code__c;
        request.Request.AR_NAME = thisContract.AR_Name__c;
        request.Request.AR_ADDRESS1 = thisContract.AR_Address_1__c;
        request.Request.AR_ADDRESS2 = thisContract.AR_Address_2__c;
        request.Request.AR_ADDRESS3 = thisContract.AR_Address_3__c;
        request.Request.AR_CITY = thisContract.AR_City__c;
        request.Request.AR_STATE = thisContract.AR_State__c;
        request.Request.AR_ZIP = thisContract.AR_Zip_Code__c;
        request.Request.AR_ATTN = thisContract.Attention__c;
        request.Request.FED_ID = thisContract.Tax_ID__c;
        request.Request.INVOICE_CODE = thisContract.Invoice_Code__c;
        request.Request.USER_CODE = thisContract.User_Code__c;
        request.Request.UM_ALPHA_FIELD3 = thisContract.Reprint_Invoice__c ? 'Yes' : '';
        request.Request.INSURANCE_CODE = insuranceCode;
        request.Request.PUR_ORDER_NUM = thisContract.PO_Number__c;
		request.Request.QUOTE_BUYOUT = thisContract.Quote_Buyout__c; 
        request.Request.INVOICE_FRMT = thisContract.Invoice_Format__c;
        //End Mapping
        return request;

    }

    public String mapSpecificFields(String contractId, Set<String> changedFieldSet){
        List<String> fieldList = new List<String>(changedFieldSet);

        Map<String,String> wrapVarFieldMap = new Map<String,String>{
            'Name' => 'ContractNumber',
            'Customer__r.Name' => 'CUST_NAME',
            'Address_1__c' => 'CUST_ADDRESS1',
            'Address_2__c' => 'CUST_ADDRESS2',
            'Address_3__c' => 'CUST_ADDRESS3',
            'City__c' => 'CUST_CITY',
            'State__c' => 'CUST_STATE',
            'Zip_Code__c' => 'CUST_ZIP',
            'AR_Name__c' => 'AR_NAME',
            'AR_Address_1__c' => 'AR_ADDRESS1',
            'AR_Address_2__c' => 'AR_ADDRESS2',
            'AR_Address_3__c' => 'AR_ADDRESS3',
            'AR_City__c' => 'AR_CITY',
            'AR_State__c' => 'AR_STATE',
            'AR_Zip_Code__c' => 'AR_ZIP',
            'Attention__c' => 'AR_ATTN',
            'Tax_ID__c' => 'FED_ID',
            'Invoice_Code__c' => 'INVOICE_CODE',
            'User_Code__c' => 'USER_CODE',
            'Reprint_Invoice__c' => 'UM_ALPHA_FIELD3',
            'Insurance_Status__c' => 'INSURANCE_CODE',
            'PO_Number__c' => 'PUR_ORDER_NUM',
            'Quote_Buyout__c' => 'QUOTE_BUYOUT',
            'Invoice_Format__c' => 'INVOICE_FRMT'
        }; 

        JSONGenerator gen = JSON.createGenerator(true);

        gen.writeStartObject();
        for(String thisField : fieldList){
            switch on thisField{
                when 'Reprint_Invoice__c'{
                    gen.writeStringField('UM_ALPHA_FIELD3', thisContract.get('Reprint_Invoice__c') == true ? 'Yes' : '');
                }
                when 'Insurance_Status__c'{
                    String insuranceCode = getInsuranceCode(thisContract, errorMessages);
                    gen.writeStringField(wrapVarFieldMap.get(thisField), String.valueOf(insuranceCode != null ? insuranceCode : ''));
                }
                when else{
                    gen.writeStringField(wrapVarFieldMap.get(thisField), String.valueOf(thisContract.get(thisField) != null ? thisContract.get(thisField) : ''));
                }
            }
            if(thisField == 'Reprint_Invoice__c'){
                
            }else{
                
            }
        }
        gen.writeStringField('UserId', util.getServiceSettings().UserId__c == null ? 'servcloud' : util.getServiceSettings().UserId__c);
        gen.writeEndObject();

        String pretty = gen.getAsString();

        pretty = '{'+
                '"Header" : {'+
                '"NitroApi" : "BW.UPDATE.CONTRACT"'+
                '},'+
                '"Request" : '+ pretty +
                '}';
        return pretty;
    }

    private Contract__c getFields(Id contractId) {

        Contract__c thisContract;
        try{
            thisContract =  [SELECT Customer__r.Name, Address_1__c, Address_2__c,Address_3__c, City__c, State__c, Zip_Code__c, AR_Name__c, 
                AR_Address_1__c, AR_Address_2__c,  AR_Address_3__c, AR_City__c, AR_State__c, Name,PO_Number__c,
                    AR_Zip_Code__c, Attention__c, Tax_ID__c, Invoice_Code__c, User_Code__c, Reprint_Invoice__c, Insurance_Status__c, 
                    Quote_Buyout__c, Invoice_Format__c, Infolease_Environment__c
                    FROM Contract__c  
                    WHERE Id = :contractId];
            return thisContract;
        }catch(Exception e){
            return null;
        }
    }

    public static String getInsuranceCode(Contract__c thisContract, List<String> errorMessages){
        String insuranceCode = thisContract.Insurance_Status__c;
        IL10_Flag__c il10Setting = IL10_Flag__c.getValues('GeneralSetting');
        Boolean isIL10 = TC_BWUtility.isIL10Record(thisContract);
        Map<String, String> insuranceStatuses = new Map<String, String>();
        Map<String, String> insuranceCodesByValue = new Map<String, String>();
        Schema.DescribeFieldResult dfr = Contract__c.Insurance_Status__c.getDescribe();
        for (Schema.PicklistEntry ple : dfr.getPicklistValues()){
            insuranceStatuses.put(ple.getValue(), ple.getLabel().toLowerCase());
        }
        for(Insurance_Status_Code__mdt insuranceCodeMDT : [SELECT Infolease_9_Code__c, Picklist_Value__c, Infolease_10_Code__c FROM Insurance_Status_Code__mdt]){
            if(il10Setting.use_IL10__c && isIL10){
                insuranceCodesByValue.put(insuranceCodeMDT.Picklist_Value__c.toLowerCase(), insuranceCodeMDT.Infolease_10_Code__c);
            }else{
                insuranceCodesByValue.put(insuranceCodeMDT.Picklist_Value__c.toLowerCase(), insuranceCodeMDT.Infolease_9_Code__c);
            }
        }
        String picklistValue = insuranceStatuses.get(thisContract.Insurance_Status__c);
        String codeToSend = insuranceCodesByValue.get(picklistValue);
        insuranceCode = codeToSend == null? thisContract.Insurance_Status__c: codeToSend;
        if(il10Setting.use_IL10__c && isIL10 && insuranceCode != '25'){// Jaclyn stated that only 25 is gonna be sent to IL10
            insuranceCode = '';
            errorMessages.add('Contract not Synced, The Insurance Status wasn\'t sent to InfoLease, only Request Cancel can be sent.');
        }
        return insuranceCode;
    }
}
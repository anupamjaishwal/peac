public with sharing class SL_InfoleaseInsuranceHelper {
    private List<String> errorMessages;
    private Insurance__c thisInsurance;
    public Id recordId;
    Boolean isIL10;

    private SL_InfoleaseInsuranceRequestWrapper request;
    public SL_InfoleaseUtils util = SL_InfoleaseUtils.getInstance();

    public SL_InfoleaseInsuranceHelper(Id insuranceId) {
        recordId = insuranceId;
        thisInsurance = getFields(recordId);
        IL10_Flag__c il10Setting = IL10_Flag__c.getValues('GeneralSetting');
        isIL10 = false;
        if(thisInsurance != null){
            isIL10 = TC_BWUtility.isIL10Record(thisInsurance);
        }
    }

    public SL_InfoleaseInsuranceRequestWrapper createRequest () {
        mapFields();
        return request;
    }

    public Boolean validate() {
        errorMessages = new List<String>();

        if (thisInsurance == null) {
            errorMessages.add('Null object sent to updateInsurance!');
            return errorMessages.isEmpty();
        }
        return errorMessages.isEmpty();
    }

    public List<String> getErrorMessages() { return errorMessages; }


    public boolean isValid() {
        return errorMessages.isEmpty();
    }

    private SL_InfoleaseInsuranceRequestWrapper mapFields() {

        request = new SL_InfoleaseInsuranceRequestWrapper();

        request.Request.UserId = util.getServiceSettings().UserId__c == null ? 'servcloud' : util.getServiceSettings().UserId__c;

        request.Request.InsuranceId = thisInsurance.Insurance_Id__c;
        request.Request.INSUR_CARRIER = thisInsurance.Carrier__c;
        request.Request.INSUR_EFFECTIVE_DATE = thisInsurance.Effective_Date__c != null ? String.valueOf(thisInsurance.Effective_Date__c.format()) : null;
        request.Request.INSUR_EXPIRE_DATE = thisInsurance.Expiration_Date__c != null ? String.valueOf(thisInsurance.Expiration_Date__c.format()) : null;
        request.Request.INSUR_CANCEL_DATE = thisInsurance.Cancel_Date__c != null ? String.valueOf(thisInsurance.Cancel_Date__c.format()) : null;
        request.Request.INSUR_STATUS = isIL10? thisInsurance.Policy_Status__c: '';
        //End Mapping
        return request;

    }

    public String mapSpecificFields(String insuranceId, Set<String> changedFieldSet){

        List<String> fieldList = new List<String>(changedFieldSet);
        String effectiveDate = thisInsurance.Effective_Date__c != null ? String.valueOf(thisInsurance.Effective_Date__c.format()) : '';
        String expireDate = thisInsurance.Expiration_Date__c != null ? String.valueOf(thisInsurance.Expiration_Date__c.format()) : '';
        String cancelDate = thisInsurance.Cancel_Date__c != null ? String.valueOf(thisInsurance.Cancel_Date__c.format()) : '';

        Map<String,String> wrapVarFieldMap = new Map<String,String>{
            'Insurance_Id__c' => 'InsuranceId',
            'Carrier__c' => 'INSUR.CARRIER',
            'Effective_Date__c' => 'INSUR.EFFECTIVE.DATE' ,
            'Expiration_Date__c' => 'INSUR.EXPIRE.DATE' ,
            'Cancel_Date__c' => 'INSUR.CANCEL.DATE',
            'Policy_Status__c' => 'INSUR.STATUS'
        }; 

        JSONGenerator gen = JSON.createGenerator(true);

        gen.writeStartObject();
        for(String thisField : fieldList){
            if(thisField == 'Effective_Date__c'){
                gen.writeStringField(wrapVarFieldMap.get(thisField), effectiveDate);
            }
            else if(thisField == 'Expiration_Date__c'){
                gen.writeStringField(wrapVarFieldMap.get(thisField), expireDate);
            }
            else if(thisField == 'Cancel_Date__c'){
                gen.writeStringField(wrapVarFieldMap.get(thisField), cancelDate);
            }
            else if(thisField == 'Policy_Status__c'){
                gen.writeStringField(wrapVarFieldMap.get(thisField), isIL10? thisInsurance.Policy_Status__c: '');
            }
            else {
                gen.writeStringField(wrapVarFieldMap.get(thisField), String.valueOf(thisInsurance.get(thisField) != null ? thisInsurance.get(thisField) : ''));
            }
        }
        gen.writeStringField('UserId', util.getServiceSettings().UserId__c == null ? 'servcloud' : util.getServiceSettings().UserId__c);
        gen.writeEndObject();

        String pretty = gen.getAsString();

        pretty = '{'+
                '"Header" : {'+
                '"NitroApi" : "BW.UPDATE.INSURANCE"'+
                '},'+
                '"Request" : '+ pretty +
                '}';
        return pretty;
    }

    private Insurance__c getFields(Id insuranceId) {
        Insurance__c thisInsurance;
        try{
            thisInsurance = [SELECT Carrier__c, Effective_Date__c, Expiration_Date__c, Cancel_Date__c,
                            Insurance_Id__c, Policy_Status__c, Infolease_Environment__c
                            FROM Insurance__c  
                            WHERE Id = :insuranceId 
                            LIMIT 1];
            return thisInsurance;
        }catch(Exception e){
            return null;
        }
    }
}
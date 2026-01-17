public with sharing class SL_InfoleaseAssetHelper {
    private List<String> errorMessages;
    private Contract_Asset__c thisAsset;
    public Id recordId;

    private SL_InfoleaseAssetRequestWrapper request;
    public SL_InfoleaseUtils util = SL_InfoleaseUtils.getInstance();

    public SL_InfoleaseAssetHelper(Id AssetId) {
        recordId = AssetId;
        thisAsset = getFields(recordId);
    }

    public SL_InfoleaseAssetRequestWrapper createRequest () {
        mapFields();
        return request;
    }

    public Boolean validate() {
        errorMessages = new List<String>();

        if (thisAsset == null) {
            errorMessages.add('Null object sent to updateAsset!');
            return errorMessages.isEmpty();
        }
        return errorMessages.isEmpty();
    }

    public List<String> getErrorMessages() { return errorMessages; }


    public boolean isValid() {
        return errorMessages.isEmpty();
    }

    private SL_InfoleaseAssetRequestWrapper mapFields() {

        request = new SL_InfoleaseAssetRequestWrapper();

        request.Request.UserId = util.getServiceSettings().UserId__c == null ? 'servcloud' : util.getServiceSettings().UserId__c;

        request.Request.AssetNumber = thisAsset.Asset_Number__c;
        request.Request.EQUIP_DESC = thisAsset.Equipment_Description__c;
        request.Request.MODEL = thisAsset.Model_Number__c;
        request.Request.A_MANUFACTURER_YEAR = thisAsset.Year_of_Manufacture__c;
        request.Request.QUANTITY = thisAsset.Quantity__c;
        request.Request.SERIAL_NUMBER = thisAsset.Serial_Number__c;
        request.Request.LICENSE_NUMBER = thisAsset.License_Number__c;

        //End Mapping
        return request;

    }

    public String mapSpecificFields(String assetId, Set<String> changedFieldSet){

        List<String> fieldList = new List<String>(changedFieldSet);

        Map<String,String> wrapVarFieldMap = new Map<String,String>{
            'Asset_Number__c' => 'AssetNumber',
            'Equipment_Description__c' => 'EQUIP.DESC',
            'Model_Number__c' => 'MODEL' ,
            'Year_of_Manufacture__c' => 'A.MANUFACTURER.YEAR' ,
            'Quantity__c' => 'QUANTITY' ,
            'Serial_Number__c' => 'SERIAL.NUMBER' ,
            'License_Number__c' => 'LICENSE.NUMBER' 
        }; 

        JSONGenerator gen = JSON.createGenerator(true);

        gen.writeStartObject();
        for(String thisField : fieldList){
            gen.writeStringField(wrapVarFieldMap.get(thisField), String.valueOf(thisAsset.get(thisField) != null ? thisAsset.get(thisField) : ''));
        }
        gen.writeStringField('UserId', util.getServiceSettings().UserId__c == null ? 'servcloud' : util.getServiceSettings().UserId__c);
        gen.writeEndObject();

        String pretty = gen.getAsString();

        System.debug('pretty: '+pretty);

        pretty = '{'+
                '"Header" : {'+
                '"NitroApi" : "BW.UPDATE.ASSET"'+
                '},'+
                '"Request" : '+ pretty +
                '}';
        System.debug('pretty: '+pretty);

        return pretty;
    }

    private Contract_Asset__c getFields(Id AssetId) {

        Contract_Asset__c thisAsset;
        try {
            thisAsset = [SELECT Equipment_Description__c,
                                Asset_Number__c,
                                Model_Number__c,
                                Year_of_Manufacture__c,
                                Quantity__c,
                                Serial_Number__c,
                                License_Number__c
                                FROM Contract_Asset__c  
                                WHERE Id = :AssetId LIMIT 1];
            return thisAsset;
        } catch (Exception e) {
            return null;
        }
    }
}
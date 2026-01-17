public with sharing class SL_UpdateAssetLocation {
    @AuraEnabled
    public static string hubExecute(String methodName, List<String> methodParameters){
        try {
            String result = '';
            switch on methodName {
                when 'getCounty'{
                    result = getCounty(methodParameters[0]);
                }
                when 'saveNewLocation'{
                    result = saveNewLocation(methodParameters[0], methodParameters[1], methodParameters[2],
                        methodParameters[3], methodParameters[4], methodParameters[5],methodParameters[6], methodParameters[7]);
                }
            }
            return result;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @testVisible
    static String getCounty(String zip){
        Boolean isIL10 = true;
        String body = '{"Header": {"NitroApi": "NITRO.VERTEX.RATE.INQ"}, "code":"' + zip + '"}';
        return SL_SummaryAndDetail.callBridgeware(body, '', false, false, isIL10);
    }

    @testVisible
    static String saveNewLocation(String recordId, String stateCode, String countyCode, String cityCode, String address1, String address2,
        String zip, String effectiveDate){
        if(effectiveDate == ''){
            effectiveDate = Datetime.now().format('MM/dd/yyyy');
        }else{
            effectiveDate = Datetime.valueOf(effectiveDate + ' 00:00:00:000Z').format('MM/dd/yyyy');
        }
        Contract_Asset__c contractAsset = [SELECT Contract__r.Name, Contract__r.Infolease_Environment__c, Asset_Number__c FROM Contract_Asset__c WHERE Id =:recordId][0];
        String contractNumber = contractAsset.Contract__r.Name;
        Boolean isIL10 = TC_BWUtility.isIL10Record(contractAsset.Contract__r);
        String body = '{"Header": {"NitroApi": "BW.UPDATE.ASSET.LOCATION"}, "Request": {"UserId": "servcloud","ContractNumber": "' + contractNumber
            + '","AssetNumber": "' + contractAsset.Asset_Number__c
            + '","StateGeoCode": "' + stateCode
            + '","CountyGeoCode": "' + countyCode
            + '","CityGeoCode": "' + cityCode
            + '","AssetAddr1": "' + address1
            + '","AssetAddr2": "' + address2
            + '","AssetZip": "' + zip
            + '","EffectiveDate": "' + effectiveDate
            + '"}}';
        return SL_SummaryAndDetail.callBridgeware(body, recordId, true, false, isIL10);
    }
}
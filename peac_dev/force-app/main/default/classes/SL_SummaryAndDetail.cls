public with sharing class SL_SummaryAndDetail {
    static String integrationName = '';
    static final List<String> xeroxLessorCodes = new List<String> {'111','113','211','213','101','103','471','473','102','104'};
    static final List<String> xeroxBTRLessorCodes = new List<String> {'111','113','211','213'}; // we might use this list of codes in future

    @auraEnabled
    public static String getOpenItems(String recordId) {
        try{
            Contract__c theContract = [SELECT Name, Infolease_Environment__c FROM Contract__c WHERE Id =:recordId];
            Boolean isIL10 = TC_BWUtility.isIL10Record(theContract);
            String responseJSON = SL_SummaryAndDetail.callBridgeware('{"Header": {"NitroApi": "BW.GET.OPEN.ITEM.SUMMARY"}, "Request": {"ContractNumber": "'
                + theContract.Name + '"}}', recordId, false, false, isIL10);
            return '{"actualResponse": ' + responseJSON + ', "isIL10": ' + json.serialize(isIL10)+ '}'; 
        } catch (Exception e) { throw new AuraHandledException(e.getMessage()); }
    }

    @AuraEnabled
    public static string getWaiverCodes(){
        try {
            String jsonResponse = '';
            for(Waiver_Code__mdt waiverCode :[SELECT Waiver_Code__c, Waiver_Code_Description__c FROM Waiver_Code__mdt ORDER BY Waiver_Code__c]){
                jsonResponse = jsonResponse + '{"label": "' + waiverCode.Waiver_Code_Description__c +
                    '", "value": "' + waiverCode.Waiver_Code__c + '"},';
            }
            if(String.isNotBlank(jsonResponse)){
                jsonResponse = '[' + jsonResponse.removeEnd(',') + ']';
            }
            return jsonResponse;
        } catch (Exception e) { throw new AuraHandledException(e.getMessage()); }
    }

    @AuraEnabled
    public static string sendWaiverByOiKey(String recordId, String oiKey, String baseAmt, String stTax, String cnTax,
        String ciTax, String tCnTax, String tCiTax, String adjCode, Boolean isIL10){
        try {
            integrationName = 'Infolease Open Item Waiver';
            return SL_SummaryAndDetail.callBridgeware('{"Header": {"NitroApi": "NITRO.ADJUST.CHARGE"},'
                +'"Request": {"Userid": "Bridgeware", '
                    +'"OIkey": "'+ oiKey + '", '
                    +'"BaseAmt": "' + baseAmt + '", '
                    +'"StTax": "' + stTax + '", '
                    +'"CnTax": "' + cnTax + '", '
                    +'"CiTax": "' + ciTax + '", '
                    +'"TCnTax": "' + tCnTax + '", '
                    +'"TCiTax": "' + tCiTax + '", '
                    +'"AdjCode": "' + adjCode + '"} '
                    +'}}', recordId, true, true, isIL10);
        } catch (Exception e) { throw new AuraHandledException(e.getMessage()); }
    }

    @AuraEnabled
    public static string getDetailByOiKey(String oiKey, Boolean isIL10){
        try {
            return SL_SummaryAndDetail.callBridgeware('{"Header": {"NitroApi": "BW.GET.OPEN.ITEM.DETAIL"}, "Request": {"OiKey": "'
                    + oiKey + '"}}', '', false, false, isIL10);
            // return SL_SummaryAndDetail.callBridgeware('{"Header":{"NitroApi": "BW.PING"}, "Request": {} }', '', false, false, isIL10);
        } catch (Exception e) { throw new AuraHandledException(e.getMessage()); }
    }

    @auraEnabled
    public static String getPaymentHistory(String recordId, Boolean isFirstTime) {
        try{
            Contract__c theContract = [SELECT Name, Infolease_Environment__c FROM Contract__c WHERE Id =:recordId][0];
            String contractNumber = theContract.Name;
            Boolean isIL10 = TC_BWUtility.isIL10Record(theContract);
            Boolean isAlsoIL9 = TC_BWUtility.isMigratedRecord(theContract);
            String finalResponse = SL_SummaryAndDetail.callBridgeware('{"Header": {"NitroApi": "BW.GET.PYMT.SUMMARY"}, "Request": {"ContractNumber": "'
                + contractNumber + '"}}', recordId, false, false, (isIL10 && isFirstTime));
            finalResponse = '{"actualResponse": '+ finalResponse +', "isIL10": ' + isIL10 + ', "isAlsoIL9": ' + isAlsoIL9 + '}';
            return finalResponse;
        } catch (Exception e) { throw new AuraHandledException(e.getMessage()); }
    }

    @AuraEnabled
    public static string getDetailByPymtKey(String pymtKey, Boolean isIL10){
        String nitroApi = 'BW.GET.PYMT.DETAIL';
        return getDetailByPymtKey(pymtKey, isIL10, nitroApi);
    }
    // DP-1458 Misael Romero
    public static String getPaymentHistoryDP(Boolean isFirstTime, Boolean isIL10, Contract__c theContract, String finalResponse) {
        Boolean isAlsoIL9 = TC_BWUtility.isMigratedRecord(theContract);
        finalResponse = '{"actualResponse": '+ finalResponse +', "isIL10": ' + isIL10 + ', "isAlsoIL9": ' + isAlsoIL9 + '}';
        return finalResponse;
    }

    public static string getDetailByPymtKey(String pymtKey, Boolean isIL10, String nitroApi){
        try {
            return SL_SummaryAndDetail.callBridgeware('{"Header": {"NitroApi": "' + nitroApi + '"}, "Request": {"PymtKey":"'
                    + pymtKey + '"}}', '', false, false, isIL10);
        } catch (Exception e) { throw new AuraHandledException(e.getMessage()); }
    }
    // DP-1458 Misael Romero
    @AuraEnabled
    public static string getDetailByPymtKeyDP(String pymtKey, Boolean isIL10){
        String nitroApi = isIL10? 'BW.PYMT.INFO.DETAIL': 'BW.GET.PYMT.DETAIL';// DP-2012 Misael Romero
        return getDetailByPymtKey(pymtKey, isIL10, nitroApi);
    }

    public static string deleteExternalCMBillable(String miscBillableId){
        return SL_SummaryAndDetail.callBridgeware('{"Header": {"NitroApi": "BW.DELETE.MISC.BILLABLE"}, "Request": {"MiscBillableId": "'
                    + miscBillableId + '","WaiveMiscInvd": "0"}}', '', true, false, false);
    }

    @AuraEnabled
    public static string requestByContractNumber(String recordId, String nitroApiOption){
        return requestByContractNumber(recordId, nitroApiOption, '');
    }

    @AuraEnabled
    public static string requestByContractNumber(String recordId, String nitroApiOption, String additionalKeys){
        try {
            Contract__c contract = [SELECT Name, Status__c, Renewal_Status__c, Quote_Buyout_Types__c, Infolease_Environment__c,
                Opportunity__r.Purchase_Options__c, Lessor_Code__c, Branch_Code__c, Dealer_Name__r.Discount_for_Upgrade_to_Keep__c
                FROM Contract__c WHERE Id =:recordId][0];
            String contractNumber = contract.Name;
            Boolean isIL10 = TC_BWUtility.isIL10Record(contract);
            String nitroApi;
            Boolean saveLog = false;
            Boolean isCallBridgeWare = true;
            Boolean isFirstTime = true;
            Boolean isFromPeacBuyout = false;
            String result = '';
            if(additionalKeys == null){
                additionalKeys = '';
            }
            switch on nitroApiOption {
                when 'buyoutQuotes' {
                    nitroApi = 'BW.GET.BUYOUT.QUOTES';
                    isFromPeacBuyout = additionalKeys == 'fromPEAC_BuyOut';
                    additionalKeys = '';
                }
                when 'createBuyout', 'createBuyoutDP' {
                    nitroApi = 'BW.CREATE.BUYOUT.QUOTE';
                    saveLog = true;
                    integrationName = 'InfoLease Generate Buyout Quote' + (nitroApiOption == 'createBuyoutDP'? ' DP': '');
                    String buyoutType = '';
                    List<Object> assets = new List<Object>();
                    if(additionalKeys.isNumeric()){
                        buyoutType = additionalKeys;
                    }else{
                        Map<String, Object> keysForPartial = (Map<String, Object>)JSON.deserializeUntyped(additionalKeys);
                        buyoutType = (String)keysForPartial.get('BuyoutType');
                        assets = (List<Object>)keysForPartial.get('Assets');
                    }
                    if(nitroApiOption == 'createBuyoutDP' 
                    || (contract.Quote_Buyout_Types__c != null && contract.Quote_Buyout_Types__c.contains(buyoutType))){
                        String quoteType = nitroApiOption == 'createBuyoutDP'? '0002': '0001';// DP-1511 Misael Romero
                        additionalKeys = ', "BuyoutType":"' + buyoutType 
                            + '", "QuoteType": "' + quoteType + '", "QuotedBy":"' + System.UserInfo.getUserName().left(16) + '"';
                        if(buyoutType == '14' || buyoutType == '78'){// SL-2629 Misael Romero
                            Decimal discountRate = Decimal.valueOf(contract.Dealer_Name__r?.Discount_for_Upgrade_to_Keep__c ?? '0.000');
                            // if(discountRate > 0){// DP-1861 Misael Romero
                                additionalKeys += ', "DiscountRate": ' + JSON.serialize(discountRate.toString());
                            // }
                        }
                        if(assets != null && assets.size() > 0){
                            additionalKeys += ', "Assets": ' + JSON.serialize(assets);
                        }
                    }
                    // SL-2672 Misael Romero
                    Integer totalContractAssets = [SELECT COUNT() FROM Contract_Asset__c 
                        WHERE Contract__c =:recordId AND Asset_Disposed_Date__c = NULL AND Asset_Cost__c > 0];
                    assets = assets ?? new List<Object>();
                    if((assets.size() == 0 && totalContractAssets > 200) || assets.size() > 200){
                        isCallBridgeWare = false;
                    }
                }
                when 'createInsurance' {
                    nitroApi = 'BW.CREATE.INSURANCE';
                    saveLog = true;
                    integrationName = 'InfoLease Create Insurance';
                }
                when 'getPaymentHistoryDP'{// DP-1458 Misael Romero
                    isFirstTime = Boolean.valueOf(additionalKeys);
                    isIL10 = isIL10 && isFirstTime;
                    nitroApi = isIL10? 'BW.PYMT.INFO.SUMMARY': 'BW.GET.PYMT.SUMMARY';// DP-2012 Misael Romero
                    additionalKeys = '';
                }
                when 'getValidQB', 'saveQB', 'getPurchaseOption', 'getUserProfile', 'generateRAs' {
                    isCallBridgeWare = false;
                }
                when else {
                    nitroApi = '';
                }
            }            
            if (isCallBridgeWare){
                result = SL_SummaryAndDetail.callBridgeware('{"Header": {"NitroApi": "'
                    + nitroApi + '"}, "Request": {"ContractNumber": "'
                    + contractNumber + '"' + additionalKeys + '}}', recordId, saveLog, false, isIL10);
            }else{
                switch on nitroApiOption {
                    when 'getValidQB' {
                        result = getValidQB(contract);
                    }
                    when 'saveQB' {
                        result = saveQB(contract, additionalKeys);
                    }
                    when 'getPurchaseOption' {
                        result = getPurchaseOption(contract);
                    }
                    when 'getUserProfile' {
                        result = getUserProfile(contract);
                    }
                    when 'generateRAs'{
                        result = generateRAs(contract);
                    }
                    when 'createBuyout', 'createBuyoutDP'{
                        result = generateError(nitroApiOption);
                    }
                }
            }
            // after call processing
            switch on nitroApiOption {
                when 'buyoutQuotes' {// SL-2640 Misael Romero
                if(!isFromPeacBuyout){
                    result = mapMiscSummarySF(result);
                }
            }
                when 'getPaymentHistoryDP'{
                    result = getPaymentHistoryDP(isFirstTime, isIL10,  contract, result);
                }
            }
            
            return result;
        } catch (Exception e) {
            if(Test.isRunningTest()){
                throw e;
            }else{
                throw new AuraHandledException(e.getMessage());
            }
        }
    }

    @testVisible
    private static String getValidQB(Contract__c contract){
        String result = '';
        List<String> validQBs = new List<String>();
        List<String> options = new List<String>();
        Boolean isOEG = contract.Branch_Code__c=='00004'||contract.Branch_Code__c=='00040'||contract.Branch_Code__c=='00044';
        Decimal discountRate = Decimal.valueOf(contract.Dealer_Name__r?.Discount_for_Upgrade_to_Keep__c ?? '0.000'); // SL-2629
        if(xeroxLessorCodes.contains(contract.Lessor_Code__c) 
        || (isOEG && discountRate > 0)){
            String jsonQBs = buyoutCreationV2(contract.Id);
            if(jsonQBs.contains('"quoteBuyouts"')){
                Map<String, Object> quoteBuyoutObj = (Map<String, Object>)JSON.deserializeUntyped(jsonQBs);
                String quoteBuyouts = (String)quoteBuyoutObj.get('quoteBuyouts');
                if(quoteBuyouts != null){
                    validQBs = quoteBuyouts.split(';');
                }
            }
        }else{
            if(contract.Status__c != 'Disposed' && contract.Status__c != 'Disposed - Charged Off'
                && contract.Renewal_Status__c == 'A'){
                validQBs = new List<String>{'37', '40', '41'};
            }else{
                if(contract.Status__c == 'Active' && (contract.Renewal_Status__c == 'E' || String.isEmpty(contract.Renewal_Status__c))){
                    validQBs = new List<String>{'1', '20', '21', '6', '22', '14', '26', '44', '45', '46', '47'};
                }
            }
        }
        
        list<Schema.PicklistEntry> values = Schema.getGlobalDescribe().get('Contract__c')
                .getDescribe().Fields.getMap().get('Quote_Buyout_Types__c').getDescribe().getPickListValues();
        for(Schema.PicklistEntry pickListValue: values){
            if(validQBs.contains(pickListValue.getValue())){
                options.add('{ "label": "' + pickListValue.getLabel() + '", "value": "' + pickListValue.getValue() + '" }');
            }
        }
        result = '{"filteredQBs": [' + String.join(options, ',') + '], "quoteBuyoutTypes": "'
            + contract.Quote_Buyout_Types__c + '"}';
        return result;
    }

    @testVisible
    private static String saveQB(Contract__c contract, String quoteBuyoutTypes){
        String result = '';
        contract.Quote_Buyout_Types__c = quoteBuyoutTypes;
        update contract;
        result = 'success';
        return result;
    }

    @testVisible
    private static String getPurchaseOption(Contract__c contract){
        String result = '';
        result = '{"oppPurchaseOpt": ' + JSON.serialize(contract.Opportunity__r?.Purchase_Options__c)+ '}';
        return result;
    }
    private static String getUserProfile(Contract__c contract){
        Profile currentProfile = [SELECT Id, Name FROM Profile WHERE Id = :UserInfo.getProfileId()];
        String result = '';
        Boolean hasPermissionToAM = label.PEAC_Return_Authorization_Button_Access.contains(currentProfile.Name);
        result = '{"isAssetManagement": ' + JSON.serialize(Boolean.valueOf(hasPermissionToAM))+ '}';
        return result;
    }
    private static String generateRAs(Contract__c contract){
        List<Contract_Asset__c> contractAssets = [SELECT Id, Name FROM Contract_Asset__c WHERE Contract__c = :contract.Id];
        String result = '';
        List<String> contractAssetIds = new List<String>();
        for(Contract_Asset__c theCA :contractAssets){
            contractAssetIds.add(theCA.Id);
        }
        if(contractAssetIds.size() > 0){
            // uncomment only when we can use DocGen
            // System.enqueueJob(new SL_DocGenCalloutQ(contractAssetIds, 'POC Contracts W Address 3 email')); // change to the actual DocGen Package name
            result = '{"contractAssetIds": ' + JSON.serialize(contractAssetIds)
                + ', "dateRequested": ' + JSON.serialize(Datetime.now()) + '}';
        }else{
            result = '{"docGenError": "No Contract Assets found."}';
        }
        return result;
    }
// SL-2672 Misael Romero
    private static String generateError(String nitroApiOption){
        String errorJson = '{"response": {"Response": {"Success": "false", "Errors": ["';
        switch on nitroApiOption {
            when 'createBuyout' {
                errorJson += 'This Contract contains large number of assets, Please generate Buyouts in Infolease';
            }
            when 'createBuyoutDP' {
                errorJson += 'This contract contains large number of assets, Please reach out to your PEAC Lease Admin to generate Buyout';
            }
        }
        return errorJson +'"]}}}';
    }

    public static String callBridgeware(String body, String recordId, Boolean saveLog, Boolean isWaiver, Boolean isIL10){
        String JSONResponse = '';
        SL_InfoleaseUtils util = SL_InfoleaseUtils.getInstance();
        IL10_Flag__c il10Setting = IL10_Flag__c.getValues('GeneralSetting');
        Http h = new Http ();
        HttpRequest req = new HttpRequest ();

        if (util.getServiceSettings().Mock_Callout__c && !String.isEmpty(util.getServiceSettings().Mock_Callout_createCustomer__c)) {
            Blob headerValue = Blob.valueOf('username' + ':' + 'password');
            String authorizationHeader = 'Basic ' + EncodingUtil.base64Encode(headerValue);
            req.setHeader('Authorization', authorizationHeader);
            req.setEndpoint(util.getServiceSettings().Mock_Callout_createCustomer__c);
        } else {
            if(isIL10 && il10Setting.use_IL10__c){
                TC_BWUtility.requestToIL10(req);
            }else{
                req.setEndpoint('callout:Bridgeware'+'/subroutine');
            }
        }

        req.setMethod('POST');
        req.setHeader('CONFIG-NAME', util.getServiceSettings().Config_Name__c);
        req.setHeader('Content-Type','application/json');
        body = isIL10 && il10Setting.use_IL10__c? '{"inputs": ' + body + '}': body;
        req.setBody(body);
        system.debug('JSON request: ' + body);
        system.debug('JSON request tail: ' + body.right(255));
        req.setTimeout(120000);
        if(Test.isRunningTest()){
            Test.setMock(HttpCalloutMock.class, new SL_OnBaseCalloutTest.RetrieveMock());
        }
        HttpResponse resp = h.send(req);
        JSONResponse = resp.getBody();
        system.debug('JSONResponse: ' + JSONResponse);
        system.debug('JSONResponse tail: ' + JSONResponse.right(255));
        if(saveLog){
            Decimal waivedAmount = null;
            List<String> errors = new List<String>();
            String errorMessage = '';
            JSONParser parser = JSON.createParser(JSONResponse);
            while (parser.nextToken() != null) {
                if(isWaiver && parser.getCurrentToken() == JSONToken.FIELD_NAME && parser.getText() == 'TotalWaived') {
                    parser.nextToken();
                    waivedAmount = Decimal.valueOf(parser.getText());
                }
                if (parser.getCurrentToken() == JSONToken.FIELD_NAME && parser.getText() == 'Errors') {
                    parser.nextToken();
                    if(parser.getCurrentToken() == JSONToken.START_ARRAY ){
                        parser.nextToken();
                        while (parser.getCurrentToken() != JSONToken.END_ARRAY){
                            String errorText = parser.getText().trim();
                            if(errorText.length()> 0){
                                errors.add(parser.getText());
                            }
                            parser.nextValue();
                        }
                    }
                }
            }
            if(errors.size() > 0){
                errorMessage = String.join(errors, ', ');
            }   
            SL_InfoleaseLoggingUtils.addLog(integrationName, recordId,  req.getBody(), JSONResponse, errorMessage, errorMessage.length() > 0, waivedAmount);
            SL_InfoleaseLoggingUtils.flush();
        }
        return JSONResponse;
    }
  public static boolean isContractBlocked(Contract__c currentCon){
        If(currentCon.Quote_Buyout__c =='04'||currentCon.Quote_Buyout__c =='07'||currentCon.Quote_Buyout__c =='13'
            ||currentCon.Quote_Buyout__c =='15'||currentCon.Quote_Buyout__c =='18'||currentCon.Quote_Buyout__c =='20'){
            return true;
        }else{
            return false;
        }
            
    }
    @AuraEnabled
    public static  String buyoutCreationV2 (String recordId){
        Contract__c contract = [SELECT Id, Name, Status__c, Renewal_Status__c, Quote_Buyout_Types__c, Infolease_Environment__c, Quote_Buyout__c,
            Branch_Code__c, Dealer_Name__r.TUR_Penalty__c, Dealer_Name__r.Penalty_for_Buyout__c, Dealer_Name__r.Days_of_Intent__c, 
            Dealer_Name__r.Discount_for_Upgrade_to_Keep__c, Term_Date__c, Lessor_Code__c, Contract_Type__c, Dealer_Name__r.Eligible_for_BORs__c, Legacy_Contract_Id__c
            FROM Contract__c WHERE Id =:recordId][0];
        List<String> acceptedQuoteBuyouts = new List<String> {'01', '02', '04', '05', '07', '08', '09', '10', '13', '15', '18', '20'};
        String result;
        String genericErrorJson = '{"errmessage":"To process your request, please contact customer service at buyouts@peacsolutions.com. Thank you"}';
        if(acceptedQuoteBuyouts.contains(contract.Quote_Buyout__c)){
            // DP-806
            Integer daysOfIntent = Integer.valueOf(contract.Dealer_Name__r != null && contract.Dealer_Name__r.Days_of_Intent__c != null? contract.Dealer_Name__r.Days_of_Intent__c: 0);
            Integer penaltyForBuyout = Integer.valueOf(contract.Dealer_Name__r != null && contract.Dealer_Name__r.Penalty_for_Buyout__c != null? contract.Dealer_Name__r.Penalty_for_Buyout__c: 0);
            Boolean isOEG = contract.Branch_Code__c=='00004'||contract.Branch_Code__c=='00040'||contract.Branch_Code__c=='00044';
            if(xeroxLessorCodes.contains(contract.Lessor_Code__c)){
                if(contract.Contract_Type__c == 'CS'){
                    contract.Quote_Buyout_Types__c = '73;78';
                }else if(contract.Contract_Type__c == 'TL' && contract.Renewal_Status__c == 'A'){
                    contract.Quote_Buyout_Types__c = '82;81;80;79';
                }else if(penaltyForBuyout == 3 && contract.Term_Date__c != null && Date.today() <= contract.Term_Date__c.addDays(daysOfIntent * -1) && contract.Contract_Type__c == 'TL'){
                    //Dealer Portal
                    if(System.Site.getSiteId() != null){
                        if(contract.Dealer_Name__r.Eligible_for_BORs__c && contract.Legacy_Contract_Id__c!=null){
                            contract.Quote_Buyout_Types__c = '73;76;78;72';
                        }
                        else{
                            contract.Quote_Buyout_Types__c = '73;76;78';
                        }
                    }
                    else {
                    contract.Quote_Buyout_Types__c = '73;76;78;72';
                    }
                }else if(penaltyForBuyout == 0 || (contract.Term_Date__c != null &&  Date.today() > contract.Term_Date__c.addDays(daysOfIntent * -1))){
                    contract.Quote_Buyout_Types__c = '73;76;78;70';
                }
                if(System.Site.getSiteId() != null && !xeroxBTRLessorCodes.contains(contract.Lessor_Code__c)){
                    // List<String> bannedForNonBTR = new List<String> {'70', '72', '79'};
                    List<String> bannedForNonBTR = new List<String> {'70','79'};
                    removeQBTypes(contract, bannedForNonBTR);
                }
            }else if((contract.Renewal_Status__c == 'A'||contract.Renewal_Status__c == 'E')){
                if(isOEG){
                    if(contract.Renewal_Status__c == 'A'){
                        contract.Quote_Buyout_Types__c = '38;10;37';
                    }
                    if(contract.Renewal_Status__c == 'E'){
                        contract.Quote_Buyout_Types__c = '39;6;35';
                    }
                }else{
                    if(contract.Renewal_Status__c == 'A'){
                        contract.Quote_Buyout_Types__c = '38;10';
                    }
                    if(contract.Renewal_Status__c == 'E'){
                        contract.Quote_Buyout_Types__c = '39;6';
                    }
                }
            }else if(contract.Renewal_Status__c == NULL){
                if(isOEG){
                    if(contract.Term_Date__c != null && contract.Term_Date__c.DaysBetween(Date.Today()) >= 180){ //Needs today operation
                        if(contract.Dealer_Name__r.TUR_Penalty__c == 'Yes'){
                            contract.Quote_Buyout_Types__c = '1;6;36';
                        }else{
                            contract.Quote_Buyout_Types__c = '1;6;35';
                        }
                    }else{
                        contract.Quote_Buyout_Types__c = '1;6;35';
                    }
                    addDiscountCode(contract);// SL-2629
                }else{
                    contract.Quote_Buyout_Types__c = '1;6';
                }
            }
            if(String.isBlank(contract.Quote_Buyout_Types__c)){
                result = genericErrorJson;
            }else{
            result = '{"quoteBuyouts": ' + JSON.serialize(contract.Quote_Buyout_Types__c)+ '}';
            }
        }else{
            result = genericErrorJson;
        }
        return result;
    }

    @AuraEnabled
    public static String toggleLockContract(String contractId, Boolean isLocking){
        Contract__c contract = [SELECT Name, Quote_Buyout__c, Infolease_Environment__c FROM Contract__c WHERE Id =:contractId][0];
        String result = '{"message":"could not Lock"}';
        Boolean isBlocked = isContractBlocked(contract);
        if(isBlocked){
            if(isLocking){
                contract.Quote_Buyout__c = '01';
            }
            SL_InfoleaseContractService service = new SL_InfoleaseContractService();
            String jsonBody = '{"ContractNumber": ' + JSON.serialize(contract.Name) + ', "QUOTE_BUYOUT": ' + JSON.serialize(contract.Quote_Buyout__c) + '}';

            jsonBody = '{'+
                '"Header" : {'+
                '"NitroApi" : "BW.UPDATE.CONTRACT"'+
                '},'+
                '"Request" : '+ jsonBody +
                '}';
            SL_InfoleaseIntegrationResponseWrapper response = service.updateContract(null, jsonBody, contract.Infolease_Environment__c);
            result='{"message":"success", "lockingPerformed": true}';
            // call the integration to send the quote buyout no update to contract;
        }else{
            result = '{"message":"success", "lockingPerformed": false}';
        }
        return result;
    }
    
     // Varun made some changes.
    @AuraEnabled
    public static String sendBuyout(String contractId, String detail){
        User u = [SELECT Id, Name, Email FROM USer WHERE ID = :userinfo.getUSerID()];
        PageReference pdf = Page.PEAC_BPPrintEmail;//pEAC_CustomerBuyOutLetter is the name of vf page
        
        pdf.getParameters().put('recId',contractId);

        Blob body;                
        try{
            body = pdf.getContent();
        }catch(VisualforceException e){
            body=Blob.valueOf('testing');
        }   
        system.debug('body:'+body);         
        OrgWideEmailAddress[] owea = [select Id from OrgWideEmailAddress where Address = 'noreply@peacsolutions.com'];
        Contract__c contract = [SELECT Id, Name, Dealer_Name__r.Name,dealer_name__r.Owner.Email, Dealer_Name__r.Dealer_Number__c FROM Contract__c WHERE Id = :contractId];
        Messaging.EmailFileAttachment attach = new Messaging.EmailFileAttachment();
        attach.setContentType('application/pdf');
        attach.setFileName('email_pdf.pdf');
        attach.setInline(false);
        attach.Body = body;
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setUseSignature(false);
        if ( owea.size() > 0 ) {
            mail.setOrgWideEmailAddressId(owea.get(0).Id);
        }
        mail.setToAddresses(new String[] { u.Email});
        mail.setSubject('Buyout PDF File');
        mail.setHtmlBody('The following PEAC Portal admin or user has generated a trade-up to keep/return quote:<br/>Full Name: '+u.Name+'<br/>Dealer #: '+contract.Dealer_Name__r.Dealer_Number__c+'<br/>Contract #: '+contract.Name);
        mail.setFileAttachments(new Messaging.EmailFileAttachment[] { attach }); 
        // Send the email    
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        // mail.setToAddresses(new String[] {contract.OwnerEmail__c});
        mail.setToAddresses(label.Buyout_BCC_Email.split(','));
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        return 'success';
    }
    
    @AuraEnabled
    public static List<Buyout__c> getBuyout(String contractId){
        // return [SELECT Buyout_Amount__c, Buyout_Description__c, Buyout_Type__c, Contract__c, Date_Quoted__c, Early_Termination_Fee__c, Ending_Deposit__c, 
        //     Expiration_Date__c, Insurance__c, Most_Recent__c 
        //     FROM Buyout__c WHERE Contract__c = :contractId ORDER BY createddate DESC];
        return [SELECT Buyout_Type__c, Contract__c, Buyout_Description__c, Buyout_Amount__c, Most_Recent__c, Receivable_Balance__c, 
            Residual__c, SalesTax__c, LateCharges__c, Early_Termination_Fee__c, Security_Deposit__c, Ending_Deposit__c, 
            Service_pass_through__c, Property_tax__c, Insurance__c, Other_Lease_Charges__c, Total_Buyout__c, Partial_Buyout__c, 
            Date_Quoted__c, Expiration_Date__c, Id, Name 
            FROM Buyout__c WHERE Contract__c = :contractId AND Most_Recent_DP__c = true  AND Show_To_DP_Users__c = TRUE  order by createddate ASC]; // Buyout_Type__c
    }
     @AuraEnabled
    public static Contract__c getContract(String contractId){
        return [SELECT Id, Customer__c,Customer__r.Name,Name, Invoice_Description__c, Commencement_Date__c, Payments_Remaining__c, Contract_Term__c, Gross_Equipment_Cost__c, Payment_Amount__c, Current_Rental_Payment__c, Next_Payment_Date__c, Quote_Buyout__c FROM Contract__c WHERE Id = :contractId];
    }
    
    // public class FieldWrapper{
    //     public String label{get;set;}
    //     public Double value{get;set;}
    //     public List<buyoutrows> rows{get; set;}
    //     public FieldWrapper(String label, String value){
    //         this.label = label;
    //         this.value = Double.valueof(value);
    //     }
    // }
    
    // public class buyoutrows{
    //     public Decimal value {get; set;}
    //     public String QuoteSeq {get; set;}
    // }
    
    
    @AuraEnabled
    public static String BuyoutReplacement(String payload){
        Map<String,Object> JsonRsponse = (Map<String,Object>)JSON.deserializeUntyped(payload);
        Map<String,Object> quoteResponse = (Map<String,Object>)JsonRsponse.get('Response');
        List<Object> payloadArray = (List<Object>) quoteResponse.get('Quotes');
        List<Map<String,Object>> newPayloadArray = new List<Map<String,Object>>();
        for(Object obj:payloadArray){
            Map<String,Object> qbuyout=(Map<String,Object>)obj;
            String qBuyoutType= (String)qbuyout.get('QuoteType');
            IF(qBuyoutType=='1'||qBuyoutType=='38'||qBuyoutType=='39'){
                qbuyout.put('QuoteTypeDesc','Buyout');                
            }
            IF(qBuyoutType=='6'||qBuyoutType=='10'||qBuyoutType=='06'){
                qbuyout.put('QuoteTypeDesc','Trade Up to Keep');                
            }
            IF(qBuyoutType=='35'||qBuyoutType=='36'||qBuyoutType=='37'){
                qbuyout.put('QuoteTypeDesc','Trade Up to Return');                
            }
            newPayloadArray.add(qbuyout);
        }
        quoteResponse.put('Quotes',newPayloadArray);
        JsonRsponse.put('Response',quoteResponse);
        String newPayload = JSON.serialize(JsonRsponse);
        return newPayload;
    }
    
    @AuraEnabled
    public static String sendCreateBuyout(String contractId){
        User u = [SELECT Id, Name, Email,Contact.account.Owner.Email FROM USer WHERE ID = :userinfo.getUSerID()];
        OrgWideEmailAddress[] owea = [select Id from OrgWideEmailAddress where Address = 'noreply@peacsolutions.com'];
        Contract__c contract = [SELECT Id, Name, Dealer_Name__r.Name, dealer_name__r.Ownerid, Dealer_Name__r.Dealer_Number__c FROM Contract__c WHERE Id = :contractId];
        system.debug('contract::'+contract.dealer_name__r.Ownerid);
        return sendBuyoutEmail(contract, u, owea);
    }
    @AuraEnabled
    public static String sendSummaryBuyout(String contractId, String buyoutTotal, String tradeReturnTotal, String tradeKeepTotal){
        User u = [SELECT Id, Name, Email,Contact.account.Owner.Email FROM USer WHERE ID = :userinfo.getUSerID()];
        OrgWideEmailAddress[] owea = [select Id from OrgWideEmailAddress where Address = 'noreply@peacsolutions.com'];
        Contract__c contract = [SELECT Id, Name, Dealer_Name__r.Name, dealer_name__r.OwnerId, Dealer_Name__r.Dealer_Number__c, DP_Buyout_Total__c, DP_Trade_Up_to_Keep_Total__c, DP_Trade_Up_to_Return_Total__c FROM Contract__c WHERE Id = :contractId];
        if(contract.DP_Buyout_Total__c <> buyoutTotal || contract.DP_Trade_Up_to_Keep_Total__c <> tradeKeepTotal || contract.DP_Trade_Up_to_Return_Total__c <> tradeReturnTotal){
            contract.DP_Buyout_Total__c = buyoutTotal;
            contract.DP_Trade_Up_to_Keep_Total__c = tradeKeepTotal;
            contract.DP_Trade_Up_to_Return_Total__c = tradeReturnTotal;
            update contract;
            return sendBuyoutEmail(contract, u, owea);
        }
        return 'success';
    }
    
    public static String sendBuyoutEmail(Contract__c contract, User u, OrgWideEmailAddress[] owea){
       
        // Fetch the email addresses from the custom label
        String additionalEmailsFromLabel = System.Label.Buyout_BCC_Email;
        
        // Split the custom label value into a list of email addresses
        List<String> additionalEmailAddresses = additionalEmailsFromLabel.split(',');

        // Initialize the list of email addresses with the logged-in user's email
        List<String> toAddresses = new List<String>{ UserInfo.getUserEmail() };

        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        if ( owea.size() > 0 ) {
            mail.setOrgWideEmailAddressId(owea.get(0).Id);
        }
        //mail.setToAddresses(new String[] {contract.OwnerEmail__c});
        mail.setSubject('Dealer Portal Notification: Quote Generated');
        mail.setHtmlBody('The following PEAC Portal admin or user has generated a trade-up to keep/return quote:<br/>Full Name: '+u.Name+'<br/>Dealer #: '+contract.Dealer_Name__r.Dealer_Number__c+'<br/>Contract #: '+contract.Name);
        
        // Send the email    
        // Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        mail.setToAddresses(label.Buyout_BCC_Email.split(','));
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        return 'success';
        
    }
    // SL-2640 Misael Romero
    public static string mapMiscSummarySF(String jsonBuyouts){
        List<Object> quotesObjs = SL_PartialBuyout.getQuotesFromJson(jsonBuyouts);
        List<Object> updatedQuotes = new List<Object>();
        if(quotesObjs != null && quotesObjs.size() > 0){
            Set<String> mappedFieldNames = new Set<String>();
            SL_PartialBuyout.getGL_Code_Mapping();
            for(GL_Code_Mapping__mdt glCodeMapping :SL_PartialBuyout.GL_Code_Mapping.values()){
                mappedFieldNames.add(glCodeMapping.Buyout_Field__c);
            }
            for(Object theObj : quotesObjs){
                pEAC_BuyOutController.BuyoutWrapper buyoutQuote = (pEAC_BuyOutController.BuyoutWrapper)JSON.deserialize(
                        JSON.serialize(theObj), pEAC_BuyOutController.BuyoutWrapper.class);
                Buyout__c tempBuyout = SL_PartialBuyout.fetchMiscTotals(new Buyout__c(), buyoutQuote.MiscSummary);
                List<pEAC_BuyOutController.MiscSummary> totalizedMiscs = new List<pEAC_BuyOutController.MiscSummary>();
                Map<String,Schema.SObjectField> buyoutFields = Schema.Buyout__c.SObjectType.getDescribe().fields.getMap();
                for(String fieldName : mappedFieldNames){
                    if((Decimal)tempBuyout.get(fieldName) > 0){
                        pEAC_BuyOutController.MiscSummary thisSummary = new pEAC_BuyOutController.MiscSummary();
                        thisSummary.MiscDescription = buyoutFields.get(fieldName).getDescribe().getLabel();
                        thisSummary.MiscTotal = String.valueOf(tempBuyout.get(fieldName));
                        totalizedMiscs.add(thisSummary);
                    }
                }
                buyoutQuote.MiscSummary = totalizedMiscs;
                buyoutQuote.showIt = true;
                updatedQuotes.add((Object)buyoutQuote);
            }
        }
        Map<String, Object> rootObj = (Map<String, Object>)JSON.deserializeUntyped(jsonBuyouts);
        Map<String, Object> outerResponse = (Map<String, Object>)rootObj.get('response');
        Map<String, Object> responseObj = (Map<String, Object>)(outerResponse ?? rootObj).get('Response');
        if(responseObj == null){
            responseObj = new Map<String, Object>();
        }
        responseObj.put('Quotes', updatedQuotes);
        if(outerResponse != null){
            outerResponse.put('Response', responseObj);
            rootObj.put('response', outerResponse);
        }else{
            rootObj.put('Response', responseObj);
        }
        return JSON.serialize(rootObj);
    }
    
   @AuraEnabled
    public static void updateOpportunity(String recordId) {
        system.debug('recordId:'+recordId);
        try{
            
          //  Dealer__c dealer = [select Id, Dealer__c from Dealer__c where Opportunity__c = :recordId limit 1];
            opportunity opptydealer = [select Id, Application__c,Docs_In_From_Portal__c,Opportunity_Status__c,StageName, Dealer_Account__c from opportunity where id = :recordId limit 1];
            //system.debug('dealer:'+dealer);
            system.debug('opptydealer:'+opptydealer);
            //if(dealer == null) {
            if(opptydealer == null) {
                
                return;
            }
            Account acc = null;
            List<Account> accList = [SELECT Id,SAM_Email__c,Ambassador_Email__c,Account_Owner_Email__c from Account where Id = :opptydealer.Dealer_Account__c];
            if(accList.size() > 0){
                acc = accList[0];
            }
            
           OrgWideEmailAddress owe = [SELECT Id, Address FROM OrgWideEmailAddress where Address = 'noreply@peacsolutions.com'];
            
           List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
            
            if(acc?.Account_Owner_Email__c <> null){
               List<string> emailAddr = new List<String>();
                emailAddr.add(acc.Account_Owner_Email__c);
                if(acc?.SAM_Email__c <> null) {
                    emailAddr.add(acc.SAM_Email__c);
                }
                if(acc?.Ambassador_Email__c <> null) {
                    emailAddr.add(acc.Ambassador_Email__c);
                }
                
                Opportunity opp = [SELECT Id, Application__c,Docs_In_From_Portal__c,Opportunity_Status__c,StageName FROM Opportunity WHERE ID = :recordId];
                //Messaging.SingleEmailMessage mail = CustomSendMailUtil.SetCustomSingleEmail(emailAddr, 'Portal Application #'+opp.Application__c+' has submitted documents for funding','The dealer has submitted documents for funding for app #'+opp.Application__c+'. Please review the funding package and inform the dealer if any other information is required for funding. \n'+URL.getOrgDomainURL().toExternalForm() + '/' +recordID +'.',null,owe.id);               
                Messaging.SingleEmailMessage mail = CustomSendMailUtil.SetCustomSingleEmail(emailAddr, 'Portal Application #'+opp.Application__c+' has submitted documents for funding','The dealer has submitted documents for funding for app #'+opp.Application__c+'.\n Please review the funding package and inform the dealer if any other information is required for funding. \n'+URL.getOrgDomainURL().toExternalForm() + '/' +recordID +'.',null,owe.id);
                system.debug('message mail:'+mail);
                emails.add(mail);
                List<Messaging.SendEmailResult> results = Messaging.sendEmail(emails);
                system.debug('results:'+results);
           }
           SL_DPImperative.SendOnBaseEmailXBS(recordId);
           if(opptydealer.StageName == 'Docs In')
           {
              opptydealer.Opportunity_Status__c = 'Docs in - Pending review';
           }
           opptydealer.Docs_In_From_Portal__c = System.Now();
           update opptydealer;
            //Update new Opportunity(id = recordId, Docs_In_From_Portal__c = System.now());
           
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled
    public static string sendBuyoutCreationEmail(Id contractId, List<String> lstEmailAddress){
        String result =  'work in progress... again';
        try {
            List <OrgWideEmailAddress> noreply = new List <OrgWideEmailAddress> ([SELECT Id, Address, DisplayName from OrgWideEmailAddress WHERE address = 'noreply@peacsolutions.com']);
            List<EmailTemplate> et = [SELECT Id, Name, DeveloperName,  FolderName, Subject
                FROM EmailTemplate WHERE Folder.Name = 'Email Notification' AND (DeveloperName = 'XFS_Buyout')];
            List<Contract__c> targetContract = [SELECT Id, Name FROM Contract__c WHERE Id = :contractId];
            if(noreply.size() == 1 && et.size() == 1 && targetContract.size() == 1){
                Messaging.SingleEmailMessage renderStoredEmailTemplate = Messaging.renderStoredEmailTemplate(et[0].Id, System.UserInfo.getUserId(), targetContract[0].Id);
                List<Messaging.RenderEmailTemplateBodyResult> renderEmailTemplate = Messaging.renderEmailTemplate(System.UserInfo.getUserId(), targetContract[0].Id, new List<String>{et[0].Subject});
                List<Messaging.SingleEmailMessage> mailPouch = new List<Messaging.SingleEmailMessage>();
                // PageReference pdf = Page.pEAC_CustomerEmailBuyOut;
                PageReference pdf = Page.PEAC_BPPrintEmail;
                pdf.getParameters().put('recId',contractId);
                Blob body = Test.isRunningTest()? Blob.valueOf('test content'): pdf.getContent();
                for(String emailAddress :lstEmailAddress){
                    Messaging.SingleEmailMessage mail = CustomSendMailUtil.SetCustomSingleEmail(
                        new List<String>{emailAddress},
                        renderEmailTemplate[0].getMergedBody(),
                        null,//(emailTemplateList[0].HtmlValue == null ? renderEmailTemplate[1].getMergedBody() : ''), 
                        renderStoredEmailTemplate.getHTMLBody(),//(emailTemplateList[0].HtmlValue != null? renderEmailTemplate[1].getMergedBody() : ''),
                        noreply[0].Id
                    );
                    Messaging.EmailFileAttachment attach = new Messaging.EmailFileAttachment();
                    attach.setContentType('application/pdf');
                    attach.setFileName('email_pdf.pdf');
                    attach.setInline(false);
                    attach.Body = body;
                    mail.setFileAttachments(new Messaging.EmailFileAttachment[] { attach }); 
                    mailPouch.add(mail);
                }
                if(mailPouch.size() > 0){
                    Messaging.sendEmail(mailPouch);
                    result = 'email(s) sent';
                }
            }
            return result;
        } catch (Exception e) { throw new AuraHandledException(e.getMessage()); }
    }
    
    @AuraEnabled
   public static Boolean checkRelatedRecords(string oppId) {
        List<dsfs__DocuSign_Status__c> docuSignList = [select Id from dsfs__DocuSign_Status__c where dsfs__Opportunity__c = :oppId AND CreatedById =: UserInfo.getUserId()];
        if(docuSignList.size() > 0) {
            return true;
        }
        List<Opportunity_Attachment__c> oppList = [select Id from Opportunity_Attachment__c where Opportunity__c = :oppId AND CreatedById =: UserInfo.getUserId()];
        
        if(oppList.size() > 0) {
            return true;
        }
        return false;
    }
    
    @InvocableMethod(label='get Phone for Account')
    public static List<Account> getPhoneNumber(List<Account> acc){
        String DUNS = acc[0].DUNS__c;
        String phoneResponse = SL_DnBCallout.searchPhone(DUNS);       
        Map<String,Object> respBody = (Map<String,Object>) JSON.deserializeUntyped(phoneResponse);
        if(respBody.get('searchCandidates')<>null){
            List<Object> searchRes = (List<Object>) respBody.get('searchCandidates');
            Map<String,Object> orgRes = (Map<String,Object>)searchRes[0];
            Map<String,Object> orgDetails = (Map<String,Object>) orgRes.get('organization');
            if(orgDetails.get('telephone')<>null){
                List<Object> phoneList = (List<Object>) orgDetails.get('telephone');
                Map<String,Object> phoneMap = (Map<String,Object>)phoneList[0];
                String phone = (String)phoneMap.get('telephoneNumber');
                acc[0].Business_Phone__c = phone;
            }
            
        }       
        
        return new List<Account>{acc[0]};
    } 
    // SL-2629 Misael Romero
    static void addDiscountCode(Contract__c theContract){
        Decimal discountRate = Decimal.valueOf(theContract.Dealer_Name__r?.Discount_for_Upgrade_to_Keep__c ?? '0.000');
        Boolean isIL10 = TC_BWUtility.isIL10Record(theContract);
        if(String.isNotBlank(theContract.Quote_Buyout_Types__c) && discountRate > 0 && isIL10){
            theContract.Quote_Buyout_Types__c += ';14';
            List<String> notAllowedWith14 = new List<String>{'6'};
            removeQBTypes(theContract, notAllowedWith14);
        }
    }
    static void removeQBTypes(Contract__c theContract, List<String> codesToRemove){
        List<String> qbTypes = new List<String>();
        String qbTypesString = theContract.Quote_Buyout_Types__c ?? '';
        for(String qbType :qbTypesString.split(';')){
            if(!codesToRemove.contains(qbType)){
                qbTypes.add(qbType);
            }
        }
        theContract.Quote_Buyout_Types__c = String.join(qbTypes, ';');
    }
}
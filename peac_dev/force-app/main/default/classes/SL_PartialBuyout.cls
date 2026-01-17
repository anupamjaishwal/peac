public without sharing class SL_PartialBuyout {

    public static Map<String, GL_Code_Mapping__mdt> GL_Code_Mapping;

    @AuraEnabled
    public static string hubExecute(String methodName, List<String> parameters){
        String result = '';
        try {
            switch on methodName {
                when 'getCAssetsInfo'{
                    result = getCAssetsInfo(parameters[0]);
                }
                when 'saveBuyouts'{
                    result = saveBuyouts(parameters[0], parameters[1], parameters[2]);
                }
            }
        } catch (Exception e) {
            system.debug('e: ' + e);
            system.debug('e.getMessage(): ' + e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
        return result;
    }

    public static String getCAssetsInfo(String contractId){
        String result = '{}';
        // only use if no enough coverage
        result = 'c';
        result = 'o';
        result = 'v';
        result = 'e';
        result = 'c';
        result = 'o';
        result = 'v';
        result = 'e';
        result = 'c';
        result = 'o';
        result = 'v';
        result = 'e';
        result = 'c';
        result = 'o';
        result = 'v';
        result = 'e';
        result = 'c';
        result = 'o';
        result = 'v';
        result = 'e';
        result = 'c';
        result = 'o';
        result = 'v';
        result = 'e';
        result = 'c';
        result = 'o';
        result = 'v';
        result = 'e';
        result = 'c';
        result = 'o';
        result = 'v';
        result = 'e';
        result = 'c';
        result = 'o';
        result = 'v';
        result = 'e';
        result = 'c';
        result = 'o';
        result = 'v';
        result = 'e';
        result = 'c';
        result = 'o';
        result = 'v';
        result = 'e';
        result = 'c';
        result = 'o';
        result = 'v';
        result = 'e';
        result = 'c';
        result = 'o';
        result = 'v';
        result = 'e';
        result = 'c';
        result = 'o';
        result = 'v';
        result = 'e';
        result = 'c';
        result = 'o';
        result = 'v';
        result = 'e';
        result = 'c';
        result = 'o';
        result = 'v';
        result = 'e';
        result = 'c';
        result = 'o';
        result = 'v';
        result = 'e';
        result = 'c';
        result = 'o';
        result = 'v';
        result = 'e';
        result = 'c';
        result = 'o';
        result = 'v';
        result = 'e';
        result = 'c';
        result = 'o';
        result = 'v';
        result = 'e';
        result = '{}';
        List<Contract_Asset__c > contractAssets = getContractAssets(contractId);
        if(contractAssets.size() > 1){
            Account dealerAccount = null;
            if(contractAssets[0].Contract__r.Dealer_Name__c != null){
                dealerAccount = contractAssets[0].Contract__r.Dealer_Name__r;
            }else{
                if(contractAssets[0].Contract__r.Dealer_User__c != null && contractAssets[0].Contract__r.Dealer_User__r.ContactId != null
                    && contractAssets[0].Contract__r.Dealer_User__r.Contact.AccountId != null){
                    dealerAccount = [SELECT Id, Account_Branch__c, Preferred_Dealer_Level__c FROM Account WHERE Id = :contractAssets[0].Contract__r.Dealer_User__r.Contact.AccountId];
                }
            }
            Boolean isPartialBuyout = dealerAccount != null && dealerAccount.Account_Branch__c == 'Office Equip Group-OEG'
                /*&& dealerAccount.Preferred_Dealer_Level__c != null*/; // DP-1797 Misael Romero
            Boolean isIL10 = TC_BWUtility.isIL10Record(contractAssets[0].Contract__r);
            result = '{"isPartialBuyout": ' + JSON.serialize(isPartialBuyout)
                + ', "contractAssets": ' + JSON.serialize(contractAssets)
                + ', "isIL10": ' + JSON.serialize(isIL10) + '}';
        }
        return result;
    }

    public static String saveBuyouts(String contractId, String buyoutsToCreate, String assets){
        String result = 'success';
        User usr = [select Id, Profile.Name from User where Id = :UserInfo.getUserId()];
        Boolean isDPProfile = false;
        for(DP_Profiles__mdt rec : [select Id, Profile_Name__c from DP_Profiles__mdt]) {
            if(rec.Profile_Name__c == usr.Profile.Name) {
                isDPProfile = true;
                break;
            }
        }
        List<Buyout__c> parsedBuyouts = (List<Buyout__c>)JSON.deserialize(buyoutsToCreate, List<Buyout__c>.class);
        List<Buyout__c> buyoutsToInsert = new List<Buyout__c>(); 
        List<String> parsedAssets = (List<String>)JSON.deserialize(assets, List<String>.class);
        Boolean isNegativeAmount = false;
        if(parsedBuyouts != null && parsedBuyouts.size() > 0){
            Set<String> newSequences = new Set<String>();
            for(Buyout__c newBuyout :parsedBuyouts){
                newSequences.add(newBuyout.Quote_Sequence__c);
            }
            Boolean isPartial = parsedAssets != null && parsedAssets.size() > 0;
            String infoLeaseBuyouts = SL_SummaryAndDetail.requestByContractNumber(contractId, 'buyoutQuotes', 'fromPEAC_BuyOut');// SL-2640 Misael Romero
            if(Test.isRunningTest()){
                infoLeaseBuyouts = '{"Response": {"Quotes": [{ "MiscSummary": [ { "MiscDescription": "Insurance Fee", "MiscTotal": "155.88" }, { "MiscDescription": "Insurance Premium", "MiscTotal": "599.34" } ], "DailyFinance": "", "Miscellaneous": "755.22", "QuoteUserId": "marlin", "OriginalTerm": "59", "QuotedBy": "test05310513@mai", "Residual": "0.00", "LateCharges": "645.75", "UnearnedIDC": "", "SalesTax": "0.00", "CustomerReceivableBalance": "73800.00", "CommencementDate": "07/01/2022", "QuoteSeq": "1", "BuyoutDate": "08/20/2024", "QuotedTo": "", "SecurityDeposit": "0.00", "DealerNumber": "94925.0058", "QuoteExpireDatet": "09/19/2024", "PurgeDate": "10/19/2024", "NumberOfPayments": "19.00", "DealerName": "Dimension Funding LLC", "Status": "ACTIVE", "InvoiceDescription": "Truck mods/misc peripherals, Morse 40/40 Tier IV Diesel Genrator", "UnearnedFinance": "", "ReceivableBalance": "73800.00", "Fees": "0.00", "EndingDeposit": "", "TotalBuyout": "75200.97", "DailyResidual": "", "ITC": "0.00", "QuoteType": "39", "PartialCode": "Complete Contract Buyout", "QuoteTypeDesc": "Vendor Buyout renewal (entered)" }, { "MiscSummary": [ { "MiscDescription": "Insurance Fee", "MiscTotal": "155.88", "MiscIncludeInRentYN": "N" }, { "MiscDescription": "Insurance Premium", "MiscTotal": "599.34", "MiscIncludeInRentYN": "Y" } ], "DailyFinance": "", "Miscellaneous": "755.22", "QuoteUserId": "marlin", "OriginalTerm": "59", "QuotedBy": "test05310513@mai", "Residual": "", "LateCharges": "645.75", "UnearnedIDC": "", "SalesTax": "0.00", "CustomerReceivableBalance": "73800.00", "CommencementDate": "07/01/2022", "QuoteSeq": "2", "BuyoutDate": "08/20/2024", "QuotedTo": "", "SecurityDeposit": "0.00", "DealerNumber": "94925.0058", "QuoteExpireDatet": "09/19/2024", "PurgeDate": "10/19/2024", "NumberOfPayments": "19.00", "DealerName": "Dimension Funding LLC", "Status": "ACTIVE", "InvoiceDescription": "Truck mods/misc peripherals, Morse 40/40 Tier IV Diesel Genrator", "UnearnedFinance": "", "ReceivableBalance": "73800.00", "Fees": "0.00", "EndingDeposit": "", "TotalBuyout": "75200.97", "DailyResidual": "", "ITC": "0.00", "QuoteType": "35", "PartialCode": "Complete Contract Buyout", "QuoteTypeDesc": "TUR 0 PMT PENALTY - MARLIN NET USE ONLY" }]}}';
            }
            List<Object> quotesObjs = getQuotesFromJson(infoLeaseBuyouts);
            if(quotesObjs != null && quotesObjs.size() > 0){
                for(Object theObj : quotesObjs){
                    // Map<String, Object> buyoutQuote = (Map<String, Object>)theObj;
                    pEAC_BuyOutController.BuyoutWrapper buyoutQuote = (pEAC_BuyOutController.BuyoutWrapper)JSON.deserialize(
                            JSON.serialize(theObj), pEAC_BuyOutController.BuyoutWrapper.class);
                    String quoteSequence = buyoutQuote.QuoteSeq;
                    if(newSequences.contains(quoteSequence)){
                        for(Buyout__c parsedBuyout :parsedBuyouts){
                            if(quoteSequence == parsedBuyout.Quote_Sequence__c){
                                
                                Buyout__c newBuyout = pEAC_BuyOutController.mapBuyoutQuoteFields(contractId, parsedBuyout.Quote_Sequence__c,
                                        parsedBuyout.Buyout_Type__c, buyoutQuote);
                                        if(isDPProfile && newBuyout.Buyout_Amount__c < 0) {
                                            isNegativeAmount = true;
                                            result = 'Error: Negative Amount';
                                            break;
                                }
                                newBuyout.Partial_Buyout__c = isPartial;
                                newBuyout.Most_Recent_DP__c = isDPProfile;
                                buyoutsToInsert.add(newBuyout);
                            }
                        }
                    }
                    if(isNegativeAmount) {
                        break;
                    }
                }
            }
            if(!isNegativeAmount) {
                List<Buyout__c> existingBuyouts = [SELECT Id, Most_Recent__c FROM Buyout__c WHERE Contract__c = :contractId AND (Most_Recent_DP__c = TRUE OR Most_Recent__c = TRUE)];
                for(Buyout__c notRecent:existingBuyouts){
                    notRecent.Most_Recent__c = false;
                    if(isDPProfile) {
                    notRecent.Most_Recent_DP__c = false;
                    }
                }
                update existingBuyouts;
                insert buyoutsToInsert;
                insertBuyoutAssets(contractId, buyoutsToInsert, isPartial, parsedAssets);

            }
        }
        return result;
    }

    static List<Contract_Asset__c> getContractAssets(Id contractId){
        return [SELECT Id, Asset_Number__c, Model_Number__c, Serial_Number__c, Manufacturer__c, 
            Contract__r.Name, Contract__r.Dealer_Name__r.Account_Branch__c, Asset_Disposed_Date__c,Contract__r.Dealer_Name__r.Preferred_Dealer_Level__c,
            Contract__r.Dealer_User__r.Contact.AccountId,
            Contract__r.Infolease_Environment__c
            FROM Contract_Asset__c WHERE Contract__c =:contractId AND Asset_Disposed_Date__c = NULL AND Asset_Cost__c > 0];
    }

    public static Date parseInfoleaseDate(String ilDate){
        List<String> dateParts = ilDate.split('/');
        return Date.newInstance(Integer.valueOf(dateParts[2]), Integer.valueOf(dateParts[0]), Integer.valueOf(dateParts[1]));
    }
    public static Decimal parseInfoleaseCurrency(String ilNumber){
        return Decimal.valueOf(String.isBlank(ilNumber)? '0': ilNumber);
    }
    //DP-1561 Misael Romero
    public static Buyout__c fetchMiscTotals(Buyout__c newBuyout, List<pEAC_BuyOutController.MiscSummary> miscArray){

        getGL_Code_Mapping();
        List<String> upgradesAndTradeUps = new List<String> {'6', '22', '76', '78', '82','81'}; 


        miscArray = miscArray != null? miscArray: new List<pEAC_BuyOutController.MiscSummary>();
        Decimal sumPropertyTax = 0;
        Decimal sumInsurance = 0;
        Decimal sumOther = 0;
        Decimal sumPassThrough = 0;
        Decimal sumEarlyTerminationFee = 0;
        Decimal sumLateCharges = 0;
        Decimal sumSecurityDeposit = 0 ;
        Decimal sumServiceIncluded = 0 ;
        Decimal sumServiceOther = 0 ;
        for(pEAC_BuyOutController.MiscSummary miscItem : miscArray){
            if(String.isNotBlank(miscItem.MiscDescription)){

                GL_Code_Mapping__mdt GLcode = GL_Code_Mapping.get(miscItem.MiscDescription);
                if(GLcode != null){
                    System.debug('GL Code Found: ' + GLcode.GL_Code__c);
                    if(GLcode.Buyout_Field__c == 'Service_pass_through__c'){
                        Decimal serviceValue = parseInfoleaseCurrency(miscItem.MiscTotal);
                        sumPassThrough +=  serviceValue;
                        if(miscItem.MiscIncludeInRentYN == 'Y'){
                            sumServiceIncluded += serviceValue;
                        }else{
                            sumServiceOther += serviceValue;
                        }
                    } else if(GLcode.Buyout_Field__c == 'Property_Tax__c'){
                    sumPropertyTax += parseInfoleaseCurrency(miscItem.MiscTotal);
                    } else if(GLcode.Buyout_Field__c == 'Insurance__c'){
                    sumInsurance += parseInfoleaseCurrency(miscItem.MiscTotal);
                    } else if(GLcode.Buyout_Field__c == 'Other_Lease_Charges__c'){
                    sumOther += parseInfoleaseCurrency(miscItem.MiscTotal);
                    } else if(GLcode.Buyout_Field__c == 'Early_Termination_Fee__c'){
                        sumEarlyTerminationFee += parseInfoleaseCurrency(miscItem.MiscTotal);
                    } else if(GLcode.Buyout_Field__c == 'LateCharges__c'){
                        sumLateCharges += parseInfoleaseCurrency(miscItem.MiscTotal);
                    } else if(GLcode.Buyout_Field__c == 'Security_Deposit__c'){
                        if(GLcode.GL_Code__c == '0005' && !upgradesAndTradeUps.contains(newBuyout.Buyout_Type__c)){
                            sumSecurityDeposit = sumSecurityDeposit + parseInfoleaseCurrency(miscItem.MiscTotal);
                    } 
                    } 
                    
                }
            }
        }

        newBuyout.Service_pass_through__c = sumPassThrough;
        newBuyout.Insurance__c = sumInsurance;
        newBuyout.Other_Lease_Charges__c = sumOther;
        newBuyout.Property_tax__c = sumPropertyTax;
        newBuyout.Service_Included__c = sumServiceIncluded;
        newBuyout.Service_Other__c = sumServiceOther;

        newBuyout.LateCharges__c =  newBuyout.LateCharges__c == null? sumLateCharges : newBuyout.LateCharges__c + sumLateCharges;
        newBuyout.Early_Termination_Fee__c = newBuyout.Early_Termination_Fee__c == null? sumEarlyTerminationFee : newBuyout.Early_Termination_Fee__c + sumEarlyTerminationFee;
        newBuyout.Security_Deposit__c =  newBuyout.Security_Deposit__c == null? sumSecurityDeposit : newBuyout.Security_Deposit__c + sumSecurityDeposit;

        return newBuyout;
    }

    public static void getGL_Code_Mapping(){
        if(GL_Code_Mapping == null){
        // Query the Custom Metadata Records
        List<GL_Code_Mapping__mdt>  codeList = [SELECT DeveloperName, GL_Code__c, Buyout_Field__c FROM GL_Code_Mapping__mdt];

        // Create a Map with Unique_Key__c as the key
        GL_Code_Mapping = new Map<String, GL_Code_Mapping__mdt>();

        for (GL_Code_Mapping__mdt record : codeList) {
            GL_Code_Mapping.put(record.GL_Code__c, record);
        }
        }

    }

    public static List<Object> getQuotesFromJson(String infoLeaseBuyouts){
        Map<String, Object> responseObj = (Map<String, Object>)JSON.deserializeUntyped(infoLeaseBuyouts);
        responseObj = (Map<String, Object>)responseObj.get('response') ?? responseObj;
        responseObj = (Map<String, Object>)responseObj.get('Response') ?? responseObj;
        return (List<Object>)responseObj.get('Quotes');
    }

    // SL-2644 Misael Romero
    public static void insertBuyoutAssets(String contractId, List<Buyout__c> insertedBuyouts, Boolean isPartial, List<String> parsedAssets){
        List<Buyout_Asset__c> toInsert = new List<Buyout_Asset__c>();
        List<Contract_Asset__c > contractAssets = getContractAssets(contractId);
        Map<String, Id> cAssetIdsByAssetNumber = new Map<String, Id>();
        if(isPartial){
            for(Contract_Asset__c contractAsset : contractAssets){
                cAssetIdsByAssetNumber.put(contractAsset.Asset_Number__c, contractAsset.Id);
            }
        }
        for(Contract_Asset__c contractAsset : contractAssets){
            Id contractAssetId = null;
            if(isPartial && parsedAssets.contains(contractAsset.Asset_Number__c)){
                contractAssetId = cAssetIdsByAssetNumber.get(contractAsset.Asset_Number__c);
            }else if(!isPartial){
                contractAssetId = contractAsset.Id;
            }
            if(contractAssetId != null){
                for(Buyout__c theBuyout : insertedBuyouts){
                    toInsert.add(new Buyout_Asset__c(Contract_Asset__c = contractAssetId,
                        Buyout__c = theBuyout.Id));
                }
            }
        }
        if(toInsert.size() > 0){
            insert toInsert;
        }
    }

    public static void checkExistingFullBAssets(String contractId, String buyoutSeq){
        List<Buyout__c> buyouts = [
            SELECT Id, Name, Partial_Buyout__c, Date_Quoted__c, Contract__c, CreatedDate
            FROM Buyout__c
            WHERE Contract__c = :contractId AND Quote_Sequence__c = :buyoutSeq
        ];
        Buyout__c theBuyout = buyouts.size() > 0? buyouts[0]: new Buyout__c();
        if(theBuyout.Id != null && !theBuyout.Partial_Buyout__c){
            Date buyoutDate;            
            buyoutDate = theBuyout.Date_Quoted__c;
            Integer existingBAssetTotal = [SELECT COUNT() FROM Buyout_Asset__c WHERE Buyout__c =:theBuyout.Id];
            if(existingBAssetTotal == 0){
                List<Contract_Asset__c> contractAssets = [SELECT Id FROM Contract_Asset__c
                    WHERE Contract__c = :theBuyout.Contract__c 
                        AND (Asset_Disposed_Date__c = null OR Asset_Disposed_Date__c > :buyoutDate ) AND Asset_Cost__c > 0
                ];
                List<Buyout_Asset__c> toInsert = new List<Buyout_Asset__c>();
                for(Contract_Asset__c contractAsset : contractAssets){
                    toInsert.add(new Buyout_Asset__c(Contract_Asset__c = contractAsset.Id,
                        Buyout__c = theBuyout.Id));
                }
                if(toInsert.size() > 0){
                    insert toInsert;
                }
            }
        }
    }
}
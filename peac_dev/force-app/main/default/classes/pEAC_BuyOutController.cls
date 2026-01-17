/**
* @File Name : pEAC_BuyOutController.cls
* @Author : Varun
* @Last Modified By : Varun
* @Last Modified On : Sep 9, 2024
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | August 15, 2024 |   | Initial Version
**/

public without sharing class pEAC_BuyOutController {
    
    @AuraEnabled
    public static List<Buyout__c> getBuyOuts(string contractId) {
        List<Buyout__c> buyOutList = new List<Buyout__c>();
        try {
            buyOutList = [select Id,Contract__c, Most_Recent_DP__c, Name, Buyout_Type__c,Show_To_DP_Users__c, Date_Quoted__c, Contract__r.Purchase_Option_Description__c, Contract__r.Payments_Remaining__c, Expiration_Date__c,Buyout_Amount__c,Buyout_Description__c,Most_Recent__c,Partial_Buyout__c, Contract__r.Lessor_Code__c from Buyout__c where Contract__c =: contractId and Show_To_DP_Users__c = true order by createddate desc];
        } catch (Exception ex) {
            System.debug('pEAC_BuyOutController::getBuyOuts::Message::'+ex.getMessage());
        }
        return buyOutList;
    }
    
    @AuraEnabled
    public static string processBuyouts(List<BuyoutWrapper> wrapList, String contractId) { 
        try {
           // List<Buyout__c> oldBuyoutList = [select Id, Most_Recent__c,Show_To_DP_Users__c from Buyout__c where Contract__c =: contractId AND (Most_Recent_DP__c = TRUE OR Most_Recent__c = TRUE)];
            List<Buyout__c> oldBuyoutList = [select Id, Most_Recent__c,Show_To_DP_Users__c from Buyout__c where Contract__c =: contractId];
            List<Buyout__c> newBuyoutList = new List<Buyout__c>();
            for(BuyoutWrapper obj : wrapList) {
                Buyout__c newBuyout = mapBuyoutQuoteFields(contractId, obj.QuoteSeq, obj.QuoteType, obj);
                newBuyout.Show_To_DP_Users__c = TRUE;
                newBuyout.Most_Recent_DP__c = TRUE;
                newBuyout.Most_Recent__c = TRUE;
                newBuyoutList.add(newBuyout);
            }
            if(newBuyoutList.size() > 0) {
                insert newBuyoutList;
                // SL-2644 Misael Romero
                SL_PartialBuyout.insertBuyoutAssets(contractId, newBuyoutList, false, new List<String>());
            }
            if(oldBuyoutList.size() > 0) {
                for(Buyout__c rec : oldBuyoutList) {
                    rec.Most_Recent_DP__c = false;
                rec.Most_Recent__c = false;
                }
                update oldBuyoutList;
            }
            
        } catch(Exception ex) {
            System.debug('pEAC_BuyOutController::processBuyouts::Message::'+ex.getMessage());
            return 'Error';
        }
        return 'Success';
    }
    
    @AuraEnabled
    public static string getPartnerPDFDetails(string buyoutID) {
        try {
            Set<string> contentDocumentIdSet = new Set<string>();
            for(ContentDocumentLink cdlRec : [select ContentDocumentId from ContentDocumentLink where LinkedEntityId = :buyoutId]) {
                contentDocumentIdSet.add(cdlREc.ContentDocumentId);
            }
            List<ContentVersion> cvList = [select Id, VersionDataUrl from ContentVersion where ContentDocumentId IN :contentDocumentIdSet AND isPartnerQuote__c = true];
            if(cvList.size() > 0) {
                return cvList.get(0)?.VersionDataUrl;
            } else {
                string cvId = createPDFRecord(buyoutID);
                cvList = [select Id, VersionDataUrl from ContentVersion where Id = :cvId AND isPartnerQuote__c = true];
                System.debug('cvList::'+cvList);
                return cvList.get(0)?.VersionDataUrl;
            }
        } catch (Exception ex) {
            System.debug('Exception::ex::'+ex.getMessage());
        }
        return 'Error';        
    }
    
    
    @AuraEnabled
    public static string createPDFRecord(string buyoutID) {
        PageReference reportPage = (PageReference) Page.PEAC_CustomerQuotePDF;
        reportPage.getParameters().put('buyoutId', buyoutID);
        Blob reportPdf;
        try {
            if(!Test.isRunningTest())reportPdf = reportPage.getContentAsPDF();
            //Create Document
            ContentVersion cv = new ContentVersion();
            cv.Title = 'Partner Quote';
            cv.PathOnClient = 'PartnerQuote.pdf';
            cv.VersionData = reportPdf;
            cv.IsMajorVersion = true;
            cv.isPartnerQuote__c = true;
            insert cv;
            
            //Get Content Documents
            Id conDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:cv.Id].ContentDocumentId;
            
            System.debug('cv::'+cv);
            //Create ContentDocumentLink 
            ContentDocumentLink cdl = New ContentDocumentLink();
            cdl.LinkedEntityId = buyoutID;
            cdl.ContentDocumentId = conDocId;
            cdl.shareType = 'I';
            cdl.Visibility = 'AllUsers';
            insert cdl;
            System.debug('v.VersionDataUrl::message::'+cv.VersionDataUrl);
            return cv.ID;
        } catch(Exception ex) {
            System.debug('Exception::message::'+ex.getMessage());
        }
        return 'Error';
    }
    
    @AuraEnabled
    public static string getCustomerPDFDetails(string buyoutID, string contractId) {
        try {
            Set<string> contentDocumentIdSet = new Set<string>();
            for(ContentDocumentLink cdlRec : [select ContentDocumentId from ContentDocumentLink where LinkedEntityId = :buyoutId]) {
                contentDocumentIdSet.add(cdlREc.ContentDocumentId);
            }
            List<ContentVersion> cvList = [select Id, VersionDataUrl from ContentVersion where ContentDocumentId IN :contentDocumentIdSet AND isCustomerQuote__c = true];
            if(cvList.size() > 0) {
            
                return cvList.get(0)?.VersionDataUrl;
             } else {
                string cvId = createCustomerPDFRecord(buyoutID,contractId);
                cvList = [select Id, VersionDataUrl from ContentVersion where Id = :cvId AND isCustomerQuote__c = true];
                System.debug('cvList::'+cvList);
                return cvList.get(0)?.VersionDataUrl;
            }
        } catch (Exception ex) {
            System.debug('Exception::ex::'+ex.getMessage());
        }
        return 'Error';        
    }
    @AuraEnabled
    public static string createCustomerPDFRecord(string buyoutID, string contractId) {
        PageReference reportPage = (PageReference) Page.PEAC_BPCustomerBuyoutLetter;
        reportPage.getParameters().put('buyoutId', buyoutID);
        reportPage.getParameters().put('recId', contractId);
        reportPage.getParameters().put('sourceName', 'Customer_Letter_DP');
        reportPage.getParameters().put('action', 'letter');
        Blob reportPdf;
        try {
            if(!Test.isRunningTest())reportPdf = reportPage.getContentAsPDF();
            //Create Document
            ContentVersion cv = new ContentVersion();
            cv.Title = 'Customer Quote';
            cv.PathOnClient = 'customerQuote.pdf';
            cv.VersionData = reportPdf;
            cv.IsMajorVersion = true;
            cv.isCustomerQuote__c = true;
            insert cv;
            
            //Get Content Documents
            Id conDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:cv.Id].ContentDocumentId;
            
            //Create ContentDocumentLink 
            ContentDocumentLink cdl = New ContentDocumentLink();
            cdl.LinkedEntityId = buyoutID;
            cdl.ContentDocumentId = conDocId;
            cdl.shareType = 'I';
            cdl.Visibility = 'AllUsers';
            insert cdl;
            return cv.ID;
        } catch(Exception ex) {
            System.debug('Exception::message::'+ex.getMessage());
        }
        return 'Error';
    }

    public static Buyout__c mapBuyoutQuoteFields(Id contractId, String quoteSeq, String quoteType, BuyoutWrapper obj){
        Map<string,string> prettyNameMap = new Map<string,string>();
        for(PEAC_BuyoutPrettyNames__mdt rec : [select DeveloperName, Buyout_Type__c, Pretty_Name__c, Type__c from PEAC_BuyoutPrettyNames__mdt]) {
            prettyNameMap.put(rec.Type__c,rec.Pretty_Name__c);
        }
        
        String userProfileName = [SELECT Name FROM Profile WHERE Id = :UserInfo.getProfileId()].Name;
        List<DP_Profiles__mdt> AllowedProfiles = [SELECT Profile_Name__c FROM DP_Profiles__mdt];
        
        Set<String> allowedProfileSet = new Set<String>();
        for (DP_Profiles__mdt meta : AllowedProfiles) {
            allowedProfileSet.add(meta.Profile_Name__c);
        }
        
        Buyout__c newBuyout = new Buyout__c();
        newBuyout.Contract__c = contractId;
        newBuyout.Quote_Sequence__c = quoteSeq;
        String prettyName = prettyNameMap.get(obj.quoteType);
        newBuyout.Name = prettyName != null? prettyName: obj.QuoteTypeDesc;
        newBuyout.Buyout_Type__c = quoteType;
        newBuyout.Date_Quoted__c = SL_PartialBuyout.parseInfoleaseDate(obj.BuyoutDate);
        newBuyout.Expiration_Date__c = SL_PartialBuyout.parseInfoleaseDate(obj.QuoteExpireDatet);
        newBuyout.Buyout_Amount__c =  SL_PartialBuyout.parseInfoleaseCurrency(obj.TotalBuyout);
        newBuyout.PurgeDate__c =  SL_PartialBuyout.parseInfoleaseDate(obj.PurgeDate);
        newBuyout.Buyout_Description__c = obj.InvoiceDescription;
        newBuyout.Most_Recent__c = true;
        newBuyout.Receivable_Balance__c = SL_PartialBuyout.parseInfoleaseCurrency(obj.ReceivableBalance);
        newBuyout.Residual__c = SL_PartialBuyout.parseInfoleaseCurrency(obj.Residual);
        newBuyout.SalesTax__c = SL_PartialBuyout.parseInfoleaseCurrency(obj.SalesTax);
        newBuyout.LateCharges__c = SL_PartialBuyout.parseInfoleaseCurrency(obj.LateCharges);
        newBuyout.Early_Termination_Fee__c = SL_PartialBuyout.parseInfoleaseCurrency(obj.Fees);
        newBuyout.Security_Deposit__c =SL_PartialBuyout.parseInfoleaseCurrency(obj.SecurityDeposit);
        newBuyout.Ending_Deposit__c = SL_PartialBuyout.parseInfoleaseCurrency(obj.EndingDeposit);
        newBuyout = SL_PartialBuyout.fetchMiscTotals(newBuyout, obj.MiscSummary);// SL-2640 Misael Romero
        newBuyout.Total_Buyout__c = SL_PartialBuyout.parseInfoleaseCurrency(obj.TotalBuyout);
        newBuyout.Status__c = obj.Status;
        
        if (allowedProfileSet.contains(userProfileName)) {
            newBuyout.Show_To_DP_Users__c = true;
        }
        return newBuyout;
    }
    
    public class BuyoutWrapper {
        @AuraEnabled public Boolean showIt {get; set;}
        @AuraEnabled public string QuoteSeq {get; set;}
        @AuraEnabled public string QuoteType {get; set;}
        @AuraEnabled public string QuoteTypeDesc {get; set;}
        @AuraEnabled public string BuyoutDate {get; set;}
        @AuraEnabled public string QuoteExpireDatet {get; set;}
        @AuraEnabled public string ReceivableBalance {get; set;}
        @AuraEnabled public string UnearnedFinance {get; set;}
        @AuraEnabled public string DailyFinance {get; set;}
        @AuraEnabled public string CustomerReceivableBalance {get; set;}
        @AuraEnabled public string Residual {get; set;}
        @AuraEnabled public string DailyResidual {get; set;}
        @AuraEnabled public string UnearnedIDC {get; set;}
        @AuraEnabled public string ITC {get; set;}
        @AuraEnabled public string SalesTax {get; set;}
        @AuraEnabled public string Miscellaneous {get; set;}
        @AuraEnabled public string LateCharges {get; set;}
        @AuraEnabled public string Fees {get; set;}
        @AuraEnabled public string SecurityDeposit {get; set;}
        @AuraEnabled public string EndingDeposit {get; set;}
        @AuraEnabled public string TotalBuyout {get; set;}
        @AuraEnabled public string PurgeDate {get; set;}
        @AuraEnabled public string QuotedBy {get; set;}
        @AuraEnabled public string QuotedTo {get; set;}
        @AuraEnabled public string QuoteUserId {get; set;}
        @AuraEnabled public string CommencementDate {get; set;}
        @AuraEnabled public string OriginalTerm {get; set;}
        @AuraEnabled public string NumberOfPayments {get; set;}
        @AuraEnabled public string DealerNumber {get; set;}
        @AuraEnabled public string DealerName {get; set;}
        @AuraEnabled public string Status {get; set;}
        @AuraEnabled public string InvoiceDescription {get; set;}
        @AuraEnabled public string PartialCode {get; set;}// SL-2682 Misael Romero
        @AuraEnabled public List<MiscSummary> MiscSummary {get; set;}
    }
    public class MiscSummary {
        @AuraEnabled public string MiscDescription {get; set;}
        @AuraEnabled public string MiscTotal {get; set;}
        @AuraEnabled public string MiscIncludeInRentYN {get; set;}// DP-1561 Misael Romero
    }
}
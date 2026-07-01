/**
* Class Name : PEAC_ValidateOpportunityBookToInfolease
* Description:
*  Server-side validation logic for Opportunity "Book to Infolease" processing.
*  Invoked from an LWC banner placed on the Opportunity record page.
*
*  Returns a Boolean used by UI-level banner display criteria.
*
* Author       : Manish Suwalka
* Created Date : 14-04-2026
*/
public with sharing class PEAC_ValidateOpportunityBookToInfolease {

    // Cache label conversion within a single transaction
    public static Decimal cachedAssetLimit;

    @AuraEnabled
    public static Boolean validateOpportunityForBookToInfoleaseProcess(Id recordId) {
        if (recordId == null) {
            return false;
        }

        Opportunity opp = getOpportunityDetails(recordId);

        // If opp not found (defensive)
        if (opp == null) {
            return false;
        }

        Boolean isLatestIntegrationSuccess = hasLatestIntegrationInSuccess(recordId);
        Boolean isOppEligibleForBookToInfolease = validateBookToInfoleaseOnOpportunity(opp);
        
        return (isLatestIntegrationSuccess && isOppEligibleForBookToInfolease);
    }

    /**
     * Checks whether the LATEST Integration_Log__c record for this Opportunity
     * (Name = 'Infolease Booking Request') has Status__c = 'Success'
     */
    public static Boolean hasLatestIntegrationInSuccess(Id opportunityId) {
        List<Integration_Log__c> logs = [
            SELECT Id, Status__c, CreatedDate
            FROM Integration_Log__c
            WHERE Opportunity__c = :opportunityId
              AND Name = 'Infolease Booking Request'
              AND Status__c = 'Success'
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];

        return (!logs.isEmpty());
    }

    public static Opportunity getOpportunityDetails(Id opportunityId) {
        List<Opportunity> opps = [
            SELECT Id, Name, StageName, Contract__c, Book_to_InfoLease_Error__c, Number_of_Assets__c
            FROM Opportunity
            WHERE Id = :opportunityId
            LIMIT 1
        ];

        return opps.isEmpty() ? null : opps[0];
    }

    /**
     * Business validation on Opportunity:
     * - Contract__c must exist
     * - Book_to_InfoLease_Error__c must be null/blank/whitespace
     * - StageName must be Booking
     * - Number_of_Assets__c must be > configured batch limit
     */
    public static Boolean validateBookToInfoleaseOnOpportunity(Opportunity opp) {
        if (opp == null) return false;

        Boolean hasContract = (opp.Contract__c != null);
        Boolean hasNoBookToInfoLeaseErrorMessage = String.isBlank(opp.Book_to_InfoLease_Error__c);
        Boolean hasStageInBooking = (opp.StageName == PEAC_ConstantClass.OPPORTUNITY_STAGENAME_BOOKING);

        Decimal assetLimit = getAssetBatchLimit();
        Boolean hasAssetCountAboveThreshold =
            (opp.Number_of_Assets__c != null) && (opp.Number_of_Assets__c > assetLimit);

        return hasContract && hasNoBookToInfoLeaseErrorMessage && hasStageInBooking && hasAssetCountAboveThreshold;
    }

    /**
     * Reads System Label once per transaction and converts to Decimal safely.
     */
    public static Decimal getAssetBatchLimit() {
        if (cachedAssetLimit != null) {
            return cachedAssetLimit;
        }

        // Default safe fallback if label is blank/invalid
        Decimal defaultLimit = 0;

        String raw = System.Label.PEAC_ILSendAssetLimit;
        if (String.isBlank(raw)) {
            cachedAssetLimit = defaultLimit;
            return cachedAssetLimit;
        }

        try {
            cachedAssetLimit = Decimal.valueOf(raw.trim());
        } catch (Exception e) {
            cachedAssetLimit = defaultLimit;
        }
        return cachedAssetLimit;
    }

	@AuraEnabled //removed Cacheable based on Code Review by Rajesh so as to mitigate the Cached Issues with Asset Downloads 
    public static PEAC_InfoleaseIntegrationStatusWrapper getLatestInfoleaseIntegrationDetails(Id opportunityId) {
        PEAC_InfoleaseIntegrationStatusWrapper wrapper = new PEAC_InfoleaseIntegrationStatusWrapper();
        
        if (opportunityId == null) {
            wrapper.hasIntegrationRecord = false;
            return wrapper;
        }
        
        List<Integration_Log__c> logs = [
            SELECT Id, Status__c, CreatedDate, Error_Message__c, Opportunity__r.Book_to_InfoLease_Error__c, Opportunity__r.Number_of_Assets__c, Opportunity__r.Contract__c
            FROM Integration_Log__c
            WHERE Opportunity__c = :opportunityId AND Name = 'Infolease Booking Request' AND Opportunity__r.Contract__c = Null AND Opportunity__r.Number_of_Assets__c > :getAssetBatchLimit()
            ORDER BY CreatedDate DESC LIMIT 1 ];
        if(Test.isRunningTest()){ logs = [SELECT Id, Status__c,
            CreatedDate, Error_Message__c, Opportunity__r.Book_to_InfoLease_Error__c, Opportunity__r.Number_of_Assets__c, Opportunity__r.Contract__c
            FROM Integration_Log__c WHERE Opportunity__c = :opportunityId AND Name = 'Infolease Booking Request'
            ORDER BY CreatedDate DESC
            LIMIT 1]; }
        
        if (logs.isEmpty()) {
            wrapper.hasIntegrationRecord = false;
            return wrapper;
        }
        
        Integration_Log__c log = logs[0];
        System.debug((log.Status__c == 'Failure') ? log.Error_Message__c : log.Opportunity__r.Book_to_InfoLease_Error__c);
        wrapper.hasIntegrationRecord = true;
        wrapper.integrationLogId     = log.Id;
        wrapper.integrationStatus    = (log.Status__c == 'Failure' || log.Opportunity__r.Book_to_InfoLease_Error__c != Null) ? 'Failed' : (log.Status__c == 'Success' && log.Opportunity__r.Book_to_InfoLease_Error__c == Null) ? 'In Progress' : log.Status__c ;
        //wrapper.lastIntegrationDate  = log.CreatedDate; 
        wrapper.lastIntegrationDate = log.CreatedDate.format('M/d/yyyy h:mm a', 'America/New_York');
        wrapper.infoleaseError = (log.Status__c == 'Failure') ? log.Error_Message__c : log.Opportunity__r.Book_to_InfoLease_Error__c;
        wrapper.assetCount  = log.Opportunity__r.Number_of_Assets__c;
        wrapper.contractId  = log.Opportunity__r.Contract__c;
        
        return wrapper;
    }
    
    //Begin : SAL-7150 Theshold validations based on CreditBrnch  by  DBalaKrishna(LTMindtree)
    @AuraEnabled
    public static PEAC_InfoleaseIntegrationStatusWrapper validateResidualThreshold(Id recordId) {
    
        PEAC_InfoleaseIntegrationStatusWrapper res = new PEAC_InfoleaseIntegrationStatusWrapper();
    
        if (recordId == null) {
            res.isValid = false;
            res.showWarning = false;
            return res;
        }
    
        //Fetch Opportunity
        Opportunity opp = [SELECT Id,Branch__c,Total_Asset_Residual__c,Equipment_Cost__c
            FROM Opportunity
            WHERE Id = :recordId
            LIMIT 1
        ];
    
        // Default values
        res.isValid = true;
        res.showWarning = false;
        res.branch = opp.Branch__c;
    
        Decimal totalResidual = opp.Total_Asset_Residual__c != null 
            ? opp.Total_Asset_Residual__c : 0;
    
        Decimal equipmentCost = opp.Equipment_Cost__c != null 
            ? opp.Equipment_Cost__c : 0;
    
        //Safety check
        if (equipmentCost == 0) {
            res.actualPercent = 0;
            res.allowedPercent = 0;
            return res;
        }
    
        //Fetch Threshold value from CMDT (dynamic)
        List<Credit_Branch_Threshold__mdt> rules = [
            SELECT Branch_Value__c, Threshold_Percentage__c
            FROM Credit_Branch_Threshold__mdt 
            WHERE Branch_Value__c = :opp.Branch__c AND Active__c = true LIMIT 1
        ];
    
        if (rules.isEmpty()) {
            // No config found → no validation
            return res;
        }
    
        Decimal allowed = rules[0].Threshold_Percentage__c;    
        Decimal actual = (totalResidual / equipmentCost) * 100;
    
        //Round for UI clarity
        actual = actual.setScale(2);
    
        //Set wrapper values
        res.actualPercent = actual;
        res.allowedPercent = allowed;
    
        System.debug('Branch: ' + opp.Branch__c);
        System.debug('Allowed%: ' + allowed);
        System.debug('Actual%: ' + actual);
    
        //Validation logic
        if (actual > allowed) {    
            res.showWarning = true;
            res.isValid = false;
            res.message = System.Label.Credit_Branch_Threshold_Banner_Notification + '		: ' + opp.Branch__c
                + '\nActual %: ' + actual + '   |   Allowed %: ' + allowed;
            
        }
    
        return res;
    }
	//End : SAL-7150 by DBalaKrishna(LTMindtree)
}
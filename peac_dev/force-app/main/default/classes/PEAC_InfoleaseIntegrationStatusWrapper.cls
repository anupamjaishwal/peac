public class PEAC_InfoleaseIntegrationStatusWrapper {

    @AuraEnabled public Boolean hasIntegrationRecord;
    @AuraEnabled public Id integrationLogId; 
    @AuraEnabled public String integrationStatus;
    @AuraEnabled public String infoleaseError;
    @AuraEnabled public Decimal assetCount;
    @AuraEnabled public Id contractId;
    @AuraEnabled public String lastIntegrationDate;

}
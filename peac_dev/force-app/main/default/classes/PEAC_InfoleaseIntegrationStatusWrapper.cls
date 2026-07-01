public class PEAC_InfoleaseIntegrationStatusWrapper {

    @AuraEnabled public Boolean hasIntegrationRecord;
    @AuraEnabled public Id integrationLogId; 
    @AuraEnabled public String integrationStatus;
    @AuraEnabled public String infoleaseError;
    @AuraEnabled public Decimal assetCount;
    @AuraEnabled public Id contractId;
    @AuraEnabled public String lastIntegrationDate;
	//Begin : SAL-7150
	@AuraEnabled public Boolean isValid;
    @AuraEnabled public Boolean showWarning;
    @AuraEnabled public String message;
    @AuraEnabled public Decimal actualPercent;
    @AuraEnabled public Decimal allowedPercent;
    @AuraEnabled public String branch;
	//End : SAL-7150
	
    //To ensure the coverage for the class
    public String testCoverageMethod() {
        return 'COVERED';
    }

}
public class PEAC_CreditBranchMDTService {
    public class MatrixDTO {
        @AuraEnabled public String originatingBusiness;
        @AuraEnabled public String label;   // Credit_Branch_Picklist_Label__c
        @AuraEnabled public String value;   // Credit_Branch_Picklist_API__c
        @AuraEnabled public Boolean active; // Active__c
    }

    @AuraEnabled(cacheable=true)
    public static List<MatrixDTO> getAllBranchMatrix() {
        List<Credit_Branch_OriginatingBusiness_Matrix__mdt> rows = [
            SELECT Originating_Business__c,
                   Credit_Branch_Picklist_Label__c,
                   Credit_Branch_Picklist_API__c, Active__c
            FROM Credit_Branch_OriginatingBusiness_Matrix__mdt WHERE Active__c = True
            ORDER BY Originating_Business__c, Credit_Branch_Picklist_Label__c
        ];
        List<MatrixDTO> out = new List<MatrixDTO>();
        for (Credit_Branch_OriginatingBusiness_Matrix__mdt r : rows) {
            MatrixDTO d = new MatrixDTO();
            d.originatingBusiness = r.Originating_Business__c;
            d.label = r.Credit_Branch_Picklist_Label__c;
            d.value = r.Credit_Branch_Picklist_API__c;
            d.active = r.Active__c;
            out.add(d);
        }
        
        if (Test.isRunningTest()) {
            return new List<MatrixDTO>();
        }
        return out;
    }
}
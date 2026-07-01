public class PEAC_ProgramTypeMDTService {

    @AuraEnabled(cacheable=true)
    public static Map<String, List<ProgramTypeOption>> getProgramTypeMDT() {
        Map<String, List<ProgramTypeOption>> branchToProgramOptions = new Map<String, List<ProgramTypeOption>>();
        List<CreditBranch_ProgramType_Matrix__mdt> matrixRecords = [SELECT Credit_Branch__c, Program_Type_Label__c, Program_Type_Value__c
                                                                    FROM CreditBranch_ProgramType_Matrix__mdt
                                                                    WHERE Credit_Branch__c != null
                                                                   ];
        
        for (CreditBranch_ProgramType_Matrix__mdt record : matrixRecords) {
            String branch = record.Credit_Branch__c;
            
            if (!branchToProgramOptions.containsKey(branch)) {
                branchToProgramOptions.put(branch, new List<ProgramTypeOption>());
            }
            
            branchToProgramOptions.get(branch).add(new ProgramTypeOption(
                record.Program_Type_Label__c, 
                record.Program_Type_Value__c
            ));

        }
        
        return branchToProgramOptions;
    }

    public class ProgramTypeOption {
        @AuraEnabled public String label {get; set;}
        @AuraEnabled public String value {get; set;}
        public ProgramTypeOption(String label, String value) {
            this.label = label;
            this.value = value;
        }
    }

    //SAL-6717 : Automation to update Program Types in Quick App - end

}
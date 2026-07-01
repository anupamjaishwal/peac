/**
 * @description Utility class for Quote screen operations, including Flow invocable actions.
 * @author Northteq
 */
public without sharing class NT_QuoteScreenUtil {

    /**
     * @description Invocable method to retrieve Program__c records associated with
     *              the dealer account via Account_Program__c junction object.
     *              Queries Account_Program__c for the dealer, then fetches the
     *              related Program__c records to drive the Program picklist on the
     *              Quote Input screen.
     * @param requests List of GetDealerProgramsRequest containing dealerAccountId
     * @return List<List<Program__c>> Program records per request
     */
    @InvocableMethod(label='Get Dealer Programs' description='Returns Program__c records linked to the dealer account via Account_Program__c')
    public static List<List<Program__c>> getDealerPrograms(List<GetDealerProgramsRequest> requests) {
        List<List<Program__c>> results = new List<List<Program__c>>();

        for (GetDealerProgramsRequest request : requests) {
            List<Program__c> programs = new List<Program__c>();

            if (String.isNotBlank(request.dealerAccountId)) {
                // Step 1: get Program Ids linked to this dealer via the junction object
                List<Account_Program__c> junctionRecords = [
                    SELECT Program__c
                    FROM Account_Program__c
                    WHERE Account__c = :request.dealerAccountId
                    AND Program__c != null
                ];

                Set<Id> programIds = new Set<Id>();
                for (Account_Program__c ap : junctionRecords) {
                    programIds.add(ap.Program__c);
                }

                // Step 2: query the actual Program__c records for display
                if (!programIds.isEmpty()) {
                    programs = [
                        SELECT Id, Name, Program_Code__c
                        FROM Program__c
                        WHERE Id IN :programIds
                        ORDER BY Program_Code__c ASC
                    ];
                }
            }

            results.add(programs);
        }

        return results;
    }

    /**
     * @description Request wrapper for getDealerPrograms invocable method
     */
    public class GetDealerProgramsRequest {
        @InvocableVariable(label='Dealer Account Id' description='The Id of the dealer Account record' required=true)
        public String dealerAccountId;
    }
}
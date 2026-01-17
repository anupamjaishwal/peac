/** @author : Northteq Consulting, Inc.
 * @date : 11/30/20
 * @description: SAL-2062 Simple complex rule evaluator
 *
 */
public with sharing class TC_SimpleComplexRuleEvaluator {
    
    ///decommissioning this class for SAL- 4149
    
    //// Start: Test class to cover codcoverage for decommision class-By Raja Sirivella
    
    public  void TC_SimpleComplexRuleEvaluator(string dummy){
        
    }
    ////End : By Raja Sirivella
    

    /***private static Map<Id,Opportunity> oppsWithChildren;
    private static List<Opportunity> oppsWithMatchingSigners = new List<Opportunity>();

    public static void doAction(Map <Id, Opportunity> oldMap, Map <Id, Opportunity> newMap) {

        if (TC_RecursiveTriggerHelper.simpleComplexRuleEvaluator) return;
**/
        /*
         Bulkified way of checking if there are included complex checklist items on each opp.
         This is because checklists do not have a master-detail relationship to the opp,
         and there's no way to rollup the number of checklists or sum of checklist fields
         */
       /*** oppsWithChildren = new Map<Id,Opportunity>([
            SELECT Id, Primary_Contact__c,
                (SELECT Id, Included_Complex__c FROM TC_Origination__Checklists__r), 
                (SELECT ID, Quantity__c,Equipment_Code__c,Equipment_City__c,Equipment_State__c,Equipment_Street__c,Equipment_Zip__c FROM Assets__r),
                (SELECT Id, Contact__c FROM Guarantor__r WHERE Type__c = 'Personal Guarantor')
            FROM Opportunity WHERE Id IN :newMap.values()
        ]);

        // Check for complex+included checklist items
        for (Opportunity opp : oppsWithChildren.values()) {
            // In the event there's no checklist or the checklist is deleted, set the field to false
            if (opp.TC_Origination__Checklists__r.size() == 0) {
                opp.Has_Included_Complex_Checklist_Items__c = false;
                continue;
            }

            // Loop through the checklists and find the first one that has included complex items, then set the checkbox
            for (TC_Origination__Checklist__c checklist : opp.TC_Origination__Checklists__r) {
                if (checklist.Included_Complex__c > 0) {
                    newMap.get(opp.Id).Has_Included_Complex_Checklist_Items__c = true;
                    break;
                } else {
                    newMap.get(opp.Id).Has_Included_Complex_Checklist_Items__c = false;
                }
            }
        }
**/


        /* SAL-3038 - Multiple Contracts Rule */
       /** findOpenOppsWithMatchingSigners();
    
        // List<Contact> signerContacts = [
        //     SELECT Id, Name 
        //     FROM Contact WHERE 
        // ];

        // END OF: Multiple Contracts Rule


        for (Opportunity opp : newMap.values()) {
            evaluate(opp, oppsWithChildren.get(opp.Id));
        }

        TC_RecursiveTriggerHelper.simpleComplexRuleEvaluator = true;
    }

    private static void evaluate(Opportunity opp, Opportunity oppWithChildren) {

        Boolean hasIncCmplxItems = opp.Has_Included_Complex_Checklist_Items__c;
        Boolean lessorCmplx = opp.Lessor__c == 405 || opp.Lessor__c == 409 || opp.Lessor__c == 421 || opp.Lessor__c == 422 || opp.Lessor__c == 423;
        Boolean pymtFreqCmplx = opp.Payment_Frequency__c == 'Quarterly' || opp.Payment_Frequency__c == 'Annually';
        //Boolean advRentAmtCmplx = opp.Advance_Rental_Amount__c > 0;
        //Boolean secDepPymtsCmplx = opp.Sec_Dep_Pymts__c > 0;
        Boolean docTempCmplx = opp.Opportunity_Document_Template__c == 'Title' || opp.Opportunity_Document_Template__c == 'Rental Docs'; //|| opp.Opportunity_Document_Template__c == 'Loan' || opp.Opportunity_Document_Template__c == 'Lease';
        Boolean fundingTypeCmplx = opp.Opportunity_Funding_Type__c == 'D&A' || opp.Opportunity_Funding_Type__c == 'Delivery Guarantee' || opp.Opportunity_Funding_Type__c == 'Multiple';
        // Boolean ptsCmplx = opp.Points__c > 0;
        Boolean purchaseOptionCmplx =  opp.Purchase_Options__c == 'FMV' || opp.Purchase_Options__c == 'Put' || opp.Purchase_Options__c == 'Assigned Residual' || opp.Purchase_Options__c == 'Assign Resid No Renewal' || opp.Purchase_Options__c == 'Guaranteed Residual'; // opp.Purchase_Options__c == '1.00 Out' 
        Boolean putAmtCmplx = opp.PUT_Amount__c > 0;
        // Boolean numReqAdvPymtsCmplx = opp.Required_Adv_Payments__c > 0;
        // Boolean secDepCmplx = opp.Security_Deposit__c > 0;
        Boolean docDelivMethodCmplx = opp.Document_Delivery_Method__c == 'PDF';
        Boolean transPymtTypeCmplx = opp.Opportunity_Transactional_Payment_Type__c == 'Wire' || opp.Opportunity_Transactional_Payment_Type__c == 'Advanced Funding Line' || opp.Opportunity_Transactional_Payment_Type__c == 'Overnight Check' || opp.Opportunity_Transactional_Payment_Type__c == 'Check';
        Boolean beginMaintFeeAmtCmplx = (opp.Beginning_Maintenance_Fee_Amount__c <> null && opp.Beginning_Maintenance_Fee_Amount__c <> 0) || opp.Beginning_Maintenance_Fee_Amount__c > 0;
        Boolean escalationRateCmplx = (opp.Escalation_Rate__c <> null && opp.Escalation_Rate__c <> 0) || opp.Escalation_Rate__c > 0;
        Boolean year1Cmplx = (opp.Year_1_Pass_Thru_Fee__c <> null && opp.Year_1_Pass_Thru_Fee__c <> 0) || opp.Year_1_Pass_Thru_Fee__c > 0;
        Boolean year2Cmplx = (opp.Year_2_Pass_Thru_Fee__c <> null && opp.Year_2_Pass_Thru_Fee__c <> 0) || opp.Year_2_Pass_Thru_Fee__c > 0;
        Boolean year3Cmplx = (opp.Year_3_Pass_Thru_Fee__c <> null && opp.Year_3_Pass_Thru_Fee__c <> 0) || opp.Year_3_Pass_Thru_Fee__c > 0;
        Boolean year4Cmplx = (opp.Year_4_Pass_Thru_Fee__c <> null && opp.Year_4_Pass_Thru_Fee__c <> 0) || opp.Year_4_Pass_Thru_Fee__c > 0;
        Boolean year5Cmplx = (opp.Year_5_Pass_Thru_Fee__c <> null && opp.Year_5_Pass_Thru_Fee__c <> 0) || opp.Year_5_Pass_Thru_Fee__c > 0;
        Boolean year6Cmplx = (opp.Year_6_Pass_Thru_Fee__c <> null && opp.Year_6_Pass_Thru_Fee__c <> 0) || opp.Year_6_Pass_Thru_Fee__c > 0;
        Boolean year7Cmplx = (opp.Year_7_Pass_Thru_Fee__c <> null && opp.Year_7_Pass_Thru_Fee__c <> 0) || opp.Year_7_Pass_Thru_Fee__c > 0;
        Boolean first12Cmplx = opp.First_12_Months_Free__c;
        Boolean numPassThruFees = (opp.Num_Pass_Thru_Fees__c <> null && opp.Num_Pass_Thru_Fees__c <> 0) || opp.Num_Pass_Thru_Fees__c > 0;
        Boolean numDealersCmplx = opp.Number_of_Dealers__c > 1;
        Boolean numGuarTotalCmplx = opp.Personal_Guarantors__c > 1 || opp.Corporate_Guarantors__c > 1;//Changed personal guarantor threshold to one for initial rollout SAL-3343
        Boolean numCorpGuarCmplx = opp.Corporate_Guarantors__c > 0;
        Boolean salesLeaseback = opp.Sales_Leaseback__c;

        Boolean numAssetsCmplx = calculateNumAssetsComplex(oppWithChildren.Assets__r); //opp.Number_of_Assets__c > 1;

        Boolean multipleSignerContractsCmplx = calculateMultipleSignerContractsComplex(oppWithChildren);
        
        //SAL-3343
        Boolean meetsInitialSimpleCriteria = initialCriteriaMet(opp);
        Boolean hasTexasEquipment = checkTexasEquipment(oppWithChildren);
        Boolean isLoanRecordType = opp.Loan_Record_Type__c;
        Boolean changeWorkflowTypeToComplex = opp.Change_Workflow_Type_to_Complex__c;

        //SAL-3593
        Boolean createdBeforeCutoffDate = opp.CreatedDate < Date.newInstance(2021, 11, 20);
        
        // SAL-4061
        Boolean isAccountStateCA = (opp.Account_Business_State_Province__c == 'CA');
        
        System.debug ('---Evaluating simple/complex rules---');
        System.debug ('Has included complex checklist items: ' + hasIncCmplxItems);
        System.debug ('Lessor is complex: ' + lessorCmplx);
        System.debug ('Payment frequency is complex: ' + pymtFreqCmplx);
        //System.debug ('Advance rental amount is complex: ' + advRentAmtCmplx);
        //System.debug ('Security deposit payments is complex: ' + secDepPymtsCmplx);
        System.debug ('Document template is complex: ' + docTempCmplx);
        System.debug ('Funding type is complex: ' + fundingTypeCmplx);
        // System.debug ('Points is complex: ' + ptsCmplx);
        System.debug ('Purchase option is complex: ' + purchaseOptionCmplx);
        System.debug ('PUT amount is complex: ' + putAmtCmplx);
        // System.debug ('# required advance payments is complex: ' + numReqAdvPymtsCmplx);
        // System.debug ('Security deposit is complex: ' + secDepCmplx);
        System.debug ('Document delivery method is complex: ' + docDelivMethodCmplx);
        System.debug ('Transactional Payment Type is complex: ' + transPymtTypeCmplx);
        System.debug ('Beginning maintenance fee amount is complex: ' + beginMaintFeeAmtCmplx);
        System.debug ('Escalation rate is complex: ' + escalationRateCmplx);
        System.debug ('Year 1 Pass Thru Fee is complex: ' + year1Cmplx);
        System.debug ('Year 2 Pass Thru Fee is complex: ' + year2Cmplx);
        System.debug ('Year 3 Pass Thru Fee is complex: ' + year3Cmplx);
        System.debug ('Year 4 Pass Thru Fee is complex: ' + year4Cmplx);
        System.debug ('Year 5 Pass Thru Fee is complex: ' + year5Cmplx);
        System.debug ('Year 6 Pass Thru Fee is complex: ' + year6Cmplx);
        System.debug ('Year 7 Pass Thru Fee is complex: ' + year7Cmplx);
        System.debug ('First 12 Months Free is complex: ' + first12Cmplx);
        System.debug ('# Pass Thru Fees is complex: ' + numPassThruFees);
        System.debug ('# of Dealers is complex: ' + numDealersCmplx);
        System.debug ('# of Guarantors is complex: ' + numGuarTotalCmplx);
        System.debug ('Guarantor Type is complex (# corp guar >= 1): ' + numCorpGuarCmplx);
        System.debug ('Sales Leaseback: ' + salesLeaseback);
        System.debug ('# of Assets w/ different addresses is complex: ' + numAssetsCmplx);
        System.debug ('Signer has another open contract (opportunity) is complex: ' + multipleSignerContractsCmplx);
        System.debug ('meetsInitialSimpleCriteria: ' + meetsInitialSimpleCriteria);
        System.debug('Has Equipment from Texas: ' + hasTexasEquipment);
        System.debug ('isLoanRecordType: ' + isLoanRecordType);
        System.debug('Change Workflow Type to Complex: ' + changeWorkflowTypeToComplex);
        System.debug('Created Date After Cutoff: ' + createdBeforeCutoffDate);



        opp.Workflow_Type__c = 'Simple';
        if (hasIncCmplxItems || lessorCmplx || pymtFreqCmplx || docTempCmplx
                || fundingTypeCmplx || putAmtCmplx || purchaseOptionCmplx
                || docDelivMethodCmplx || transPymtTypeCmplx || beginMaintFeeAmtCmplx
                || escalationRateCmplx || year1Cmplx || year2Cmplx || year3Cmplx || year4Cmplx || year5Cmplx
                || year6Cmplx || year7Cmplx || first12Cmplx || numPassThruFees || numDealersCmplx || numAssetsCmplx
                || numGuarTotalCmplx || numCorpGuarCmplx || salesLeaseback || multipleSignerContractsCmplx 
                || meetsInitialSimpleCriteria || hasTexasEquipment || isLoanRecordType || changeWorkflowTypeToComplex || createdBeforeCutoffDate || isAccountStateCA) {
            opp.Workflow_Type__c = 'Complex';
        }
    }***/
    
    /** @author : Northteq Consulting, Inc.
    * @date : 9/21/2021
    * @description: SAL-3343 This is logic to limit the opportunities deemed as simple initially
    *
    */
   /*** private static Boolean initialCriteriaMet(Opportunity opp){
        
        Set<String> includedDealerNumbers = new Set<String>{'888303.3974', '888303.3975', '888303.3976'};
        
        Boolean complex = true;
        
        String ort = '';
        
        if(opp.RecordTypeId != null){
            ort = Schema.getGlobalDescribe().get('Opportunity').getDescribe().getRecordTypeInfosById().get(opp.RecordTypeId).getName().split(' ')[0];
        }
        
        if(ort == 'Express'){
            complex = false;
        }else if(ort == 'Program'){
            List<Dealer__c> dealers = [SELECT Id FROM Dealer__c WHERE Dealer__r.Dealer_Number__c IN :includedDealerNumbers AND Opportunity__c = :opp.Id];
            if(dealers.size() > 0){
                complex = false;
            }
        }
        
        return complex;
    }***/

    /** @author : Northteq Consulting, Inc.
    * @date : 9/21/2021
    * @description: SAL-3343 Limits simple opportunities only to those that do not have equipment from Texas
    *
    */
   /*** private static Boolean checkTexasEquipment(Opportunity opp){

        Boolean exists = false;
        for(Asset__c equipment : opp.Assets__r){
            if(equipment.Equipment_State__c == 'TX'){
                exists = true;
                break;
            }
        }

        return exists;
    }

    // SAL-3038 - Number of assets = complex if more than 1 asset WITH different addresses
    private static Boolean calculateNumAssetsComplex(List<Asset__c> assets) {
        Set<String> uniqueStreets = new Set<String>();
        Set<String> uniqueCities = new Set<String>();

        for (Asset__c asset : assets) {
            System.debug('5555 asset '+ asset);
            uniqueStreets.add(asset?.Equipment_Street__c);
            uniqueCities.add(asset?.Equipment_City__c);
        }
        // return true if more than 1 address present 
        return uniqueStreets.size()>1 || uniqueCities.size()>1;
    }

    // SAL-3038 - Multiple Contract
    // Check if this opp's signers are connected to other open opportunities
    private static Boolean calculateMultipleSignerContractsComplex(Opportunity oppWithChildren) {
        Set<Id> signerContactIds = getSignersContactIds(oppWithChildren);

        // Exclude all signers from this opp from the potential match list (to prevent matching against itself)
        Set<Id> potentialMatchContactIds = getSignersContactIds(oppsWithMatchingSigners, oppWithChildren.Id);
        System.debug('5555 signerContactIds '+ signerContactIds);

        System.debug('5555 potentialMatchContactIds '+ potentialMatchContactIds);

        // Check if this opp's signers are connected to other open opportunities
        for (Id signerContactId : signerContactIds) {
            if (potentialMatchContactIds.contains(signerContactId)) {
                return true;
            }
        }

        // return false since no signers
        return false;
    }**/

    // Queries for other open opportunities with matching signer contacts (primary contact or personal guarantor)
   /** private static void findOpenOppsWithMatchingSigners() {

        Set<Id> signerContactIds = getSignersContactIds( oppsWithChildren.values() );

        if (!signerContactIds.isEmpty()) {
        // Query for any open opportunities with matching signers
        Map<Id,Opportunity> matchedOpps = new Map<Id,Opportunity>([ 
            SELECT Id, Primary_Contact__c,
                (SELECT Id, Contact__c FROM Guarantor__r WHERE Type__c = 'Personal Guarantor')
            FROM Opportunity
            WHERE Id IN (SELECT Opportunity__c FROM Guarantor__c WHERE Contact__c IN: signerContactIds)
            AND Approval_Expiration_Date__c > TODAY
            AND StageName !='Lost' AND StageName !='Funded/Booked'
        ]);
        System.debug('5555 matchedOpps with guarantors '+ matchedOpps);


        // Also get find matches by primary contact and add to the map of matches 
        List<Opportunity> oppsMatchedByPrimaryCon = [ 
            SELECT Id, Primary_Contact__c,
                (SELECT Id, Contact__c FROM Guarantor__r WHERE Type__c = 'Personal Guarantor')
            FROM Opportunity
            WHERE Primary_Contact__c IN: signerContactIds
            AND Approval_Expiration_Date__c > TODAY
            AND StageName !='Lost' AND StageName !='Funded/Booked'
        ];
        System.debug('5555 oppsMatchedByPrimaryCon '+ oppsMatchedByPrimaryCon);


        for (Opportunity primaryConMatch : oppsMatchedByPrimaryCon) {
            matchedOpps.put(primaryConMatch.Id, primaryConMatch);
        }
        
        oppsWithMatchingSigners = matchedOpps.values();
        }
    }

    // Returns the contact Ids of -Signers- for an opportunity (or list of opps).
    // IMPORTANT - Opp must have children personal guarantors included to work correctly
    private static Set<Id> getSignersContactIds(List<Opportunity> opps, Id excludedOppId) {
        Set<Id> signerContactIds = new Set<Id>();
        // Populate set of signer contact ids 
        for (Opportunity opp: opps) {
            if (excludedOppId==null || excludedOppId != opp.Id) { // Don't include id's from an excluded opp (itself usually)
                signerContactIds.add(opp.Primary_Contact__c); // Store primary contact
                    
                for (Guarantor__c guarantor : opp.Guarantor__r) {
                    signerContactIds.add(guarantor.Contact__c);
                }
            }
        }
        signerContactIds.remove(null);
        return signerContactIds;
    }
    // Single parameter version
    private static Set<Id> getSignersContactIds(List<Opportunity> opps) {return getSignersContactIds(opps, null);}
    // Single Opp version
    private static Set<Id> getSignersContactIds(Opportunity opp) {return getSignersContactIds(new List<Opportunity>{opp}, null);}**/

}
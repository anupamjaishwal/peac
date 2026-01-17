public with sharing class PEAC_GuarantorHandler  extends SL_Trigger.baseHandler  {
    
    public static boolean gurantorRecursiveCheck = false;
    
    public override void beforeInsert(List<SObject> newList) {
        List<Guarantor__c> newGuarantors = (List<Guarantor__c>) newList;
        handleDuplicatePGCheck(newGuarantors, null);
    }
    
    public override void beforeUpdate(Map<Id, SObject> oldMap, Map<Id, SObject> newMap) {
        List<Guarantor__c> updatedGuarantors = new List<Guarantor__c>();
        Map<Id, Guarantor__c> oldGuarantors = (Map<Id, Guarantor__c>) oldMap;
        Map<Id, Guarantor__c> newGuarantorsMap = (Map<Id, Guarantor__c>) newMap;
        
        for (Id id : newGuarantorsMap.keySet()) {
            Guarantor__c oldRec = oldGuarantors.get(id);
            Guarantor__c newRec = newGuarantorsMap.get(id);
            // Only check if PG_Number__c or Opportunity__c changed
            if (oldRec.PG_Number__c != newRec.PG_Number__c || oldRec.Opportunity__c != newRec.Opportunity__c) {
                updatedGuarantors.add(newRec);
            }
        }
        
        handleDuplicatePGCheck(updatedGuarantors, oldMap);
    }
    
    public override void afterInsert(Map<Id, SObject> newMap) {
        System.debug('PEAC_GuarantorHandler::afterInsert::');
        FieldChangeTracker.trackCreateAndDeleteForChilds(newMap, 'Guarantor__c', 'Created');
    }
    
    public override void afterUpdate(Map<Id, SObject> oldMap, Map<Id, SObject> newMap) {
        if(!PEAC_GuarantorHandler.gurantorRecursiveCheck) {
            PEAC_GuarantorHandler.gurantorRecursiveCheck = true;
            FieldChangeTracker.TrackerWrapper trackerDetails = new FieldChangeTracker.TrackerWrapper();
            trackerDetails.newRecordMap = newMap;
            trackerDetails.oldRecordMap = oldMap;
            trackerDetails.objectApiName = 'Guarantor__c';
            FieldChangeTracker.trackDetails(trackerDetails);
        }
        
    }
    
    public override void beforeDelete(Map<Id, SObject> oldMap) {
        FieldChangeTracker.trackCreateAndDeleteForChilds(oldMap,'Guarantor__c','Deleted');
    }
    
    private void handleDuplicatePGCheck(List<Guarantor__c> guarantorsToCheck, Map<Id, SObject> oldMap) {
        Set<Id> oppIds = new Set<Id>();
        Map<Id, Set<String>> newPGsPerOpp = new Map<Id, Set<String>>();
        
        for (Guarantor__c g : guarantorsToCheck) {
            if (g.Opportunity__c != null && g.PG_Number__c != null) {
                oppIds.add(g.Opportunity__c);
                if (!newPGsPerOpp.containsKey(g.Opportunity__c)) {
                    newPGsPerOpp.put(g.Opportunity__c, new Set<String>());
                }
                newPGsPerOpp.get(g.Opportunity__c).add(g.PG_Number__c);
            }
        }
        
        if (oppIds.isEmpty()) return;
        
        // Map each Opp to its Loan flag
        Map<Id, Boolean> oppIsLoan = new Map<Id, Boolean>();
        for (Opportunity o : [
            SELECT Id, Loan_Record_Type__c
            FROM Opportunity
            WHERE Id IN :oppIds
        ]) {
            oppIsLoan.put(o.Id, o.Loan_Record_Type__c);
        }
        
        // Query existing Guarantors under those Opportunities (ALL opps to support duplicate rule everywhere)
        Map<Id, List<Guarantor__c>> oppToExistingGuarantors = new Map<Id, List<Guarantor__c>>();
        for (Guarantor__c existing : [
            SELECT Id, Opportunity__c, PG_Number__c
            FROM Guarantor__c
            WHERE Opportunity__c IN :oppIds
        ]) {
            if (!oppToExistingGuarantors.containsKey(existing.Opportunity__c)) {
                oppToExistingGuarantors.put(existing.Opportunity__c, new List<Guarantor__c>());
            }
            oppToExistingGuarantors.get(existing.Opportunity__c).add(existing);
        }
        
        
        // Define order of PGs
        List<String> validPGs = new List<String>{'PG1', 'PG2', 'PG3', 'PG4'};
            
        for (Guarantor__c g : guarantorsToCheck) {
            if (g.Opportunity__c == null || g.PG_Number__c == null) continue;
            
            Boolean isLoan = oppIsLoan.containsKey(g.Opportunity__c) ? oppIsLoan.get(g.Opportunity__c) : false;
            
            List<Guarantor__c> existingList = oppToExistingGuarantors.get(g.Opportunity__c);
            Set<String> existingPGs = new Set<String>();
            
            if (existingList != null) {
                for (Guarantor__c existing : existingList) {
                    if (g.Id != null && existing.Id == g.Id) continue; // Skip self
                    existingPGs.add(existing.PG_Number__c);
                }
            }
            
            // Add new PGs from current insert/update batch
            if (newPGsPerOpp.containsKey(g.Opportunity__c)) {
                existingPGs.addAll(newPGsPerOpp.get(g.Opportunity__c));
            }

            if (existingList != null && !existingList.isEmpty()) {
                for (Guarantor__c existing : existingList) {
                    if (existing.Id != g.Id && existing.PG_Number__c == g.PG_Number__c) {
                        g.addError('Duplicate PG Number "' + g.PG_Number__c + '" is not allowed for the same Opportunity.');
                        break;
                    }
                }
            }
            
            // Check max PG limit for only Loan opps
            if (isLoan) {
                if (existingPGs.size() > 4) {
                    g.addError('Cannot have more than 4 PG records under an Opportunity.');
                    continue;
                }
                
                // Sequential Check
                Integer currentIndex = validPGs.indexOf(g.PG_Number__c);
                if (currentIndex > 0) {
                    for (Integer i = 0; i < currentIndex; i++) {
                        String requiredPG = validPGs[i];
                        if (!existingPGs.contains(requiredPG)) {
                            g.addError('You must create PGs in sequence. "' + requiredPG + '" must be created before "' + g.PG_Number__c + '".');
                            break;
                        }
                    }
                }
            }
        }
    }
    
    @future
    public static void updateSyncGuarantor(string recordId) {
        if(recordId != null) {
            List<Guarantor__c> guarList = new List<Guarantor__c>();
            for(Guarantor__c guar : [select id, Sync_To_GDS__c, Latest_Rescore_Date__c from Guarantor__c where Opportunity__c = :recordId]) {
                guar.Sync_To_GDS__c = true;
                guar.Latest_Rescore_Date__c = System.now();
                guarList.add(guar);
            }
            if(guarList.size() > 0) {
                update guarList;
            }
        }
    }
    
}
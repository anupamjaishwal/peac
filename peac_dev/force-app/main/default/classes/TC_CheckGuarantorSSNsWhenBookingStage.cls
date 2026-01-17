public class TC_CheckGuarantorSSNsWhenBookingStage {
    public static Marlin_Configuration__c config = Marlin_Configuration__c.getOrgDefaults();
public static void checkGuarantorSSNsWhenBookingStage (Map <Id, Opportunity> oldMap, Map <Id, Opportunity> newMap, Map<Id, Guarantor__c> guarantors) {
        
        Set <Id> bookingOppIds = new Set <Id> ();
        // only on change to booking stage
        if(config != null && config.Apex_Validations_Active__c){
            for (Opportunity opp : newMap.values ()) {
                if (!opp.Loan_Record_Type__c && opp.StageName == 'Booking' && opp.StageName != oldMap.get (opp.Id).StageName) {
                    bookingOppIds.add (opp.Id);
                }
            }
        }        
        if (!bookingOppIds.isEmpty ()) {
            Id pgRecordTypeId = Schema.SObjectType.Guarantor__c.getRecordTypeInfosByName().get('Personal').getRecordTypeId();
            
            Map<Id, List<Guarantor__c>> guarantorsByOpp = TC_OpportunityFieldUpdates.getGuarantorMap(guarantors);
            for (Id oppId : bookingOppIds) {
                List<Guarantor__c> guarantorsThisOpp = guarantorsByOpp.get(oppId);
                if(guarantorsThisOpp != null){
                    List <String> errors = new List <String> ();
                    for(Guarantor__c guar : guarantorsThisOpp) {
                        if(guar.RecordTypeId == pgRecordTypeId && (String.isBlank(guar.Contact__r.SSN__c) || guar.Contact__r.SSN__c.length() != 9)) {
                            errors.add(guar.Contact__r.Name);
                        }
                    }
                    if(!errors.isEmpty())
                        newMap.get(oppId).addError('Personal Guarantor: ' + errors + ' SSN can\'t be less than 9 digits when stage is changed to Booking');
                }
                
            }
        }
        
    }
}
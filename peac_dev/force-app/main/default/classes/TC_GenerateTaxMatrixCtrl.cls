public class TC_GenerateTaxMatrixCtrl {
    
    @AuraEnabled
    public static void generateTaxMatrix(String recordId) {
        try {
            Id oppId = [SELECT Opportunity__c FROM Asset__c WHERE Id = :recordId].Opportunity__c;
            Tax_Rules_Settings__c settings = Tax_Rules_Settings__c.getInstance();
            
            SObject parent = Schema.getGlobalDescribe().get(settings.Parent_Object__c).newSObject();
            parent.Id = oppId;
            parent.put(settings.Parent_Tax_Calculation_Begin_Field__c, System.now());
            parent.put(settings.Parent_Tax_Calculation_In_Progress_Field__c, true);
            parent.put(settings.Parent_Tax_Calculation_Successful_Field__c, true);
            update parent;
            Map<String, Set<Id> > childRecordIds = new Map<String, Set<Id> >();
            Id recId = Id.valueOf(recordId);
            childRecordIds.put(recId.getSobjectType().getDescribe().getName(), new Set<Id> {recId});
            TaxRules.generateTaxMatrixFuture(oppId, JSON.serialize(childRecordIds));
        } catch(Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }
}
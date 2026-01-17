public class GenerateTaxMatrixCtrl {

    @AuraEnabled
    public static void generateTaxMatrix(String recordId) {
        try {
            System.debug( 'GenerateTaxMatrixCtrl generateTaxMatrix');
            SObject parent = Schema.getGlobalDescribe().get(TaxRulesHelper.getSettings().getParentObject()).newSObject();
            parent.Id = recordId;
            parent.put(TaxRulesHelper.getSettings().getParentTaxCalculationBeginField(), System.now());
            parent.put(TaxRulesHelper.getSettings().getParentTaxCalculationInProgressField(), true);
            parent.put(TaxRulesHelper.getSettings().getParentTaxCalculationSuccessfulField(), true);
            update parent;

            Set<Id> recIds = new Set<Id>();
            List<Tax_Object__mdt> childTaxObjects  = TaxRulesHelper.getSettings().getChildTaxObjects();
            for (Tax_Object__mdt childTaxObject : childTaxObjects) {
                String childQuery = TaxRulesHelper.createQueryString(new Set<String> {'Id', childTaxObject.Tax_State_Field__r.QualifiedApiName}, childTaxObject.Object__r.QualifiedApiName, childTaxObject.Lookup_Field_to_Parent__r.QualifiedApiName, recordId);
                List<SObject> childRecords = Database.query(childQuery);
                for (SObject child : childRecords) {
                    recIds.add(child.Id);
                }
            }
            TaxRulesQueueable taxRulesQueueable = new TaxRulesQueueable(recordId, recIds);
            System.enqueueJob(taxRulesQueueable);
        } catch(Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled
    public static String getTaxCalculationStatus(String recordId) {
        String status = 'none';

        try {
            Set<String> queryFields = new Set<String>();
            queryFields.add(TaxRulesHelper.getSettings().getParentTaxCalculationInProgressField());
            queryFields.add(TaxRulesHelper.getSettings().getParentTaxCalculationSuccessfulField());
            queryFields.add(TaxRulesHelper.getSettings().getParentTaxCalculationCompleteField());
            queryFields.add(TaxRulesHelper.getSettings().getParentTaxCalculationErrorField());

            String parentQuery = TaxRulesHelper.createQueryString(queryFields, String.valueOf(((Id) recordId).getSObjectType()), 'Id', recordId);
            SObject parent = Database.query(parentQuery);

            Decimal alertSeconds = TaxRulesHelper.getSettings().getTaxCalculationCompletionAlertSeconds();

            if ((Boolean) parent.get(TaxRulesHelper.getSettings().getParentTaxCalculationInProgressField()))
                status = 'warning';
            else if (!(Boolean) parent.get(TaxRulesHelper.getSettings().getParentTaxCalculationSuccessfulField()) && parent.get(TaxRulesHelper.getSettings().getParentTaxCalculationCompleteField()) != null)
                status = (String) parent.get(TaxRulesHelper.getSettings().getParentTaxCalculationErrorField());
            else if (parent.get(TaxRulesHelper.getSettings().getParentTaxCalculationCompleteField()) != null && System.now().getTime() - ((Datetime) parent.get(TaxRulesHelper.getSettings().getParentTaxCalculationCompleteField())).getTime() < (alertSeconds == null ? 90 : alertSeconds) * 1000)
                status = 'success';
        } catch(Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }

        return status;
    }

}
global class GenerateTaxMatrixInvocable {
	global class TaxMatrixParam { 
        @InvocableVariable
        global String recordId;
        @InvocableVariable
        global String status;
        global TaxMatrixParam () {}

    }
    @InvocableMethod(
            Label='Generate Tax Matrix Async Platform Event'
            Description='Generates Tax Matrix asycn using a platform event. Need to enable via a custom setting also'
    ) 
    global static void execute(List<TaxMatrixParam> params) {
        for (TaxMatrixParam param : params) {
             if (param.status == 'Submitted') TaxRules.generateTaxMatrix (param.recordId);
		}
        
    }
    
    
}
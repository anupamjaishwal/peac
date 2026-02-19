({
	doInIt : function(cmp, event, helper) {
		helper.runTwhStoredProcFraudQuery( cmp, event );
		// helper.runGdsScore (cmp, event, helper);
	}
})
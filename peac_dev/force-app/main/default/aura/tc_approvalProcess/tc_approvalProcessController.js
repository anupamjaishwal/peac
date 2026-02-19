({
	doInit : function(cmp, event, helper) {
		helper.getApprovalProcessDefinitions (cmp, event, helper);
	}
    , submitClicked : function(cmp, event, helper) {
		helper.submitProcesses (cmp, event, helper);
	}, onRadio : function(cmp, event, helper) {
        
		let results = cmp.find("radioButtonGroup");
        for (let i = 0; i<results.length;i++) {
            results[i].set("v.value",false);
        }
             
        event.getSource().set("v.value",true);
	}
    
})
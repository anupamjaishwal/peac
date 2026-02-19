({
	onInit : function(component, event, helper) {
		helper.getSignerLabels(component, event, helper);     
        helper.getTableFieldSetForStatus(component, event, helper);         
        helper.getDateTime(component, event, helper);   
	}   
})
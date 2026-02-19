({
	 doInit: function(component, event, helper) {
        var leadId = component.get('v.recordId');
        helper.validateLead(component, component.get('v.recordId'));
    }
})
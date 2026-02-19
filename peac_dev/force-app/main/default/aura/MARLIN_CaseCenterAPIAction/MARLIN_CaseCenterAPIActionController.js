({
    doInit: function(component, event, helper) {
        
        var opptyId = component.get('v.recordId');       
        helper.validateOpportunity(component, component.get('v.recordId'));
     //  alert('check 1');
        
        
    },
    
    showSpinner: function(component, event, helper) {
        
        var spinner = component.find('spinner');
        var evt = spinner.get("e.toggle");
        evt.setParams({
            isVisible: true
        });
        evt.fire();
    },
    
    hideSpinner: function(component, event, helper) {
        
        var spinner = component.find('spinner');
        var evt = spinner.get("e.toggle");
        evt.setParams({
            isVisible: false
        });
        evt.fire();
    },
    
    processClose: function(component, event, helper) {
        
        var dismissActionPanel = $A.get("e.force:closeQuickAction");
        dismissActionPanel.fire();
    },
})
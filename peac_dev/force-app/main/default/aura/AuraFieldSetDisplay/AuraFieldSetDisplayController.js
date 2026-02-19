({
    doInit : function(component, event, helper) {
        helper.initialize(component, event, helper);
    },
    doSubmit : function (component, event, helper) {
        helper.handleSubmit(component, event, helper);
    },
    
    handleError : function(component, event, helper) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": "Error!",
            "message": "Error."
        });
        toastEvent.fire();
    }
})
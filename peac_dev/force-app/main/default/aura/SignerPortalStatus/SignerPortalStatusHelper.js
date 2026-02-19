({
    getSignerStatus : function(component, event, helper) {
        let action = component.get("c.getSignerStatusInfo");
        action.setParams({
            parentRecordId:component.get("v.recordId")
        });
        action.setCallback(this, function (response) {
            let state = response.getState();
            console.log(state);
            if (state == 'SUCCESS') {
                component.set("v.signerList",response.getReturnValue());
            } else if (state == 'ERROR') {
                var errors = response.getError();
            }
        });
        $A.enqueueAction(action);
    }          
})
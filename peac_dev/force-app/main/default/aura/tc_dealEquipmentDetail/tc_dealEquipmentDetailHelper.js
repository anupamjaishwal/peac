({
    getPicklistVals: function(component, picklistMap, contrValue, elementId) {
        var action = component.get("c.getPicklistVals");
        action.setParams({
            "picklistMapString": JSON.stringify(picklistMap),
            "contrValue": contrValue
        });
        
        var opts = [];
        action.setCallback(this, function(response) {
            if (response.getState() == "SUCCESS") {
                var allValues = response.getReturnValue();
 
                if (allValues != undefined && allValues.length > 0) {
                    opts.push({
                        class: "optionClass",
                        label: "--- None ---",
                        value: ""
                    });
                }
                
                for (var i = 0; i < allValues.length; i++) {
                    opts.push({
                        class: "optionClass",
                        label: allValues[i],
                        value: allValues[i]
                    });
                }
                component.find(elementId).set("v.options", opts);
            }
        });
        
        $A.enqueueAction(action);
    }
})
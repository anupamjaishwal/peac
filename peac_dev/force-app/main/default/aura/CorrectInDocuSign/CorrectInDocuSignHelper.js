({
    doInitHelper : function(component, event) {
        //alert("inside helper");
        var labelVal = $A.get("$Label.dsfs.statuscorrectindocusignerrormessage")
        component.set("v.labelText", labelVal);
        //alert(labelVal);
        var action = component.get("c.getCorrectInDocuSignBtn");
        //alert(action);
        //alert(component.get("v.recordId"));
        action.setParams({
            "docuId":component.get("v.recordId")
        });
        action.setCallback(this, function(response) {
            if (response.getState() === "SUCCESS") {
                var data = response.getReturnValue();
                if (data.dsfs__Envelope_Status__c != "Sent" && data.dsfs__Envelope_Status__c != "Delivered") {
                    var toggleText = component.find("labelTextVal");
                    component.set("v.showMe", !component.get("v.showMe"));
                    //alert(labelVal);	
                }
                else{
                    
                    window.location.href='/apex/dsfs__DocuSignAdvCorrectStandalone?e='+data.dsfs__DocuSign_Envelope_ID__c;
                }
            }
        });
        $A.enqueueAction(action);
        
    }
    
})
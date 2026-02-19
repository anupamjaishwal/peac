({
    processCaseCenterCallout: function(component, dealerNumber) {
        component.set('v.validateSubmitResult', 'In Progress');
        
        var calloutResp = '';
        var action = component.get("c.submitAppToGDS");
        action.setParams({
            OpptyId: component.get('v.recordId')
        });
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            
            if (component.isValid() && state === "SUCCESS") {
                calloutResp = response.getReturnValue();
             //   alert('calloutResp-- '+calloutResp);
                if(calloutResp.substring(0,13) == 'Error Message'){
                    //        message = message + '<br /><b>Callout Result:</b>: Fail';
                    component.set('v.validateSubmitResult', 'Fail [' + calloutResp + ']');
                    //        component.set('v.rapportResponse', calloutResp);                
                    
                }
                else{
                    //   message = message + '<br /><b>Callout Result:</b>: Success';
                    component.set('v.validateSubmitResult', 'Succcess [' + calloutResp + ']');
                    //  component.set('v.rapportResponse', calloutResp);  
                    
                    // Display result in toast
                    var resultsToast = $A.get("e.force:showToast");
                    resultsToast.setParams({
                        "title": "Succcess",
                        "message": calloutResp,
                        "type": "success"
                    });
                    resultsToast.fire();
                    
                    // Close the action panel
                    //var dismissActionPanel = $A.get("e.force:closeQuickAction");
                    //dismissActionPanel.fire();

                    // tamarack added for app wizard

                                        if (component.get ('v.fromWizard')) {
                                            var navEvt = $A.get("e.force:navigateToSObject");
                                                                    navEvt.setParams({
                                                                      "recordId": component.get ('v.recordId'),
                                                                      "slideDevName": "detail"
                                                                    });
                                                                    navEvt.fire();
                                        } else {
                                            // Close the action panel
                                                                var dismissActionPanel = $A.get("e.force:closeQuickAction");
                                                                dismissActionPanel.fire();
                                        }
                    
                }       
                
                $A.get('e.force:refreshView').fire();
                //alert(response.getReturnValue());
            } else {
                //alert('Error');
                component.set('v.validateSubmitResult', response.getReturnValue());
            }
            
        });
        
        $A.enqueueAction(action);
    },
    

    validateOpportunity: function(component, opptyId) {
        
        component.set('v.validateAppResult', 'In Progress');
        var action = component.get("c.validateApplicationForSubmission");
        action.setParams({
            "OpptyId": opptyId
        });
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            
            if (component.isValid() && state === "SUCCESS") {
             //   alert(JSON.stringify(response));
             //   alert(response.getReturnValue());
                var validationResult = response.getReturnValue();
                if (validationResult == 'Success') {
                    //    message = message + '<br /><b>Validation Result:</b>: Success';
                    component.set('v.validateAppResult', validationResult);
                    
                    this.processCaseCenterCallout(component);
                    
                    
                }
                else{ 
               //     alert('Result:' + validationResult);
                    //	message = message + '<br /><b>Validation Result:</b>: ' + validationResult; 
                    component.set('v.validateAppResult', validationResult);   
                    //component.set('v.rapportResponse', '');            
                }
                
                
                //alert(response.getReturnValue());
            } else {
                component.set('v.validateAppResult', response.getReturnValue());
            }
            
            
        });
        
        $A.enqueueAction(action);
    }
})
({
    processRapportCallout: function(component, dealerNumber) {
        //alert('dealer in helpr-- '+ dealerNumber);
        component.set('v.validateSubmitResult', 'In Progress');
        
   //     alert('rapport:' + JSON.stringify(component.get('v.ValidateRPMap')));
        //  var message = component.get('v.rapportProgress');
        var calloutResp = '';
        var action = component.get("c.generateApplicationNumber");
        action.setParams({
            OpptyId: component.get('v.recordId'),
            dNumber : dealerNumber,
            aMapPhoneToCCAN : component.get('v.ValidateRPMap')
        });
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            
            if (component.isValid() && state === "SUCCESS") {
                calloutResp = response.getReturnValue();
                //alert('calloutResp-- '+calloutResp);
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
                    


                    // tamarack added for app wizard

                    if (component.get ('v.fromWizard') && component.get ('v.runGDS')) {
                        
                        // fire off gds score
                        //
                        var action = component.get('c.callGdsScoreApex');

                        action.setParams({
                            recordId: component.get('v.recordId')
                        });
                        
                        $A.enqueueAction(action); // fire and forget
                        
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
                        var navEvt = $A.get("e.force:navigateToSObject");
                                                navEvt.setParams({
                                                  "recordId": component.get ('v.recordId'),
                                                  "slideDevName": "detail"
                                                });
                                                navEvt.fire();
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
    
    processDealerCallout : function(component, validationResult){
        //alert('accountType in processDealerCallout helper-- '+validationResult);
        component.set('v.validateDealerSubmission', 'In Progress');
        
        //  var message = component.get('v.rapportProgress');
        var calloutResp = '';
        var action = component.get("c.checkAccountType");
        action.setParams({
            OpptyId: component.get('v.recordId')
        });
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            //alert(state);
            if (component.isValid() && state === "SUCCESS") {
                calloutResp = response.getReturnValue();
                //alert('calloutResp inside send dealer data helepr-- '+calloutResp);
                //alert('calloutResp-- '+calloutResp);
                if(calloutResp.includes('ERROR') || calloutResp.includes('Error')){
                    //alert('inside if');
                    component.set('v.validateDealerSubmission', 'Fail [' + calloutResp + ']');              
                    
                }else if(calloutResp.includes('Fail')){
                    //alert('inside else');
                    component.set('v.validateDealerSubmission', 'Fail [' + calloutResp + ']');  
                }
                    else{
                        //alert('inside else');
                        //   message = message + '<br /><b>Callout Result:</b>: Success';
                        component.set('v.validateDealerSubmission', 'Dealer Created, DealerId :' + calloutResp);
                        this.processRapportCallout(component,response.getReturnValue());                                                              
                    }            
            } else {
                //alert('Error');
                component.set('v.validateDealerSubmission', response.getReturnValue());
            }
            
            
        });
        
        $A.enqueueAction(action);
    },
    
    validateDealerData : function(component){
        
        component.set('v.validateDealerData', 'In Progress');
        var opptyId = component.get('v.recordId');
        var action = component.get("c.validateDealerForSubmission");
        action.setParams({
            OpptyId : opptyId
        });
        
        action.setCallback(this, function(response) {
            
            var state = response.getState();
            //alert('state-- '+state);
            if (component.isValid() && state === "SUCCESS") {
                var validationResult = response.getReturnValue();
                //alert('validationResult--11--- '+validationResult);
                if(validationResult.includes('SUCCESS')){
                    component.set('v.validateDealerData', validationResult);
                    this.validatePGsCallout(component,validationResult);
                }else{
                    component.set('v.validateDealerData', validationResult);
                                         
                }
            } else {
                component.set('v.validateDealerData', response.getReturnValue());
            }
            
        });
        
        $A.enqueueAction(action);
    },
    
    
    validatePGsCallout: function(component, validationResult) {
        //alert('validationResult-- in PG helpre-- '+validationResult);
        //  var message = component.get('v.rapportProgress');
        component.set('v.validatePGsResult', 'In Progress');
        var calloutResp = '';
        var action = component.get("c.validatePGsInRapportNew");
        action.setParams({
            "OpptyId": component.get('v.recordId')
        });
        
        action.setCallback(this, function(response) {
            var state = response.getState();
         //   alert(JSON.stringify(response.getReturnValue().MapPhoneToCCAN));
            
          //  alert(response.getReturnValue().Status);
            if (component.isValid() && state === "SUCCESS") {
                calloutResp = response.getReturnValue().Status;
                if(calloutResp.substring(0,13) == 'Error Message'){
                    component.set('v.validatePGsResult', 'Fail [' + calloutResp + ']');               
                    
                }
                else{
                    if(isNaN(validationResult)){
                      //  alert(validationResult);
                      //  alert('true/false--'+ isNaN(validationResult));
                        component.set('v.validatePGsResult', calloutResp); 
                        component.set('v.ValidateRPMap',response.getReturnValue().MapPhoneToCCAN);
                        this.processDealerCallout(component,validationResult);
                    }else {
                      //  alert('validationResult in PG-- '+validationResult);
                        component.set('v.validatePGsResult', calloutResp); 
                        component.set('v.ValidateRPMap',response.getReturnValue().MapPhoneToCCAN);
                        this.processRapportCallout(component, validationResult); 
                    }
                    
                }                
                
            } else {
                //alert('Error');
                component.set('v.validatePGsResult', response.getReturnValue());
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
                var validationResult = response.getReturnValue();
                if (validationResult == 'Success') {
                    //    message = message + '<br /><b>Validation Result:</b>: Success';
                    component.set('v.validateAppResult', validationResult);
                    
                    //Previous code
                    //this.validatePGsCallout(component);
                    //Nirosha Changes
                    this.validateDealerData(component);
                    
                    
                }
                else{ 
                    //alert('Result:' + validationResult);
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
({
    doInit: function(component, event, helper) {
       
         var action = component.get("c.GetAccount");
            action.setParams({
                "AccId" : component.get("v.recordId")
                
            });
            // set call back 
            action.setCallback(this, function(response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                   
                    component.set('v.Objaccount', response.getReturnValue());
                    console.log('v.Objaccount', component.get('v.Objaccount'));
                }
                  
            });
           
            $A.enqueueAction(action);
        
         var action2 = component.get("c.GetContact");
            action2.setParams({
                "AccId" : component.get("v.recordId")
                
            });
            // set call back 
            action2.setCallback(this, function(response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                   
                    component.set('v.ObjCon', response.getReturnValue());
                   
                } 
                    
                
                  
            });
           
            $A.enqueueAction(action2);
        
    },
                               
	/*Onchecked : function(component, event, helper) {
     
        
         var action2 = component.get("c.UpdateAccount");
            action2.setParams({
                "objAcc" : component.get("v.Objaccount")
                
            });
            // set call back 
            action2.setCallback(this, function(response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                   
                 
                }else {
                    console.log('response.getError()',response.getError());
                    var errorMsg = response.getError()[0].message;
                    var toastEvent = $A.get("e.force:showToast");
                    
                    toastEvent.setParams({
                        title : 'Error',
                        message: errorMsg,
                        type: 'error',
                        mode: 'sticky',
                    }); 
                    toastEvent.fire();
                    
                }
                  
            });
           
            $A.enqueueAction(action2);
        
    }, */

    UpdateContactRecord : function(component, event, helper) {
        
       
        
         var action2 = component.get("c.UpdateContact");
            action2.setParams({
                "objACRW" : JSON.stringify(component.get("v.ObjCon")),
                "objAcc" :  component.get("v.Objaccount")
            });
            // set call back 
            action2.setCallback(this, function(response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                   
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        title : 'Success',
                        message: ' Successfully Update ',
                        type: 'success',
                        mode : 'dismissible'
                        
                    });
                    toastEvent.fire();
                    
                   
                }else {
                    console.log('response.getError()',response.getError());
                    var errorMsg = response.getError()[0].message;
                    var toastEvent = $A.get("e.force:showToast");
                    
                    toastEvent.setParams({
                        title : 'Error',
                        message: errorMsg,
                        type: 'error',
                        mode : 'dismissible'
                       
                    }); 
                    toastEvent.fire();
                    
                }
                
            });
           
            $A.enqueueAction(action2);
        
    },
    
  		
	
})
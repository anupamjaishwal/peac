({
    doInit : function (component, event, helper) {
        console.log('dealQuoteController init',component.get("v.clientWrapper.deal"));
     
        //alert(component.get("v.clientWrapper.deal.Risk_Based_Pricing__c"));
        var recId = component.get("v.clientWrapper.deal.opportunity.Id");
      
        
        var getOpportunity = component.get("c.getOpportunity");
        getOpportunity.setParams({
            "recordId": recId         
        });
        getOpportunity.setCallback(this, function(result) {
            var state = result.getState();
            
            if (state === "SUCCESS"){
              //  alert(JSON.stringify(result.getReturnValue()));
                component.set("v.opplst",result.getReturnValue());
                console.log('gating criteria met: ', component.get('v.opplst.Gating_Criteria_Met__c'));
                console.log('dfgasdfasdfasdfasdff',component.get("v.opplst"));
            }
        });
        $A.enqueueAction(getOpportunity); 
        
        var action = component.get("c.sendApprovedOffers");
          component.set("v.showSpinner",true);
        action.setParams({
            "recordId": recId         
        });
        action.setCallback(this, function(result) {
            var state = result.getState();
            
            if (state === "SUCCESS"){
               
                var resultNew = JSON.parse(JSON.stringify(result.getReturnValue()));
                component.set("v.offerWrap", result.getReturnValue());
                console.log('resultNew', resultNew);
                console.log('resultNew', component.get("v.offerWrap"));
                component.set("v.showSpinner",false);
                
            }
        });
       // $A.enqueueAction(action);  
        
    },
    
    itemsChange : function (component, event, helper) {
         component.set("v.showSpinner",true);
        var recId = component.get("v.clientWrapper.deal.opportunity.Id");
        var action = component.get("c.sendApprovedOffers");
        action.setParams({
            "recordId": recId     
        });
        action.setCallback(this, function(result) {
            var state = result.getState();
            
            if (state === "SUCCESS"){
                //alert(result.getReturnValue());
                component.set("v.offerWrap",result.getReturnValue());
                component.set("v.showSpinner",false);
                
            }
        });
        $A.enqueueAction(action);   
        
    },

    goToNext : function(component, event, helper) {
		var navEvent = $A.get("e.c:tc_applicationNavigation_evt");
        var dir = "next";
        
        navEvent.setParams({
            data: {
                direction: dir
            }
        });
        
        navEvent.fire();
	},

	quickSave : function (cmp, event, helper) {
	    console.log('entered quick save in controller');
        helper.quickSave(cmp, event, helper);
    }
})
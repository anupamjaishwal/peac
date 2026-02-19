({
    
    doInit : function(component, event, helper) {
       	helper.queryAccountPriority(component); 
        
    }, 
  
  refreshView : function(component, event, helper) {
	  component.set("v.errorMessage","");
      helper.queryAccountPriority(component); 
        
    }, 
    
    queryAccount: function(component, event, helper) {
       var stepName = event.getParam("value");
       helper.queryAccount(component,stepName);
	   $A.get('e.force:refreshView').fire(); 

       
    }
 
})
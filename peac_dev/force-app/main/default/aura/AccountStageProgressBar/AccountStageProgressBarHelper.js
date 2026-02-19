({
    queryAccount : function(cmp,stepName,callback) {
        var recordID = cmp.get("v.recordId");
        var action = cmp.get("c.getAccount");
        action.setParams({"stepName": stepName,"recordID": recordID});
        action.setCallback(this, function(response) {
            var state = response.getState();
            //alert(JSON.stringify(result));
            if (cmp.isValid() && state === "SUCCESS") 
            {
                
                $A.get('e.force:refreshView').fire();
                 //alert(JSON.stringify(response));
                var result = response.getReturnValue();
              //  alert(JSON.stringify(result));
                if(!result.isSuccess){
                 	//alert(response.errorMsg);
                 	var strin = result.errorMsg.replace("&amp;", "&");
                    var str = strin.replace("FIELD_CUSTOM_VALIDATION_EXCEPTION,","#");
                    var str1 = str.split('#').pop().split(':').shift();
                  //  alert(str1);
                   cmp.set("v.errorMessage",str1);
                }
                else{
                    
                    cmp.set("v.errorMessage","");
                }
            }
            
        });
        $A.enqueueAction(action);
    },	

   queryAccountPriority : function(cmp,callback) {
     var recordID = cmp.get("v.recordId");
     var action = cmp.get("c.getAccountPriority");
      action.setParams({"recordID": recordID});
        action.setCallback(this, function(response) {
   
            var state = response.getState();
            if (cmp.isValid() && state === "SUCCESS") 
            {
                cmp.set("v.account",response.getReturnValue());
             //   cmp.set("v.errorMessage","");
   
            }
       
        });
        $A.enqueueAction(action);
    }	    
	
})
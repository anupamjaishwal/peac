({
	sendBorrowerHelper : function(cmp, event, helper) {
        
        
        /*var spinner = cmp.find("spinner");
		$A.util.removeClass(spinner, 'slds-hide');
		$A.util.addClass(spinner, 'slds-show');*/


        var action = cmp.get('c.createBorrowerAsCustomerLtng');
        action.setParams({'recordId' : cmp.get('v.recordId')});

        action.setCallback(this, function (result) {
            
            //$A.util.removeClass(spinner, 'slds-show');
            //$A.util.addClass(spinner, 'slds-hide');

            if (result.getState() === 'SUCCESS') {
                var returnVal = result.getReturnValue();
                helper.showToast ('Success','Infolease customer created', 'dismissible','success');
				$A.get('e.force:refreshView').fire();
            } else {
                helper.showToast ('Error', result.getError()[0].message, 'sticky','error');
            }
            $A.get('e.force:closeQuickAction').fire();
        });
        
        $A.enqueueAction(action);
    }
    , showToast : function(title, message, mode, type) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": title,
            "message": message,
            "mode" : mode,
            "type" : type 
        });
        toastEvent.fire();
    },
})
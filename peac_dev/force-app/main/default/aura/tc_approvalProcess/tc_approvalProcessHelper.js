({
	getApprovalProcessDefinitions : function(cmp, event, helper) {
        
        var spinner = cmp.find("spinner");
		$A.util.removeClass(spinner, 'slds-hide');
		$A.util.addClass(spinner, 'slds-show');

        
        var action = cmp.get('c.getApprovalProcesses');
        action.setParams({'recordId' : cmp.get('v.recordId')});
        
        action.setCallback(this, function (result) {
            
            $A.util.removeClass(spinner, 'slds-show');
            $A.util.addClass(spinner, 'slds-hide');



                if (result.getState() === 'SUCCESS') {
                    //var processes = result.getReturnValue();
                    cmp.set ('v.approvalProcesses', result.getReturnValue());
                } else {
                    helper.showToast ('Error', result.getError()[0].message, 'sticky','error');
                    $A.get("e.force:closeQuickAction").fire ();
                }
        });
        $A.enqueueAction(action);
	},
    submitProcesses : function(cmp, event, helper) {
        var spinner = cmp.find("spinner");
		$A.util.removeClass(spinner, 'slds-hide');
		$A.util.addClass(spinner, 'slds-show');

        
        var action = cmp.get('c.submitApprovalProcesses');
        
        
        action.setParams({
            'approvalProcessWrappersJson' : JSON.stringify(cmp.get('v.approvalProcesses'))
            , 'recordId' : cmp.get('v.recordId')});
        
        action.setCallback(this, function (result) {
            
            
            $A.util.removeClass(spinner, 'slds-show');
            $A.util.addClass(spinner, 'slds-hide');



                if (result.getState() === 'SUCCESS') {
                    //var processes = result.getReturnValue();
                    cmp.set ('v.approvalProcesses', result.getReturnValue());
                    helper.showToast ('Success', 'Submitted for Approval', 'dismissible','success');
                    $A.get("e.force:closeQuickAction").fire ();
                } else {
                    helper.showToast ('Error', result.getError()[0].message, 'sticky','error');
                }
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
    }

})
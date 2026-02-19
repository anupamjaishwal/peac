({
	searchHelper : function(cmp, event, helper) {

        let action = cmp.get('c.getFundingAuthUsers');

        action.setParams({ recordId: cmp.get('v.recordId'), term: cmp.get('v.search')});

            action.setCallback(this, function (result) {

                if (result.getState() === 'SUCCESS') {
					cmp.set ('v.results', result.getReturnValue());
                } else {
                    helper.showToast ('Error', result.getError()[0].message, 'sticky', 'error');
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
    ,selectUserHelper : function(cmp, event, helper) {
        
        var spinner = cmp.find("spinner");
        
        $A.util.removeClass(spinner, 'slds-hide');
        $A.util.addClass(spinner, 'slds-show');

        let action = cmp.get('c.selectUser');
        action.setParams({ recordId: cmp.get('v.recordId')
                          , userJson: JSON.stringify(cmp.get ('v.results').find(addr => addr.selected))});

            action.setCallback(this, function (result) {
                
 
                $A.util.removeClass(spinner, 'slds-show');
            	$A.util.addClass(spinner, 'slds-hide');

                if (result.getState() === 'SUCCESS') {
					helper.showToast ('Success', 'User selected', 'dismissible','success');
                    $A.get('e.force:refreshView').fire();
                    $A.get("e.force:closeQuickAction").fire();
                } else {
                    helper.showToast ('Error', result.getError()[0].message, 'sticky', 'error');
                    //$A.get("e.force:closeQuickAction").fire();
                }

            });
            $A.enqueueAction(action);
    }
})
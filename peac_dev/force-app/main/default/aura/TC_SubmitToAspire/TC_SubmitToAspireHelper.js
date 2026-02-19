({
    refreshAspireData: function (cmp) {
        console.log('refreshAspireData', cmp.get('v.recordId'));
        var action = cmp.get('c.refreshAspireData');

        action.setParams({
            recordId: cmp.get('v.recordId')
        });

        var spinner = cmp.find("spinner");
        $A.util.removeClass(spinner, "slds-hide");
        
        action.setCallback(this, function (result) {
            if (result.getState() === 'SUCCESS') {
                this.submitToAspire(cmp);
            } else {
                console.log(result.getError());
                this.showToast('Error', result.getError()[0].message, 'error', 'sticky');
                $A.util.addClass(spinner, "slds-hide");
                $A.get('e.force:closeQuickAction').fire();
            }
        });

        $A.enqueueAction(action);
    },
    
    submitToAspire: function (cmp) {
        console.log('submitToAspire', cmp.get('v.recordId'));
        var action = cmp.get('c.submitToAspire');

        action.setParams({
            recordId: cmp.get('v.recordId')
        });
        
        action.setCallback(this, function (result) {
            if (result.getState() === 'SUCCESS') {
                this.showToast('Success', 'Opportunity has been submitted successfully to Aspire.', 'success', 'sticky');
                $A.get('e.force:refreshView').fire();
            } else {
                console.log(result.getError());
                this.showToast('Error', result.getError()[0].message, 'error', 'sticky');
            }
            
            $A.get('e.force:closeQuickAction').fire();
        });

        $A.enqueueAction(action);
    },
    
    showToast : function(title, message, type, mode) {
        var toastEvent = $A.get('e.force:showToast');
        
        toastEvent.setParams({
            'title': title,
            'message': message,
            'type': type,
            'mode': mode
        });
        
        toastEvent.fire();
    }
})
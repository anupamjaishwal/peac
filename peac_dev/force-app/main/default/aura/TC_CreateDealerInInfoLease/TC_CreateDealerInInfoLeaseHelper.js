({
    sendDealer: function (cmp) {
        console.log('createDealer', cmp.get('v.recordId'));
        var action = cmp.get('c.createDealer');

        action.setParams({
            recordId: cmp.get('v.recordId')
        });
        
        action.setCallback(this, function (result) {
            if (result.getState() === 'SUCCESS') {
                var response = result.getReturnValue();
                if (response.startsWith('Success')) {
                        this.showToast('Success', response, 'success', 'sticky');
                } else
                    this.showToast('Error', response, 'error', 'sticky');
            } else {
                console.log(result.getError());
                this.showToast('Error', result.getError()[0].message, 'error', 'sticky');
            }
            
            $A.get('e.force:refreshView').fire();
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
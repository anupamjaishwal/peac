({
    generateTaxMatrix: function (cmp) {
        console.log('generateTaxMatrix', cmp.get('v.recordId'));
        var action = cmp.get('c.generateTaxMatrix');

        action.setParams({
            recordId: cmp.get('v.recordId')
        });
        
        action.setCallback(this, function (result) {
            $A.get('e.force:closeQuickAction').fire();
            
            if (result.getState() === 'SUCCESS') {
                this.showToast('Success', 'Tax Matrix Generation queued successfully.', 'success', 'sticky');
                $A.get('e.force:refreshView').fire();
            } else {
                console.log(result.getError());
                this.showToast('Error', result.getError()[0].message, 'error', 'sticky');
            }
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
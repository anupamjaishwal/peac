({
    getTaxCalculationAlert: function (cmp) {
        console.log('getTaxCalculationAlert', cmp.get('v.recordId'));
        var action = cmp.get('c.getTaxCalculationStatus');

        action.setParams({
            recordId: cmp.get('v.recordId')
        });
        
        action.setCallback(this, function (result) {
            if (result.getState() === 'SUCCESS') {
                var status = result.getReturnValue();
                console.log('getTaxCalculationAlert status', status);
                
                if (status == 'warning')
                    this.showToast('In Progress', 'Tax calculation in progress. Refresh page for status updates.', 'warning', 'sticky');
                else if (status == 'success') {
                    this.showToast('Success', 'Tax calculation completed successfully.', 'success', 'sticky');
                    $A.get('e.force:refreshView').fire();
                }
                else if (status != 'none')
                    this.showToast('Error', 'Tax calculation resulted in error - ' + status, 'error', 'sticky');
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
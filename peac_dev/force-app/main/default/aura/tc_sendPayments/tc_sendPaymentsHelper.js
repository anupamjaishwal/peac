({
	sendPaymentsHelper : function(cmp) {
		var action = cmp.get('c.sendPayments');

        action.setParams({
            recId: cmp.get('v.recordId')
        });

        action.setCallback(this, function (result) {
			var spinner = cmp.find("mySpinner");
            $A.util.toggleClass(spinner, "slds-hide");
            
            if (result.getState() === 'SUCCESS') {
                var numberOfPayments = result.getReturnValue();
                //alert ('Success: ' + numberOfPayments + ' payments successfully sent!');
                TCLightningUtils.showToast('Success', numberOfPayments + ' payments successfully sent!', 'success', 'dismissible');
            } else {
                console.log(result.getError());
                //alert ('Error: ' + result.getError()[0].message);
                TCLightningUtils.showToast('Error', result.getError()[0].message, 'error', 'sticky');
            }
            
            $A.get("e.force:closeQuickAction").fire()
        });

        $A.enqueueAction(action);
	},
    // success, error
    showToast : function(title, message, toastType, mode) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            title : title,
            message: message,
            messageTemplate: 'Record {0} created! See it {1}!',
            duration:' 5000',
            key: 'info_alt',
            type: toastType,
            mode: mode
        });
        toastEvent.fire();
    },
})